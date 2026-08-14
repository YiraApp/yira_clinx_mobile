import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/prescriptions/prescription_item.dart';
import '../../../domain/entities/prescriptions/prescription_entity.dart';
import '../../../use_cases/save_prescription_use_case.dart';

part 'prescription_event.dart';
part 'prescription_state.dart';

class PrescriptionBloc extends Bloc<PrescriptionEvent, PrescriptionState> {
  final SavePrescriptionUseCase? _savePrescriptionUseCase;

  PrescriptionBloc({
    SavePrescriptionUseCase? savePrescriptionUseCase,
  })  : _savePrescriptionUseCase = savePrescriptionUseCase,
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
    on<AddPrescriptionRecordNavEvent>((event, emit) async {
      emit(AddPrescriptionRecordNavState());
    });
    on<SinglePrescriptionDetailsNavEvent>((event, emit) async {
      emit(SinglePrescriptionDetailsNavState(event.prescriptionId));
    });
  }

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
      if (data != null && (data.medications.isNotEmpty || data.diagnoses.isNotEmpty || data.additionalNotes.isNotEmpty)) {
        emit(state.copyWith(
          status: PrescriptionStatus.success,
          diagnoses: data.diagnoses,
          medications: data.medications.isEmpty
              ? [MedicationItem(id: DateTime.now().millisecondsSinceEpoch.toString(), name: '')]
              : data.medications,
          additionalNotes: data.additionalNotes,
        ));
      }
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
        patientId: event.patientId,
        appointmentId: event.appointmentId,
        hospitalId: event.hospitalId,
        orgId: event.orgId,
        diagnoses: state.diagnoses,
        medications: validMeds,
        additionalNotes: event.additionalNotes,
      );

      final PrescriptionEntity synchronizedData = await _savePrescriptionUseCase!.call(payload);

      emit(state.copyWith(
        status: PrescriptionStatus.submitSuccess,
        diagnoses: synchronizedData.diagnoses,
        medications: synchronizedData.medications,
        additionalNotes: synchronizedData.additionalNotes,
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
        );
      }
      return item;
    }).toList();
    emit(state.copyWith(medications: updated));
  }

  void _onTogglePrescriptionExpansion(TogglePrescriptionExpansion event, Emitter<PrescriptionState> emit) {
    emit(state.copyWith(isPrescriptionExpanded: !state.isPrescriptionExpanded));
  }
}