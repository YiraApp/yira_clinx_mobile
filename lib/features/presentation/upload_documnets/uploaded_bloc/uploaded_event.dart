part of 'uploaded_bloc.dart';

@immutable
abstract class UploadedBlocEvent {}

class FetchUploadedRecords extends UploadedBlocEvent {}

class FilterCategoryChanged extends UploadedBlocEvent {
  final String category;
  FilterCategoryChanged(this.category);
}

class DeleteUploadedRecordItem extends UploadedBlocEvent {
  final String recordId;
  DeleteUploadedRecordItem(this.recordId);
}
class UploadRecordScreenNavEvent extends UploadedBlocEvent{

}