part of 'uploaded_bloc.dart';
enum UploadedStatus { initial, loading, success, failure }
@immutable
class UploadedBlocState {
  final UploadedStatus status;
  final List<UploadedRecord> allRecords;
  final List<UploadedRecord> filteredRecords;
  final String selectedCategory;

  const UploadedBlocState({
    this.status = UploadedStatus.initial,
    this.allRecords = const [],
    this.filteredRecords = const [],
    this.selectedCategory = 'All',
  });

  UploadedBlocState copyWith({
    UploadedStatus? status,
    List<UploadedRecord>? allRecords,
    List<UploadedRecord>? filteredRecords,
    String? selectedCategory,
  }) {
    return UploadedBlocState(
      status: status ?? this.status,
      allRecords: allRecords ?? this.allRecords,
      filteredRecords: filteredRecords ?? this.filteredRecords,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}
class UploadRecordScreenNavState extends UploadedBlocState{

}