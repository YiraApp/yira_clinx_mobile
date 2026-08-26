import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

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
    on<UpdateTimeRangeEvent>(_onUpdateTimeRange);
    on<AddBreakTimeEvent>(_onAddBreakTime);
    on<UpdateBreakTimeEvent>(_onUpdateBreakTime);
    on<RemoveBreakTimeEvent>(_onRemoveBreakTime);
    on<GenerateTemplateSlotsEvent>(_onGenerateTemplateSlots);
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

  int _bufferStringToMinutes(String bufferType) {
    if (bufferType.toLowerCase().contains('continuous')) {
      return 0;
    }
    final match = RegExp(r'\d+').firstMatch(bufferType);
    if (match != null) {
      return int.tryParse(match.group(0)!) ?? 0;
    }
    return 0;
  }

  int _timeStringToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 0;
    try {
      final cleaned = timeStr.replaceAll(RegExp(r'[\s\u00A0\u2000-\u200B\u202F]+'), ' ').trim();
      
      final match = RegExp(r'^(\d{1,2}):(\d{2})\s*([a-zA-Z]{2})?', caseSensitive: false).firstMatch(cleaned);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        String? ampm = match.group(3)?.toUpperCase();

        if (ampm == 'PM' && hour < 12) {
          hour += 12;
        } else if (ampm == 'AM' && hour == 12) {
          hour = 0;
        }
        return hour * 60 + minute;
      }

      DateTime dt;
      if (cleaned.toUpperCase().contains('AM') || cleaned.toUpperCase().contains('PM')) {
        try {
          dt = DateFormat('h:mm a').parse(cleaned);
        } catch (_) {
          dt = DateFormat('hh:mm a').parse(cleaned);
        }
      } else {
        dt = DateFormat('HH:mm').parse(cleaned);
      }
      return dt.hour * 60 + dt.minute;
    } catch (_) {
      return 0;
    }
  }

  String _minutesToTimeString(int totalMinutes) {
    int h = (totalMinutes ~/ 60) % 24;
    int m = totalMinutes % 60;
    final dt = DateTime(2000, 1, 1, h, m);
    return DateFormat('hh:mm a').format(dt);
  }

  bool _isOverlapping(int start1, int end1, int start2, int end2) {
    return start1 < end2 && end1 > start2;
  }

  List<SlotEntity> _generateScheduleSlots({
    required int durationMinutes,
    required String bufferType,
    String fromTime = '09:00 AM',
    String toTime = '05:00 PM',
    List<BreakTimeEntity> breakTimes = const [],
    List<SlotEntity>? existingSlots,
    DateTime? targetDate,
    bool isSingleDay = true,
  }) {
    final int bufferMinutes = _bufferStringToMinutes(bufferType);
    final int effectiveDuration = durationMinutes > 0 ? durationMinutes : 20;

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    // If targetDate is in the past, no slots can be generated
    if (targetDate != null && isSingleDay && DateTime(targetDate.year, targetDate.month, targetDate.day).isBefore(todayMidnight)) {
      return [];
    }

    final bool isToday = isSingleDay &&
        targetDate != null &&
        targetDate.year == now.year &&
        targetDate.month == now.month &&
        targetDate.day == now.day;

    final int nowMinutes = now.hour * 60 + now.minute;

    final int dayStart = _timeStringToMinutes(fromTime);
    final int dayEnd = _timeStringToMinutes(toTime);

    // Preserve existing booked slots only if they don't overlap with any break and fall within shift hours
    final bookedSlots = (existingSlots ?? []).where((s) {
      if (!s.hasAppointment && s.label != 'Booked') return false;
      final sStart = _timeStringToMinutes(s.startTime);
      final sEnd = _timeStringToMinutes(s.endTime);
      if (sStart < dayStart || sEnd > dayEnd) return false;

      for (final b in breakTimes) {
        final bStart = _timeStringToMinutes(b.fromTime);
        final bEnd = _timeStringToMinutes(b.toTime);
        if (_isOverlapping(sStart, sEnd, bStart, bEnd)) {
          return false;
        }
      }
      return true;
    }).toList();

    if (dayStart >= dayEnd) {
      return bookedSlots;
    }

    final List<SlotEntity> generated = [];
    int current = dayStart;
    int iterations = 0;

    while (current + effectiveDuration <= dayEnd && iterations < 500) {
      iterations++;
      final int slotStart = current;
      final int slotEnd = current + effectiveDuration;

      // Filter out past time slots if scheduling for today
      if (isToday && slotStart < nowMinutes) {
        current = slotEnd + bufferMinutes;
        continue;
      }

      // 1. Check if this candidate slot overlaps with ANY break interval
      BreakTimeEntity? overlappingBreak;
      for (final b in breakTimes) {
        final bStart = _timeStringToMinutes(b.fromTime);
        final bEnd = _timeStringToMinutes(b.toTime);
        if (bStart < bEnd && _isOverlapping(slotStart, slotEnd, bStart, bEnd)) {
          overlappingBreak = b;
          break;
        }
      }

      if (overlappingBreak != null) {
        final bEnd = _timeStringToMinutes(overlappingBreak.toTime);
        if (bEnd > current) {
          current = bEnd;
        } else {
          current = slotEnd;
        }
        continue;
      }

      // 2. Check if this candidate slot overlaps with any existing booked slot
      final overlappingBooked = bookedSlots.where((b) {
        final bStart = _timeStringToMinutes(b.startTime);
        final bEnd = _timeStringToMinutes(b.endTime);
        return _isOverlapping(slotStart, slotEnd, bStart, bEnd);
      }).toList();

      if (overlappingBooked.isEmpty) {
        final newId = "slot_${slotStart}_${slotEnd}_${DateTime.now().millisecondsSinceEpoch}_$iterations";
        final startStr = _minutesToTimeString(slotStart);
        final endStr = _minutesToTimeString(slotEnd);

        generated.add(SlotEntity(
          id: newId,
          startTime: startStr,
          endTime: endStr,
          label: 'Available',
        ));
        current = slotEnd + bufferMinutes;
      } else {
        final bEnd = _timeStringToMinutes(overlappingBooked.first.endTime);
        if (bEnd > current) {
          current = bEnd + bufferMinutes;
        } else {
          current = slotEnd + bufferMinutes;
        }
      }
    }

    // Combine with booked slots and sort chronologically
    final allSlots = [...generated, ...bookedSlots];
    allSlots.sort((a, b) => _timeStringToMinutes(a.startTime).compareTo(_timeStringToMinutes(b.startTime)));
    return allSlots;
  }

  List<TimeSlot> _mapSlotsToTimeSlots(List<SlotEntity> slots, int durationMinutes) {
    return slots.map((s) {
      final isBooked = s.hasAppointment || s.label == 'Booked';
      final isBlocked = s.label == 'Blocked';
      SlotStatus status = SlotStatus.available;
      if (isBooked) {
        status = SlotStatus.booked;
      } else if (isBlocked) {
        status = SlotStatus.blocked;
      }

      return TimeSlot(
        id: s.id,
        time: s.startTime,
        duration: isBlocked ? 'Blocked' : '${durationMinutes}m',
        status: status,
        patientName: s.appointment?.patientName,
        type: isBooked ? AppointmentType.regularCheckUp : null,
        appointmentId: s.appointment?.id,
        reason: s.appointment?.reason,
      );
    }).toList();
  }

  void _onInitializeSlots(InitializeSlotsEvent event, Emitter<SlotState> emit) async {
    final SlotDataState currentState = state is SlotDataState
        ? state as SlotDataState
        : SlotDataState.initial();

    emit(currentState.copyWith(isLoading: true, deploySuccess: false));

    final dateString = currentState.isSingleDay
        ? DateFormat('yyyy-MM-dd').format(currentState.targetDate)
        : "${DateFormat('yyyy-MM-dd').format(currentState.startDate)} - ${DateFormat('yyyy-MM-dd').format(currentState.endDate)}";

    try {
      final fetchedLegacySlots = await schedulerRepository.generateSlots(
        isSingleDay: currentState.isSingleDay,
        targetDate: dateString,
        durationMinutes: currentState.durationMinutes,
        bufferType: currentState.bufferType,
      );

      final fetchedModernSlots = await schedulerRepository.generateTimeSlots(
        isSingleDay: currentState.isSingleDay,
        targetDate: dateString,
        durationMinutes: currentState.durationMinutes,
        bufferType: currentState.bufferType,
      );

      List<SlotEntity> slots = fetchedLegacySlots;
      List<TimeSlot> timeSlots = fetchedModernSlots;

      // Always calculate slots on frontend if API returns empty schedule
      if (slots.isEmpty) {
        slots = _generateScheduleSlots(
          durationMinutes: currentState.durationMinutes,
          bufferType: currentState.bufferType,
          fromTime: currentState.fromTime,
          toTime: currentState.toTime,
          breakTimes: currentState.breakTimes,
          targetDate: currentState.targetDate,
          isSingleDay: currentState.isSingleDay,
        );
        timeSlots = _mapSlotsToTimeSlots(slots, currentState.durationMinutes);
      }

      emit(currentState.copyWith(
        slots: slots,
        timeSlots: timeSlots,
        isLoading: false,
        deploySuccess: false,
      ));
    } catch (e) {
      debugPrint('SlotBloc: InitializeSlots fallback to frontend calculation: $e');
      final slots = _generateScheduleSlots(
        durationMinutes: currentState.durationMinutes,
        bufferType: currentState.bufferType,
        fromTime: currentState.fromTime,
        toTime: currentState.toTime,
        breakTimes: currentState.breakTimes,
        targetDate: currentState.targetDate,
        isSingleDay: currentState.isSingleDay,
      );
      final timeSlots = _mapSlotsToTimeSlots(slots, currentState.durationMinutes);
      emit(currentState.copyWith(
        slots: slots,
        timeSlots: timeSlots,
        isLoading: false,
        deploySuccess: false,
      ));
    }
  }

  void _onGenerateTemplateSlots(GenerateTemplateSlotsEvent event, Emitter<SlotState> emit) {
    final SlotDataState currentState = state is SlotDataState
        ? state as SlotDataState
        : SlotDataState.initial();

    final templateSlots = _generateScheduleSlots(
      durationMinutes: currentState.durationMinutes,
      bufferType: currentState.bufferType,
      fromTime: currentState.fromTime,
      toTime: currentState.toTime,
      breakTimes: currentState.breakTimes,
      existingSlots: currentState.slots,
      targetDate: currentState.targetDate,
      isSingleDay: currentState.isSingleDay,
    );
    final templateModernSlots = _mapSlotsToTimeSlots(templateSlots, currentState.durationMinutes);

    emit(currentState.copyWith(
      slots: templateSlots,
      timeSlots: templateModernSlots,
      isLoading: false,
      deploySuccess: false,
    ));
  }

  void _onUpdateTimeRange(UpdateTimeRangeEvent event, Emitter<SlotState> emit) {
    final SlotDataState currentState = state is SlotDataState
        ? state as SlotDataState
        : SlotDataState.initial();

    final newSlots = _generateScheduleSlots(
      durationMinutes: currentState.durationMinutes,
      bufferType: currentState.bufferType,
      fromTime: event.fromTime,
      toTime: event.toTime,
      breakTimes: currentState.breakTimes,
      existingSlots: currentState.slots,
      targetDate: currentState.targetDate,
      isSingleDay: currentState.isSingleDay,
    );
    final newTimeSlots = _mapSlotsToTimeSlots(newSlots, currentState.durationMinutes);

    emit(currentState.copyWith(
      fromTime: event.fromTime,
      toTime: event.toTime,
      slots: newSlots,
      timeSlots: newTimeSlots,
      isLoading: false,
    ));
  }

  void _onAddBreakTime(AddBreakTimeEvent event, Emitter<SlotState> emit) {
    final SlotDataState currentState = state is SlotDataState
        ? state as SlotDataState
        : SlotDataState.initial();

    final count = currentState.breakTimes.length + 1;
    final defaultLabel = 'Break $count';
    String defaultFrom = '01:00 PM';
    String defaultTo = '02:00 PM';

    if (currentState.breakTimes.isNotEmpty) {
      if (currentState.breakTimes.length == 1) {
        defaultFrom = '04:00 PM';
        defaultTo = '04:30 PM';
      } else if (currentState.breakTimes.length == 2) {
        defaultFrom = '06:00 PM';
        defaultTo = '06:30 PM';
      } else {
        defaultFrom = '07:00 PM';
        defaultTo = '07:30 PM';
      }
    }

    final newBreak = BreakTimeEntity(
      id: 'break_${DateTime.now().millisecondsSinceEpoch}',
      label: event.label ?? defaultLabel,
      fromTime: event.fromTime ?? defaultFrom,
      toTime: event.toTime ?? defaultTo,
    );

    final updatedBreaks = [...currentState.breakTimes, newBreak];

    debugPrint("SlotBloc: Adding break '${newBreak.label}' (${newBreak.fromTime} - ${newBreak.toTime}). Total breaks: ${updatedBreaks.length}");

    final newSlots = _generateScheduleSlots(
      durationMinutes: currentState.durationMinutes,
      bufferType: currentState.bufferType,
      fromTime: currentState.fromTime,
      toTime: currentState.toTime,
      breakTimes: updatedBreaks,
      existingSlots: currentState.slots,
      targetDate: currentState.targetDate,
      isSingleDay: currentState.isSingleDay,
    );
    final newTimeSlots = _mapSlotsToTimeSlots(newSlots, currentState.durationMinutes);

    debugPrint("SlotBloc: Slots reallocated around break. Total slots: ${newSlots.length}");

    emit(currentState.copyWith(
      breakTimes: updatedBreaks,
      slots: newSlots,
      timeSlots: newTimeSlots,
    ));
  }

  void _onUpdateBreakTime(UpdateBreakTimeEvent event, Emitter<SlotState> emit) {
    final SlotDataState currentState = state is SlotDataState
        ? state as SlotDataState
        : SlotDataState.initial();

    final updatedBreaks = currentState.breakTimes.map((b) {
      if (b.id == event.breakId) {
        return b.copyWith(
          label: event.label,
          fromTime: event.fromTime,
          toTime: event.toTime,
        );
      }
      return b;
    }).toList();

    debugPrint("SlotBloc: Updating break ${event.breakId} to (${event.fromTime} - ${event.toTime})");

    final newSlots = _generateScheduleSlots(
      durationMinutes: currentState.durationMinutes,
      bufferType: currentState.bufferType,
      fromTime: currentState.fromTime,
      toTime: currentState.toTime,
      breakTimes: updatedBreaks,
      existingSlots: currentState.slots,
      targetDate: currentState.targetDate,
      isSingleDay: currentState.isSingleDay,
    );
    final newTimeSlots = _mapSlotsToTimeSlots(newSlots, currentState.durationMinutes);

    debugPrint("SlotBloc: Slots reallocated on break update. Total slots: ${newSlots.length}");

    emit(currentState.copyWith(
      breakTimes: updatedBreaks,
      slots: newSlots,
      timeSlots: newTimeSlots,
    ));
  }

  void _onRemoveBreakTime(RemoveBreakTimeEvent event, Emitter<SlotState> emit) {
    final SlotDataState currentState = state is SlotDataState
        ? state as SlotDataState
        : SlotDataState.initial();

    final updatedBreaks = currentState.breakTimes.where((b) => b.id != event.breakId).toList();

    debugPrint("SlotBloc: Removed break ${event.breakId}. Remaining breaks: ${updatedBreaks.length}");

    final newSlots = _generateScheduleSlots(
      durationMinutes: currentState.durationMinutes,
      bufferType: currentState.bufferType,
      fromTime: currentState.fromTime,
      toTime: currentState.toTime,
      breakTimes: updatedBreaks,
      existingSlots: currentState.slots,
      targetDate: currentState.targetDate,
      isSingleDay: currentState.isSingleDay,
    );
    final newTimeSlots = _mapSlotsToTimeSlots(newSlots, currentState.durationMinutes);

    debugPrint("SlotBloc: Slots reallocated on break removal. Total slots: ${newSlots.length}");

    emit(currentState.copyWith(
      breakTimes: updatedBreaks,
      slots: newSlots,
      timeSlots: newTimeSlots,
    ));
  }

  void _onChangeExecutionMode(ChangeExecutionModeEvent event, Emitter<SlotState> emit) {
    final SlotDataState currentState = state is SlotDataState
        ? state as SlotDataState
        : SlotDataState.initial();

    // Ensure template slots exist
    List<SlotEntity> slots = currentState.slots;
    if (slots.isEmpty) {
      slots = _generateScheduleSlots(
        durationMinutes: currentState.durationMinutes,
        bufferType: currentState.bufferType,
        fromTime: currentState.fromTime,
        toTime: currentState.toTime,
        breakTimes: currentState.breakTimes,
        targetDate: currentState.targetDate,
        isSingleDay: event.isSingleDay,
      );
    }
    final timeSlots = _mapSlotsToTimeSlots(slots, currentState.durationMinutes);

    emit(currentState.copyWith(
      isSingleDay: event.isSingleDay,
      slots: slots,
      timeSlots: timeSlots,
    ));
  }

  void _onUpdateTargetDate(UpdateTargetDateEvent event, Emitter<SlotState> emit) {
    final SlotDataState currentState = state is SlotDataState
        ? state as SlotDataState
        : SlotDataState.initial();

    final newSlots = _generateScheduleSlots(
      durationMinutes: currentState.durationMinutes,
      bufferType: currentState.bufferType,
      fromTime: currentState.fromTime,
      toTime: currentState.toTime,
      breakTimes: currentState.breakTimes,
      existingSlots: currentState.slots,
      targetDate: event.selectedDate,
      isSingleDay: currentState.isSingleDay,
    );
    final newTimeSlots = _mapSlotsToTimeSlots(newSlots, currentState.durationMinutes);

    emit(currentState.copyWith(
      targetDate: event.selectedDate,
      slots: newSlots,
      timeSlots: newTimeSlots,
    ));
  }

  void _onUpdateDateRange(UpdateDateRangeEvent event, Emitter<SlotState> emit) {
    final SlotDataState currentState = state is SlotDataState
        ? state as SlotDataState
        : SlotDataState.initial();

    List<SlotEntity> slots = currentState.slots;
    if (slots.isEmpty) {
      slots = _generateScheduleSlots(
        durationMinutes: currentState.durationMinutes,
        bufferType: currentState.bufferType,
        fromTime: currentState.fromTime,
        toTime: currentState.toTime,
        breakTimes: currentState.breakTimes,
        targetDate: event.startDate,
        isSingleDay: false,
      );
    }
    final timeSlots = _mapSlotsToTimeSlots(slots, currentState.durationMinutes);

    emit(currentState.copyWith(
      startDate: event.startDate,
      endDate: event.endDate,
      slots: slots,
      timeSlots: timeSlots,
    ));
  }

  void _onChangeDuration(ChangeDurationEvent event, Emitter<SlotState> emit) {
    final SlotDataState currentState = state is SlotDataState
        ? state as SlotDataState
        : SlotDataState.initial();

    final newSlots = _generateScheduleSlots(
      durationMinutes: event.duration,
      bufferType: currentState.bufferType,
      fromTime: currentState.fromTime,
      toTime: currentState.toTime,
      breakTimes: currentState.breakTimes,
      existingSlots: currentState.slots,
      targetDate: currentState.targetDate,
      isSingleDay: currentState.isSingleDay,
    );
    final newTimeSlots = _mapSlotsToTimeSlots(newSlots, event.duration);

    emit(currentState.copyWith(
      durationMinutes: event.duration,
      slots: newSlots,
      timeSlots: newTimeSlots,
      isLoading: false,
    ));
  }

  void _onChangeBuffer(ChangeBufferEvent event, Emitter<SlotState> emit) {
    final SlotDataState currentState = state is SlotDataState
        ? state as SlotDataState
        : SlotDataState.initial();

    final newSlots = _generateScheduleSlots(
      durationMinutes: currentState.durationMinutes,
      bufferType: event.buffer,
      fromTime: currentState.fromTime,
      toTime: currentState.toTime,
      breakTimes: currentState.breakTimes,
      existingSlots: currentState.slots,
      targetDate: currentState.targetDate,
      isSingleDay: currentState.isSingleDay,
    );
    final newTimeSlots = _mapSlotsToTimeSlots(newSlots, currentState.durationMinutes);

    emit(currentState.copyWith(
      bufferType: event.buffer,
      slots: newSlots,
      timeSlots: newTimeSlots,
      isLoading: false,
    ));
  }

  void _onAddCustomSlot(AddCustomSlotEvent event, Emitter<SlotState> emit) {
    final SlotDataState currentState = state is SlotDataState
        ? state as SlotDataState
        : SlotDataState.initial();

    String start = event.startTime ?? '05:00 PM';
    String end = event.endTime ?? '05:30 PM';
    String label = event.label ?? 'Available';

    if (event.startTime == null) {
      if (currentState.slots.isNotEmpty) {
        final lastSlot = currentState.slots.last;
        final lastEndMin = _timeStringToMinutes(lastSlot.endTime);
        final bufferMin = _bufferStringToMinutes(currentState.bufferType);
        final nextStartMin = lastEndMin + bufferMin;
        final nextEndMin = nextStartMin + currentState.durationMinutes;
        start = _minutesToTimeString(nextStartMin);
        end = _minutesToTimeString(nextEndMin);
      }
    }

    final newId = "custom_${DateTime.now().millisecondsSinceEpoch}";
    final updatedLegacy = List<SlotEntity>.from(currentState.slots);

    final newStartMin = _timeStringToMinutes(start);
    final newEndMin = _timeStringToMinutes(end);

    // Overlap check
    final hasOverlap = updatedLegacy.any((s) {
      final sMin = _timeStringToMinutes(s.startTime);
      final eMin = _timeStringToMinutes(s.endTime);
      return _isOverlapping(newStartMin, newEndMin, sMin, eMin);
    });

    if (!hasOverlap) {
      updatedLegacy.add(SlotEntity(
        id: newId,
        startTime: start,
        endTime: end,
        label: label,
      ));
      updatedLegacy.sort((a, b) => _timeStringToMinutes(a.startTime).compareTo(_timeStringToMinutes(b.startTime)));

      final updatedModern = _mapSlotsToTimeSlots(updatedLegacy, currentState.durationMinutes);
      emit(currentState.copyWith(
        slots: updatedLegacy,
        timeSlots: updatedModern,
        isLoading: false,
      ));
    }
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

    final targetSlot = currentState.slots.firstWhere((s) => s.id == event.slotId, orElse: () => currentState.slots.first);
    final String effectiveStart = event.startTime ?? targetSlot.startTime;
    final String effectiveEnd = event.endTime ?? targetSlot.endTime;

    final newStartMin = _timeStringToMinutes(effectiveStart);
    final newEndMin = _timeStringToMinutes(effectiveEnd);

    // Overlap check against other slots
    final hasOverlap = currentState.slots.any((s) {
      if (s.id == event.slotId) return false;
      final sMin = _timeStringToMinutes(s.startTime);
      final eMin = _timeStringToMinutes(s.endTime);
      return _isOverlapping(newStartMin, newEndMin, sMin, eMin);
    });

    if (hasOverlap) {
      return;
    }

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

    updatedLegacy.sort((a, b) => _timeStringToMinutes(a.startTime).compareTo(_timeStringToMinutes(b.startTime)));
    final updatedModern = _mapSlotsToTimeSlots(updatedLegacy, currentState.durationMinutes);

    emit(currentState.copyWith(slots: updatedLegacy, timeSlots: updatedModern));
  }

  void _onBlockSlot(BlockSlotEvent event, Emitter<SlotState> emit) async {
    if (state is! SlotDataState) return;
    final currentState = state as SlotDataState;

    emit(currentState.copyWith(isLoading: true));
    try {
      final success = await schedulerRepository.blockSlot(
        slotId: event.slotId,
        block: event.block,
      );
      if (success) {
        add(InitializeSlotsEvent());
      } else {
        emit(currentState.copyWith(isLoading: false));
      }
    } catch (e) {
      debugPrint("SlotBloc: _onBlockSlot Error: $e");
      emit(currentState.copyWith(isLoading: false));
    }
  }

  void _onBookAppointment(BookAppointmentEvent event, Emitter<SlotState> emit) async {
    if (state is! SlotDataState) return;
    final currentState = state as SlotDataState;

    emit(currentState.copyWith(isLoading: true));
    try {
      final targetDateStr = DateFormat('yyyy-MM-dd').format(currentState.targetDate);
      final startTime = event.startTime ?? currentState.timeSlots.firstWhere(
        (s) => s.id == event.slotId,
        orElse: () => const TimeSlot(id: '', time: '10:00 AM', duration: '', status: SlotStatus.available),
      ).time;

      final success = await schedulerRepository.bookSlotAppointment(
        slotId: event.slotId,
        patientName: event.patientName,
        patientPhone: event.contactNumber,
        appointmentDate: targetDateStr,
        startTime: startTime,
        reason: event.reason,
        appointmentType: event.appointmentType,
      );

      if (success) {
        add(InitializeSlotsEvent());
      } else {
        emit(currentState.copyWith(isLoading: false));
      }
    } catch (e) {
      debugPrint("SlotBloc: _onBookAppointment Error: $e");
      emit(currentState.copyWith(isLoading: false));
    }
  }

  void _onCancelAppointment(CancelAppointmentEvent event, Emitter<SlotState> emit) async {
    if (state is! SlotDataState) return;
    final currentState = state as SlotDataState;

    emit(currentState.copyWith(isLoading: true));
    try {
      String appointmentId = event.appointmentId ?? '';
      if (appointmentId.isEmpty) {
        try {
          final slot = currentState.slots.firstWhere((s) => s.id == event.slotId);
          appointmentId = slot.appointment?.id ?? '';
        } catch (_) {}
      }
      if (appointmentId.isEmpty) {
        try {
          final timeSlot = currentState.timeSlots.firstWhere((s) => s.id == event.slotId);
          appointmentId = timeSlot.appointmentId ?? '';
        } catch (_) {}
      }

      if (appointmentId.isNotEmpty) {
        final success = await schedulerRepository.cancelSlotAppointment(
          appointmentId: appointmentId,
          slotId: event.slotId,
        );
        if (success) {
          add(InitializeSlotsEvent());
          return;
        }
      }
      emit(currentState.copyWith(isLoading: false));
    } catch (e) {
      debugPrint("SlotBloc: _onCancelAppointment Error: $e");
      emit(currentState.copyWith(isLoading: false));
    }
  }

  void _onDeploySchedule(DeployScheduleEvent event, Emitter<SlotState> emit) async {
    final SlotDataState currentState = state is SlotDataState
        ? state as SlotDataState
        : SlotDataState.initial();

    emit(currentState.copyWith(isDeploying: true, deploySuccess: false));

    try {
      final breakTimesList = currentState.breakTimes
          .map((b) => {
                "fromTime": b.fromTime,
                "toTime": b.toTime,
                "label": b.label,
              })
          .toList();

      bool success = false;
      if (currentState.isSingleDay) {
        final dateStr = DateFormat('yyyy-MM-dd').format(currentState.targetDate);
        success = await schedulerRepository.deploySchedule(
          currentState.slots,
          targetDate: dateStr,
          isSingleDay: true,
          breakTimes: breakTimesList,
        );
      } else {
        DateTime current = currentState.startDate;
        bool allSuccess = true;
        while (!current.isAfter(currentState.endDate)) {
          final dateStr = DateFormat('yyyy-MM-dd').format(current);
          final res = await schedulerRepository.deploySchedule(
            currentState.slots,
            targetDate: dateStr,
            isSingleDay: false,
            breakTimes: breakTimesList,
          );
          if (!res) allSuccess = false;
          current = current.add(const Duration(days: 1));
        }
        success = allSuccess;
      }

      emit(currentState.copyWith(
        isDeploying: false,
        deploySuccess: success,
      ));
    } catch (e) {
      debugPrint("SlotBloc: _onDeploySchedule error: $e");
      emit(currentState.copyWith(isDeploying: false, deploySuccess: false));
    }
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