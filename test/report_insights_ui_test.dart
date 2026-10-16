// Renders the AI report insights screen and the report upload sheet with real
// AI output (test/fixtures) at phone sizes. Any layout overflow fails the
// test. Run with DIET_SHOTS=<dir> and --update-goldens to save screenshots.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/domain/entities/medical_report/medical_report_analysis.dart';
import 'package:yiraclinics/features/presentation/patient/documents/report_insights_screen.dart';
import 'package:yiraclinics/features/presentation/patient/documents/report_upload_sheet.dart';

Future<void> _loadFonts() async {
  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$w.ttf'));
  }
  await poppins.load();
  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = root == null ? null : File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons != null && icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

MedicalReportAnalysis _fixture(String name) =>
    MedicalReportAnalysis.fromJson(jsonDecode(File('test/fixtures/report_analysis_$name.json').readAsStringSync()));

final String? _shotsDir = Platform.environment['DIET_SHOTS'];

void main() {
  setUpAll(_loadFonts);

  test('parses the lab analysis', () {
    final a = _fixture('lab');
    expect(a.status, ReportStatus.critical);
    expect(a.consultation.isEmergency, isTrue);
    expect(a.allTests.length, a.stats.total);
    expect(a.flaggedTests.first.isCritical, isTrue);
    expect(MedicalReportAnalysis.tryParse('not json'), isNull);
  });

  Future<void> sized(WidgetTester tester, Size size) async {
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  // Tall viewports so a screenshot shows a whole tab.
  for (final size in [const Size(390, 2800), const Size(320, 3400)]) {
    final tag = size.width > 350 ? 'phone' : 'small';
    for (final name in ['lab', 'mri']) {
      testWidgets('insights $name renders every tab ($tag)', (tester) async {
        await sized(tester, size);
        await tester.pumpWidget(MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Poppins'),
          home: ReportInsightsScreen(
            documentId: '1',
            documentTitle: 'Report',
            initialAnalysis: _fixture(name),
            onViewDocument: () {},
          ),
        ));
        await tester.pump(const Duration(milliseconds: 300));
        Future<void> shot(String tab) async {
          if (_shotsDir != null) {
            await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/insights_${name}_${tab}_$tag.png')));
          }
        }

        // Overview
        expect(find.text('Report insights'), findsOneWidget);
        expect(find.text('Book appointment'), findsOneWidget);
        if (name == 'lab') {
          expect(find.text('Critical - act now'), findsOneWidget);
          expect(find.text('Call emergency (108)'), findsOneWidget);
          expect(find.text('Results to look at'), findsOneWidget);
        } else {
          expect(find.text('Needs attention'), findsOneWidget);
          expect(find.text('Call emergency (108)'), findsNothing);
        }
        await shot('overview');

        // Results
        await tester.tap(find.text('Results').first);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Flagged'), findsOneWidget);
        await shot('results');
        await tester.tap(find.text('Flagged'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Normal').evaluate().isNotEmpty, isTrue);

        // Next steps
        await tester.tap(find.text('Next steps'));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Your action plan'), findsOneWidget);
        expect(find.text('Questions to ask your doctor'), findsOneWidget);
        await shot('next');
      });
    }
  }

  for (final size in [const Size(390, 844), const Size(320, 640)]) {
    final tag = size.width > 350 ? 'phone' : 'small';

    testWidgets('doctor view hides booking and re-analyse ($tag)', (tester) async {
      await sized(tester, const Size(390, 2800));
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'Poppins'),
        home: ReportInsightsScreen(documentId: '1', documentTitle: 'Report', initialAnalysis: _fixture('mri'), forPatient: false),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Book appointment'), findsNothing);
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
    });

    testWidgets('insights top of page ($tag)', (tester) async {
      await sized(tester, size);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Poppins'),
        home: ReportInsightsScreen(documentId: '1', documentTitle: 'Report', initialAnalysis: _fixture('lab'), onViewDocument: () {}),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Critical - act now'), findsOneWidget);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/insights_top_$tag.png')));
      }
    });

    testWidgets('upload sheet renders ($tag)', (tester) async {
      await sized(tester, size);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Poppins'),
        home: const Scaffold(
          backgroundColor: Color(0xFF64748B),
          body: Align(alignment: Alignment.bottomCenter, child: ReportUploadSheet()),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Upload medical report'), findsOneWidget);
      expect(find.text('Scan pages'), findsOneWidget);
      expect(find.text('Analyse with Yira AI'), findsOneWidget);
      if (_shotsDir != null) {
        await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/upload_sheet_$tag.png')));
      }
    });
  }
}
