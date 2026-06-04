


import '../../../domain/entities/uploaded_record/uploaded_record_entity.dart';


class UploadedRecordModel extends UploadedRecord {
  const UploadedRecordModel({
    required super.id,
    required super.fileName,
    required super.category,
    required super.uploadDate,
    required super.fileSizeKB,
  });

  factory UploadedRecordModel.fromJson(Map<String, dynamic> json) {
    return UploadedRecordModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      category: json['category'] as String,
      uploadDate: DateTime.parse(json['uploadDate'] as String),
      fileSizeKB: json['fileSizeKB'] as int,
    );
  }
}