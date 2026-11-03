// My billing and My policies with sample data. Any layout overflow fails the
// test. Run with DIET_SHOTS=<dir> and --update-goldens to save screenshots.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/data/data_sources/wallet/wallet_remote_data_source.dart';
import 'package:yiraclinics/features/data/models/wallet/wallet_models.dart';
import 'package:yiraclinics/features/presentation/patient/wallet/bill_form_sheet.dart';
import 'package:yiraclinics/features/presentation/patient/wallet/patient_billing_screen.dart';
import 'package:yiraclinics/features/presentation/patient/wallet/patient_policies_screen.dart';
import 'package:yiraclinics/features/presentation/patient/wallet/policy_form_sheet.dart';

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
final _today = DateTime.now();
String _ago(int days) => walletDateKey(_today.subtract(Duration(days: days)));

class _FakeWallet extends WalletRemoteDataSource {
  _FakeWallet({this.billing, this.policies = const [], this.fail = false});
  BillingData? billing;
  List<PolicyEntry> policies;
  bool fail;
  Map<String, dynamic>? savedBill;
  Map<String, dynamic>? savedPolicy;
  final deleted = <String>[];

  @override
  Future<BillingData> getBilling() async {
    if (fail) throw Exception('offline');
    return billing!;
  }

  @override
  Future<BillEntry> saveBill(Map<String, dynamic> fields, {String? id, String? filePath}) async {
    savedBill = fields;
    return BillEntry.fromJson({'id': 'm-9', 'source': 'manual', 'title': fields['title'], 'category': fields['category'], 'total': fields['totalAmount'], 'paid': fields['paidAmount'], 'due': 0, 'editable': true});
  }

  @override
  Future<void> deleteBill(String id) async => deleted.add(id);

  @override
  Future<List<PolicyEntry>> getPolicies() async => List.of(policies);

  @override
  Future<PolicyEntry> savePolicy(Map<String, dynamic> fields, {String? id, String? filePath}) async {
    savedPolicy = fields;
    return PolicyEntry.fromJson({'id': 'm-5', 'source': 'manual', ...fields, 'editable': true});
  }
}

BillingData _sampleBilling() => BillingData.fromJson({
      'summary': {
        'count': 4,
        'totalBilled': 6650,
        'totalPaid': 5650,
        'totalDue': 1000,
        'thisYear': 6650,
        'byCategory': [
          {'category': 'Procedure', 'total': 3500},
          {'category': 'Pharmacy', 'total': 1250},
          {'category': 'Lab tests', 'total': 1300},
          {'category': 'Consultation', 'total': 600},
        ],
      },
      'bills': [
        {'id': 'h-1', 'source': 'hospital', 'title': 'Treatment bill', 'provider': 'Ocimum Dental Clinic', 'doctor': 'Dr. Asha Rao', 'category': 'Procedure', 'date': _ago(2), 'billNumber': 'INV-000123', 'total': 3500, 'paid': 2500, 'due': 1000, 'status': 'Partly paid', 'paymentMode': 'UPI', 'subTotal': 3200, 'discount': 200, 'tax': 500,
          'items': [{'name': 'Root canal', 'quantity': 1, 'unitPrice': 3000, 'total': 3000}, {'name': 'Consultation', 'quantity': 1, 'unitPrice': 200, 'total': 200}], 'editable': false},
        {'id': 'm-1', 'source': 'manual', 'title': 'Apollo Pharmacy', 'provider': 'Apollo Pharmacy', 'category': 'Pharmacy', 'date': _ago(5), 'total': 1250, 'paid': 1250, 'due': 0, 'status': 'Paid', 'paymentMode': 'UPI', 'editable': true, 'fileUrl': 'https://example.com/b.jpg', 'fileName': 'pharmacy.jpg'},
        {'id': 'm-2', 'source': 'manual', 'title': 'Thyroid profile', 'provider': 'Vijaya Diagnostics', 'category': 'Lab tests', 'date': _ago(40), 'total': 1300, 'paid': 1300, 'due': 0, 'status': 'Paid', 'editable': true},
        {'id': 'p-1', 'source': 'payment', 'title': 'Consultation payment', 'provider': 'Yira Hospitals', 'category': 'Consultation', 'date': _ago(70), 'total': 600, 'paid': 600, 'due': 0, 'status': 'Paid', 'paymentMode': 'Razorpay', 'editable': false},
      ],
    });

List<PolicyEntry> _samplePolicies() => [
      PolicyEntry.fromJson({'id': 'm-1', 'source': 'manual', 'policyType': 'Health', 'insurer': 'Star Health', 'policyName': 'Family Health Optima', 'policyNumber': 'P/181211/01/2026/004512', 'sumInsured': 500000, 'endDate': _ago(-12), 'coveredMembers': 'Self, spouse, 2 kids', 'helplineNumber': '1800 425 2255', 'editable': true}),
      PolicyEntry.fromJson({'id': 'm-2', 'source': 'manual', 'policyType': 'Government scheme', 'insurer': 'Ayushman Bharat (PM-JAY)', 'policyNumber': 'PMJAY-4512-8890', 'sumInsured': 500000, 'endDate': _ago(-300), 'editable': true}),
      PolicyEntry.fromJson({'id': 'm-3', 'source': 'manual', 'policyType': 'Life', 'insurer': 'LIC', 'policyName': 'Jeevan Anand', 'policyNumber': '889912345', 'sumInsured': 2000000, 'endDate': _ago(20), 'editable': true}),
      PolicyEntry.fromJson({'id': 'h-7', 'source': 'hospital', 'policyType': 'Health', 'insurer': 'Niva Bupa', 'policyNumber': 'NB-77812', 'addedBy': 'Yira Hospitals', 'editable': false}),
    ];

Future<void> _pump(WidgetTester tester, Widget screen, {Size size = const Size(390, 844), Brightness brightness = Brightness.light}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Poppins', primaryColor: const Color(0xFF2563EB), brightness: brightness),
    home: RepaintBoundary(child: screen),
  ));
  await tester.pumpAndSettle();
}

Future<void> _shot(WidgetTester tester, String name, [Finder? of]) async {
  if (_shotsDir == null) return;
  await expectLater(of ?? find.byType(RepaintBoundary).first, matchesGoldenFile('$_shotsDir/$name.png'));
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('billing shows totals, hospital and own bills, grouped by month', (tester) async {
    await _pump(tester, PatientBillingScreen(dataSource: _FakeWallet(billing: _sampleBilling())));
    expect(find.text('₹6,650'), findsOneWidget);
    expect(find.text('Treatment bill'), findsOneWidget);
    expect(find.text('₹1,000 due'), findsOneWidget);
    expect(find.text('Added by you'), findsWidgets);
    expect(tester.takeException(), isNull);
    await _shot(tester, 'billing');
  });

  testWidgets('billing filters to bills with money due', (tester) async {
    await _pump(tester, PatientBillingScreen(dataSource: _FakeWallet(billing: _sampleBilling())));
    await tester.tap(find.text('Due').last);
    await tester.pumpAndSettle();
    expect(find.text('Treatment bill'), findsOneWidget);
    expect(find.text('Apollo Pharmacy'), findsNothing);
  });

  testWidgets('hospital bill detail lists items and is read-only', (tester) async {
    await _pump(tester, PatientBillingScreen(dataSource: _FakeWallet(billing: _sampleBilling())));
    await tester.tap(find.text('Treatment bill'));
    await tester.pumpAndSettle();
    expect(find.text('Root canal'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.textContaining('Contact the hospital'), findsOneWidget);
    await _shot(tester, 'bill_detail', find.byType(BillDetailSheet));
  });

  testWidgets('own bill can be deleted after confirming', (tester) async {
    final fake = _FakeWallet(billing: _sampleBilling());
    await _pump(tester, PatientBillingScreen(dataSource: fake));
    await tester.tap(find.text('Thyroid profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete bill'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(fake.deleted, ['m-2']);
  });

  testWidgets('add bill form validates and sends the right fields', (tester) async {
    final fake = _FakeWallet(billing: _sampleBilling());
    await _pump(tester, Scaffold(body: BillFormSheet(dataSource: fake)), size: const Size(390, 1500));
    await _shot(tester, 'bill_form');
    await tester.tap(find.text('Save bill'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount'), findsOneWidget);
    expect(fake.savedBill, isNull);
    await tester.tap(find.text('Lab tests'));
    await tester.enterText(find.byType(TextFormField).first, '850');
    await tester.tap(find.text('Save bill'));
    await tester.pumpAndSettle();
    expect(fake.savedBill?['category'], 'Lab tests');
    expect(fake.savedBill?['totalAmount'], 850);
    expect(fake.savedBill?['paidAmount'], 850);
    expect(fake.savedBill?['title'], 'Lab tests bill');
  });

  testWidgets('billing error state offers a retry', (tester) async {
    await _pump(tester, PatientBillingScreen(dataSource: _FakeWallet(fail: true)));
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('policies: renewal soon first, total cover, hospital record read-only', (tester) async {
    await _pump(tester, PatientPoliciesScreen(dataSource: _FakeWallet(policies: _samplePolicies())));
    expect(find.text('Renew in 12 days'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('₹10,00,000'), findsOneWidget); // Star + PM-JAY; the expired LIC policy is left out
    expect(find.text('Recorded by Yira Hospitals'), findsOneWidget);
    final star = tester.getTopLeft(find.text('Star Health')).dy;
    final lic = tester.getTopLeft(find.text('LIC')).dy;
    expect(star < lic, isTrue);
    expect(tester.takeException(), isNull);
    await _shot(tester, 'policies');
  });

  testWidgets('policy detail offers the claims helpline and edit', (tester) async {
    await _pump(tester, PatientPoliciesScreen(dataSource: _FakeWallet(policies: _samplePolicies())));
    await tester.tap(find.text('Star Health'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Call claims helpline'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    await _shot(tester, 'policy_detail', find.byType(PolicyDetailSheet));
  });

  testWidgets('policies empty state', (tester) async {
    await _pump(tester, PatientPoliciesScreen(dataSource: _FakeWallet()));
    expect(find.text('Keep your policies handy'), findsOneWidget);
  });

  testWidgets('add policy needs insurer and number; suggestion sets scheme type', (tester) async {
    final fake = _FakeWallet();
    await _pump(tester, Scaffold(body: PolicyFormSheet(dataSource: fake)), size: const Size(390, 1900));
    await _shot(tester, 'policy_form');
    await tester.tap(find.text('Save policy'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the insurer'), findsOneWidget);
    expect(find.text('Enter the policy number'), findsOneWidget);
    await tester.ensureVisible(find.text('Ayushman Bharat (PM-JAY)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ayushman Bharat (PM-JAY)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'PMJAY-1');
    await tester.tap(find.text('Save policy'));
    await tester.pumpAndSettle();
    expect(fake.savedPolicy?['insurer'], 'Ayushman Bharat (PM-JAY)');
    expect(fake.savedPolicy?['policyType'], 'Government scheme');
    expect(fake.savedPolicy?['policyNumber'], 'PMJAY-1');
  });

  testWidgets('sideways, billing shows spending by type as a ring chart', (tester) async {
    await _pump(tester, PatientBillingScreen(dataSource: _FakeWallet(billing: _sampleBilling())), size: const Size(844, 390));
    expect(find.text('Spending by type'), findsOneWidget);
    expect(find.text('Spent in ${_today.year}'), findsOneWidget);
    expect(find.text('Add bill'), findsNothing);
    expect(tester.takeException(), isNull);
    await _shot(tester, 'billing_landscape');
    // Tapping a legend row puts that type in the middle of the ring.
    await tester.tap(find.text('Pharmacy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('of spending'), findsOneWidget);
    await _shot(tester, 'billing_landscape_selected');
    await tester.tap(find.text('All time'));
    await tester.pumpAndSettle();
    expect(find.text('All time'), findsNWidgets(1));
  });

  testWidgets('sideways chart in dark mode', (tester) async {
    await _pump(tester, PatientBillingScreen(dataSource: _FakeWallet(billing: _sampleBilling())),
        size: const Size(844, 390), brightness: Brightness.dark);
    expect(tester.takeException(), isNull);
    await _shot(tester, 'billing_landscape_dark');
  });

  testWidgets('billing renders in dark mode', (tester) async {
    await _pump(tester, PatientBillingScreen(dataSource: _FakeWallet(billing: _sampleBilling())), brightness: Brightness.dark);
    expect(tester.takeException(), isNull);
    await _shot(tester, 'billing_dark');
  });
}
