


import '../../../domain/entities/slot/time_slot_entity.dart';

class TimeSlotModel extends TimeSlot {
  const TimeSlotModel({
    required super.id,
    required super.time,
    required super.duration,
    required super.status,
    super.patientName,
    super.type,
    super.isVerified,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id'] as String,
      time: json['time'] as String,
      duration: json['duration'] as String,
      status: json['status'] == 'booked' ? SlotStatus.booked : SlotStatus.available,
      patientName: json['patient_name'] as String?,
      type: _parseType(json['type'] as String?),
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  static AppointmentType? _parseType(String? type) {
    switch (type) {
      case 'consult': return AppointmentType.consult;
      case 'review': return AppointmentType.review;
      case 'regular': return AppointmentType.regularCheckUp;
      case 'followup': return AppointmentType.followUp;
      default: return null;
    }
  }
}