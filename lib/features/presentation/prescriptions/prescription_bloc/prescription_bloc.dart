import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/prescriptions/prescription_item.dart';
import '../../../domain/entities/prescriptions/prescription_entity.dart';
import '../../../use_cases/save_prescription_use_case.dart'; // Verify this path matches your project structure

part 'prescription_event.dart';
part 'prescription_state.dart';

class PrescriptionBloc extends Bloc<PrescriptionEvent, PrescriptionState> {
  final SavePrescriptionUseCase? _savePrescriptionUseCase;

  PrescriptionBloc({
     SavePrescriptionUseCase? savePrescriptionUseCase,
  })  : _savePrescriptionUseCase = savePrescriptionUseCase,
        super(const PrescriptionState()) {
    on<LoadPrescriptionData>(_onLoadPrescriptionData);
    on<SubmitPrescription>(_onSubmitPrescription);
    on<AddDiagnosis>(_onAddDiagnosis);
    on<RemoveDiagnosis>(_onRemoveDiagnosis);
    on<AddMedication>(_onAddMedication);
    on<RemoveMedication>(_onRemoveMedication);
    on<UpdateMedicationDetails>(_onUpdateMedicationDetails);
    on<TogglePrescriptionExpansion>(_onTogglePrescriptionExpansion);
  }

  void _onLoadPrescriptionData(LoadPrescriptionData event, Emitter<PrescriptionState> emit) {
    emit(state.copyWith(status: PrescriptionStatus.loading));
    emit(state.copyWith(
      status: PrescriptionStatus.success,
      diagnoses: ['Hypermetropia', 'Axial hypermetropia'],
      medications: [
        MedicationItem(
          id: '1',
          name: 'Acetaminophen-containing product',
          dosage: '500mg',
          frequency: 'Once daily (OD)',
          duration: '7 Days',
          route: 'Oral',
        ),
        const MedicationItem(
          id: '2',
          name: 'Acetaminophen-containing product',
        ),
      ],
    ));
  }

  /// 🚀 NEW: Event handler that executes both repository actions sequentially via the use case
  Future<void> _onSubmitPrescription(SubmitPrescription event, Emitter<PrescriptionState> emit) async {
    emit(state.copyWith(status: PrescriptionStatus.loading));
    try {
      final payload = PrescriptionEntity(
        patientId: event.patientId,
        diagnoses: state.diagnoses,
        medications: state.medications,
        additionalNotes: event.additionalNotes,
      );

      // Executes Method 1 (Save) and Method 2 (Fetch) sequentially inside your UseCase
      final PrescriptionEntity synchronizedData = await _savePrescriptionUseCase!.call(payload);

      emit(state.copyWith(
        status: PrescriptionStatus.success,
        diagnoses: synchronizedData.diagnoses,
        medications: synchronizedData.medications,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PrescriptionStatus.failure,
        errorMessage: e.toString(),
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

  void _onRemoveMedication(RemoveMedication event, Emitter<PrescriptionState> emit) {
    final updated = List<MedicationItem>.from(state.medications)
      ..removeWhere((item) => item.id == event.id);
    emit(state.copyWith(medications: updated));
  }

  void _onUpdateMedicationDetails(UpdateMedicationDetails event, Emitter<PrescriptionState> emit) {
    final updated = state.medications.map((item) {
      if (item.id == event.id) {
        return item.copyWith(
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