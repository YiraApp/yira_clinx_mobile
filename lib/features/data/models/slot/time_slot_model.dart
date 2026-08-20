


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
    super.appointmentId,
    super.reason,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    SlotStatus slotStatus = SlotStatus.available;
    final statusStr = json['status']?.toString().toLowerCase();
    if (statusStr == 'booked' || json['is_booked'] == true || json['isBooked'] == true) {
      slotStatus = SlotStatus.booked;
    } else if (statusStr == 'blocked' || json['is_blocked'] == true || json['isBlocked'] == true || json['isAvailable'] == false) {
      slotStatus = SlotStatus.blocked;
    }

    return TimeSlotModel(
      id: json['id'] as String,
      time: json['time'] as String,
      duration: json['duration'] as String,
      status: slotStatus,
      patientName: json['patient_name'] as String? ?? json['patientName'] as String?,
      type: _parseType(json['type'] as String? ?? json['appointmentType'] as String?),
      isVerified: json['is_verified'] as bool? ?? false,
      appointmentId: json['appointment_id'] as String? ?? json['appointmentId'] as String?,
      reason: json['reason'] as String?,
    );
  }

  static AppointmentType? _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'consult': return AppointmentType.consult;
      case 'review': return AppointmentType.review;
      case 'regular':
      case 'regular check-up':
      case 'regularcheckup': return AppointmentType.regularCheckUp;
      case 'followup':
      case 'follow-up': return AppointmentType.followUp;
      default: return null;
    }
  }
}