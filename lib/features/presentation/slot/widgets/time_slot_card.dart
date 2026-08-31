import 'package:flutter/material.dart';
import '../../../../core/colors/colors.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';
import '../../../domain/entities/slot/time_slot_entity.dart';

class TimeSlotCard extends StatelessWidget {
  final TimeSlot slot;
  final VoidCallback bookSlot;
  final VoidCallback viewSlotDetails;
  final bool isTab;
  final DateTime? targetDate;

  const TimeSlotCard({
    super.key,
    required this.slot,
    required this.bookSlot,
    required this.viewSlotDetails,
    required this.isTab,
    this.targetDate,
  });

  bool _isSlotPast(DateTime? date, String timeStr) {
    if (date == null) return false;
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) {
      try {
        final clean = timeStr.trim();
        if (clean.isEmpty) return false;
        final firstPart = clean.contains(' - ') ? clean.split(' - ').first.trim() : clean;
        final isPM = firstPart.toUpperCase().contains('PM');
        final isAM = firstPart.toUpperCase().contains('AM');
        final digitsOnly = firstPart.replaceAll(RegExp(r'[^0-9:]'), '');
        final parts = digitsOnly.split(':');
        if (parts.isEmpty) return false;
        int hour = int.parse(parts[0]);
        int minute = parts.length > 1 ? int.parse(parts[1]) : 0;
        if (isPM && hour < 12) hour += 12;
        if (isAM && hour == 12) hour = 0;
        final slotTime = DateTime(date.year, date.month, date.day, hour, minute);
        return slotTime.isBefore(now);
      } catch (_) {
        return false;
      }
    } else {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final todayOnly = DateTime(now.year, now.month, now.day);
      return dateOnly.isBefore(todayOnly);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBooked = slot.status == SlotStatus.booked;
    final isBlocked = slot.status == SlotStatus.blocked;
    final bool isPast = _isSlotPast(targetDate, slot.time);
    final primaryColor = theme.primaryColor;

    if (isBlocked || (isPast && !isBooked)) {
      final bool isPastNotBlocked = isPast && !isBlocked;
      final cardBg = isPastNotBlocked
          ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
          : (isDark ? const Color(0xFF2A1818) : const Color(0xFFFFF5F5));
      final borderColor = isPastNotBlocked
          ? (isDark ? Colors.white12 : const Color(0xFFCBD5E1))
          : Colors.redAccent.withValues(alpha: 0.35);
      final tagBg = isPastNotBlocked
          ? (isDark ? Colors.white10 : const Color(0xFFE2E8F0))
          : Colors.redAccent.withValues(alpha: 0.12);
      final tagColor = isPastNotBlocked
          ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
          : Colors.redAccent;
      final tagText = isPastNotBlocked ? "Past Time" : "Blocked";
      final icon = isPastNotBlocked ? Icons.history_toggle_off_rounded : Icons.block_rounded;
      final desc = isPastNotBlocked ? "Past Time • Closed" : "Slot Blocked • Tap to unblock";

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isPastNotBlocked
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Cannot book an appointment for past time.",
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 13),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF334155),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                : bookSlot,
            borderRadius: BorderRadius.circular(fieldBorderRadius),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(fieldBorderRadius),
                border: Border.all(
                  color: borderColor,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonText(
                          slot.time,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.035,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: isDark ? Colors.white60 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        CommonText(
                          isPastNotBlocked ? "Passed" : slot.duration,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.028,
                            color: tagColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: tagColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: CommonText(
                            desc,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.026,
                              color: tagColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CommonText(
                      tagText,
                      style: TextStyle(
                        color: tagColor,
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.024,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (isBooked) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: bookSlot,
            borderRadius: BorderRadius.circular(fieldBorderRadius),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? darkModeCardColor : Colors.white,
                borderRadius: BorderRadius.circular(fieldBorderRadius),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.25),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 38,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonText(
                          slot.time,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.035,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        CommonText(
                          slot.duration,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.028,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: CommonText(
                                slot.patientName ?? "Patient Booked",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.034,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (slot.isVerified) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified_rounded,
                                color: primaryColor,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            CommonText(
                              slot.type == AppointmentType.regularCheckUp
                                  ? "Regular Consultation"
                                  : "Follow-up Visit",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.026,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CommonText(
                      "Booked",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        color: primaryColor,
                        fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.024,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      const greenColor = Color(0xFF10B981);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: bookSlot,
            borderRadius: BorderRadius.circular(fieldBorderRadius),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? darkModeCardColor : Colors.white,
                borderRadius: BorderRadius.circular(fieldBorderRadius),
                border: Border.all(
                  color: greenColor.withValues(alpha: 0.4),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonText(
                          slot.time,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.035,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        CommonText(
                          slot.duration,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.028,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          color: greenColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: CommonText(
                            "Free Slot • Tap to book",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.026,
                              color: greenColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: greenColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: greenColor.withValues(alpha: 0.28),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: Colors.white, size: 15),
                        const SizedBox(width: 3),
                        CommonText(
                          "Book",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.026,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
