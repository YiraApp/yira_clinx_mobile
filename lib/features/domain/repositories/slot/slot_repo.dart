

import '../../entities/slot/time_slot_entity.dart';

abstract class SlotRepository {
  /// Fetches a collection of structured time slot segments for a target date calendar selection.
  Future<List<TimeSlot>> getTimeSlots({required DateTime date});
}