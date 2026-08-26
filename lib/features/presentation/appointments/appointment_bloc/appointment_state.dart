part of 'appointment_bloc.dart';

@immutable
abstract class AppointmentState {
  // Form / Slot Properties
  final DateTime? selectedDob;
  final List<String> availableSlots;
  final String? selectedSlot;

  // Dashboard Properties
  final List<Appointment> appointments;
  final int todayCount;
  final int confirmedCount;
  final int pendingCount;
  final int completedCount;
  final int aiOptimizationScore;

  const AppointmentState({
    this.selectedDob,
    this.availableSlots = const [],
    this.selectedSlot,
    this.appointments = const [],
    this.todayCount = 0,
    this.confirmedCount = 0,
    this.pendingCount = 0,
    this.completedCount = 0,
    this.aiOptimizationScore = 0,
  });

  /// Base copyWith that returns an updated state while maintaining existing properties
  AppointmentState copyWith({
    DateTime? selectedDob,
    List<String>? availableSlots,
    String? Function()? selectedSlot,
    List<Appointment>? appointments,
    int? todayCount,
    int? confirmedCount,
    int? pendingCount,
    int? completedCount,
    int? aiOptimizationScore,
  });
}

// 1. Initial State
final class AppointmentInitial extends AppointmentState {
  const AppointmentInitial() : super();

  @override
  AppointmentState copyWith({
    DateTime? selectedDob,
    List<String>? availableSlots,
    String? Function()? selectedSlot,
    List<Appointment>? appointments,
    int? todayCount,
    int? confirmedCount,
    int? pendingCount,
    int? completedCount,
    int? aiOptimizationScore,
  }) {
    return AppointmentLoaded(
      selectedDob: selectedDob ?? this.selectedDob,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedSlot: selectedSlot != null ? selectedSlot() : this.selectedSlot,
      appointments: appointments ?? this.appointments,
      todayCount: todayCount ?? this.todayCount,
      confirmedCount: confirmedCount ?? this.confirmedCount,
      pendingCount: pendingCount ?? this.pendingCount,
      completedCount: completedCount ?? this.completedCount,
      aiOptimizationScore: aiOptimizationScore ?? this.aiOptimizationScore,
    );
  }
}

// 2. Loading State
final class AppointmentLoading extends AppointmentState {
  const AppointmentLoading({
    super.selectedDob,
    super.availableSlots,
    super.selectedSlot,
    super.appointments,
    super.todayCount,
    super.confirmedCount,
    super.pendingCount,
    super.completedCount,
    super.aiOptimizationScore,
  });

  @override
  AppointmentState copyWith({
    DateTime? selectedDob,
    List<String>? availableSlots,
    String? Function()? selectedSlot,
    List<Appointment>? appointments,
    int? todayCount,
    int? confirmedCount,
    int? pendingCount,
    int? completedCount,
    int? aiOptimizationScore,
  }) {
    return AppointmentLoading(
      selectedDob: selectedDob ?? this.selectedDob,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedSlot: selectedSlot != null ? selectedSlot() : this.selectedSlot,
      appointments: appointments ?? this.appointments,
      todayCount: todayCount ?? this.todayCount,
      confirmedCount: confirmedCount ?? this.confirmedCount,
      pendingCount: pendingCount ?? this.pendingCount,
      completedCount: completedCount ?? this.completedCount,
      aiOptimizationScore: aiOptimizationScore ?? this.aiOptimizationScore,
    );
  }
}

// 3. Loaded State (Your UI depends on this check!)
final class AppointmentLoaded extends AppointmentState {
  const AppointmentLoaded({
    super.selectedDob,
    super.availableSlots,
    super.selectedSlot,
    super.appointments,
    super.todayCount,
    super.confirmedCount,
    super.pendingCount,
    super.completedCount,
    super.aiOptimizationScore,
  });

  @override
  AppointmentState copyWith({
    DateTime? selectedDob,
    List<String>? availableSlots,
    String? Function()? selectedSlot,
    List<Appointment>? appointments,
    int? todayCount,
    int? confirmedCount,
    int? pendingCount,
    int? completedCount,
    int? aiOptimizationScore,
  }) {
    return AppointmentLoaded(
      selectedDob: selectedDob ?? this.selectedDob,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedSlot: selectedSlot != null ? selectedSlot() : this.selectedSlot,
      appointments: appointments ?? this.appointments,
      todayCount: todayCount ?? this.todayCount,
      confirmedCount: confirmedCount ?? this.confirmedCount,
      pendingCount: pendingCount ?? this.pendingCount,
      completedCount: completedCount ?? this.completedCount,
      aiOptimizationScore: aiOptimizationScore ?? this.aiOptimizationScore,
    );
  }
}

// 4. Error State
final class AppointmentError extends AppointmentState {
  final String message;
  const AppointmentError(
    this.message, {
    super.selectedDob,
    super.availableSlots,
    super.selectedSlot,
  });

  @override
  AppointmentState copyWith({
    DateTime? selectedDob,
    List<String>? availableSlots,
    String? Function()? selectedSlot,
    List<Appointment>? appointments,
    int? todayCount,
    int? confirmedCount,
    int? pendingCount,
    int? completedCount,
    int? aiOptimizationScore,
  }) => this;
}

class OnAddAppointmentState extends AppointmentState {
  @override
  AppointmentState copyWith({
    DateTime? selectedDob,
    List<String>? availableSlots,
    String? Function()? selectedSlot,
    List<Appointment>? appointments,
    int? todayCount,
    int? confirmedCount,
    int? pendingCount,
    int? completedCount,
    int? aiOptimizationScore,
  }) => this;
}

class BookAppointmentLoadingState extends AppointmentState {
  const BookAppointmentLoadingState();

  @override
  AppointmentState copyWith({
    DateTime? selectedDob,
    List<String>? availableSlots,
    String? Function()? selectedSlot,
    List<Appointment>? appointments,
    int? todayCount,
    int? confirmedCount,
    int? pendingCount,
    int? completedCount,
    int? aiOptimizationScore,
  }) => this;
}

class BookAppointmentSuccessState extends AppointmentState {
  final String message;
  final String? patientName;
  final String? appointmentDate;
  final String? time;
  final bool isTeleConsultation;

  const BookAppointmentSuccessState({
    this.message = "Appointment booked successfully!",
    this.patientName,
    this.appointmentDate,
    this.time,
    this.isTeleConsultation = false,
  });

  @override
  AppointmentState copyWith({
    DateTime? selectedDob,
    List<String>? availableSlots,
    String? Function()? selectedSlot,
    List<Appointment>? appointments,
    int? todayCount,
    int? confirmedCount,
    int? pendingCount,
    int? completedCount,
    int? aiOptimizationScore,
  }) => this;
}
