import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/medicine/medical_history_entity.dart';
import '../../../domain/repositories/medicine/medical_history_repo.dart';
import '../../../use_cases/medical_history_use_case.dart';

part 'medical_history_event.dart';
part 'medical_history_state.dart';

class MedicalHistoryBloc extends Bloc<MedicalHistoryEvent, MedicalHistoryState> {
  final GetMedicalRecordsUseCase getMedicalRecordsUseCase;
  final MedicalHistoryRepository repository;

  MedicalHistoryBloc({required this.getMedicalRecordsUseCase, required this.repository}) : super(MedicalHistoryInitial()) {
    on<LoadMedicalHistoryRecords>((event, emit) async {
      emit(MedicalHistoryLoading());
      try {
        final data = await getMedicalRecordsUseCase(
          patientId: event.patientId,
          appointmentId: event.appointmentId,
          hospitalId: event.hospitalId,
          orgId: event.orgId,
        );
        emit(MedicalHistoryLoaded(data));
      } catch (e) {
        emit(const MedicalHistoryError("Failed to synchronize records history log."));
      }
    });

    on<DeleteMedicalHistoryRecord>((event, emit) async {
      if (state is MedicalHistoryLoaded) {
        final currentRecords = (state as MedicalHistoryLoaded).records;
        try {
          await repository.deleteMedicalRecord(event.recordId);
          final updatedRecords = currentRecords.where((element) => element.id != event.recordId).toList();
          emit(MedicalHistoryLoaded(updatedRecords));
        } catch (_) {}
      }
    });
    on<AddMedicalRecordNavEvent>((event, emit) async {
      emit(AddMedicalRecordNavState());
    });
    on<SingleMedicineDetailsNavEvent>((event, emit) async {
      emit(SingleMedicineDetailsNavState(recordId: event.recordId, record: event.record));
    });
  }
}