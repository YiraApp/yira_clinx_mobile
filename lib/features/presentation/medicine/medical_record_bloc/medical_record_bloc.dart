import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'medical_record_event.dart';
part 'medical_record_state.dart';

class MedicalRecordBloc extends Bloc<MedicalRecordEvent, MedicalRecordState> {
  MedicalRecordBloc() : super(MedicalRecordInitial(initialDate: DateTime(2026, 5, 27))) {

    // Register reactive event mappings
    on<ChangeSelectedDateEvent>(_onChangeSelectedDate);
    on<SaveMedicalRecordEvent>(_onSaveMedicalRecord);
  }

  void _onChangeSelectedDate(
      ChangeSelectedDateEvent event,
      Emitter<MedicalRecordState> emit,
      ) {
    // Retain full historical context of the entry view while dynamically re-rendering targets
    emit(MedicalRecordFormUpdated(selectedDate: event.selectedDate));
  }

  Future<void> _onSaveMedicalRecord(
      SaveMedicalRecordEvent event,
      Emitter<MedicalRecordState> emit,
      ) async {
    // Access state parameters safely using state.selectedDate if needed
    final currentRecordDate = state.selectedDate;

    emit(MedicalRecordLoading(selectedDate: currentRecordDate));

    try {
      await Future.delayed(const Duration(milliseconds: 1000));
      emit(MedicalRecordSuccess(selectedDate: currentRecordDate));
    } catch (error) {
      emit(MedicalRecordFailure(error.toString(), selectedDate: currentRecordDate));
    }
  }
}
