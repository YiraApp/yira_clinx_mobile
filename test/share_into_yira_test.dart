// Sharing a PDF or photo into Yira from another app: which files are taken,
// waiting for sign-in, and the hand-off into the report upload sheet.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/navigation_services/navigation_services.dart';
import 'package:yiraclinics/core/services/share_into_yira/shared_report.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'package:yiraclinics/features/presentation/patient/documents/report_upload_sheet.dart';
import 'package:yiraclinics/features/presentation/patient/documents/share_into_yira.dart';

// A 1x1 PNG.
const _png = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81, 0x84, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
  0x44, 0xAE, 0x42, 0x60, 0x82,
];

late Directory _root;

/// A share folder laid out like ShareIntoYiraActivity.kt makes it.
Directory _shareDir() {
  final dir = Directory('${_root.path}/shared_into_yira/${DateTime.now().microsecondsSinceEpoch}');
  dir.createSync(recursive: true);
  return dir;
}

File _pdf(Directory dir, String name, {int pages = 1}) {
  final doc = PdfDocument();
  for (var i = 0; i < pages; i++) {
    doc.pages.add();
  }
  final file = File('${dir.path}/$name')..writeAsBytesSync(doc.saveSync());
  doc.dispose();
  return file;
}

File _photo(Directory dir, String name) => File('${dir.path}/$name')..writeAsBytesSync(_png);

File _other(Directory dir, String name) => File('${dir.path}/$name')..writeAsStringSync('not a report');

SharedReportFile _shared(File f, [String? mime]) => SharedReportFile(path: f.path, mimeType: mime);

/// File reads run on the real event loop, which a widget test only reaches in runAsync.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump();
  }
}

Future<void> _pumpSheet(WidgetTester tester, SharedReport shared, {bool chooseProfile = false}) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: ReportUploadSheet(shared: shared, chooseProfile: chooseProfile),
      ),
    ),
  ));
  await _settle(tester);
}

bool _uploadEnabled(WidgetTester tester) {
  final button = tester.widget<ButtonStyleButton>(find.ancestor(of: find.text('Upload & analyse'), matching: find.bySubtype<ButtonStyleButton>()));
  return button.onPressed != null;
}

void main() {
  setUp(() {
    _root = Directory.systemTemp.createTempSync('share_into_yira_test');
    ReceiveSharingIntent.setMockValues(initialMedia: const [], mediaStream: const Stream.empty());
  });

  tearDown(() {
    GlobalSession.instance.userNotifier.value = null;
    try {
      _root.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('which shared files can be uploaded', () {
    test('PDFs and JPG, PNG and HEIC photos; the sending app\'s type wins over the name', () {
      expect(SharedReportFile.kindOf('Lab report.pdf', 'application/pdf'), SharedFileKind.pdf);
      expect(SharedReportFile.kindOf('DOC-20261120-WA0003', 'application/pdf'), SharedFileKind.pdf);
      expect(SharedReportFile.kindOf('scan.HEIC', 'image/heic'), SharedFileKind.photo);
      expect(SharedReportFile.kindOf('IMG_1.jpg', null), SharedFileKind.photo);
      expect(SharedReportFile.kindOf('page.png', 'image/*'), SharedFileKind.photo);
      expect(SharedReportFile.kindOf('report.pdf', 'application/octet-stream'), SharedFileKind.pdf);
      expect(SharedReportFile.kindOf('funny.gif', 'image/gif'), SharedFileKind.unsupported);
      expect(SharedReportFile.kindOf('renamed.jpg', 'image/gif'), SharedFileKind.unsupported);
      expect(SharedReportFile.kindOf('notes.docx', 'application/octet-stream'), SharedFileKind.unsupported);
    });

    test('says which files were left out and why', () {
      final dir = _shareDir();
      final big = File('${dir.path}/too_large/huge scan.pdf')..createSync(recursive: true);
      final report = SharedReport([
        _shared(_pdf(dir, 'lab.pdf'), 'application/pdf'),
        _shared(_other(dir, 'notes.docx'), 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'),
        _shared(big, 'application/pdf'),
      ]);
      expect(report.usable.map((f) => f.name), ['lab.pdf']);
      expect(report.problem, contains('"notes.docx" can\'t be uploaded. Yira takes PDFs and photos (JPG, PNG, HEIC).'));
      expect(report.problem, contains('"huge scan.pdf" is too large to upload.'));
    });

    test('a share whose files are gone is not a share', () {
      final report = SharedReport([SharedReportFile(path: '${_root.path}/shared_into_yira/1/gone.pdf', mimeType: 'application/pdf')]);
      expect(report.isGone, isTrue);
      expect(report.hasUsable, isFalse);
    });

    test('iOS share extension copies in the app group are handled the same way', () async {
      // ios/ShareExtension/ShareViewController.swift lays files out like the Android side.
      final dir = Directory('${_root.path}/Shared/AppGroup/7F2C9A10/shared_into_yira/1764000000000')..createSync(recursive: true);
      final copy = _pdf(dir, 'lab.pdf');
      final big = File('${dir.path}/too_large/scan.pdf')..createSync(recursive: true);
      final report = SharedReport([_shared(copy, 'application/pdf'), _shared(big, 'application/pdf')]);
      expect(report.usable.map((f) => f.name), ['lab.pdf']);
      expect(report.problem, contains('"scan.pdf" is too large to upload.'));
      await report.discard();
      expect(dir.existsSync(), isFalse);
      expect(dir.parent.existsSync(), isTrue);
    });

    test('discard deletes the app\'s own copies and their folder, nothing else', () async {
      final dir = _shareDir();
      final copy = _pdf(dir, 'lab.pdf');
      final elsewhere = _pdf(Directory('${_root.path}/Download')..createSync(), 'mine.pdf');
      await SharedReport([_shared(copy, 'application/pdf'), _shared(elsewhere, 'application/pdf')]).discard();
      expect(copy.existsSync(), isFalse);
      expect(dir.existsSync(), isFalse);
      expect(elsewhere.existsSync(), isTrue);
    });
  });

  group('hand-off', () {
    late List<SharedReport> opened;
    late List<String> told;
    late ShareReadiness readiness;
    late ShareIntoYira share;

    setUp(() {
      opened = [];
      told = [];
      readiness = ShareReadiness.ready;
      share = ShareIntoYira(
        readiness: () => readiness,
        open: (r) async => opened.add(r),
        tell: told.add,
        settle: Duration.zero,
      );
    });

    tearDown(() => share.dispose());

    Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 20));

    SharedMediaFile media(File f, String mime) =>
        SharedMediaFile(path: f.path, type: mime.startsWith('image') ? SharedMediaType.image : SharedMediaType.file, mimeType: mime);

    test('signed in: opens the upload with the shared file', () async {
      final pdf = _pdf(_shareDir(), 'lab.pdf');
      share.receive([media(pdf, 'application/pdf')]);
      await tick();
      expect(opened, hasLength(1));
      expect(opened.single.usable.single.path, pdf.path);
      expect(share.pending, isNull);
    });

    test('signed out: keeps the file, asks to sign in once, then opens after sign-in', () async {
      readiness = ShareReadiness.signIn;
      final pdf = _pdf(_shareDir(), 'lab.pdf');
      share.receive([media(pdf, 'application/pdf')]);
      await tick();
      share.check(); // another screen, still signed out
      await tick();
      expect(opened, isEmpty);
      expect(told, ['Sign in to upload "lab.pdf" to your records.']);
      expect(share.pending, isNotNull);

      // Signing in goes through screens that are not home yet.
      readiness = ShareReadiness.wait;
      share.check();
      await tick();
      expect(opened, isEmpty);

      readiness = ShareReadiness.ready;
      share.check();
      await tick();
      expect(opened.single.usable.single.path, pdf.path);
      expect(pdf.existsSync(), isTrue);
    });

    test('in a doctor workspace: asks to switch to the patient profile', () async {
      readiness = ShareReadiness.notPatient;
      share.receive([media(_photo(_shareDir(), 'page.jpg'), 'image/jpeg')]);
      await tick();
      expect(opened, isEmpty);
      expect(told, ['Switch to your patient profile to upload "page.jpg".']);
    });

    test('a newer share replaces one still waiting, and its copies are deleted', () async {
      readiness = ShareReadiness.signIn;
      final first = _pdf(_shareDir(), 'old.pdf');
      share.receive([media(first, 'application/pdf')]);
      final second = _pdf(_shareDir(), 'new.pdf');
      share.receive([media(second, 'application/pdf')]);
      await tick();
      expect(first.existsSync(), isFalse);
      expect(share.pending!.files.single.path, second.path);
    });

    test('ignores text and links, and shares that were already handled', () async {
      share.receive([SharedMediaFile(path: 'hello', type: SharedMediaType.text)]);
      share.receive([SharedMediaFile(path: '${_root.path}/shared_into_yira/1/gone.pdf', type: SharedMediaType.file, mimeType: 'application/pdf')]);
      await tick();
      expect(opened, isEmpty);
      expect(share.pending, isNull);
    });

    test('cold start and app already running both reach the upload', () async {
      final pdf = _pdf(_shareDir(), 'cold.pdf');
      final photo = _photo(_shareDir(), 'warm.jpg');
      final stream = StreamController<List<SharedMediaFile>>();
      addTearDown(stream.close);
      ReceiveSharingIntent.setMockValues(initialMedia: [media(pdf, 'application/pdf')], mediaStream: stream.stream);

      await share.start();
      await tick();
      expect(opened.map((r) => r.files.single.name), ['cold.pdf']);

      stream.add([media(photo, 'image/jpeg')]);
      await tick();
      expect(opened.map((r) => r.files.single.name), ['cold.pdf', 'warm.jpg']);
    });

    testWidgets('nothing uploadable: says why instead of opening the upload', (tester) async {
      final docx = _other(_shareDir(), 'notes.docx');
      await tester.pumpWidget(MaterialApp(navigatorKey: NavigationService.navigatorKey, home: const Scaffold()));
      unawaited(ShareIntoYira.openUploadFlow(SharedReport([_shared(docx, 'application/msword')])));
      await tester.pumpAndSettle();
      expect(find.text("Can't upload this"), findsOneWidget);
      expect(find.textContaining('"notes.docx" can\'t be uploaded'), findsOneWidget);
      expect(find.text('Upload medical report'), findsNothing);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await _settle(tester);
      expect(docx.existsSync(), isFalse);
    });
  });

  group('upload sheet with shared files', () {
    testWidgets('a shared PDF is attached and named, ready to upload', (tester) async {
      final pdf = _pdf(_shareDir(), 'Thyroid profile.pdf', pages: 2);
      await _pumpSheet(tester, SharedReport([_shared(pdf, 'application/pdf')]));
      expect(find.text('Thyroid profile.pdf'), findsOneWidget);
      expect(find.text('PDF · 2 pages'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Thyroid profile'), findsOneWidget);
      expect(_uploadEnabled(tester), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a PDF over 10 MB is refused with the sheet\'s own message', (tester) async {
      final dir = _shareDir();
      final big = File('${dir.path}/big.pdf')..writeAsBytesSync(List.filled(10 * 1024 * 1024 + 1, 0));
      await _pumpSheet(tester, SharedReport([_shared(big, 'application/pdf')]));
      expect(find.text('"big.pdf" is larger than 10 MB. Try a smaller file.'), findsOneWidget);
      expect(find.textContaining('PDF ·'), findsNothing);
      expect(_uploadEnabled(tester), isFalse);
    });

    testWidgets('a PDF over 10 pages is refused', (tester) async {
      final pdf = _pdf(_shareDir(), 'long.pdf', pages: 11);
      await _pumpSheet(tester, SharedReport([_shared(pdf, 'application/pdf')]));
      expect(find.text('"long.pdf" has 11 pages. Reports can have up to 10 pages.'), findsOneWidget);
      expect(_uploadEnabled(tester), isFalse);
    });

    testWidgets('shared photos become pages; extra ones and other files are explained', (tester) async {
      final dir = _shareDir();
      final photos = [for (var i = 1; i <= 12; i++) _shared(_photo(dir, 'page$i.png'), 'image/png')];
      await _pumpSheet(tester, SharedReport([...photos, _shared(_other(dir, 'clip.gif'), 'image/gif')]));
      expect(find.text('10 of 10 pages · photos are joined into one report'), findsOneWidget);
      expect(find.textContaining('Only 10 more pages can be added. The first 10 were kept.'), findsOneWidget);
      expect(find.textContaining('"clip.gif" can\'t be uploaded'), findsOneWidget);
      expect(_uploadEnabled(tester), isTrue);
    });

    testWidgets('a PDF and photos together: the first file decides', (tester) async {
      final dir = _shareDir();
      await _pumpSheet(
        tester,
        SharedReport([_shared(_pdf(dir, 'lab.pdf'), 'application/pdf'), _shared(_photo(dir, 'p.jpg'), 'image/jpeg')]),
      );
      expect(find.text('PDF · 1 page'), findsOneWidget);
      expect(find.textContaining('not both, so the photos were left out'), findsOneWidget);
    });

    testWidgets('the patient picks which family member the report is for', (tester) async {
      GlobalSession.instance.userNotifier.value = LoginEntity(
        status: true,
        data: DataEntity(id: 'p1', firstName: 'teja', profiles: [
          ProfileEntity(id: 'p2', name: 'Rajesh Kumar', relation: 'Brother', isPrimary: false),
          ProfileEntity(id: 'p1', name: 'teja chennu', relation: 'Self', isPrimary: true),
        ]),
      );
      final pdf = _pdf(_shareDir(), 'lab.pdf');
      await _pumpSheet(tester, SharedReport([_shared(pdf, 'application/pdf')]), chooseProfile: true);
      expect(find.text('Who is this report for?'), findsOneWidget);
      expect(tester.getTopLeft(find.text('You')).dx, lessThan(tester.getTopLeft(find.text('Rajesh')).dx));
      expect(find.text('For Rajesh Kumar'), findsNothing);

      await tester.tap(find.text('Rajesh'));
      await tester.pump();
      expect(find.text('For Rajesh Kumar'), findsOneWidget);
    });

    testWidgets('no family choice for a single profile or when not asked', (tester) async {
      GlobalSession.instance.userNotifier.value = LoginEntity(
        status: true,
        data: DataEntity(id: 'p1', profiles: [ProfileEntity(id: 'p1', name: 'teja', relation: 'Self', isPrimary: true)]),
      );
      await _pumpSheet(tester, SharedReport([_shared(_pdf(_shareDir(), 'lab.pdf'), 'application/pdf')]), chooseProfile: true);
      expect(find.text('Who is this report for?'), findsNothing);
    });
  });
}
