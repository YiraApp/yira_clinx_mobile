// Family links: the family code card and the "Link an existing Yira user"
// sheet, with a fake API. Any layout overflow fails the test. Run with
// DIET_SHOTS=<dir> and --update-goldens to also save screenshots.
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'package:yiraclinics/features/presentation/patient/family/family_code_card.dart';
import 'package:yiraclinics/features/presentation/patient/family/family_link_api.dart';
import 'package:yiraclinics/features/presentation/patient/family/family_add_options_sheet.dart';
import 'package:yiraclinics/features/presentation/patient/family/family_links_section.dart';
import 'package:yiraclinics/features/presentation/patient/family/family_session_sync.dart';
import 'package:yiraclinics/features/presentation/patient/family/link_family_member_sheet.dart';

class _FakeFamilyApi extends FamilyLinkApi {
  final List<String> calls = [];
  final List<String> codes = const ['4821', '7305', '1964'];
  int _codeIndex = 0;
  int secondsLeft = 600;
  bool failCode = false;
  FamilyLookupResult lookupResult;
  Object? linkError;
  FamilyLinkRequests requests;

  _FakeFamilyApi({
    this.lookupResult = const FamilyLookupResult(found: true, maskedName: 'Ra*** K***'),
    this.requests = const FamilyLinkRequests(),
  });

  FamilyCodeInfo _next() {
    final code = codes[_codeIndex < codes.length ? _codeIndex : codes.length - 1];
    _codeIndex++;
    return FamilyCodeInfo(code: code, secondsLeft: secondsLeft);
  }

  @override
  Future<FamilyCodeInfo> getCode() async {
    calls.add('getCode');
    if (failCode) throw const FamilyLinkException('OFFLINE', 'No internet connection. Check your connection and try again.');
    return _next();
  }

  @override
  Future<FamilyCodeInfo> refreshCode() async {
    calls.add('refreshCode');
    return _next();
  }

  @override
  Future<FamilyLookupResult> lookup(String phone) async {
    calls.add('lookup:$phone');
    return lookupResult;
  }

  @override
  Future<FamilyLinkOutcome> linkWithCode({required String phone, required String code, required String relation}) async {
    calls.add('code:$phone:$code:$relation');
    if (linkError != null) throw linkError!;
    return const FamilyLinkOutcome(linked: true, message: 'Ravi Kumar is now in your family.');
  }

  @override
  Future<FamilyLinkOutcome> sendRequest({required String phone, required String relation}) async {
    calls.add('request:$phone:$relation');
    if (linkError != null) throw linkError!;
    return const FamilyLinkOutcome(linked: false, message: 'Request sent. They can accept it in My Family within 7 days.');
  }

  @override
  Future<FamilyLinkRequests> getRequests() async {
    calls.add('getRequests');
    return requests;
  }

  @override
  Future<FamilyLinkedMember?> acceptRequest(int id, {String? relation}) async {
    calls.add('accept:$id');
    requests = const FamilyLinkRequests();
    return null;
  }

  @override
  Future<void> declineRequest(int id) async => calls.add('decline:$id');

  @override
  Future<void> cancelRequest(int id) async => calls.add('cancel:$id');
}

final String? _shotsDir = Platform.environment['DIET_SHOTS'];

Future<void> _loadFonts() async {
  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$w.ttf'));
  }
  await poppins.load();
  for (final style in ['Bold', 'Fill', 'Duotone']) {
    await (FontLoader('Phosphor$style')..addFont(rootBundle.load('assets/fonts/phosphor/Phosphor-$style.ttf'))).load();
  }
}

Widget _host(Widget child, {bool dark = false}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins', brightness: dark ? Brightness.dark : Brightness.light),
      home: Scaffold(
        backgroundColor: dark ? const Color(0xFF121212) : const Color(0xFFF4F6FA),
        body: child,
      ),
    );

void main() {
  setUpAll(_loadFonts);

  Future<void> phoneSized(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360 * 3, 760 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  String? clipboard;
  setUp(() {
    clipboard = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clipboard = (call.arguments as Map)['text'] as String?;
      return null;
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('FamilyCodeCard', () {
    testWidgets('shows the code with a live countdown', (tester) async {
      await phoneSized(tester);
      var now = DateTime(2026, 11, 12, 10);
      final api = _FakeFamilyApi();
      await tester.pumpWidget(_host(Padding(
        padding: const EdgeInsets.all(16),
        child: FamilyCodeCard(api: api, clock: () => now),
      )));
      await tester.pump();

      for (final d in ['4', '8', '2', '1']) {
        expect(find.descendant(of: find.byKey(const Key('familyCode.digits')), matching: find.text(d)), findsOneWidget);
      }
      expect(find.text('Valid for 10:00'), findsOneWidget);

      now = now.add(const Duration(seconds: 65));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Valid for 8:55'), findsOneWidget);
      expect(api.calls, ['getCode']);
      expect(tester.takeException(), isNull);

      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/family_code_card.png')));
      }
    });

    testWidgets('fetches a new code when the old one runs out', (tester) async {
      await phoneSized(tester);
      var now = DateTime(2026, 11, 12, 10);
      final api = _FakeFamilyApi();
      await tester.pumpWidget(_host(FamilyCodeCard(api: api, clock: () => now)));
      await tester.pump();
      expect(find.text('4'), findsOneWidget);

      now = now.add(const Duration(minutes: 10, seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(api.calls, ['getCode', 'getCode']);
      for (final d in ['7', '3', '0', '5']) {
        expect(find.descendant(of: find.byKey(const Key('familyCode.digits')), matching: find.text(d)), findsOneWidget);
      }
      expect(find.text('Valid for 10:00'), findsOneWidget);
    });

    testWidgets('copies, shares and refreshes the code', (tester) async {
      await phoneSized(tester);
      final now = DateTime(2026, 11, 12, 10);
      final api = _FakeFamilyApi();
      String? shared;
      await tester.pumpWidget(_host(FamilyCodeCard(
        api: api,
        clock: () => now,
        phoneNumber: '9876543210',
        onShare: (text) async => shared = text,
      )));
      await tester.pump();

      await tester.tap(find.byKey(const Key('familyCode.copy')));
      await tester.pump();
      expect(clipboard, '4821');
      expect(find.text('Family code copied'), findsOneWidget);

      await tester.tap(find.byKey(const Key('familyCode.share')));
      await tester.pump();
      expect(shared, contains('4821'));
      expect(shared, contains('9876543210'));
      expect(shared, contains('10 minutes'));

      await tester.tap(find.byKey(const Key('familyCode.refresh')));
      await tester.pump();
      expect(api.calls, ['getCode', 'refreshCode']);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('shows a friendly error and tries again', (tester) async {
      await phoneSized(tester);
      final api = _FakeFamilyApi()..failCode = true;
      await tester.pumpWidget(_host(FamilyCodeCard(api: api)));
      await tester.pump();
      expect(find.text('No internet connection. Check your connection and try again.'), findsOneWidget);

      api.failCode = false;
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('fits a phone in dark mode', (tester) async {
      await phoneSized(tester);
      await tester.pumpWidget(_host(
        Padding(padding: const EdgeInsets.all(16), child: FamilyCodeCard(api: _FakeFamilyApi(), clock: () => DateTime(2026))),
        dark: true,
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      final card = tester.widget<Container>(find.byKey(const Key('familyCode.card')));
      expect((card.decoration as BoxDecoration).color, const Color(0xFF232323));
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/family_code_card_dark.png')));
      }
    });
  });

  group('LinkFamilyMemberSheet', () {
    Future<_FakeFamilyApi> pumpSheet(WidgetTester tester, {_FakeFamilyApi? api, bool dark = false}) async {
      await phoneSized(tester);
      final fake = api ?? _FakeFamilyApi();
      await tester.pumpWidget(_host(Align(alignment: Alignment.bottomCenter, child: LinkFamilyMemberSheet(api: fake)), dark: dark));
      await tester.pump();
      return fake;
    }

    Future<void> tapKey(WidgetTester tester, String key) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pump();
      await tester.tap(find.byKey(Key(key)));
      await tester.pump();
    }

    String? errorText(WidgetTester tester) {
      final banner = find.byKey(const Key('familyLink.error'));
      if (banner.evaluate().isEmpty) return null;
      return tester.widget<Text>(find.descendant(of: banner, matching: find.byType(Text))).data;
    }

    testWidgets('checks the mobile number before looking it up', (tester) async {
      final api = await pumpSheet(tester);

      await tapKey(tester, 'familyLink.find');
      expect(errorText(tester), 'Enter their mobile number.');

      await tester.enterText(find.byKey(const Key('familyLink.phone')), '98765');
      await tapKey(tester, 'familyLink.find');
      expect(errorText(tester), 'Enter a 10-digit mobile number.');

      // Letters and extra digits are not accepted by the field.
      await tester.enterText(find.byKey(const Key('familyLink.phone')), '98765abc432109999');
      expect(tester.widget<TextField>(find.byKey(const Key('familyLink.phone'))).controller!.text, '9876543210');

      expect(api.calls, isEmpty);
      await tapKey(tester, 'familyLink.find');
      expect(api.calls, ['lookup:9876543210']);
      expect(errorText(tester), isNull);
      expect(find.text('Ra*** K***'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('needs a relation and a 4-digit code before linking', (tester) async {
      final api = await pumpSheet(tester);
      await tester.enterText(find.byKey(const Key('familyLink.phone')), '9876543210');
      await tapKey(tester, 'familyLink.find');

      await tapKey(tester, 'familyLink.submit');
      expect(errorText(tester), 'Choose how they are related to you.');

      await tester.ensureVisible(find.text('Father'));
      await tester.tap(find.text('Father'));
      await tester.pump();
      await tapKey(tester, 'familyLink.submit');
      expect(errorText(tester), 'Enter their 4-digit family code.');

      await tester.enterText(find.byKey(const Key('familyLink.code')), '12');
      await tapKey(tester, 'familyLink.submit');
      expect(errorText(tester), 'The family code has 4 digits.');

      // Only digits go into the code field, at most four.
      await tester.enterText(find.byKey(const Key('familyLink.code')), '4a8b2c19');
      expect(tester.widget<TextField>(find.byKey(const Key('familyLink.code'))).controller!.text, '4821');

      expect(api.calls, ['lookup:9876543210']);
      expect(tester.takeException(), isNull);

      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/family_link_sheet.png')));
      }
    });

    testWidgets('shows the server\'s message for a wrong code', (tester) async {
      final api = _FakeFamilyApi()
        ..linkError = const FamilyLinkException('WRONG_CODE', "That code doesn't match. Check the 4 digits in their app and try again.");
      await pumpSheet(tester, api: api);
      await tester.enterText(find.byKey(const Key('familyLink.phone')), '9876543210');
      await tapKey(tester, 'familyLink.find');
      await tester.ensureVisible(find.text('Spouse'));
      await tester.tap(find.text('Spouse'));
      await tester.enterText(find.byKey(const Key('familyLink.code')), '1234');
      await tapKey(tester, 'familyLink.submit');

      expect(api.calls.last, 'code:9876543210:1234:Spouse');
      expect(errorText(tester), "That code doesn't match. Check the 4 digits in their app and try again.");
    });

    testWidgets('says so when no account uses the number', (tester) async {
      await pumpSheet(tester, api: _FakeFamilyApi(lookupResult: const FamilyLookupResult(found: false)));
      await tester.enterText(find.byKey(const Key('familyLink.phone')), '9000000001');
      await tapKey(tester, 'familyLink.find');

      expect(find.byKey(const Key('familyLink.notFound')), findsOneWidget);
      expect(find.byKey(const Key('familyLink.submit')), findsNothing);
    });

    testWidgets('does not offer linking someone already in the family', (tester) async {
      await pumpSheet(
        tester,
        api: _FakeFamilyApi(lookupResult: const FamilyLookupResult(found: true, maskedName: 'Ra*** K***', alreadyLinked: true)),
      );
      await tester.enterText(find.byKey(const Key('familyLink.phone')), '9876543210');
      await tapKey(tester, 'familyLink.find');

      expect(find.text('Already in your family'), findsOneWidget);
      expect(find.byKey(const Key('familyLink.submit')), findsNothing);
    });

    testWidgets('sends a request without a code and returns the outcome', (tester) async {
      await phoneSized(tester);
      final api = _FakeFamilyApi();
      FamilyLinkOutcome? outcome;
      await tester.pumpWidget(_host(Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async => outcome = await LinkFamilyMemberSheet.show(context, api: api),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('familyLink.phone')), '9876543210');
      await tapKey(tester, 'familyLink.find');
      await tester.ensureVisible(find.text('Mother'));
      await tester.tap(find.text('Mother'));
      await tapKey(tester, 'familyLink.method.request');
      expect(find.byKey(const Key('familyLink.code')), findsNothing);
      expect(find.text('Send request'), findsOneWidget);

      await tapKey(tester, 'familyLink.submit');
      await tester.pumpAndSettle();

      expect(api.calls, ['lookup:9876543210', 'request:9876543210:Mother']);
      expect(outcome?.linked, isFalse);
      expect(find.byType(LinkFamilyMemberSheet), findsNothing);
    });

    testWidgets('fits a phone in dark mode', (tester) async {
      await pumpSheet(tester, dark: true);
      await tester.enterText(find.byKey(const Key('familyLink.phone')), '9876543210');
      await tapKey(tester, 'familyLink.find');
      expect(tester.takeException(), isNull);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/family_link_sheet_dark.png')));
      }
    });
  });

  group('FamilyLinksSection', () {
    testWidgets('lists requests and accepts one', (tester) async {
      await phoneSized(tester);
      var changed = 0;
      final api = _FakeFamilyApi(
        requests: FamilyLinkRequests(
          incoming: const [FamilyLinkRequest(id: 7, incoming: true, name: 'Ravi Kumar', relation: 'Son', suggestedRelation: 'Father')],
          outgoing: [FamilyLinkRequest(id: 9, incoming: false, name: 'Su*** P***', relation: 'Sister', expiresAt: DateTime.now().add(const Duration(days: 6, hours: 2)))],
        ),
      );
      await tester.pumpWidget(_host(SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FamilyLinksSection(api: api, phoneNumber: '9876543210', onFamilyChanged: () async => changed++),
      )));
      await tester.pump();

      expect(find.text('REQUESTS FOR YOU'), findsOneWidget);
      expect(find.text('Ravi Kumar'), findsOneWidget);
      expect(find.text('Wants to add you as their son. They will show as your father.'), findsOneWidget);
      expect(find.text('WAITING FOR THEM'), findsOneWidget);
      expect(find.textContaining('Expires in 6 days'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Accept'));
      await tester.tap(find.text('Accept'));
      await tester.pump();
      await tester.pump();
      expect(api.calls, contains('accept:7'));
      expect(changed, 1);
      expect(find.text('REQUESTS FOR YOU'), findsNothing);
    });

    testWidgets('the family code opens in a popup and closes', (tester) async {
      await phoneSized(tester);
      final key = GlobalKey<FamilyLinksSectionState>();
      await tester.pumpWidget(_host(SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FamilyLinksSection(key: key, api: _FakeFamilyApi(), phoneNumber: '9876543210', onFamilyChanged: () async {}),
      )));
      await tester.pump();
      // Nothing on the page itself: the screen's one "Add member" button opens these
      expect(find.byKey(const Key('familyCode.digits')), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);

      key.currentState!.openCode();
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byKey(const Key('familyCode.digits')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('familyCode.close')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });
  });

  group('FamilyAddOptionsSheet', () {
    Future<FamilyAddChoice?> pick(WidgetTester tester, String key, {bool canAddMore = true, bool canLink = true}) async {
      FamilyAddChoice? picked;
      await tester.pumpWidget(_host(Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () async => picked = await FamilyAddOptionsSheet.show(context, canAddMore: canAddMore, canLink: canLink),
            child: const Text('open'),
          ),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      return picked;
    }

    testWidgets('offers the three ways and returns the one tapped', (tester) async {
      await phoneSized(tester);
      expect(await pick(tester, 'familyAdd.member'), FamilyAddChoice.addMember);
      expect(await pick(tester, 'familyAdd.link'), FamilyAddChoice.linkUser);
      expect(await pick(tester, 'familyAdd.code'), FamilyAddChoice.myCode);
    });

    testWidgets('a full family can still open its code, but not add or link', (tester) async {
      await phoneSized(tester);
      await tester.pumpWidget(_host(const Align(
        alignment: Alignment.bottomCenter,
        child: FamilyAddOptionsSheet(canAddMore: false, canLink: true),
      )));
      InkWell inkOf(String key) => tester.widget<InkWell>(find.descendant(of: find.byKey(Key(key)), matching: find.byType(InkWell)));
      expect(inkOf('familyAdd.member').onTap, isNull);
      expect(inkOf('familyAdd.link').onTap, isNull);
      expect(inkOf('familyAdd.code').onTap, isNotNull);
      expect(find.text('Your family has 6 members. Remove someone first.'), findsNWidgets(2));
    });

    testWidgets("a family member's profile only offers adding", (tester) async {
      await phoneSized(tester);
      await tester.pumpWidget(_host(const Align(
        alignment: Alignment.bottomCenter,
        child: FamilyAddOptionsSheet(canAddMore: true, canLink: false),
      )));
      expect(find.byKey(const Key('familyAdd.member')), findsOneWidget);
      expect(find.byKey(const Key('familyAdd.link')), findsNothing);
      expect(find.byKey(const Key('familyAdd.code')), findsNothing);
    });

    for (final dark in [false, true]) {
      testWidgets('fits a 320 px screen with large text (${dark ? 'dark' : 'light'})', (tester) async {
        tester.view.physicalSize = const Size(320 * 3, 640 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MediaQuery(
          data: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.3)),
          child: _host(const Align(alignment: Alignment.bottomCenter, child: FamilyAddOptionsSheet(canAddMore: true, canLink: true)), dark: dark),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
        if (_shotsDir != null) {
          await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/family_add_options_${dark ? 'dark' : 'light'}.png')));
        }
      });
    }
  });

  group('helpers', () {
    test('phone and code checks', () {
      expect(normalizeFamilyPhone('+91 98765 43210'), '9876543210');
      expect(normalizeFamilyPhone('09876543210'), '9876543210');
      expect(normalizeFamilyPhone('98765'), isNull);
      expect(validateFamilyPhone(''), 'Enter their mobile number.');
      expect(validateFamilyPhone('12345'), 'Enter a 10-digit mobile number.');
      expect(validateFamilyPhone('9876543210'), isNull);
      expect(validateFamilyCode(''), 'Enter their 4-digit family code.');
      expect(validateFamilyCode('12a4'), 'The family code has 4 digits.');
      expect(validateFamilyCode('0042'), isNull);
      expect(formatFamilyCountdown(const Duration(seconds: 545)), '9:05');
    });

    test('server errors become one sentence', () {
      final options = RequestOptions(path: '/v1/api/auth/family/link-with-code');
      DioException error(int status, Map<String, dynamic> body) => DioException(
            requestOptions: options,
            response: Response(requestOptions: options, statusCode: status, data: body),
            type: DioExceptionType.badResponse,
          );

      final withMessage = familyLinkError(error(400, {
        'status': false,
        'message': 'This code has expired. Ask them to open My Family and share the new code.',
        'data': {'code': 'CODE_EXPIRED'},
      }));
      expect(withMessage.code, 'CODE_EXPIRED');
      expect(withMessage.message, startsWith('This code has expired'));

      final codeOnly = familyLinkError(error(409, {'status': false, 'data': {'code': 'ALREADY_LINKED'}}));
      expect(codeOnly.message, 'They are already in your family.');

      final offline = familyLinkError(DioException(requestOptions: options, type: DioExceptionType.connectionError));
      expect(offline.code, 'OFFLINE');
    });

    test('a profile reloaded without tokens keeps the session\'s tokens and family', () {
      final current = LoginEntity(
        status: true,
        data: DataEntity(
          id: 'B',
          accessToken: 'token-of-A',
          refreshToken: 'refresh-of-A',
          profiles: [
            ProfileEntity(id: 'A', relation: 'Self', isPrimary: true),
            ProfileEntity(id: 'B', relation: 'Spouse'),
          ],
        ),
      );
      final fresh = LoginEntity(
        status: true,
        data: DataEntity(id: 'B', firstName: 'Bhavana', profiles: [ProfileEntity(id: 'B', relation: 'Self', isPrimary: true)]),
      );

      final merged = mergeFreshFamilySession(current, fresh, rootId: 'a').data!;
      expect(merged.accessToken, 'token-of-A');
      expect(merged.refreshToken, 'refresh-of-A');
      expect(merged.firstName, 'Bhavana');
      expect(merged.profiles!.map((p) => p.id), ['A', 'B']);

      final ownReload = LoginEntity(
        status: true,
        data: DataEntity(id: 'A', accessToken: 'new', profiles: [ProfileEntity(id: 'A'), ProfileEntity(id: 'C')]),
      );
      final own = mergeFreshFamilySession(current, ownReload, rootId: 'A').data!;
      expect(own.accessToken, 'new');
      expect(own.profiles!.map((p) => p.id), ['A', 'C']);
    });

    test('linked members are added once and removed ones dropped', () {
      final profiles = [ProfileEntity(id: 'A', isPrimary: true), ProfileEntity(id: 'D', relation: 'Son')];
      const linked = [
        FamilyLinkedMember(userId: 'L1', linkId: 1, name: 'Ravi Kumar', relation: 'Father'),
        FamilyLinkedMember(userId: 'd', linkId: 2, name: 'Duplicate'),
      ];
      final added = withLinkedFamily(profiles, linked);
      expect(added.map((p) => p.id), ['A', 'D', 'L1']);
      expect(added.last.relation, 'Father');
      expect(added.last.isPrimary, isFalse);

      final removed = withLinkedFamily(added, const [], removedIds: {'l1'});
      expect(removed.map((p) => p.id), ['A', 'D']);
    });
  });
}
