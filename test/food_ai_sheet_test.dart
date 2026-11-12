// "Ask AI" in the diet food picker: the button that fills calories and macros when they aren't
// known, and the patient-friendly note label.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/diet_food_picker_sheet.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/doctor_prescribe_diet_sheet.dart';

DoctorMealItemInput _item({int calories = 0, String? notes}) => DoctorMealItemInput(
      mealSlot: 'Breakfast',
      mealTime: '08:30',
      foodName: 'Ragi malt',
      quantity: 1,
      unit: 'glass',
      calories: calories,
      proteinG: calories > 0 ? 4 : null,
      carbsG: calories > 0 ? 28 : null,
      fatG: calories > 0 ? 2.5 : null,
      notes: notes,
    );

Future<void> _open(WidgetTester tester, DoctorMealItemInput item, {bool forPatient = false}) async {
  tester.view.physicalSize = const Size(390 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: DietFoodPickerSheet(
        slotName: 'Breakfast',
        slotTime: '08:30 AM',
        existingItem: item,
        authToken: '',
        orgId: '',
        allowSaveToList: !forPatient,
        onSubmit: (_) {},
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('offers AI to fill the values when none are known', (tester) async {
    await _open(tester, _item());
    await tester.scrollUntilVisible(find.byKey(const Key('dietFood.askAi')), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Ask AI to fill the values'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offers to check the values when they are already filled', (tester) async {
    await _open(tester, _item(calories: 150));
    await tester.scrollUntilVisible(find.byKey(const Key('dietFood.askAi')), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Check values with AI'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
  });

  testWidgets('a doctor adds an instruction for the patient; a patient adds a note', (tester) async {
    await _open(tester, _item());
    await tester.scrollUntilVisible(find.text('Add instruction for the patient'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Add instruction for the patient'), findsOneWidget);

    await _open(tester, _item(), forPatient: true);
    await tester.scrollUntilVisible(find.text('Add a note'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Add a note'), findsOneWidget);
    expect(find.text('Add instruction for the patient'), findsNothing);
  });
}
