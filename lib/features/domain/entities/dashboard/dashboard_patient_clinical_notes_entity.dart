class DashBoardPatientDetailsClinicalNotesEntity {
  final bool? status;
  final String? message;
  final ClinicalNotesDataEntity? data;

  const DashBoardPatientDetailsClinicalNotesEntity({
    this.status,
    this.message,
    this.data,
  });
}

class ClinicalNotesDataEntity {
  final List<ClinicalNotesEntity>? clinicalNotes;

  const ClinicalNotesDataEntity({this.clinicalNotes});
}

class ClinicalNotesEntity {
  final int? id;
  final String? doctorName;
  final String? date;
  final String? note;

  const ClinicalNotesEntity({
    this.id,
    this.doctorName,
    this.date,
    this.note,
  });
}