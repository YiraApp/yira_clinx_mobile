// The "This visit | Full history" switch on a doctor's record tabs: the visit
// view by default, the full history only with consent (with a banner saying
// so), and the access gate otherwise.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/domain/entities/consent/patient_access_consent_entity.dart';
import 'package:yiraclinics/features/presentation/consent/bloc/patient_access_consent_state.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_record_scope.dart';

class _Host extends StatefulWidget {
  final bool hasAccess;
  final DoctorAccessStatusLoaded? status;

  const _Host({required this.hasAccess, this.status});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool _history = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PatientRecordScopeTab(
          showHistory: _history,
          onChanged: (v) => setState(() => _history = v),
          visitLabel: 'This visit',
          hasAccess: widget.hasAccess,
          accessStatus: widget.status,
          visit: () => const Text('VISIT RECORDS'),
          history: () => Text(widget.hasAccess ? 'ALL RECORDS' : 'ACCESS GATE'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('with consent, full history shows every record and the banner', (tester) async {
    final expires = DateTime.now().add(const Duration(days: 3));
    await tester.pumpWidget(_Host(
      hasAccess: true,
      status: DoctorAccessStatusLoaded(
        hasAccess: true,
        status: 'APPROVED',
        expiresAt: expires,
        consent: const PatientAccessConsentEntity(durationMinutes: 10080),
      ),
    ));

    expect(find.text('VISIT RECORDS'), findsOneWidget);
    expect(find.textContaining('shared by the patient'), findsNothing);

    await tester.tap(find.text('Full history'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ALL RECORDS'), findsOneWidget);
    expect(find.textContaining('Full history from all hospitals'), findsOneWidget);
    expect(find.byIcon(Icons.history_rounded), findsOneWidget);

    await tester.tap(find.text('This visit'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('VISIT RECORDS'), findsOneWidget);
  });

  testWidgets('without consent, full history shows the access gate', (tester) async {
    await tester.pumpWidget(const _Host(
      hasAccess: false,
      status: DoctorAccessStatusLoaded(hasAccess: false, status: 'NO_REQUEST'),
    ));
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

    await tester.tap(find.text('Full history'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ACCESS GATE'), findsOneWidget);
    expect(find.textContaining('Full history from all hospitals'), findsNothing);
  });

  test('banner wording for open-ended and timed consent', () {
    expect(
      ConsentHistoryBanner.expiryText(const DoctorAccessStatusLoaded(
        hasAccess: true,
        status: 'APPROVED',
        consent: PatientAccessConsentEntity(durationMinutes: 0),
      )),
      'no end date',
    );
    final later = DateTime(2030, 1, 5, 14, 30);
    expect(
      ConsentHistoryBanner.expiryText(DoctorAccessStatusLoaded(hasAccess: true, status: 'APPROVED', expiresAt: later)),
      'until 5 Jan, 2:30 PM',
    );
  });
}
