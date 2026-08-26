
class SlotAppointmentEntity {
  final String id;
  final String patientName;
  final String contactNumber;
  final String? reason;

  SlotAppointmentEntity({
    required this.id,
    required this.patientName,
    required this.contactNumber,
    this.reason,
  });
}

class SlotEntity {
  final String id;
  final String startTime;
  final String endTime;
  final String label;
  final SlotAppointmentEntity? appointment;

  SlotEntity({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.label,
    this.appointment,
  });

  bool get hasAppointment => appointment != null;

  SlotEntity copyWith({
    String? startTime,
    String? endTime,
    String? label,
    SlotAppointmentEntity? Function()? appointment,
  }) {
    return SlotEntity(
      id: id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      label: label ?? this.label,
      appointment: appointment != null ? appointment() : this.appointment,
    );
  }
}

class BreakTimeEntity {
  final String id;
  final String label;
  final String fromTime;
  final String toTime;

  BreakTimeEntity({
    required this.id,
    required this.label,
    required this.fromTime,
    required this.toTime,
  });

  BreakTimeEntity copyWith({
    String? id,
    String? label,
    String? fromTime,
    String? toTime,
  }) {
    return BreakTimeEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
    );
  }
}