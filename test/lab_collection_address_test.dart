import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/presentation/patient/lab_packages/lab_collection_address.dart';

void main() {
  test('address rules match the server', () {
    const ok = LabCollectionAddress(line1: '12 MG Road', city: 'Hyderabad', pincode: '500081', landmark: 'Near Metro');
    expect(ok.problem, isNull);
    expect(ok.text, '12 MG Road, Near Metro, Hyderabad 500081');
    expect(ok.toJson(), {'line1': '12 MG Road', 'landmark': 'Near Metro', 'city': 'Hyderabad', 'pincode': '500081'});
    expect(const LabCollectionAddress(line1: '', city: 'Hyderabad', pincode: '500081').problem, isNotNull);
    expect(const LabCollectionAddress(line1: '12', city: '', pincode: '500081').problem, isNotNull);
    expect(const LabCollectionAddress(line1: '12', city: 'Hyd', pincode: '5000').problem, 'Enter a 6-digit pincode.');
  });

  testWidgets('picks a saved address with one tap', (tester) async {
    LabCollectionAddress? picked;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => picked = await showModalBottomSheet<LabCollectionAddress>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const LabAddressPickerSheet(saved: [
                LabCollectionAddress(label: 'Home', line1: '12 MG Road', city: 'Hyderabad', pincode: '500081'),
              ]),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    await tester.tap(find.text('12 MG Road, Hyderabad 500081'));
    await tester.pumpAndSettle();
    expect(picked?.pincode, '500081');
  });

  testWidgets('a new address needs street, city and a 6-digit pincode', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    LabCollectionAddress? picked;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => picked = await showModalBottomSheet<LabCollectionAddress>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const LabAddressPickerSheet(saved: [], pincode: '500032'),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('500032'), findsOneWidget, reason: 'searched pincode is prefilled');

    await tester.tap(find.text('Use this address'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the house number and street.'), findsOneWidget);
    expect(find.text('Enter the city.'), findsOneWidget);
    expect(picked, isNull);

    await tester.enterText(find.widgetWithText(TextFormField, 'House / flat no. and street *'), 'Flat 4, Road 2');
    await tester.enterText(find.widgetWithText(TextFormField, 'City *'), 'Hyderabad');
    await tester.tap(find.text('Use this address'));
    await tester.pumpAndSettle();
    expect(picked?.text, 'Flat 4, Road 2, Hyderabad 500032');
  });
}
