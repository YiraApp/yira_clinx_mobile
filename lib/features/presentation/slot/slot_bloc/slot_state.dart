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

  // =========================================================================
  // DUAL DATA ENTITY ECOSYSTEM CORES
  // =========================================================================
  final List<SlotEntity> slots;       // Legacy tracker pipeline collection
  final List<TimeSlot> timeSlots;     // Modern dash template layout tracking array
  final int selectedTabIndex;         // 0 = All, 1 = Booked, 2 = Available

  const SlotState({
    required this.isSingleDay,
    required this.targetDate,
    required this.startDate,
    required this.endDate,
    required this.durationMinutes,
    required this.bufferType,
    required this.slots,
    required this.timeSlots,          // Added for the new framework model integration
    this.isLoading = false,
    this.isDeploying = false,
    this.deploySuccess = false,
    this.selectedTabIndex = 0,         // Managed for filter perspective matrices
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

  // =========================================================================
  // LEGACY HELPERS & DATA PIPELINES (SlotEntity)
  // =========================================================================
  /// Determines if a legacy [SlotEntity] item is explicitly flagged as blocked.
  bool isSlotBlocked(String slotId) {
    try {
      final slot = slots.firstWhere((s) => s.id == slotId);
      return slot.label == 'Blocked';
    } catch (_) {
      return false;
    }
  }

  // =========================================================================
  // MODERN HELPERS & DATA PIPELINES (TimeSlot)
  // =========================================================================
  /// Determines if a clean architecture [TimeSlot] instance is explicitly blocked.
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
      case 1: // Booked
        return timeSlots.where((s) => s.status == SlotStatus.booked).toList();
      case 2: // Available
        return timeSlots.where((s) => s.status == SlotStatus.available).toList();
      case 0:
      default: // All
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

      // Breaking raw memory pointers array references ensures reliable widget redraws
      slots: slots ?? List<SlotEntity>.from(this.slots),
      timeSlots: timeSlots ?? List<TimeSlot>.from(this.timeSlots),
    );
  }
}
