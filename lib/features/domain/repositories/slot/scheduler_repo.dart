
import '../../entities/slot/slot_appointment_entity.dart';

import '../../../domain/entities/slot/time_slot_entity.dart';

abstract class SchedulerRepository {
  Future<List<SlotEntity>> generateSlots({
    required bool isSingleDay,
    required String targetDate,
    required int durationMinutes,
    required String bufferType,
  });

  Future<bool> deploySchedule(List<SlotEntity> slots, {required String targetDate, required bool isSingleDay});

  Future<List<TimeSlot>> generateTimeSlots({
    required bool isSingleDay,
    required String targetDate,
    required int durationMinutes,
    required String bufferType,
  });

  Future<bool> deployTimeSchedule(List<TimeSlot> slots, {required String targetDate, required bool isSingleDay});
}