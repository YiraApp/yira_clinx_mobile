part of 'uploaded_bloc.dart';

@immutable
abstract class UploadedBlocEvent {}

class FetchUploadedRecords extends UploadedBlocEvent {
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;

  FetchUploadedRecords({
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
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

class DeleteUploadedRecordItem extends UploadedBlocEvent {
  final String recordId;
  DeleteUploadedRecordItem(this.recordId);
}

class UploadRecordScreenNavEvent extends UploadedBlocEvent {}