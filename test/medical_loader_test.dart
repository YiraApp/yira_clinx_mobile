import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/core/widgets/medical_loader.dart';

void main() {
  testWidgets('shows its message and animates', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: MedicalLoader(message: 'Loading your orders…')))));
    expect(find.text('Loading your orders…'), findsOneWidget);
    expect(find.bySemanticsLabel('Loading your orders…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('stays still with reduced motion', (tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: MediaQueryData(disableAnimations: true),
      child: MaterialApp(home: Scaffold(body: Center(child: MedicalLoader()))),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });
}
