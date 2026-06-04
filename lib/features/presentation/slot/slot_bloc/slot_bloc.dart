import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/slot/slot_appointment_entity.dart';
import '../../../domain/entities/slot/time_slot_entity.dart';
import '../../../domain/repositories/slot/scheduler_repo.dart';

part 'slot_event.dart';
part 'slot_state.dart';
class SlotBloc extends Bloc<SlotEvent, SlotState> {
  final SchedulerRepository schedulerRepository; // Single repository handles all code paths

  SlotBloc({required this.schedulerRepository}) : super(SlotState.initial()) {
    // Legacy & Core Events
    on<InitializeSlotsEvent>(_onInitializeSlots);
    on<ChangeExecutionModeEvent>(_onChangeExecutionMode);
    on<UpdateTargetDateEvent>(_onUpdateTargetDate);
    on<UpdateDateRangeEvent>(_onUpdateDateRange);
    on<ChangeDurationEvent>(_onChangeDuration);
    on<ChangeBufferEvent>(_onChangeBuffer);
    on<AddCustomSlotEvent>(_onAddCustomSlot);
    on<RemoveSlotEvent>(_onRemoveSlot);
    on<UpdateSlotDetailsEvent>(_onUpdateSlotDetails);
    on<BlockSlotEvent>(_onBlockSlot);
    on<BookAppointmentEvent>(_onBookAppointment);
    on<CancelAppointmentEvent>(_onCancelAppointment);
    on<DeployScheduleEvent>(_onDeploySchedule);

    // Modern Dashboard Filter UI Event
    on<ChangeFilterTabUiEvent>(_onChangeFilterTabUi);
  }

  void _onInitializeSlots(InitializeSlotsEvent event, Emitter<SlotState> emit) async {
    emit(state.copyWith(isLoading: true));

    final dateString = state.isSingleDay
        ? DateFormat('MMM dd, yyyy').format(state.targetDate)
        : "${DateFormat('MMM dd').format(state.startDate)} - ${DateFormat('MMM dd, yyyy').format(state.endDate)}";

    try {
      // 1. Fetch old data using the legacy method signature
      final generatedLegacySlots = await schedulerRepository.generateSlots(
        isSingleDay: state.isSingleDay,
        targetDate: dateString,
        durationMinutes: state.durationMinutes,
        bufferType: state.bufferType,
      );

      // 2. Fetch new dashboard metrics using the modern overloaded method signature
      final generatedModernSlots = await schedulerRepository.generateTimeSlots(
        isSingleDay: state.isSingleDay,
        targetDate: dateString,
        durationMinutes: state.durationMinutes,
        bufferType: state.bufferType,
      );

      emit(state.copyWith(
        slots: generatedLegacySlots,
        timeSlots: generatedModernSlots,
        isLoading: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void _onChangeExecutionMode(ChangeExecutionModeEvent event, Emitter<SlotState> emit) {
    emit(state.copyWith(isSingleDay: event.isSingleDay));
  }

  void _onUpdateTargetDate(UpdateTargetDateEvent event, Emitter<SlotState> emit) {
    emit(state.copyWith(targetDate: event.selectedDate));
  }

  void _onUpdateDateRange(UpdateDateRangeEvent event, Emitter<SlotState> emit) {
    emit(state.copyWith(startDate: event.startDate, endDate: event.endDate));
  }

  void _onChangeDuration(ChangeDurationEvent event, Emitter<SlotState> emit) {
    emit(state.copyWith(durationMinutes: event.duration));
  }

  void _onChangeBuffer(ChangeBufferEvent event, Emitter<SlotState> emit) {
    emit(state.copyWith(bufferType: event.buffer));
  }

  void _onAddCustomSlot(AddCustomSlotEvent event, Emitter<SlotState> emit) {
    final updatedLegacy = List<SlotEntity>.from(state.slots);
    final updatedModern = List<TimeSlot>.from(state.timeSlots);
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    // Append to both lists to keep data mirrors completely synchronized
    updatedLegacy.add(SlotEntity(id: newId, startTime: '12:00 PM', endTime: '12:30 PM', label: 'Available'));
    updatedModern.add(TimeSlot(id: newId, time: '12:00 PM', duration: '30m', status: SlotStatus.available));

    emit(state.copyWith(slots: updatedLegacy, timeSlots: updatedModern));
  }

  void _onRemoveSlot(RemoveSlotEvent event, Emitter<SlotState> emit) {
    emit(state.copyWith(
      slots: state.slots.where((slot) => slot.id != event.slotId).toList(),
      timeSlots: state.timeSlots.where((slot) => slot.id != event.slotId).toList(),
    ));
  }

  void _onUpdateSlotDetails(UpdateSlotDetailsEvent event, Emitter<SlotState> emit) {
    // 1. Update Legacy Slot Collection
    final updatedLegacy = state.slots.map((slot) {
      if (slot.id == event.slotId) {
        return slot.copyWith(
          startTime: event.startTime,
          endTime: event.endTime,
          label: event.label,
        );
      }
      return slot;
    }).toList();

    // 2. Update Modern TimeSlot Collection
    final updatedModern = state.timeSlots.map((slot) {
      if (slot.id == event.slotId) {
        return TimeSlot(
          id: slot.id,
          time: event.startTime ?? slot.time,
          duration: event.endTime ?? slot.duration,
          status: event.label == 'Booked' ? SlotStatus.booked : SlotStatus.available,
          patientName: slot.patientName,
          type: slot.type,
          isVerified: slot.isVerified,
        );
      }
      return slot;
    }).toList();

    emit(state.copyWith(slots: updatedLegacy, timeSlots: updatedModern));
  }

  void _onBlockSlot(BlockSlotEvent event, Emitter<SlotState> emit) {
    final updatedLegacy = state.slots.map((slot) {
      if (slot.id == event.slotId) {
        return slot.copyWith(label: 'Blocked', appointment: () => null);
      }
      return slot;
    }).toList();

    final updatedModern = state.timeSlots.map((slot) {
      if (slot.id == event.slotId) {
        return TimeSlot(
          id: slot.id,
          time: slot.time,
          duration: 'Blocked',
          status: SlotStatus.available,
          patientName: null,
          type: null,
          isVerified: false,
        );
      }
      return slot;
    }).toList();

    emit(state.copyWith(slots: updatedLegacy, timeSlots: updatedModern));
  }

  void _onBookAppointment(BookAppointmentEvent event, Emitter<SlotState> emit) {
    final updatedLegacy = state.slots.map((slot) {
      if (slot.id == event.slotId) {
        return slot.copyWith(
          label: 'Booked',
          appointment: () => SlotAppointmentEntity(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            patientName: event.patientName,
            contactNumber: event.contactNumber,
          ),
        );
      }
      return slot;
    }).toList();

    final updatedModern = state.timeSlots.map((slot) {
      if (slot.id == event.slotId) {
        return TimeSlot(
          id: slot.id,
          time: slot.time,
          duration: 'Consult',
          status: SlotStatus.booked,
          patientName: event.patientName,
          type: AppointmentType.regularCheckUp,
          isVerified: true,
        );
      }
      return slot;
    }).toList();

    emit(state.copyWith(slots: updatedLegacy, timeSlots: updatedModern));
  }

  void _onCancelAppointment(CancelAppointmentEvent event, Emitter<SlotState> emit) {
    final updatedLegacy = state.slots.map((slot) {
      if (slot.id == event.slotId) {
        return slot.copyWith(label: 'Available', appointment: () => null);
      }
      return slot;
    }).toList();

    final updatedModern = state.timeSlots.map((slot) {
      if (slot.id == event.slotId) {
        return TimeSlot(
          id: slot.id,
          time: slot.time,
          duration: '30m',
          status: SlotStatus.available,
          patientName: null,
          type: null,
          isVerified: false,
        );
      }
      return slot;
    }).toList();

    emit(state.copyWith(slots: updatedLegacy, timeSlots: updatedModern));
  }

  void _onDeploySchedule(DeployScheduleEvent event, Emitter<SlotState> emit) async {
    emit(state.copyWith(isDeploying: true));

    // Deploys both versions to the downstream system via your single repository hooks
    final outcomeLegacy = await schedulerRepository.deploySchedule(state.slots);
    final outcomeModern = await schedulerRepository.deployTimeSchedule(state.timeSlots);

    emit(state.copyWith(
      isDeploying: false,
      deploySuccess: outcomeLegacy && outcomeModern,
    ));
  }

  void _onChangeFilterTabUi(ChangeFilterTabUiEvent event, Emitter<SlotState> emit) {
    emit(state.copyWith(selectedTabIndex: event.tabIndex));
  }
}
