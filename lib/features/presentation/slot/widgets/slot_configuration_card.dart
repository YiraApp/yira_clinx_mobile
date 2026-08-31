
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/colors/colors.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
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
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    final isBooked = slot.hasAppointment || slot.label == 'Booked';
    final isBlocked = slot.label == 'Blocked';

    final Color accentColor = isBooked
        ? primaryColor
        : (isBlocked ? Colors.redAccent : const Color(0xFF10B981));

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => SlotDetailsDialog.show(context, slot),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? darkModeCardColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? accentColor.withValues(alpha: 0.15)
                : accentColor.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : accentColor.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 4,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor,
                    accentColor.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            // Time column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time row
                  Row(
                    children: [
                      // Start time
                      Expanded(
                        child: _TimeChip(
                          label: 'START',
                          time: slot.startTime,
                          isDark: isDark,
                          primaryColor: primaryColor,
                          isTab: isTab,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: isDark ? Colors.white30 : Colors.grey.shade400,
                        ),
                      ),
                      // End time
                      Expanded(
                        child: _TimeChip(
                          label: 'END',
                          time: slot.endTime,
                          isDark: isDark,
                          primaryColor: primaryColor,
                          isTab: isTab,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Status + Duration + Delete row
                  Row(
                    children: [
                      // Status pill
                      _StatusPill(
                        accentColor: accentColor,
                        isBooked: isBooked,
                        isBlocked: isBlocked,
                        isDark: isDark,
                        isTab: isTab,
                      ),
                      const SizedBox(width: 8),
                      // Duration pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 3),
                            CommonText(
                              slot.duration.isNotEmpty ? slot.duration : '—',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? displayWidth(context) * 0.013 : 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Delete button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            context.read<SlotBloc>().add(
                              RemoveSlotEvent(slot.id),
                            );
                          },
                          child: Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.red.withValues(alpha: 0.12)
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                          ),
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
}

class _TimeChip extends StatelessWidget {
  final String label;
  final String time;
  final bool isDark;
  final Color primaryColor;
  final bool isTab;

  const _TimeChip({
    required this.label,
    required this.time,
    required this.isDark,
    required this.primaryColor,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            label,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: 0.8,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: primaryColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: CommonText(
                  time,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w700,
                    fontSize: isTab ? displayWidth(context) * 0.014 : 12,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Color accentColor;
  final bool isBooked;
  final bool isBlocked;
  final bool isDark;
  final bool isTab;

  const _StatusPill({
    required this.accentColor,
    required this.isBooked,
    required this.isBlocked,
    required this.isDark,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String text;

    if (isBooked) {
      icon = Icons.event_available_rounded;
      text = "Booked";
    } else if (isBlocked) {
      icon = Icons.block_rounded;
      text = "Blocked";
    } else {
      icon = Icons.check_circle_outline_rounded;
      text = "Available";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accentColor),
          const SizedBox(width: 4),
          CommonText(
            text,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.w700,
              fontSize: isTab ? displayWidth(context) * 0.013 : 10,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}