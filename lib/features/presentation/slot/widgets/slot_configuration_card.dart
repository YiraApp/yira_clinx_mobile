
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/colors/colors.dart';
import '../../../domain/entities/slot/slot_appointment_entity.dart';
import '../slot_bloc/slot_bloc.dart';
import 'appointment_modal_sheet.dart';
import '../../../../core/common_widgets/common_text.dart';

class SlotConfigurationCard extends StatelessWidget {
  final SlotEntity slot;

  const SlotConfigurationCard({
    super.key,
    required this.slot,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.primaryColor;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => AppointmentModalSheet.show(
        context,
        slot,
        context.read<SlotBloc>(),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark? darkModeCardColor:Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: slot.hasAppointment
                ? primary.withOpacity(.25)
                : isDark
                ? Colors.white10
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black12
                  : Colors.black.withOpacity(.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 70,
              decoration: BoxDecoration(
                color: slot.hasAppointment
                    ? primary
                    : Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _timeCard(
                          context,
                          title: "Start",
                          value: slot.startTime,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _timeCard(
                          context,
                          title: "End",
                          value: slot.endTime,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _statusCard(context),
                      ),
                      const SizedBox(width: 10),

                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.red.withOpacity(.15)
                              : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                          ),
                          color: Colors.red,
                          onPressed: () {
                            context.read<SlotBloc>().add(
                              RemoveSlotEvent(slot.id),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeCard(
      BuildContext context, {
        required String title,
        required String value,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? darkModeInnerCardColor
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: theme.primaryColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: CommonText(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: slot.hasAppointment
            ? theme.primaryColor.withOpacity(.12)
            : Colors.green.withOpacity(.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            slot.hasAppointment
                ? Icons.event_available
                : Icons.check_circle,
            size: 16,
            color: slot.hasAppointment
                ? theme.primaryColor
                : Colors.green,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: CommonText(
              slot.hasAppointment
                  ? "Booked"
                  : "Available",
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: slot.hasAppointment
                    ? theme.primaryColor
                    : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}