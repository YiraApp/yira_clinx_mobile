import 'package:flutter/material.dart';
import '../../../../core/colors/colors.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';
import '../../../domain/entities/slot/time_slot_entity.dart';
import 'dashboard_painter.dart';

class TimeSlotCard extends StatelessWidget {
  final TimeSlot slot;
  final VoidCallback bookSlot;
  final VoidCallback viewSlotDetails;
final bool isTab;
  const TimeSlotCard({
    super.key,
    required this.slot,
    required this.bookSlot,
    required this.viewSlotDetails, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBooked = slot.status == SlotStatus.booked;
    final primaryColor = theme.primaryColor;

    if (isBooked) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Stack(
          children: [
            InkWell(
              onTap: bookSlot,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? darkModeCardColor : Colors.white,
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 0.5,
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
                              fontSize:  isTab?displayWidth(context) * 0.02:displayWidth(context) * 0.035,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CommonText(
                            slot.duration,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab?displayWidth(context) * 0.018: displayWidth(context) * 0.03,
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: CommonText(
                                  slot.patientName ?? "Unknown Patient",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize:  isTab?displayWidth(context) * 0.02:displayWidth(context) * 0.035,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (slot.isVerified) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.verified,
                                  color: primaryColor,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
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
                                    ? "Regular Check-up"
                                    : "Follow-up",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab?displayWidth(context) * 0.018: displayWidth(context) * 0.03,
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
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: CommonText(
                        "Booked",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          color: primaryColor,
                          fontSize: isTab?displayWidth(context) * 0.018: displayWidth(context) * 0.023,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 16,
              bottom: 16,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final greenColor = isDark ? Colors.green : Colors.green;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: CustomPaint(
          painter: DashedBorderPainter(
            color: greenColor.withOpacity(0.4),
            strokeWidth: 1.2,
            gap: 4,
          ),
          child: InkWell(
            onTap: bookSlot,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? darkModeCardColor : Colors.white,
                borderRadius: BorderRadius.circular(fieldBorderRadius),
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
                            fontSize: isTab?displayWidth(context) * 0.02: displayWidth(context) * 0.035,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        CommonText(
                          slot.duration,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize:  isTab?displayWidth(context) * 0.018:displayWidth(context) * 0.03,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: greenColor.withOpacity(0.7),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        CommonText(
                          "Open for booking",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab?displayWidth(context) * 0.018: displayWidth(context) * 0.024,
                            color: greenColor,
                            fontWeight: FontWeight.w600,
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
                      color: greenColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CommonText(
                      "Available",
                      style: TextStyle(
                        color: greenColor,
                        fontFamily: appPoppinFont,
                        fontSize: isTab?displayWidth(context) * 0.018: displayWidth(context) * 0.023,
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
  }
}
