class UploadedRecord {
  final String id;
  final String fileName;
  final String category;
  final DateTime uploadDate;
  final int fileSizeKB;
  final String? fileUrl;
  final String? filePath;
  final String? description;
  final String? doctorName;
  final String? hospitalName;
  final String? appointmentDate;
  final String? appointmentId;
  final String? fileType;
  final bool isAppointmentDoc;
  final bool isPatientUploaded;
  final bool isDeletable;

  const UploadedRecord({
    required this.id,
    required this.fileName,
    required this.category,
    required this.uploadDate,
    required this.fileSizeKB,
    this.fileUrl,
    this.filePath,
    this.description,
    this.doctorName,
    this.hospitalName,
    this.appointmentDate,
    this.appointmentId,
    this.fileType,
    this.isAppointmentDoc = false,
    this.isPatientUploaded = false,
    this.isDeletable = true,
  });

  UploadedRecord copyWith({
    String? id,
    String? fileName,
    String? category,
    DateTime? uploadDate,
    int? fileSizeKB,
    String? fileUrl,
    String? filePath,
    String? description,
    String? doctorName,
    String? hospitalName,
    String? appointmentDate,
    String? appointmentId,
    String? fileType,
    bool? isAppointmentDoc,
    bool? isPatientUploaded,
    bool? isDeletable,
  }) {
    return UploadedRecord(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      category: category ?? this.category,
      uploadDate: uploadDate ?? this.uploadDate,
      fileSizeKB: fileSizeKB ?? this.fileSizeKB,
      fileUrl: fileUrl ?? this.fileUrl,
      filePath: filePath ?? this.filePath,
      description: description ?? this.description,
      doctorName: doctorName ?? this.doctorName,
      hospitalName: hospitalName ?? this.hospitalName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentId: appointmentId ?? this.appointmentId,
      fileType: fileType ?? this.fileType,
      isAppointmentDoc: isAppointmentDoc ?? this.isAppointmentDoc,
      isPatientUploaded: isPatientUploaded ?? this.isPatientUploaded,
      isDeletable: isDeletable ?? this.isDeletable,
    );
  }
}