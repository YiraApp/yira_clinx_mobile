import '../../../domain/entities/slot/slot_appointment_entity.dart';
import '../../../domain/entities/slot/time_slot_entity.dart';
import '../../../domain/repositories/slot/scheduler_repo.dart';
import '../../models/slot/slot_appointment_model.dart';

class SchedulerRepositoryImpl implements SchedulerRepository {

  @override
  Future<List<SlotEntity>> generateSlots({
    required bool isSingleDay,
    required String targetDate,
    required int durationMinutes,
    required String bufferType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      SlotModel(id: '1', startTime: '12:30 PM', endTime: '01:00 PM', label: 'Available'),
      SlotModel(id: '2', startTime: '01:00 PM', endTime: '01:30 PM', label: 'Available'),
      SlotModel(id: '3', startTime: '01:30 PM', endTime: '02:00 PM', label: 'Available'),
      SlotModel(id: '4', startTime: '02:00 PM', endTime: '02:30 PM', label: 'Available'),
    ];
  }

  @override
  Future<bool> deploySchedule(List<SlotEntity> slots) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<List<TimeSlot>> generateTimeSlots({
    required bool isSingleDay,
    required String targetDate,
    required int durationMinutes,
    required String bufferType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return [
      const TimeSlot(id: "sch_1", time: "9:00 AM", duration: "30 minutes", status: SlotStatus.available),
      const TimeSlot(id: "sch_2", time: "9:30 AM", duration: "30 minutes", status: SlotStatus.available),
      const TimeSlot(id: "sch_3", time: "11:00 AM", duration: "Consult", status: SlotStatus.booked, patientName: "Jhon Doe", type: AppointmentType.regularCheckUp, isVerified: true),
      const TimeSlot(id: "sch_5", time: "11:30 AM", duration: "Review", status: SlotStatus.booked, patientName: "Demo Manikanta", type: AppointmentType.followUp),
      const TimeSlot(id: "sch_4", time: "11:30 AM", duration: "30 minutes", status: SlotStatus.available),
      const TimeSlot(id: "sch_10", time: "4:30 PM", duration: "Consult", status: SlotStatus.booked, patientName: "Sarah Smith", type: AppointmentType.regularCheckUp),
      const TimeSlot(id: "sch_6", time: "12:00 PM", duration: "30 minutes", status: SlotStatus.available),
      const TimeSlot(id: "sch_8", time: "2:00 PM", duration: "Consult", status: SlotStatus.booked, patientName: "Ananya Rao", type: AppointmentType.regularCheckUp),
      const TimeSlot(id: "sch_9", time: "3:30 PM", duration: "Review", status: SlotStatus.booked, patientName: "Vikram Malhotra", type: AppointmentType.followUp, isVerified: true),
      const TimeSlot(id: "sch_7", time: "1:30 PM", duration: "30 minutes", status: SlotStatus.available)
    ];
  }

  @override
  Future<bool> deployTimeSchedule(List<TimeSlot> slots) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}