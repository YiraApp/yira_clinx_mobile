import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/prescriptions/lab_test_entity.dart';
import '../../../domain/entities/prescriptions/prescription_item.dart';
import '../../../domain/entities/prescriptions/prescription_entity.dart';
import '../../../use_cases/get_hospital_lab_tests_use_case.dart';
import '../../../use_cases/save_prescription_use_case.dart';

part 'prescription_event.dart';
part 'prescription_state.dart';

class PrescriptionBloc extends Bloc<PrescriptionEvent, PrescriptionState> {
  final SavePrescriptionUseCase? _savePrescriptionUseCase;
  final GetHospitalLabTestsUseCase? _getHospitalLabTestsUseCase;

  PrescriptionBloc({
    SavePrescriptionUseCase? savePrescriptionUseCase,
    GetHospitalLabTestsUseCase? getHospitalLabTestsUseCase,
  })  : _savePrescriptionUseCase = savePrescriptionUseCase,
        _getHospitalLabTestsUseCase = getHospitalLabTestsUseCase,
        super(PrescriptionState()) {
    on<LoadPrescriptionData>(_onLoadPrescriptionData);
    on<SubmitPrescription>(_onSubmitPrescription);
    on<AddDiagnosis>(_onAddDiagnosis);
    on<RemoveDiagnosis>(_onRemoveDiagnosis);
    on<AddMedication>(_onAddMedication);
    on<AddEmptyMedication>(_onAddEmptyMedication);
    on<RemoveMedication>(_onRemoveMedication);
    on<UpdateMedicationDetails>(_onUpdateMedicationDetails);
    on<TogglePrescriptionExpansion>(_onTogglePrescriptionExpansion);
    on<LoadLabTestCatalog>(_onLoadLabTestCatalog);
    on<SetLabTests>(_onSetLabTests);
    on<RemoveLabTest>(_onRemoveLabTest);
    on<UpdateLabTest>(_onUpdateLabTest);
    on<AddPrescriptionRecordNavEvent>((event, emit) async {
      emit(AddPrescriptionRecordNavState());
    });
    on<SinglePrescriptionDetailsNavEvent>((event, emit) async {
      emit(SinglePrescriptionDetailsNavState(event.prescriptionId));
    });
  }

  bool _savedTestsLoaded = false;

  Future<void> _onLoadPrescriptionData(
    LoadPrescriptionData event,
    Emitter<PrescriptionState> emit,
  ) async {
    if (event.patientId == null || event.patientId!.trim().isEmpty) {
      return;
    }
    try {
      final data = await _savePrescriptionUseCase?.repository.getPrescriptionByPatientId(
        event.patientId!.trim(),
        appointmentId: event.appointmentId,
        hospitalId: event.hospitalId,
        orgId: event.orgId,
      );
      final labTests = data?.labTests ?? const <PrescribedLabTest>[];
      if (data != null &&
          (data.medications.isNotEmpty ||
              data.diagnoses.isNotEmpty ||
              data.additionalNotes.isNotEmpty ||
              labTests.isNotEmpty)) {
        emit(state.copyWith(
          status: PrescriptionStatus.success,
          diagnoses: data.diagnoses,
          medications: data.medications.isEmpty
              ? [MedicationItem(id: DateTime.now().millisecondsSinceEpoch.toString(), name: '')]
              : data.medications,
          labTests: labTests,
          additionalNotes: data.additionalNotes,
          pdfUrl: data.pdfUrl,
          prescriptionId: data.id,
        ));
      }
      // A failed load comes back as an empty prescription with no id.
      _savedTestsLoaded = (data?.id ?? '').isNotEmpty;
    } catch (_) {}
  }

  Future<void> _onSubmitPrescription(
    SubmitPrescription event,
    Emitter<PrescriptionState> emit,
  ) async {
    emit(state.copyWith(status: PrescriptionStatus.submitLoading));
    try {
      final validMeds = state.medications.where((m) => m.name.trim().isNotEmpty).toList();

      final payload = PrescriptionEntity(
        id: state.prescriptionId,
        patientId: event.patientId,
        appointmentId: event.appointmentId,
        hospitalId: event.hospitalId,
        orgId: event.orgId,
        diagnoses: state.diagnoses,
        medications: validMeds,
        additionalNotes: event.additionalNotes,
        // Always a list, even empty, so removing every test reaches the server.
        // Null leaves the saved tests alone: an empty form after a failed load
        // must not read as the doctor removing them.
        labTests: (_savedTestsLoaded || state.labTests.isNotEmpty) ? state.labTests : null,
      );

      final PrescriptionEntity synchronizedData = await _savePrescriptionUseCase!.call(payload);

      emit(state.copyWith(
        status: PrescriptionStatus.submitSuccess,
        diagnoses: synchronizedData.diagnoses,
        medications: synchronizedData.medications,
        additionalNotes: synchronizedData.additionalNotes,
        pdfUrl: synchronizedData.pdfUrl,
        prescriptionId: synchronizedData.id,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PrescriptionStatus.submitFailure,
        errorMessage: e.toString().replaceAll("Exception: ", ""),
      ));
    }
  }

  void _onAddDiagnosis(AddDiagnosis event, Emitter<PrescriptionState> emit) {
    if (event.diagnosis.trim().isEmpty) return;
    final updated = List<String>.from(state.diagnoses)..add(event.diagnosis);
    emit(state.copyWith(diagnoses: updated));
  }

  void _onRemoveDiagnosis(RemoveDiagnosis event, Emitter<PrescriptionState> emit) {
    final updated = List<String>.from(state.diagnoses)..remove(event.diagnosis);
    emit(state.copyWith(diagnoses: updated));
  }

  void _onAddMedication(AddMedication event, Emitter<PrescriptionState> emit) {
    if (event.medicationName.trim().isEmpty) return;
    final newItem = MedicationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: event.medicationName,
    );
    final updated = List<MedicationItem>.from(state.medications)..add(newItem);
    emit(state.copyWith(medications: updated));
  }

  void _onAddEmptyMedication(AddEmptyMedication event, Emitter<PrescriptionState> emit) {
    final newItem = MedicationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '',
    );
    final updated = List<MedicationItem>.from(state.medications)..add(newItem);
    emit(state.copyWith(medications: updated));
  }

  void _onRemoveMedication(RemoveMedication event, Emitter<PrescriptionState> emit) {
    final updated = List<MedicationItem>.from(state.medications)
      ..removeWhere((item) => item.id == event.id);
    emit(state.copyWith(medications: updated));
  }

  void _onUpdateMedicationDetails(UpdateMedicationDetails event, Emitter<PrescriptionState> emit) {
    final updated = state.medications.map((item) {
      if (item.id == event.id) {
        return item.copyWith(
          name: event.name ?? item.name,
          dosage: event.dosage ?? item.dosage,
          frequency: event.frequency ?? item.frequency,
          duration: event.duration ?? item.duration,
          route: event.route ?? item.route,
          instructions: event.instructions ?? item.instructions,
        );
      }
      return item;
    }).toList();
    emit(state.copyWith(medications: updated));
  }

  Future<void> _onLoadLabTestCatalog(LoadLabTestCatalog event, Emitter<PrescriptionState> emit) async {
    if (state.labCatalogStatus == LabCatalogStatus.loading || state.labCatalogStatus == LabCatalogStatus.success) {
      return;
    }
    final hospitalId = event.hospitalId?.trim() ?? '';
    final useCase = _getHospitalLabTestsUseCase;
    if (hospitalId.isEmpty || useCase == null) {
      emit(state.copyWith(labCatalogStatus: LabCatalogStatus.failure));
      return;
    }
    emit(state.copyWith(labCatalogStatus: LabCatalogStatus.loading));
    try {
      final tests = await useCase(hospitalId);
      emit(state.copyWith(labCatalogStatus: LabCatalogStatus.success, labCatalog: tests));
    } catch (_) {
      emit(state.copyWith(labCatalogStatus: LabCatalogStatus.failure));
    }
  }

  void _onSetLabTests(SetLabTests event, Emitter<PrescriptionState> emit) {
    emit(state.copyWith(labTests: List<PrescribedLabTest>.from(event.tests)));
  }

  void _onRemoveLabTest(RemoveLabTest event, Emitter<PrescriptionState> emit) {
    emit(state.copyWith(labTests: state.labTests.where((test) => test.key != event.key).toList()));
  }

  void _onUpdateLabTest(UpdateLabTest event, Emitter<PrescriptionState> emit) {
    emit(state.copyWith(
      labTests: state.labTests
          .map((test) => test.key == event.key
              ? test.copyWith(priority: event.priority, instructions: event.instructions)
              : test)
          .toList(),
    ));
  }

  void _onTogglePrescriptionExpansion(TogglePrescriptionExpansion event, Emitter<PrescriptionState> emit) {
    emit(state.copyWith(isPrescriptionExpanded: !state.isPrescriptionExpanded));
  }
}