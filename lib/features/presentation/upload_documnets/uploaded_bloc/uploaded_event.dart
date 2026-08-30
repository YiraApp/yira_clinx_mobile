part of 'uploaded_bloc.dart';

@immutable
abstract class UploadedBlocEvent {}

class FetchUploadedRecords extends UploadedBlocEvent {
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;
  final int? limit;
  final int? page;

  FetchUploadedRecords({
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
    this.limit,
    this.page,
  });
}

class LoadMoreUploadedRecords extends UploadedBlocEvent {
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;
  final int limit;

  LoadMoreUploadedRecords({
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
    this.limit = 15,
  });
}

class AddUploadedRecord extends UploadedBlocEvent {
  final UploadedRecord record;
  AddUploadedRecord(this.record);
}

class FilterCategoryChanged extends UploadedBlocEvent {
  final String category;
  FilterCategoryChanged(this.category);
}

class SearchQueryChanged extends UploadedBlocEvent {
  final String query;
  SearchQueryChanged(this.query);
}

class DeleteUploadedRecordItem extends UploadedBlocEvent {
  final String recordId;
  DeleteUploadedRecordItem(this.recordId);
}

class UploadRecordScreenNavEvent extends UploadedBlocEvent {}