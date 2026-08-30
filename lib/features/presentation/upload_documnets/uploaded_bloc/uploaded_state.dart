part of 'uploaded_bloc.dart';

enum UploadedStatus { initial, loading, success, failure }

@immutable
class UploadedBlocState {
  final UploadedStatus status;
  final List<UploadedRecord> allRecords;
  final List<UploadedRecord> filteredRecords;
  final String selectedCategory;
  final String searchQuery;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;

  const UploadedBlocState({
    this.status = UploadedStatus.initial,
    this.allRecords = const [],
    this.filteredRecords = const [],
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
  });

  UploadedBlocState copyWith({
    UploadedStatus? status,
    List<UploadedRecord>? allRecords,
    List<UploadedRecord>? filteredRecords,
    String? selectedCategory,
    String? searchQuery,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
  }) {
    return UploadedBlocState(
      status: status ?? this.status,
      allRecords: allRecords ?? this.allRecords,
      filteredRecords: filteredRecords ?? this.filteredRecords,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class UploadRecordScreenNavState extends UploadedBlocState {}