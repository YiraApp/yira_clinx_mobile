
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/colors/colors.dart';
import '../../../../core/constants/constants.dart';
import '../../../domain/entities/slot/slot_appointment_entity.dart';
import '../slot_bloc/slot_bloc.dart';
import '../slot_details_screen.dart';
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
      borderRadius: BorderRadius.circular(fieldBorderRadius),
      onTap: () => SlotDetailsDialog.show(context, slot),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? darkModeCardColor : Colors.white,
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          border: Border.all(
            color: (slot.hasAppointment || slot.label == 'Booked')
                ? primary.withValues(alpha: .25)
                : (slot.label == 'Blocked'
                    ? Colors.redAccent.withValues(alpha: .3)
                    : (isDark ? Colors.white10 : Colors.grey.shade200)),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black12
                  : Colors.black.withValues(alpha: .03),
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
                color: (slot.hasAppointment || slot.label == 'Booked')
                    ? primary
                    : (slot.label == 'Blocked' ? Colors.redAccent : Colors.green),
                borderRadius: BorderRadius.circular(fieldBorderRadius),
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
                              ? Colors.red.withValues(alpha: .15)
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
            ? Colors.white.withValues(alpha: 0.1)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(fieldBorderRadius/2),
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
    final isBooked = slot.hasAppointment || slot.label == 'Booked';
    final isBlocked = slot.label == 'Blocked';

    Color color;
    IconData icon;
    String text;

    if (isBooked) {
      color = theme.primaryColor;
      icon = Icons.event_available;
      text = "Booked";
    } else if (isBlocked) {
      color = Colors.redAccent;
      icon = Icons.block;
      text = "Blocked";
    } else {
      color = Colors.green;
      icon = Icons.check_circle;
      text = "Available";
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: CommonText(
              text,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}