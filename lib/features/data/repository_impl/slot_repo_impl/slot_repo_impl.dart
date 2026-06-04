
import '../../../domain/entities/slot/slot_appointment_entity.dart';
import '../../../domain/entities/slot/time_slot_entity.dart';
import '../../../domain/repositories/slot/slot_repo.dart';
import '../../models/slot/time_slot_model.dart';

class SlotRepositoryImpl implements SlotRepository {
  const SlotRepositoryImpl();

  @override
  Future<List<TimeSlot>> getTimeSlots({required DateTime date}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    return [
      const TimeSlotModel(id: "1", time: "9:00 AM", duration: "30m", status: SlotStatus.available),
      const TimeSlotModel(id: "2", time: "9:30 AM", duration: "30m", status: SlotStatus.available),
      const TimeSlotModel(id: "4", time: "11:30 AM", duration: "30m", status: SlotStatus.available),
      const TimeSlotModel(id: "6", time: "12:00 PM", duration: "30m", status: SlotStatus.available),
      const TimeSlotModel(id: "7", time: "1:30 PM", duration: "30m", status: SlotStatus.available),
      const TimeSlotModel(id: "3", time: "11:00 AM", duration: "Consult", status: SlotStatus.booked, patientName: "Jhon Doe", type: AppointmentType.regularCheckUp, isVerified: true),
      const TimeSlotModel(id: "5", time: "11:30 AM", duration: "Review", status: SlotStatus.booked, patientName: "Demo Manikanta", type: AppointmentType.followUp),
      const TimeSlotModel(id: "8", time: "2:00 PM", duration: "Consult", status: SlotStatus.booked, patientName: "Ananya Rao", type: AppointmentType.regularCheckUp),
      const TimeSlotModel(id: "9", time: "3:30 PM", duration: "Review", status: SlotStatus.booked, patientName: "Vikram Malhotra", type: AppointmentType.followUp, isVerified: true),
      const TimeSlotModel(id: "10", time: "4:30 PM", duration: "Consult", status: SlotStatus.booked, patientName: "Sarah Smith", type: AppointmentType.regularCheckUp),
    ];
  }
}