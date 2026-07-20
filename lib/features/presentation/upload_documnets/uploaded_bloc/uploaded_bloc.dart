import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/uploaded_record/uploaded_record_entity.dart';
import '../../../domain/repositories/uploaded_record/uploaded_record_repo.dart';

part 'uploaded_event.dart';
part 'uploaded_state.dart';

class UploadedBloc extends Bloc<UploadedBlocEvent, UploadedBlocState> {
  final RecordsRepository repository;

  UploadedBloc({required this.repository}) : super(const UploadedBlocState()) {
    on<FetchUploadedRecords>(_onFetchUploadedRecords);
    on<FilterCategoryChanged>(_onFilterCategoryChanged);
    on<DeleteUploadedRecordItem>(_onDeleteUploadedRecordItem);
    on<UploadRecordScreenNavEvent>((event, emit) async {
      emit(UploadRecordScreenNavState());
    });
  }

  Future<void> _onFetchUploadedRecords(FetchUploadedRecords event, Emitter<UploadedBlocState> emit) async {
    emit(state.copyWith(status: UploadedStatus.loading));
    try {
      final data = await repository.getUploadedRecords();
      emit(state.copyWith(
        status: UploadedStatus.success,
        allRecords: data,
        filteredRecords: _filterData(data, state.selectedCategory),
      ));
    } catch (_) {
      emit(state.copyWith(status: UploadedStatus.failure));
    }
  }

  void _onFilterCategoryChanged(FilterCategoryChanged event, Emitter<UploadedBlocState> emit) {
    emit(state.copyWith(
      selectedCategory: event.category,
      filteredRecords: _filterData(state.allRecords, event.category),
    ));
  }

  Future<void> _onDeleteUploadedRecordItem(DeleteUploadedRecordItem event, Emitter<UploadedBlocState> emit) async {
    await repository.deleteUploadedRecord(event.recordId);
    final updatedList = state.allRecords.where((r) => r.id != event.recordId).toList();
    emit(state.copyWith(
      allRecords: updatedList,
      filteredRecords: _filterData(updatedList, state.selectedCategory),
    ));
  }
  List<UploadedRecord> _filterData(List<UploadedRecord> list, String category) {
    if (category.toLowerCase() == 'all') {
      return list;
    }
    return list.where((item) => item.category.toLowerCase() == category.toLowerCase()).toList();
  }
}