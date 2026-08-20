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

class UpdateTimeRangeEvent extends SlotEvent {
  final String fromTime;
  final String toTime;
  UpdateTimeRangeEvent({required this.fromTime, required this.toTime});
}

class GenerateTemplateSlotsEvent extends SlotEvent {}

class AddCustomSlotEvent extends SlotEvent {
  final String? startTime;
  final String? endTime;
  final String? label;
  AddCustomSlotEvent({this.startTime, this.endTime, this.label});
}

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
  final bool block;
  BlockSlotEvent({required this.slotId, this.block = true});
}

class BookAppointmentEvent extends SlotEvent {
  final String slotId;
  final String patientName;
  final String contactNumber;
  final String? startTime;
  final String? reason;
  final String? appointmentType;
  BookAppointmentEvent({
    required this.slotId,
    required this.patientName,
    required this.contactNumber,
    this.startTime,
    this.reason,
    this.appointmentType,
  });
}

class CancelAppointmentEvent extends SlotEvent {
  final String slotId;
  final String? appointmentId;
  CancelAppointmentEvent({required this.slotId, this.appointmentId});
}

class DeployScheduleEvent extends SlotEvent {}
class SlotGenNavEvent extends SlotEvent {}

class ChangeFilterTabUiEvent extends SlotEvent {
  final int tabIndex;
  ChangeFilterTabUiEvent(this.tabIndex);
}
class OnTapSlotCardEvent extends SlotEvent {

}