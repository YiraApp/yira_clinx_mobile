


class UploadedRecord {
  final String id;
  final String fileName;
  final String category;
  final DateTime uploadDate;
  final int fileSizeKB;

  const UploadedRecord({
    required this.id,
    required this.fileName,
    required this.category,
    required this.uploadDate,
    required this.fileSizeKB,
  });
}