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
    on<LoadMoreUploadedRecords>(_onLoadMoreUploadedRecords);
    on<AddUploadedRecord>(_onAddUploadedRecord);
    on<FilterCategoryChanged>(_onFilterCategoryChanged);
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<DeleteUploadedRecordItem>(_onDeleteUploadedRecordItem);
    on<UploadRecordScreenNavEvent>((event, emit) async {
      emit(UploadRecordScreenNavState());
    });
  }

  Future<void> _onFetchUploadedRecords(
    FetchUploadedRecords event,
    Emitter<UploadedBlocState> emit,
  ) async {
    emit(state.copyWith(
      status: UploadedStatus.loading,
      currentPage: 1,
      hasMore: true,
    ));
    try {
      final data = await repository.getUploadedRecords(
        patientId: event.patientId,
        appointmentId: event.appointmentId,
        hospitalId: event.hospitalId,
        orgId: event.orgId,
        limit: event.limit ?? 20,
        page: event.page ?? 1,
      );
      final hasMore = data.length >= (event.limit ?? 20);
      emit(state.copyWith(
        status: UploadedStatus.success,
        allRecords: data,
        filteredRecords: _filterData(data, state.selectedCategory, state.searchQuery),
        currentPage: 1,
        hasMore: hasMore,
      ));
    } catch (_) {
      emit(state.copyWith(status: UploadedStatus.failure));
    }
  }

  Future<void> _onLoadMoreUploadedRecords(
    LoadMoreUploadedRecords event,
    Emitter<UploadedBlocState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));
    try {
      final nextPage = state.currentPage + 1;
      final newItems = await repository.getUploadedRecords(
        patientId: event.patientId,
        appointmentId: event.appointmentId,
        hospitalId: event.hospitalId,
        orgId: event.orgId,
        limit: event.limit,
        page: nextPage,
      );

      final hasMore = newItems.length >= event.limit;
      final existingIds = state.allRecords.map((r) => r.id).toSet();
      final distinctNewItems = newItems.where((r) => !existingIds.contains(r.id)).toList();
      final updatedAll = List<UploadedRecord>.from(state.allRecords)..addAll(distinctNewItems);

      emit(state.copyWith(
        allRecords: updatedAll,
        filteredRecords: _filterData(updatedAll, state.selectedCategory, state.searchQuery),
        currentPage: nextPage,
        hasMore: hasMore,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  void _onAddUploadedRecord(AddUploadedRecord event, Emitter<UploadedBlocState> emit) {
    final updatedAll = List<UploadedRecord>.from(state.allRecords)..insert(0, event.record);
    emit(state.copyWith(
      status: UploadedStatus.success,
      allRecords: updatedAll,
      filteredRecords: _filterData(updatedAll, state.selectedCategory, state.searchQuery),
    ));
  }

  void _onFilterCategoryChanged(FilterCategoryChanged event, Emitter<UploadedBlocState> emit) {
    emit(state.copyWith(
      selectedCategory: event.category,
      filteredRecords: _filterData(state.allRecords, event.category, state.searchQuery),
    ));
  }

  void _onSearchQueryChanged(SearchQueryChanged event, Emitter<UploadedBlocState> emit) {
    emit(state.copyWith(
      searchQuery: event.query,
      filteredRecords: _filterData(state.allRecords, state.selectedCategory, event.query),
    ));
  }

  Future<void> _onDeleteUploadedRecordItem(DeleteUploadedRecordItem event, Emitter<UploadedBlocState> emit) async {
    await repository.deleteUploadedRecord(event.recordId);
    final updatedList = state.allRecords.where((r) => r.id != event.recordId).toList();
    emit(state.copyWith(
      allRecords: updatedList,
      filteredRecords: _filterData(updatedList, state.selectedCategory, state.searchQuery),
    ));
  }

  List<UploadedRecord> _filterData(List<UploadedRecord> list, String category, String query) {
    var result = list;
    if (category.toLowerCase() != 'all') {
      result = result.where((item) => item.category.toLowerCase() == category.toLowerCase()).toList();
    }
    if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      result = result.where((item) {
        final title = item.fileName.toLowerCase();
        final cat = item.category.toLowerCase();
        final desc = (item.description ?? '').toLowerCase();
        final doc = (item.doctorName ?? '').toLowerCase();
        final hosp = (item.hospitalName ?? '').toLowerCase();
        return title.contains(q) || cat.contains(q) || desc.contains(q) || doc.contains(q) || hosp.contains(q);
      }).toList();
    }
    return result;
  }
}