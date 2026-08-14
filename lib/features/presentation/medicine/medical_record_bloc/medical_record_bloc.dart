import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../domain/repositories/medicine/medical_history_repo.dart';

part 'medical_record_event.dart';
part 'medical_record_state.dart';

class MedicalRecordBloc extends Bloc<MedicalRecordEvent, MedicalRecordState> {
  final MedicalHistoryRepository repository;

  MedicalRecordBloc({required this.repository})
      : super(MedicalRecordInitial(initialDate: DateTime(2026, 5, 27))) {

    // Register reactive event mappings
    on<ChangeSelectedDateEvent>(_onChangeSelectedDate);
    on<SaveMedicalRecordEvent>(_onSaveMedicalRecord);
  }

  void _onChangeSelectedDate(
      ChangeSelectedDateEvent event,
      Emitter<MedicalRecordState> emit,
      ) {
    emit(MedicalRecordFormUpdated(selectedDate: event.selectedDate));
  }

  Future<void> _onSaveMedicalRecord(
      SaveMedicalRecordEvent event,
      Emitter<MedicalRecordState> emit,
      ) async {
    final currentRecordDate = state.selectedDate;

    emit(MedicalRecordLoading(selectedDate: currentRecordDate));

    try {
      final payload = <String, dynamic>{
        if (event.patientId != null && event.patientId!.trim().isNotEmpty)
          'patientId': event.patientId!.trim(),
        if (event.appointmentId != null && event.appointmentId!.trim().isNotEmpty)
          'appointmentId': event.appointmentId!.trim(),
        if (event.hospitalId != null && event.hospitalId!.trim().isNotEmpty)
          'hospitalId': event.hospitalId!.trim(),
        if (event.orgId != null && event.orgId!.trim().isNotEmpty)
          'organizationId': event.orgId!.trim(),
        'type': event.visitType,
        'chiefComplaint': event.chiefComplaint,
        'symptoms': event.symptoms,
        'physicalExamination': event.physicalExamination,
        'bloodPressure': event.bp,
        'heartRate': event.hr,
        'temperature': event.temperature,
        'weight': event.weight,
        'height': event.height,
        'diagnosis': event.diagnosis,
        'treatmentPlan': event.treatmentPlan,
      };

      if (event.recordId != null && event.recordId!.trim().isNotEmpty) {
        await repository.updateMedicalRecord(event.recordId!.trim(), payload);
      } else {
        await repository.createMedicalRecord(payload);
      }
      emit(MedicalRecordSuccess(selectedDate: currentRecordDate));
    } catch (error) {
      emit(MedicalRecordFailure(
        error.toString().replaceAll('Exception:', '').trim(),
        selectedDate: currentRecordDate,
      ));
    }
  }
}
