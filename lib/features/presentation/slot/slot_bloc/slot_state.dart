/*
part of 'slot_bloc.dart';

@immutable
class SlotState {
  final bool isSingleDay;
  final DateTime targetDate;
  final DateTime startDate;
  final DateTime endDate;
  final int durationMinutes;
  final String bufferType;
  final bool isLoading;
  final bool isDeploying;
  final bool deploySuccess;

  final List<SlotEntity> slots;
  final List<TimeSlot> timeSlots;
  final int selectedTabIndex;

  const SlotState({
    required this.isSingleDay,
    required this.targetDate,
    required this.startDate,
    required this.endDate,
    required this.durationMinutes,
    required this.bufferType,
    required this.slots,
    required this.timeSlots,
    this.isLoading = false,
    this.isDeploying = false,
    this.deploySuccess = false,
    this.selectedTabIndex = 0,
  });

  factory SlotState.initial() {
    final now = DateTime.now();
    return SlotState(
      isSingleDay: true,
      targetDate: now,
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      durationMinutes: 20,
      bufferType: '5 Minutes',
      slots: const [],
      timeSlots: const [],
      selectedTabIndex: 0,
    );
  }

  bool isSlotBlocked(String slotId) {
    try {
      final slot = slots.firstWhere((s) => s.id == slotId);
      return slot.label == 'Blocked';
    } catch (_) {
      return false;
    }
  }

  bool isTimeSlotBlocked(String slotId) {
    try {
      final slot = timeSlots.firstWhere((s) => s.id == slotId);
      return slot.duration == 'Blocked';
    } catch (_) {
      return false;
    }
  }

  List<TimeSlot> get filteredSlots {
    switch (selectedTabIndex) {
      case 1:
        return timeSlots.where((s) => s.status == SlotStatus.booked).toList();
      case 2:
        return timeSlots
            .where((s) => s.status == SlotStatus.available)
            .toList();
      case 0:
      default:
        return timeSlots;
    }
  }

  SlotState copyWith({
    bool? isSingleDay,
    DateTime? targetDate,
    DateTime? startDate,
    DateTime? endDate,
    int? durationMinutes,
    String? bufferType,
    List<SlotEntity>? slots,
    List<TimeSlot>? timeSlots,
    bool? isLoading,
    bool? isDeploying,
    bool? deploySuccess,
    int? selectedTabIndex,
  }) {
    return SlotState(
      isSingleDay: isSingleDay ?? this.isSingleDay,
      targetDate: targetDate ?? this.targetDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      bufferType: bufferType ?? this.bufferType,
      isLoading: isLoading ?? this.isLoading,
      isDeploying: isDeploying ?? this.isDeploying,
      deploySuccess: deploySuccess ?? this.deploySuccess,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      slots: slots ?? List<SlotEntity>.from(this.slots),
      timeSlots: timeSlots ?? List<TimeSlot>.from(this.timeSlots),
    );
  }
}

class SlotGenNavState extends SlotState {
  SlotGenNavState({
    super.isSingleDay = true,
    DateTime? targetDate,
    DateTime? startDate,
    DateTime? endDate,
    super.durationMinutes = 0,
    super.bufferType = '',
    super.slots = const [],
    super.timeSlots = const [],
  }) : super(
    targetDate: targetDate ?? DateTime.now(),
    startDate: startDate ?? DateTime.now(),
    endDate: endDate ?? DateTime.now(),
  );
}



*/
part of 'slot_bloc.dart';

@immutable
abstract class SlotState {
  const SlotState();
}

class SlotGenNavState extends SlotState {
  const SlotGenNavState();
}
class OnTapSlotCardState extends SlotState {
  const OnTapSlotCardState();
}

class SlotDataState extends SlotState {
  final bool isSingleDay;
  final DateTime targetDate;
  final DateTime startDate;
  final DateTime endDate;
  final int durationMinutes;
  final String bufferType;
  final String fromTime;
  final String toTime;
  final bool isLoading;
  final bool isDeploying;
  final bool deploySuccess;

  final List<SlotEntity> slots;
  final List<TimeSlot> timeSlots;
  final int selectedTabIndex;

  const SlotDataState({
    required this.isSingleDay,
    required this.targetDate,
    required this.startDate,
    required this.endDate,
    required this.durationMinutes,
    required this.bufferType,
    this.fromTime = '09:00 AM',
    this.toTime = '05:00 PM',
    required this.slots,
    required this.timeSlots,
    this.isLoading = false,
    this.isDeploying = false,
    this.deploySuccess = false,
    this.selectedTabIndex = 0,
  });

  factory SlotDataState.initial() {
    final now = DateTime.now();
    return SlotDataState(
      isSingleDay: true,
      targetDate: now,
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      durationMinutes: 20,
      bufferType: '5 Minutes',
      fromTime: '09:00 AM',
      toTime: '05:00 PM',
      slots: const [],
      timeSlots: const [],
      selectedTabIndex: 0,
    );
  }

  bool isSlotBlocked(String slotId) {
    try {
      final slot = slots.firstWhere((s) => s.id == slotId);
      return slot.label == 'Blocked';
    } catch (_) {
      return false;
    }
  }

  bool isTimeSlotBlocked(String slotId) {
    try {
      final slot = timeSlots.firstWhere((s) => s.id == slotId);
      return slot.status == SlotStatus.blocked || slot.duration == 'Blocked';
    } catch (_) {
      return false;
    }
  }

  List<TimeSlot> get filteredSlots {
    switch (selectedTabIndex) {
      case 1:
        return timeSlots.where((s) => s.status == SlotStatus.booked).toList();
      case 2:
        return timeSlots
            .where((s) => s.status == SlotStatus.available)
            .toList();
      case 3:
        return timeSlots
            .where((s) => s.status == SlotStatus.blocked)
            .toList();
      case 0:
      default:
        return timeSlots;
    }
  }

  SlotDataState copyWith({
    bool? isSingleDay,
    DateTime? targetDate,
    DateTime? startDate,
    DateTime? endDate,
    int? durationMinutes,
    String? bufferType,
    String? fromTime,
    String? toTime,
    List<SlotEntity>? slots,
    List<TimeSlot>? timeSlots,
    bool? isLoading,
    bool? isDeploying,
    bool? deploySuccess,
    int? selectedTabIndex,
  }) {
    return SlotDataState(
      isSingleDay: isSingleDay ?? this.isSingleDay,
      targetDate: targetDate ?? this.targetDate,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      bufferType: bufferType ?? this.bufferType,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
      isLoading: isLoading ?? this.isLoading,
      isDeploying: isDeploying ?? this.isDeploying,
      deploySuccess: deploySuccess ?? this.deploySuccess,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      slots: slots ?? List<SlotEntity>.from(this.slots),
      timeSlots: timeSlots ?? List<TimeSlot>.from(this.timeSlots),
    );
  }
}