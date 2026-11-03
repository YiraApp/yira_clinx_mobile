// Parsing of the lab test API shapes, the prescription save body, and the bloc
// and validation rules behind prescribing lab tests.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/features/data/data_sources/patient_history/past_records_remote_data_source.dart';
import 'package:yiraclinics/features/data/models/prescriptions/lab_test_model.dart';
import 'package:yiraclinics/features/data/models/prescriptions/prescriptions_model.dart';
import 'package:yiraclinics/features/data/repository_impl/prescriptions/prescriptions_repo_impl.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/lab_test_entity.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/prescription_entity.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/prescription_item.dart';
import 'package:yiraclinics/features/domain/repositories/prescritpions/prescriptions_repo.dart';
import 'package:yiraclinics/features/presentation/prescriptions/add_prescription_screen.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/use_cases/get_hospital_lab_tests_use_case.dart';
import 'package:yiraclinics/features/use_cases/save_prescription_use_case.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.body);
  final Map<String, dynamic> body;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    request = options;
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

class _FakeApi implements ApiClient {
  _FakeApi(this.dio);
  final Dio dio;

  @override
  Dio account({bool showSuccessSnack = true}) => dio;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRepo implements PrescriptionRepository {
  PrescriptionEntity existing = const PrescriptionEntity(patientId: '', diagnoses: [], medications: [], additionalNotes: '');
  PrescriptionEntity? saved;
  int catalogCalls = 0;
  bool failCatalog = false;

  @override
  Future<PrescriptionEntity> getPrescriptionByPatientId(String patientId, {String? appointmentId, String? hospitalId, String? orgId}) async =>
      existing;

  @override
  Future<PrescriptionEntity> savePrescription(PrescriptionEntity prescription) async {
    saved = prescription;
    return prescription.copyWith(pdfUrl: 'https://example.com/rx.pdf');
  }

  @override
  Future<List<HospitalLabTest>> getHospitalLabTests(String hospitalId) async {
    catalogCalls++;
    if (failCatalog) throw Exception('offline');
    return const [HospitalLabTest(id: 1, testName: 'CBC', category: 'Haematology')];
  }
}

PrescriptionBloc _bloc(_FakeRepo repo) => PrescriptionBloc(
      savePrescriptionUseCase: SavePrescriptionUseCase(repo),
      getHospitalLabTestsUseCase: GetHospitalLabTestsUseCase(repo),
    );

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('parsing', () {
    test('hospital lab test reads the server shape, with a decimal as a string', () {
      final tests = HospitalLabTestModel.listFromJson([
        {
          'Id': 7,
          'HospitalId': 19,
          'TestName': 'Fasting Blood Sugar',
          'TestCode': 'FBS',
          'Category': 'Biochemistry',
          'SampleType': 'Blood',
          'Price': '150.00',
          'Preparation': 'Fast for 8 hours',
        },
        {'Id': 8, 'TestName': 'Urine Routine', 'Price': null, 'Preparation': null},
        {'Id': 9, 'TestName': ''},
        'not a map',
      ]);
      expect(tests, hasLength(2));
      expect(tests.first.id, 7);
      expect(tests.first.testCode, 'FBS');
      expect(tests.first.price, 150.0);
      expect(tests.first.preparation, 'Fast for 8 hours');
      expect(tests.last.price, isNull);
      expect(tests.last.category, isNull);
    });

    test('prescribed lab test reads the server shape and normalises priority', () {
      final tests = PrescribedLabTestModel.listFromJson([
        {'Id': 3, 'HospitalLabTestId': 7, 'TestName': 'CBC', 'Category': 'Haematology', 'Priority': 'URGENT', 'Instructions': 'Morning sample'},
        {'Id': 4, 'HospitalLabTestId': null, 'TestName': 'Typed test', 'Category': null, 'Priority': null, 'Instructions': null},
      ]);
      expect(tests.first.hospitalLabTestId, 7);
      expect(tests.first.isUrgent, isTrue);
      expect(tests.first.detail, 'Haematology · Morning sample');
      expect(tests.last.hospitalLabTestId, isNull);
      expect(tests.last.priority, PrescribedLabTest.routine);
      expect(tests.last.instructions, '');
      expect(tests.last.detail, '');
    });

    test('a prescription carries its lab tests, and older ones read as none', () {
      final withTests = PrescriptionModel.fromJson({
        'Id': 'abc',
        'PatientId': 'p1',
        'Medications': [],
        'LabTests': [
          {'Id': 1, 'HospitalLabTestId': 2, 'TestName': 'CBC', 'Priority': 'Routine'},
        ],
      });
      expect(withTests.labTests!.single.testName, 'CBC');
      expect(PrescriptionModel.fromJson({'Id': 'abc', 'PatientId': 'p1'}).labTests, isEmpty);
    });

    test('past records read lab tests when the server sends them, and none when it does not', () {
      expect(PastPrescription({'date': '2026-09-12'}).labTests, isEmpty);
      final p = PastPrescription({
        'labTests': [
          {'testName': 'CBC', 'priority': 'Urgent'},
        ],
      });
      expect(p.labTests.single.isUrgent, isTrue);
    });
  });

  group('repository', () {
    PrescriptionRepositoryImpl repoWith(_Adapter adapter) =>
        PrescriptionRepositoryImpl(_FakeApi(Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter));

    test('asks for the hospital\'s tests and unwraps the envelope', () async {
      final adapter = _Adapter({
        'status': 'success',
        'message': 'ok',
        'data': [
          {'Id': 1, 'TestName': 'CBC'},
        ],
      });
      final tests = await repoWith(adapter).getHospitalLabTests('19');
      expect(adapter.request!.path, '/v1/api/auth/hospitals/19/lab-tests');
      expect(tests.single.testName, 'CBC');
    });

    test('an unexpected lab tests body is an error, not an empty list', () async {
      expect(repoWith(_Adapter({'status': 'error'})).getHospitalLabTests('19'), throwsException);
    });

    Future<Map<String, dynamic>> savedBody(List<PrescribedLabTest>? labTests) async {
      final adapter = _Adapter({'data': []});
      await repoWith(adapter).savePrescription(
        PrescriptionEntity(patientId: 'p1', diagnoses: const [], medications: const [], additionalNotes: '', labTests: labTests),
      );
      return Map<String, dynamic>.from(adapter.request!.data as Map);
    }

    test('saves lab tests in the contract\'s shape, a typed test with a null id', () async {
      final body = await savedBody(const [
        PrescribedLabTest(hospitalLabTestId: 7, testName: 'CBC', category: 'Haematology', priority: PrescribedLabTest.urgent, instructions: ' Morning '),
        PrescribedLabTest(testName: 'Typed test'),
      ]);
      expect(body['labTests'], [
        {'hospitalLabTestId': 7, 'testName': 'CBC', 'category': 'Haematology', 'priority': 'Urgent', 'instructions': 'Morning'},
        {'hospitalLabTestId': null, 'testName': 'Typed test', 'category': null, 'priority': 'Routine', 'instructions': ''},
      ]);
    });

    test('an empty list is sent, and null leaves the key out', () async {
      expect((await savedBody(const []))['labTests'], isEmpty);
      expect((await savedBody(null)).containsKey('labTests'), isFalse);
    });
  });

  group('validation', () {
    const blank = MedicationItem(id: '1', name: '');
    const test1 = PrescribedLabTest(testName: 'CBC');
    const full = MedicationItem(id: '2', name: 'Dolo', dosage: '1', frequency: 'OD', duration: '5 Days', route: 'Oral');

    test('nothing prescribed is refused', () {
      expect(prescriptionValidationError(const [blank], const []), 'Please add at least one medication or lab test.');
      expect(prescriptionValidationError(const [], const []), 'Please add at least one medication or lab test.');
    });

    test('lab tests alone can be issued past the empty medicine row', () {
      expect(prescriptionValidationError(const [blank], const [test1]), isNull);
      expect(prescriptionValidationError(const [], const [test1]), isNull);
    });

    test('a half-filled medicine is still refused when lab tests are present', () {
      expect(prescriptionValidationError(const [MedicationItem(id: '3', name: 'Dolo')], const [test1]), 'Dosage is required.');
      expect(prescriptionValidationError(const [MedicationItem(id: '3', name: '', dosage: '1')], const [test1]), 'Medication name is required.');
    });

    test('medicines without lab tests keep their old rules', () {
      expect(prescriptionValidationError(const [full], const []), isNull);
      expect(prescriptionValidationError(const [full, blank], const []), 'Medication name is required for Medication #2.');
    });
  });

  group('bloc', () {
    test('a prescription with only lab tests loads for editing', () async {
      final repo = _FakeRepo()
        ..existing = const PrescriptionEntity(
          id: 'rx1',
          patientId: 'p1',
          diagnoses: [],
          medications: [],
          additionalNotes: '',
          labTests: [PrescribedLabTest(testName: 'CBC')],
        );
      final bloc = _bloc(repo)..add(const LoadPrescriptionData(patientId: 'p1'));
      await _settle();
      expect(bloc.state.prescriptionId, 'rx1');
      expect(bloc.state.labTests.single.testName, 'CBC');
      expect(bloc.state.medications, hasLength(1));
      await bloc.close();
    });

    test('removing every test submits an empty list', () async {
      final repo = _FakeRepo()
        ..existing = const PrescriptionEntity(id: 'rx1', patientId: 'p1', diagnoses: [], medications: [], additionalNotes: '');
      final bloc = _bloc(repo)
        ..add(LoadPrescriptionData(patientId: 'p1'))
        ..add(const SetLabTests([PrescribedLabTest(testName: 'CBC')]))
        ..add(RemoveLabTest(PrescribedLabTest.keyOf(' cbc ')))
        ..add(const SubmitPrescription(patientId: 'p1', additionalNotes: ''));
      await _settle();
      await _settle();
      expect(repo.saved!.labTests, isEmpty);
      expect(repo.saved!.medications, isEmpty);
      await bloc.close();
    });

    test('an empty form that never loaded leaves saved tests alone', () async {
      final repo = _FakeRepo();
      final bloc = _bloc(repo)
        ..add(LoadPrescriptionData(patientId: 'p1'))
        ..add(const SubmitPrescription(patientId: 'p1', additionalNotes: ''));
      await _settle();
      await _settle();
      expect(repo.saved?.labTests, isNull);
      await bloc.close();
    });

    test('priority and instructions change one test at a time', () async {
      final bloc = _bloc(_FakeRepo())
        ..add(const SetLabTests([PrescribedLabTest(testName: 'CBC'), PrescribedLabTest(testName: 'ESR')]))
        ..add(const UpdateLabTest(key: 'esr', priority: PrescribedLabTest.urgent))
        ..add(const UpdateLabTest(key: 'esr', instructions: 'Fasting'));
      await _settle();
      expect(bloc.state.labTests.first.priority, PrescribedLabTest.routine);
      expect(bloc.state.labTests.last.isUrgent, isTrue);
      expect(bloc.state.labTests.last.instructions, 'Fasting');
      await bloc.close();
    });

    test('the catalog loads once, and a failure can be retried', () async {
      final repo = _FakeRepo()..failCatalog = true;
      final bloc = _bloc(repo)..add(const LoadLabTestCatalog('19'));
      await _settle();
      expect(bloc.state.labCatalogStatus, LabCatalogStatus.failure);

      repo.failCatalog = false;
      bloc.add(const LoadLabTestCatalog('19'));
      await _settle();
      expect(bloc.state.labCatalogStatus, LabCatalogStatus.success);
      expect(bloc.state.labCatalog.single.testName, 'CBC');

      bloc.add(const LoadLabTestCatalog('19'));
      await _settle();
      expect(repo.catalogCalls, 2);
      await bloc.close();
    });

    test('with no hospital the catalog fails rather than asking the server', () async {
      final repo = _FakeRepo();
      final bloc = _bloc(repo)..add(const LoadLabTestCatalog(null));
      await _settle();
      expect(bloc.state.labCatalogStatus, LabCatalogStatus.failure);
      expect(repo.catalogCalls, 0);
      await bloc.close();
    });
  });
}
