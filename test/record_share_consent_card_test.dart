import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/presentation/appointments/widgets/record_share_consent_card.dart';

void main() {
  Widget host({required bool value, required String duration, ValueChanged<bool>? onChanged, ValueChanged<String>? onDuration}) =>
      MaterialApp(
        home: Scaffold(
          body: RecordShareConsentCard(
            value: value,
            onChanged: onChanged ?? (_) {},
            duration: duration,
            onDurationChanged: onDuration ?? (_) {},
            doctorName: 'Asha Rao',
          ),
        ),
      );

  testWidgets('on by default text names the doctor and the 7 days', (tester) async {
    await tester.pumpWidget(host(value: true, duration: RecordShareConsentCard.defaultDuration));
    expect(find.text('Give Dr. Asha Rao access to my profile'), findsOneWidget);
    expect(find.textContaining('for 7 days'), findsOneWidget);
    expect(find.textContaining(r'${'), findsNothing);
    expect(find.text('1 day'), findsOneWidget);
    expect(find.text('1 month'), findsOneWidget);
  });

  testWidgets('picking a duration and unticking report back', (tester) async {
    String? picked;
    bool? ticked;
    await tester.pumpWidget(host(value: true, duration: '7_DAYS', onDuration: (d) => picked = d, onChanged: (v) => ticked = v));
    await tester.tap(find.text('1 month'));
    expect(picked, '1_MONTH');
    await tester.tap(find.byType(Checkbox));
    expect(ticked, isFalse);
  });

  testWidgets('when off, no durations and the hospital-only note', (tester) async {
    await tester.pumpWidget(host(value: false, duration: '7_DAYS'));
    expect(find.text('7 days'), findsNothing);
    expect(find.text('They will only see their own consultations with you.'), findsOneWidget);
  });
}
