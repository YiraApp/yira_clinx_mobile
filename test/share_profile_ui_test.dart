// Share my profile: doctor access and web links, with a fake API.
// Any layout overflow fails the test. Run with DIET_SHOTS=<dir> and
// --update-goldens to also save screenshots.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/data/data_sources/share/profile_share_remote_data_source.dart';
import 'package:yiraclinics/features/presentation/patient/share/share_profile_screen.dart';

class _FakeShareApi extends ProfileShareRemoteDataSource {
  final List<String> calls = [];
  bool failLinks = false;
  List<ProfileShareLink> links;
  List<ShareableDoctor> doctors;

  _FakeShareApi({required this.links, required this.doctors});

  @override
  Future<List<ShareableDoctor>> getDoctors() async => doctors;

  @override
  Future<List<ProfileShareLink>> getLinks() async {
    if (failLinks) throw Exception('offline');
    return links;
  }

  @override
  Future<ProfileShareLink> createLink({required String duration, String? label}) async {
    calls.add('create:$duration:${label ?? ''}');
    final link = ProfileShareLink(
      id: 99,
      status: 'ACTIVE',
      label: (label ?? '').isEmpty ? null : label,
      createdAt: DateTime(2026, 11, 2, 10),
      expiresAt: DateTime(2026, 11, 9, 10),
      url: 'https://clinicx.yira.ai/shared-profile/AbCdEfGhIjKlMnOpQrStUvWxYz0123456789',
    );
    links = [link, ...links];
    return link;
  }

  @override
  Future<void> revokeLink(int id) async => calls.add('revoke:$id');

  @override
  Future<void> grantDoctorAccess({required String doctorId, required String duration, int? hospitalId}) async =>
      calls.add('grant:$doctorId:$duration');

  @override
  Future<void> stopDoctorAccess(int consentId) async => calls.add('stop:$consentId');
}

_FakeShareApi _api() => _FakeShareApi(
      doctors: [
        ShareableDoctor(
          id: 'd1',
          name: 'Dr. Asha Rao',
          specialty: 'Endocrinology',
          hospitalName: 'Yira Hospitals',
          hasAccess: true,
          accessUntil: DateTime(2026, 11, 9, 18, 30),
          consentId: 7,
        ),
        const ShareableDoctor(id: 'd2', name: 'Dr. Santhosh Varama Nadimpalli', specialty: 'Critical Care Medicine', hospitalName: 'YIRA'),
        const ShareableDoctor(id: 'd3', name: 'Dr. Madhu Vasepalli', specialty: 'Dentistry', hospitalName: 'Ocimum Dental Clinic'),
      ],
      links: [
        ProfileShareLink(
          id: 1,
          status: 'ACTIVE',
          label: 'Dr. Mehta, second opinion',
          createdAt: DateTime(2026, 11, 1, 9),
          expiresAt: DateTime(2026, 11, 8, 9),
          viewCount: 2,
          lastViewedAt: DateTime(2026, 11, 1, 18, 5),
        ),
        ProfileShareLink(id: 2, status: 'EXPIRED', createdAt: DateTime(2026, 10, 1), expiresAt: DateTime(2026, 10, 2)),
      ],
    );

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
  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = root == null ? null : File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons != null && icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);

  Future<void> sized(WidgetTester tester, Size size) async {
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpScreen(WidgetTester tester, _FakeShareApi api, {int option = 0, bool dark = false}) async {
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins', brightness: dark ? Brightness.dark : Brightness.light),
      home: ShareProfileScreen(dataSource: api, initialOption: option),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    final tag = size.width > 350 ? 'phone' : 'small';

    testWidgets('doctors option renders ($tag)', (tester) async {
      await sized(tester, size);
      await pumpScreen(tester, _api());
      expect(find.text('Doctor on Yira'), findsOneWidget);
      expect(find.text('SHARING WITH'), findsOneWidget);
      expect(find.text('Dr. Asha Rao'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Share'), findsNWidgets(2));
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/share_doctors_$tag.png')));
      }
    });

    testWidgets('web link option renders ($tag)', (tester) async {
      await sized(tester, size);
      await pumpScreen(tester, _api(), option: 1);
      expect(find.text('Create a web link'), findsOneWidget);
      expect(find.text('OPEN LINKS'), findsOneWidget);
      expect(find.text('Dr. Mehta, second opinion'), findsOneWidget);
      expect(find.textContaining('Opened 2 times'), findsOneWidget);
      expect(find.text('PAST LINKS'), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/share_links_$tag.png')));
      }
    });
  }

  testWidgets('share with a Yira doctor for 1 month', (tester) async {
    await sized(tester, const Size(390, 844));
    final api = _api();
    await pumpScreen(tester, api);
    await tester.tap(find.text('Share').first);
    await tester.pumpAndSettle();
    expect(find.text('Share with Dr. Santhosh Varama Nadimpalli'), findsOneWidget);
    await tester.tap(find.text('1 month'));
    await tester.pump();
    await tester.tap(find.text('Share profile'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('grant:d2:1_MONTH'));
  });

  testWidgets('stop sharing with a doctor asks first', (tester) async {
    await sized(tester, const Size(390, 844));
    final api = _api();
    await pumpScreen(tester, api);
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    expect(find.text('Stop sharing with Dr. Asha Rao?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(api.calls, isEmpty);
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop sharing'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('stop:7'));
  });

  testWidgets('create a web link and see it once', (tester) async {
    await sized(tester, const Size(390, 844));
    final api = _api();
    await pumpScreen(tester, api, option: 1);
    await tester.tap(find.text('Create a web link'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Send it only to your doctor'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Dr. Iyer');
    await tester.tap(find.text('30 days'));
    await tester.pump();
    await tester.tap(find.text('Create link'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('create:30_DAYS:Dr. Iyer'));
    expect(find.text('Your link is ready'), findsOneWidget);
    expect(find.textContaining('/shared-profile/'), findsOneWidget);
    if (_shotsDir != null) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/share_link_ready.png')));
    }
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.tap(find.text('Copy'));
    await tester.pump();
    expect(copied, contains('/shared-profile/'));
  });

  testWidgets('turn a link off', (tester) async {
    await sized(tester, const Size(390, 844));
    final api = _api();
    await pumpScreen(tester, api, option: 1);
    await tester.tap(find.text('Turn off'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turn off').last);
    await tester.pumpAndSettle();
    expect(api.calls, contains('revoke:1'));
  });

  testWidgets('links fail to load shows a retry', (tester) async {
    await sized(tester, const Size(390, 844));
    final api = _api()..failLinks = true;
    await pumpScreen(tester, api, option: 1);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('share screen in dark mode', (tester) async {
    await sized(tester, const Size(390, 844));
    await pumpScreen(tester, _api(), dark: true);
    expect(find.text('Dr. Asha Rao'), findsOneWidget);
    if (_shotsDir != null) {
      await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/share_doctors_dark.png')));
    }
  });
}
