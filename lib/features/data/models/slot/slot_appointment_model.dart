
import '../../../domain/entities/slot/slot_appointment_entity.dart';

class SlotAppointmentModel extends SlotAppointmentEntity {
  SlotAppointmentModel({
    required super.id,
    required super.patientName,
    required super.contactNumber,
  });

  factory SlotAppointmentModel.fromJson(Map<String, dynamic> json) {
    return SlotAppointmentModel(
      id: json['id'] as String,
      patientName: json['patient_name'] as String,
      contactNumber: json['contact_number'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_name': patientName,
      'contact_number': contactNumber,
    };
  }
}

class SlotModel extends SlotEntity {
  SlotModel({
    required super.id,
    required super.startTime,
    required super.endTime,
    required super.label,
    super.appointment,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      id: json['id'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      label: json['label'] as String,
      appointment: json['appointment'] != null
          ? SlotAppointmentModel.fromJson(json['appointment'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime,
      'end_time': endTime,
      'label': label,
      'appointment': appointment != null
          ? (appointment as SlotAppointmentModel).toJson()
          : null,
    };
  }
}