import 'package:bloc/bloc.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/slot/slot_appointment_entity.dart';
import '../../../domain/entities/slot/time_slot_entity.dart';
import '../../../domain/repositories/slot/scheduler_repo.dart';

part 'slot_event.dart';
part 'slot_state.dart';

class SlotBloc extends Bloc<SlotEvent, SlotState> {
  final SchedulerRepository schedulerRepository;

  SlotBloc({required this.schedulerRepository}) : super(SlotDataState.initial()) {
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
    on<ChangeFilterTabUiEvent>(_onChangeFilterTabUi);
    on<SlotGenNavEvent>(_onSlotGenNav);
    on<OnTapSlotCardEvent>(_onSlotTapNav);
  }

  void _onInitializeSlots(InitializeSlotsEvent event, Emitter<SlotState> emit) async {
    // FIX: If we are stuck in a navigation state, fall back to an initial data state structure
    final SlotDataState currentState = state is SlotDataState
        ? state as SlotDataState
        : SlotDataState.initial();

    emit(currentState.copyWith(isLoading: true));

    final dateString = currentState.isSingleDay
        ? DateFormat('MMM dd, yyyy').format(currentState.targetDate)
        : "${DateFormat('MMM dd').format(currentState.startDate)} - ${DateFormat('MMM dd, yyyy').format(currentState.endDate)}";

    try {
      final generatedLegacySlots = await schedulerRepository.generateSlots(
        isSingleDay: currentState.isSingleDay,
        targetDate: dateString,
        durationMinutes: currentState.durationMinutes,
        bufferType: currentState.bufferType,
      );

      final generatedModernSlots = await schedulerRepository.generateTimeSlots(
        isSingleDay: currentState.isSingleDay,
        targetDate: dateString,
        durationMinutes: currentState.durationMinutes,
        bufferType: currentState.bufferType,
      );

      emit(currentState.copyWith(
        slots: generatedLegacySlots,
        timeSlots: generatedModernSlots,
        isLoading: false,
      ));
    } catch (_) {
      emit(currentState.copyWith(isLoading: false));
    }
  }

  void _onChangeExecutionMode(ChangeExecutionModeEvent event, Emitter<SlotState> emit) {
    if (state is! SlotDataState) return;
    emit((state as SlotDataState).copyWith(isSingleDay: event.isSingleDay));
  }

  void _onUpdateTargetDate(UpdateTargetDateEvent event, Emitter<SlotState> emit) {
    if (state is! SlotDataState) return;
    emit((state as SlotDataState).copyWith(targetDate: event.selectedDate));
  }

  void _onUpdateDateRange(UpdateDateRangeEvent event, Emitter<SlotState> emit) {
    if (state is! SlotDataState) return;
    emit((state as SlotDataState).copyWith(startDate: event.startDate, endDate: event.endDate));
  }

  void _onChangeDuration(ChangeDurationEvent event, Emitter<SlotState> emit) {
    if (state is! SlotDataState) return;
    emit((state as SlotDataState).copyWith(durationMinutes: event.duration));
  }

  void _onChangeBuffer(ChangeBufferEvent event, Emitter<SlotState> emit) {
    if (state is! SlotDataState) return;
    emit((state as SlotDataState).copyWith(bufferType: event.buffer));
  }

  void _onAddCustomSlot(AddCustomSlotEvent event, Emitter<SlotState> emit) {
    if (state is! SlotDataState) return;
    final currentState = state as SlotDataState;

    final updatedLegacy = List<SlotEntity>.from(currentState.slots);
    final updatedModern = List<TimeSlot>.from(currentState.timeSlots);
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    updatedLegacy.add(SlotEntity(id: newId, startTime: '12:00 PM', endTime: '12:30 PM', label: 'Available'));
    updatedModern.add(TimeSlot(id: newId, time: '12:00 PM', duration: '30m', status: SlotStatus.available));

    emit(currentState.copyWith(slots: updatedLegacy, timeSlots: updatedModern));
  }

  void _onRemoveSlot(RemoveSlotEvent event, Emitter<SlotState> emit) {
    if (state is! SlotDataState) return;
    final currentState = state as SlotDataState;

    emit(currentState.copyWith(
      slots: currentState.slots.where((slot) => slot.id != event.slotId).toList(),
      timeSlots: currentState.timeSlots.where((slot) => slot.id != event.slotId).toList(),
    ));
  }

  void _onUpdateSlotDetails(UpdateSlotDetailsEvent event, Emitter<SlotState> emit) {
    if (state is! SlotDataState) return;
    final currentState = state as SlotDataState;

    final updatedLegacy = currentState.slots.map((slot) {
      if (slot.id == event.slotId) {
        return slot.copyWith(
          startTime: event.startTime,
          endTime: event.endTime,
          label: event.label,
        );
      }
      return slot;
    }).toList();

    final updatedModern = currentState.timeSlots.map((slot) {
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

    emit(currentState.copyWith(slots: updatedLegacy, timeSlots: updatedModern));
  }

  void _onBlockSlot(BlockSlotEvent event, Emitter<SlotState> emit) {
    if (state is! SlotDataState) return;
    final currentState = state as SlotDataState;

    final updatedLegacy = currentState.slots.map((slot) {
      if (slot.id == event.slotId) {
        return slot.copyWith(label: 'Blocked', appointment: () => null);
      }
      return slot;
    }).toList();

    final updatedModern = currentState.timeSlots.map((slot) {
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

    emit(currentState.copyWith(slots: updatedLegacy, timeSlots: updatedModern));
  }

  void _onBookAppointment(BookAppointmentEvent event, Emitter<SlotState> emit) {
    if (state is! SlotDataState) return;
    final currentState = state as SlotDataState;

    final updatedLegacy = currentState.slots.map((slot) {
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

    final updatedModern = currentState.timeSlots.map((slot) {
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

    emit(currentState.copyWith(slots: updatedLegacy, timeSlots: updatedModern));
  }

  void _onCancelAppointment(CancelAppointmentEvent event, Emitter<SlotState> emit) {
    if (state is! SlotDataState) return;
    final currentState = state as SlotDataState;

    final updatedLegacy = currentState.slots.map((slot) {
      if (slot.id == event.slotId) {
        return slot.copyWith(label: 'Available', appointment: () => null);
      }
      return slot;
    }).toList();

    final updatedModern = currentState.timeSlots.map((slot) {
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

    emit(currentState.copyWith(slots: updatedLegacy, timeSlots: updatedModern));
  }

  void _onDeploySchedule(DeployScheduleEvent event, Emitter<SlotState> emit) async {
    if (state is! SlotDataState) return;
    final currentState = state as SlotDataState;

    emit(currentState.copyWith(isDeploying: true));

    final outcomeLegacy = await schedulerRepository.deploySchedule(currentState.slots);
    final outcomeModern = await schedulerRepository.deployTimeSchedule(currentState.timeSlots);

    emit(currentState.copyWith(
      isDeploying: false,
      deploySuccess: outcomeLegacy && outcomeModern,
    ));
  }

  void _onChangeFilterTabUi(ChangeFilterTabUiEvent event, Emitter<SlotState> emit) {
    if (state is! SlotDataState) return;
    emit((state as SlotDataState).copyWith(selectedTabIndex: event.tabIndex));
  }

  void _onSlotGenNav(SlotGenNavEvent event, Emitter<SlotState> emit) {
    emit(const SlotGenNavState());
  }
  void _onSlotTapNav(OnTapSlotCardEvent event, Emitter<SlotState> emit) {
    emit(const OnTapSlotCardState());
  }
}