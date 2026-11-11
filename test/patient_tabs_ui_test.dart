// Renders the restyled cards of the doctor's patient tabs at phone sizes, in
// light and dark. Any layout overflow fails the test. Run with
// DIET_SHOTS=<dir> and --update-goldens to also save screenshots.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/data/data_sources/diet/doctor_diet_remote_data_source.dart';
import 'package:yiraclinics/features/data/data_sources/patient_history/past_records_remote_data_source.dart';
import 'package:yiraclinics/features/domain/entities/over_view/over_view_entity.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/prescription_item.dart';
import 'package:yiraclinics/features/domain/entities/uploaded_record/uploaded_record_entity.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/doctor_patient_diet_tab.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_appointments_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_contact_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_history_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_insurance_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_medical_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_summary_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/prescription_history_tab.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/record_tab_ui.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/single_prescription_card.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/widgets/uploaded_record_card.dart';

Future<void> _loadFonts() async {
  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    poppins.addFont(rootBundle.load('assets/fonts/Poppins-$w.ttf'));
  }
  await poppins.load();
  final root = Platform.environment['FLUTTER_ROOT'];
  final icons = root == null ? null : File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons != null && icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)))).load();
  }
}

final String? _shotsDir = Platform.environment['DIET_SHOTS'];

const _appointments = [
  PatientAppointmentEntity(
    id: '1042',
    tokenNumber: '12',
    appointmentDate: 'Sep 12, 2026',
    startTime: '16:30:00',
    endTime: '16:45:00',
    condition: 'Follow-up for blood pressure and persistent morning headaches',
    reason: 'Headache',
    status: 'PaymentPending',
    appointmentType: 'In-Clinic',
    hospitalName: 'Yira Multispeciality Hospital, Banjara Hills',
    hospitalPhone: '040 2222 3333',
    doctorName: 'Dr. Venkata Subramanyam Chennupati',
    prescriptions: [
      AppointmentPrescriptionEntity(
        id: 'p1',
        date: 'Sep 12, 2026',
        time: '4:40 PM',
        doctorName: 'Dr. Asha Rao',
        notes: 'Review in two weeks.',
        diagnoses: [AppointmentDiagnosisEntity(id: 'd1', name: 'Essential hypertension', icd10: 'I10')],
        medications: [
          AppointmentMedicationEntity(
            id: 'm1',
            name: 'Amlodipine with a very long brand name to check wrapping',
            dosage: '1 tablet after food',
            frequency: 'Once daily in the morning',
            duration: '30 days',
            instructions: 'After breakfast',
          ),
        ],
      ),
    ],
    clinicalNotes: [AppointmentClinicalNoteEntity(id: 'n1', doctorName: 'Dr. Asha Rao', notes: 'BP remains high despite treatment. Started on amlodipine.')],
    documents: [AppointmentDocumentEntity(id: 'c1', fileName: 'Lipid profile report.pdf', category: 'Lab Report', type: 'PDF', createdAt: 'Sep 10, 2026')],
    medicalRecords: [AppointmentMedicalRecordEntity(id: 'r1', recordType: 'Consultation', createdAt: 'Sep 12, 2026')],
  ),
  PatientAppointmentEntity(id: '1043', appointmentDate: 'Aug 2, 2026', status: 'CANCELLED', isTeleConsultation: true, appointmentType: 'Video'),
  PatientAppointmentEntity(id: '1044', status: 'COMPLETED', startTime: '09:00'),
];

const _meds = [
  MedicationItem(id: '1', name: 'Amlodipine 5mg', dosage: '1 tablet', frequency: 'Once daily', duration: '30 days', route: 'Oral'),
  MedicationItem(id: '2', name: 'Telmisartan 40mg', dosage: '1 tablet', frequency: 'Once daily'),
  MedicationItem(id: '3', name: 'Aspirin 75mg'),
  MedicationItem(id: '4', name: 'Atorvastatin 10mg'),
];

UploadedRecord _document({bool hospital = true, String? description, String? aiStatus}) => UploadedRecord(
      id: 'u1',
      fileName: 'Complete blood count and lipid profile report for September.pdf',
      category: 'Imaging / Radiology',
      uploadDate: DateTime(2026, 9, 12),
      fileSizeKB: 2048,
      fileType: 'pdf',
      description: description,
      isPatientUploaded: !hospital,
      hospitalName: hospital ? 'Yira Multispeciality Hospital, Banjara Hills, Hyderabad, Telangana' : null,
      doctorName: hospital ? 'Dr. Venkata Subramanyam Chennupati' : null,
      aiStatus: aiStatus,
    );

class _FakeRecords implements PastRecordsRemoteDataSource {
  _FakeRecords(this.result);
  final PastRecordsResult result;
  @override
  Future<PastRecordsResult> fetch({required String patientId, String? appointmentId, String? hospitalId}) async => result;
}

PastRecordsResult _prescriptions() => PastRecordsResult.records(PastRecords.fromJson({
      'scope': 'all',
      'prescriptions': [
        {
          'date': '2026-09-12',
          'doctor': 'Dr. Asha Rao',
          'hospital': 'Yira Multispeciality Hospital, Banjara Hills',
          'diagnoses': ['Hypertension', 'Migraine'],
          'notes': 'Review in two weeks.',
          'pdfUrl': 'https://example.com/rx.pdf',
          'medications': [
            {'name': 'Amlodipine 5mg', 'dosage': '1 tablet', 'frequency': 'Once daily', 'duration': '30 days'},
            {'name': 'Aspirin 75mg'},
          ],
        },
      ],
    }));

class _FakeDiet extends DoctorDietRemoteDataSource {
  _FakeDiet(this.plans);
  final List<Map<String, dynamic>> plans;
  @override
  Future<List<Map<String, dynamic>>> getPatientPlans(String patientId, {String? orgId, bool fullHistory = false}) async => plans;
}

Map<String, dynamic> _plan(int id, String name, String status) => {
      'Id': id,
      'PlanName': name,
      'Status': status,
      'TotalDays': 3,
      'StartDate': '2020-01-01',
      'EndDate': '2099-01-01',
      'TargetCalories': 1600,
      'DietType': 'Veg',
      'Condition': 'Type 2 Diabetes',
      'AssignedByDoctor': {'FirstName': 'Asha', 'LastName': 'Rao'},
      'Hospital': {'Name': 'Yira Multispeciality Hospital'},
      'Organization': {'Name': 'Yira Clinics'},
    };

void main() {
  setUpAll(_loadFonts);

  Future<void> pump(WidgetTester tester, Widget child, Size size, {bool dark = false, bool scroll = true}) async {
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins', brightness: dark ? Brightness.dark : Brightness.light),
      home: Scaffold(
        backgroundColor: dark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
        body: scroll ? SingleChildScrollView(padding: const EdgeInsets.all(16), child: child) : child,
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> shot(String name) async {
    if (_shotsDir == null) return;
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(Uri.file('$_shotsDir/$name.png')));
  }

  for (final (size, tag) in [(const Size(393, 852), '393'), (const Size(320, 640), '320')]) {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';
      final name = '${tag}_$mode';

      testWidgets('info cards ($name)', (tester) async {
        await pump(
          tester,
          const Column(
            children: [
              PatientContactCard(
                isTab: false,
                patient: ContactInformationEntity(
                  phone: '+91 98765 43210',
                  emailAddress: 'a.very.long.address.for.this.patient@yira-example-hospital.com',
                  residentialAddress: '12-3-456, Road No. 12, Banjara Hills, Hyderabad, Telangana 500034',
                  emergencyContact: EmergencyContactEntity(name: 'Lakshmi', relationship: 'Spouse', phone: '+91 91234 56789'),
                ),
              ),
              PatientMedicalCard(isTab: false, patient: MedicalInformationEntity(allergies: 'Penicillin', bloodGroup: 'O+', totalVisits: 7)),
            ],
          ),
          size,
          dark: dark,
        );
        expect(find.text('Allergies'), findsOneWidget);
        expect(find.text('Lakshmi (Spouse) · +91 91234 56789'), findsOneWidget);
        await shot('info_$name');
      });

      testWidgets('info cards without data ($name)', (tester) async {
        await pump(
          tester,
          const Column(
            children: [
              PatientContactCard(isTab: false, patient: ContactInformationEntity()),
              PatientSummaryCard(isTab: false, summary: 'Hypertensive for five years, well controlled until this spring.'),
              PatientInsuranceCard(isTab: false, patient: InsuranceEntity()),
              PatientInsuranceCard(isTab: false, patient: InsuranceEntity(policyName: 'Star Health', policyNumber: 'SH-221')),
              PatientHistoryCard(isTab: false, patient: VisitHistoryEntity(initialRegistration: 'Jan 2, 2024')),
            ],
          ),
          size,
          dark: dark,
        );
        expect(find.text('N/A'), findsNWidgets(3));
        expect(find.text('Not added by the patient'), findsOneWidget);
        expect(find.text('No insurance details linked.'), findsOneWidget);
        await shot('info_empty_$name');
      });

      testWidgets('appointment cards and their sheet ($name)', (tester) async {
        await pump(tester, const PatientAppointmentsCard(appointments: _appointments, isTab: false), size, dark: dark);
        expect(find.text('Payment pending'), findsOneWidget);
        expect(find.text('Token #12 · 4:30 PM'), findsOneWidget);
        await shot('appointments_$name');

        await tester.tap(find.text('Sep 12, 2026'));
        await tester.pumpAndSettle();
        expect(find.text('Appointment Details'), findsOneWidget);
        await shot('appointment_sheet_$name');

        await tester.ensureVisible(find.text('View details').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('View details').last);
        await tester.pumpAndSettle();
        expect(find.text('Prescription Details'), findsOneWidget);
        await shot('prescription_sheet_$name');
      });

      testWidgets('prescription card ($name)', (tester) async {
        var opened = 0;
        await pump(
          tester,
          // The card brings its own 16 px gutter, as in the Prescribe tab's list.
          ListView(
            padding: EdgeInsets.zero,
            children: [
              SinglePrescriptionCard(medications: _meds, date: 'Today · Clinical Consultation', isTab: false, onEdit: () {}, onDelete: () {}, onPdfView: () => opened++),
            ],
          ),
          size,
          dark: dark,
          scroll: false,
        );
        expect(find.text('+ 1 more medications'), findsOneWidget);
        await tester.tap(find.text('Prescription Record'));
        expect(opened, 1);
        await shot('prescription_$name');
      });

      testWidgets('prescription history ($name)', (tester) async {
        await pump(
          tester,
          PrescriptionHistoryTab(patientId: 'p', dataSource: _FakeRecords(_prescriptions())),
          size,
          dark: dark,
          scroll: false,
        );
        expect(find.text('12 Sep 2026'), findsOneWidget);
        expect(find.byTooltip('PDF'), findsOneWidget);
        await shot('prescription_history_$name');
      });

      testWidgets('diet tab keeps each status colour ($name)', (tester) async {
        await pump(
          tester,
          DoctorPatientDietTab(
            patientId: 'p',
            patientName: 'Ravi',
            dataSource: _FakeDiet([
              _plan(1, 'Diabetes Friendly Vegetarian Plan', 'active'),
              _plan(2, 'Low Salt Plan', 'paused'),
              _plan(3, 'Weight Loss Plan', 'cancelled'),
            ]),
          ),
          size,
          dark: dark,
          scroll: false,
        );
        Color? tone(String label) => tester.widget<Text>(find.text(label)).style?.color;
        expect(tone('Paused'), DietUi.amber);
        expect(tone('Stopped'), DietUi.red);
        expect(find.byTooltip('Edit plan'), findsNWidgets(2));
        await shot('diet_$name');
      });

      testWidgets('diet tab with no plans ($name)', (tester) async {
        await pump(tester, DoctorPatientDietTab(patientId: 'p', patientName: 'Ravi', dataSource: _FakeDiet(const [])), size, dark: dark, scroll: false);
        expect(find.text('Prescribe'), findsOneWidget);
        await shot('diet_empty_$name');
      });

      testWidgets('document cards ($name)', (tester) async {
        var opened = 0;
        await pump(
          tester,
          Column(
            children: [
              UploadedRecordCard(
                record: _document(description: 'Fasting sample taken at the hospital lab. ' * 4, aiStatus: 'attention'),
                isTab: false,
                onView: () => opened++,
                onAiInsights: () {},
                onDelete: () {},
              ),
              // As a patient sees theirs: uploaded by them, nothing to delete.
              UploadedRecordCard(record: _document(hospital: false), isTab: false, onView: () {}),
            ],
          ),
          size,
          dark: dark,
        );
        expect(find.text('Needs attention'), findsOneWidget);
        await tester.tap(find.textContaining('Complete blood count').first);
        expect(opened, 1);
        await shot('documents_$name');
      });

      testWidgets('empty states ($name)', (tester) async {
        await pump(
          tester,
          const Column(
            children: [
              RecordEmptyState(icon: Icons.medication_outlined, title: 'No prescriptions yet'),
              SizedBox(height: 24),
              RecordEmptyState(
                icon: Icons.folder_open_outlined,
                title: 'No Documents Uploaded',
                message: 'Tap the button below to upload lab reports, scan files, or prescriptions.',
              ),
            ],
          ),
          size,
          dark: dark,
        );
        await shot('empty_$name');
      });
    }
  }
}
