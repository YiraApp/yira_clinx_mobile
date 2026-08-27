
import '../../entities/slot/slot_appointment_entity.dart';

import '../../../domain/entities/slot/time_slot_entity.dart';

abstract class SchedulerRepository {
  Future<List<SlotEntity>> generateSlots({
    required bool isSingleDay,
    required String targetDate,
    required int durationMinutes,
    required String bufferType,
  });

  Future<bool> deploySchedule(
    List<SlotEntity> slots, {
    required String targetDate,
    required bool isSingleDay,
    List<Map<String, dynamic>>? breakTimes,
  });

  Future<List<TimeSlot>> generateTimeSlots({
    required bool isSingleDay,
    required String targetDate,
    required int durationMinutes,
    required String bufferType,
  });

  Future<List<BreakTimeEntity>> fetchBreakTimes({
    required String targetDate,
    required bool isSingleDay,
  });

  Future<bool> deployTimeSchedule(
    List<TimeSlot> slots, {
    required String targetDate,
    required bool isSingleDay,
    List<Map<String, dynamic>>? breakTimes,
  });

  Future<bool> blockSlot({required String slotId, bool block = true});

  Future<bool> bookSlotAppointment({
    required String slotId,
    required String patientName,
    required String patientPhone,
    required String appointmentDate,
    required String startTime,
    String? reason,
    String? appointmentType,
  });

  Future<bool> cancelSlotAppointment({
    required String appointmentId,
    String? slotId,
  });
}