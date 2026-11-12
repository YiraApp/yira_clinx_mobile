// Lab package card and page: render in light and dark, phone and small screens, without overflow.
// Run with PKG_SHOTS=<dir> and --update-goldens to save screenshots.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/presentation/patient/lab_packages/lab_package_cover.dart';
import 'package:yiraclinics/features/presentation/patient/lab_packages/patient_lab_packages_screen.dart';

Map<String, dynamic> _pkg({String name = '999 Health Package', List<String>? tests, String? imageUrl}) => {
      'id': 7,
      'name': name,
      'description': 'A complete yearly check of blood, liver, kidney, sugar and thyroid with a doctor review of the report.',
      'tests': tests ?? ['Complete Blood Count with P. Smear', 'Liver Profile', 'Lipid Profile', 'Urine Routine and Microscopy', 'Thyroid Profile', 'HbA1c'],
      'testGroups': [
        {'name': 'Complete Blood Count with P. Smear', 'description': 'Infections, anaemia', 'tests': ['Haemoglobin', 'RBC count', 'WBC count', 'Platelets']},
        {'name': 'Liver Profile', 'description': 'Liver health', 'tests': ['SGOT', 'SGPT', 'Bilirubin']},
        {'name': 'Lipid Profile', 'description': '', 'tests': ['Total cholesterol', 'HDL', 'LDL', 'Triglycerides']},
        {'name': 'Urine Routine and Microscopy', 'description': '', 'tests': []},
        {'name': 'Thyroid Profile', 'description': '', 'tests': ['T3', 'T4', 'TSH']},
        {'name': 'HbA1c', 'description': '3-month sugar average', 'tests': []},
      ],
      'parameterCount': 72,
      'sampleType': 'Blood & urine',
      'preparation': '10–12 hours fasting',
      'reportTurnaround': '12 hours',
      'mrp': 4999,
      'price': 999,
      'gstPercentage': 18,
      'gstAmount': 179.82,
      'totalAmount': 1178.82,
      'benefitsValue': 4100,
      'benefitsValuePlus': true,
      'benefits': [
        {'icon': 'doctor', 'title': 'Doctor consultation', 'description': 'Review of your report', 'value': 600},
        {'icon': 'lab', 'title': 'Lab tests', 'description': '72 parameters', 'value': 3500, 'valuePlus': true},
      ],
      'imageUrl': imageUrl,
    };

Future<void> _loadFonts() async {
  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$w.ttf'));
  }
  await poppins.load();
  final duo = FontLoader('PhosphorDuotone')..addFont(rootBundle.load('assets/fonts/phosphor/Phosphor-Duotone.ttf'));
  await duo.load();
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final iconFile = flutterRoot == null ? null : File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (iconFile != null && iconFile.existsSync()) {
    final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(iconFile.readAsBytesSync().buffer)));
    await icons.load();
  }
}

final String? _shotsDir = Platform.environment['PKG_SHOTS'];

Future<void> _render(WidgetTester tester, Widget screen, Size size, String shot, {bool dark = false}) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light, fontFamily: 'Poppins'),
    home: screen,
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  if (_shotsDir != null) {
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/$shot.png')));
  }
}

Widget _list(bool dark) => Scaffold(
      backgroundColor: dark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        labPackageCardForTest(_pkg(), isDark: dark),
        const SizedBox(height: 12),
        labPackageCardForTest(_pkg(name: 'Diabetes Care Package', tests: ['HbA1c', 'Fasting Blood Sugar']), isDark: dark),
        const SizedBox(height: 12),
        labPackageCardForTest(_pkg(name: 'Thyroid Check'), isDark: dark),
      ]),
    );

void main() {
  setUpAll(_loadFonts);

  test('covers follow what the package is about', () {
    expect(labPackageLook({'name': 'Diabetes Care Package'}).label, 'Diabetes care');
    expect(labPackageLook({'name': 'Thyroid Check'}).label, 'Thyroid care');
    expect(labPackageLook({'name': 'Healthy Heart'}).label, 'Heart care');
    expect(labPackageLook({'name': '999 Health Package'}).label, 'Full body checkup');
    // "women" must not match inside another word, "men" must not match "supplements"
    expect(labPackageLook({'name': 'Vitamin supplements panel'}).label, 'Vitamins');
  });

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    for (final size in const [Size(390, 844), Size(320, 640)]) {
      final tag = size.width == 390 ? 'phone' : 'small';
      testWidgets('package cards render ($mode, $tag)', (tester) async {
        await _render(tester, _list(dark), size, 'cards_${mode}_$tag', dark: dark);
        expect(find.text('999 Health Package'), findsOneWidget);
        expect(find.text('80% OFF'), findsWidgets);
        expect(find.text('View details'), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      testWidgets('package page renders ($mode, $tag)', (tester) async {
        await _render(tester, labPackageDetailsForTest(_pkg()), size, 'details_${mode}_$tag', dark: dark);
        expect(find.text('Book now'), findsOneWidget);
        // Booking is the next step, not part of this page
        expect(find.text('Book this package'), findsNothing);
        await tester.scrollUntilVisible(find.text('Tests included'), 300, scrollable: find.byType(Scrollable).first);
        expect(find.text('Price details'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('checkout step renders ($mode, $tag)', (tester) async {
        await _render(tester, labPackageDetailsForTest(_pkg(), checkout: true), size, 'checkout_${mode}_$tag', dark: dark);
        expect(find.text('Book package'), findsOneWidget);
        expect(find.text('Book this package'), findsOneWidget);
        expect(find.text('Add sample collection address *'), findsOneWidget);
        expect(find.textContaining('Pay ₹'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Price details'), 300, scrollable: find.byType(Scrollable).first);
        if (_shotsDir != null) {
          await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/checkout_${mode}_${tag}_scrolled.png')));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
