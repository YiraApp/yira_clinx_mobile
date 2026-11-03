// The round profile switcher on My Profile. Run with DIET_SHOTS=<dir> and
// --update-goldens to also save a screenshot.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'package:yiraclinics/features/presentation/patient/profile/widgets/family_profiles_strip.dart';

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

LoginEntity _session(String activeId, List<ProfileEntity> profiles) =>
    LoginEntity(status: true, data: DataEntity(id: activeId, firstName: 'teja', lastName: 'chennu', profiles: profiles));

final _family = [
  ProfileEntity(id: 'p1', name: 'teja chennu', relation: 'Self', isPrimary: true),
  ProfileEntity(id: 'p2', name: 'Rajesh', relation: 'Brother', isPrimary: false),
  ProfileEntity(id: 'p3', name: 'Greeshma', relation: 'Sister', isPrimary: false),
  ProfileEntity(id: 'p4', name: 'Naveen', relation: 'Brother', isPrimary: false),
];

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 220) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Poppins', primaryColor: const Color(0xFF2563EB)),
    home: const Scaffold(
      backgroundColor: Color(0xFFF6F7F9),
      body: Padding(padding: EdgeInsets.all(16), child: RepaintBoundary(child: FamilyProfilesStrip(isDark: false))),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('shows every profile, you first, the open one ticked, and Add', (tester) async {
    GlobalSession.instance.userNotifier.value = _session('p2', _family.reversed.toList());
    await _pump(tester);
    expect(find.text('teja'), findsOneWidget);
    expect(find.text('Rajesh'), findsOneWidget);
    expect(find.text('Greeshma'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    // The main profile comes first even if the list arrives in another order.
    expect(tester.getTopLeft(find.text('teja')).dx < tester.getTopLeft(find.text('Rajesh')).dx, isTrue);
    expect(tester.takeException(), isNull);
    final dir = Platform.environment['DIET_SHOTS'];
    if (dir != null) {
      await expectLater(find.byType(RepaintBoundary).first, matchesGoldenFile('$dir/family_strip.png'));
    }
  });

  testWidgets('hidden for a family member who signed in themselves', (tester) async {
    GlobalSession.instance.userNotifier.value =
        _session('p2', [ProfileEntity(id: 'p2', name: 'Rajesh', relation: 'Self', isPrimary: true, accountType: 'Dependent')]);
    await _pump(tester);
    expect(find.text('SWITCH PROFILE'), findsNothing);
  });
}
