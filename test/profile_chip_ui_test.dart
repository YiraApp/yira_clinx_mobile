// The dashboard's profile chip. Any layout
// overflow fails the test. Run with DIET_SHOTS=<dir> and --update-goldens to
// also save screenshots.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/core/widgets/active_profile_chip.dart';

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

final String? _shotsDir = Platform.environment['DIET_SHOTS'];

Future<void> _pump(WidgetTester tester, Widget child, {double width = 360}) async {
  tester.view.physicalSize = Size(width * 3, 900);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Poppins'),
    home: Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: Padding(padding: const EdgeInsets.all(16), child: RepaintBoundary(child: child)),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _shot(WidgetTester tester, String name) async {
  if (_shotsDir == null) return;
  await expectLater(find.byType(RepaintBoundary).first, matchesGoldenFile('$_shotsDir/$name.png'));
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('chip names the primary profile and the profile count', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: ActiveProfileChip(
          name: 'teja chennu',
          imagePath: null,
          relation: 'Self',
          isPrimary: true,
          profileCount: 4,
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.text('teja chennu'), findsOneWidget);
    expect(find.textContaining('You'), findsOneWidget);
    expect(find.textContaining('4 profiles'), findsOneWidget);
    await tester.tap(find.byType(ActiveProfileChip));
    expect(taps, 1);
    await _shot(tester, 'chip_self');
  });

  testWidgets('chip says whose profile is open and fits a long name', (tester) async {
    await _pump(
      tester,
      SizedBox(
        width: 220,
        child: ActiveProfileChip(
          name: 'Venkata Satya Rajesh Chennupati',
          imagePath: null,
          relation: 'brother',
          isPrimary: false,
          profileCount: 4,
          onTap: () {},
        ),
      ),
    );
    expect(find.textContaining("Brother's profile"), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _shot(tester, 'chip_brother');
  });

  testWidgets('chip hides the count for a single profile', (tester) async {
    await _pump(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: ActiveProfileChip(
          name: 'Naveen',
          imagePath: null,
          relation: 'Self',
          isPrimary: true,
          profileCount: 1,
          onTap: () {},
        ),
      ),
    );
    expect(find.textContaining('profiles'), findsNothing);
  });
}
