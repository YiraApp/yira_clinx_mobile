
import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../domain/entities/slot/slot_appointment_entity.dart';
import '../slot_bloc/slot_bloc.dart';
import '../../../../core/common_widgets/common_text.dart';

class AppointmentModalSheet extends StatelessWidget {
  final SlotEntity currentSlot;
  final SlotBloc slotBloc;

  const AppointmentModalSheet({
    super.key,
    required this.currentSlot,
    required this.slotBloc,
  });

  static void show(BuildContext context, SlotEntity slot, SlotBloc bloc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(fieldBorderRadius)),
      ),
      builder: (context) => AppointmentModalSheet(currentSlot: slot, slotBloc: bloc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isBlocked = currentSlot.label == 'Blocked';

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CommonText(
                currentSlot.hasAppointment ? 'Appointment Info' : 'Slot Details',
                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          CommonText(
            'Slot Time: ${currentSlot.startTime} - ${currentSlot.endTime}',
            style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (currentSlot.hasAppointment) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(fieldBorderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText('Patient Name', style: textTheme.labelSmall),
                  CommonText(
                    currentSlot.appointment!.patientName,
                    style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  CommonText('Contact Number', style: textTheme.labelSmall),
                  CommonText(currentSlot.appointment!.contactNumber, style: textTheme.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
                    ),
                    onPressed: () {
                      slotBloc.add(CancelAppointmentEvent(
                        slotId: currentSlot.id,
                        appointmentId: currentSlot.appointment?.id,
                      ));
                      Navigator.pop(context);
                    },
                    child: const CommonText('Cancel Appointment', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const CommonText('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isBlocked ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(fieldBorderRadius),
                border: Border.all(
                  color: isBlocked ? Colors.redAccent.withOpacity(0.3) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isBlocked ? Icons.block : Icons.check_circle_outline,
                        color: isBlocked ? Colors.redAccent : Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      CommonText(
                        isBlocked ? 'Status: Blocked / Offline' : 'Status: Available for Booking',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isBlocked ? Colors.redAccent : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  CommonText(
                    isBlocked
                        ? 'This slot is marked offline and patients cannot book appointments during this time.'
                        : 'This slot is open and available for patient appointments.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBlocked ? Colors.green : Colors.redAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      slotBloc.add(BlockSlotEvent(
                        slotId: currentSlot.id,
                        block: !isBlocked,
                      ));
                      Navigator.pop(context);
                    },
                    child: CommonText(
                      isBlocked ? 'Unblock Slot' : 'Block Slot',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const CommonText('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}