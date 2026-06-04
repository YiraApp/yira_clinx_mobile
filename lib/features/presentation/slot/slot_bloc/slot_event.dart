part of 'slot_bloc.dart';

@immutable
abstract class SlotEvent {}

class InitializeSlotsEvent extends SlotEvent {}

class ChangeExecutionModeEvent extends SlotEvent {
  final bool isSingleDay;
  ChangeExecutionModeEvent(this.isSingleDay);
}

class UpdateTargetDateEvent extends SlotEvent {
  final DateTime selectedDate;
  UpdateTargetDateEvent(this.selectedDate);
}

class UpdateDateRangeEvent extends SlotEvent {
  final DateTime startDate;
  final DateTime endDate;
  UpdateDateRangeEvent({required this.startDate, required this.endDate});
}

class ChangeDurationEvent extends SlotEvent {
  final int duration;
  ChangeDurationEvent(this.duration);
}

class ChangeBufferEvent extends SlotEvent {
  final String buffer;
  ChangeBufferEvent(this.buffer);
}

class AddCustomSlotEvent extends SlotEvent {}

class RemoveSlotEvent extends SlotEvent {
  final String slotId;
  RemoveSlotEvent(this.slotId);
}

class UpdateSlotDetailsEvent extends SlotEvent {
  final String slotId;
  final String? startTime;
  final String? endTime;
  final String? label;
  UpdateSlotDetailsEvent(this.slotId, {this.startTime, this.endTime, this.label});
}

// --- ADDED EXPLICIT MISSING EVENT FOR BLOCKING SLOTS ---
class BlockSlotEvent extends SlotEvent {
  final String slotId;
  BlockSlotEvent({required this.slotId});
}

class BookAppointmentEvent extends SlotEvent {
  final String slotId;
  final String patientName;
  final String contactNumber;
  BookAppointmentEvent({
    required this.slotId,
    required this.patientName,
    required this.contactNumber,
  });
}

class CancelAppointmentEvent extends SlotEvent {
  final String slotId;
  CancelAppointmentEvent(this.slotId);
}

class DeployScheduleEvent extends SlotEvent {}

class ChangeFilterTabUiEvent extends SlotEvent {
  final int tabIndex;
  ChangeFilterTabUiEvent(this.tabIndex);
}