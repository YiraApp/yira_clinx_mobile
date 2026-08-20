import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/features/presentation/slot/slot_bloc/slot_bloc.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';
import '../../../../di/dependency_injection.dart';
import '../../domain/entities/slot/slot_appointment_entity.dart';

class SlotDetailsDialog extends StatefulWidget {
  final SlotEntity slot;
  const SlotDetailsDialog({super.key, required this.slot});

  static Future<void> show(BuildContext context, SlotEntity slot) {
    SlotBloc bloc;
    try {
      bloc = context.read<SlotBloc>();
    } catch (_) {
      bloc = sl<SlotBloc>();
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: SlotDetailsDialog(slot: slot),
      ),
    );
  }

  @override
  State<SlotDetailsDialog> createState() => _SlotDetailsDialogState();
}

class _SlotDetailsDialogState extends State<SlotDetailsDialog> {
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _isBlocked = widget.slot.label == 'Blocked';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    final double headlineSize = isTab? displayWidth(context) * 0.022:  displayWidth(context) * 0.042;
    final double labelSize = isTab? displayWidth(context) * 0.02: displayWidth(context) * 0.032;
    final double valueSize = isTab? displayWidth(context) * 0.022: displayWidth(context) * 0.04;

    return AlertDialog(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      titlePadding: const EdgeInsets.only(top: 20, left: 20, right: 16, bottom: 0),
      contentPadding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 24),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.history_toggle_off_rounded,
              color: isDark ? Colors.white : const Color(0xFF4F46E5),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText(
                  'Session Details',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w600,
                    fontSize: headlineSize,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                CommonText(
                  widget.slot.hasAppointment ? 'Booked Session' : (widget.slot.label == 'Blocked' ? 'Blocked Session' : 'Available Session'),
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w600,
                    fontSize: labelSize,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 24),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: displayWidth(context),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTimeDisplayCard(
                      context,
                      label: 'Start Time',
                      time: widget.slot.startTime,
                      labelSize: labelSize,
                      valueSize: valueSize,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimeDisplayCard(
                      context,
                      label: 'End Time',
                      time: widget.slot.endTime,
                      labelSize: labelSize,
                      valueSize: valueSize,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CommonText(
                'Status Management',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: labelSize,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey.shade500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              widget.slot.hasAppointment
                  ? _buildBookedAppointmentView(context, labelSize,isTab)
                  : _buildUnbookedSlotForm(context, theme, labelSize,isTab),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplayCard(
      BuildContext context, {
        required String label,
        required String time,
        required double labelSize,
        required double valueSize,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            label,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          CommonText(
            time,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: valueSize,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookedAppointmentView(BuildContext context, double labelSize,bool isTab) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appointment = widget.slot.appointment!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(color: const Color(0xFFD2E3FC).withOpacity(0.4),width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                ),
                child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonText(
                      'Patient Details',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize:isTab? displayWidth(context) * 0.02: displayWidth(context) * 0.03,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    CommonText(
                      appointment.patientName,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize:isTab? displayWidth(context) * 0.022: displayWidth(context) * 0.035,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildAppointmentMetaBox(
                  context,
                  title: 'Phone',
                  value: appointment.contactNumber,
                  labelSize: labelSize,
                  isTab: isTab
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? darkModeCardColor : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonText(
                        'Status',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab? displayWidth(context) * 0.02:displayWidth(context) * 0.03,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(fieldBorderRadius),
                        ),
                        child: CommonText(
                          'Confirmed',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize:isTab? displayWidth(context) * 0.016: displayWidth(context) * 0.02,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAppointmentMetaBox(
            context,
            title: 'Reason for visit',
            value: appointment.reason ?? 'General Consultation',
            labelSize: labelSize,
            isFullWidth: true,
            isTab: isTab
          ),
          const SizedBox(height: 24),
          Center(
            child: InkWell(
              onTap: () {
                context.read<SlotBloc>().add(
                  CancelAppointmentEvent(
                    slotId: widget.slot.id,
                    appointmentId: appointment.id,
                  ),
                );
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(fieldBorderRadius),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.close_rounded, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    CommonText(
                      'Cancel Appointment',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontWeight: FontWeight.w600,
                        fontSize:isTab? displayWidth(context) * 0.02: displayWidth(context) * 0.032,
                        color: Colors.redAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnbookedSlotForm(BuildContext context, ThemeData theme, double labelSize, bool isTab) {
    final isDark = theme.brightness == Brightness.dark;
    final bool isAlreadyBlocked = widget.slot.label == 'Blocked';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isBlocked = false),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: !_isBlocked
                        ? (isDark ? Colors.green.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.1))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    border: Border.all(
                      color: !_isBlocked ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: CommonText(
                      'Available',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontWeight: FontWeight.w600,
                        fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.034,
                        color: !_isBlocked ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _isBlocked = true),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isBlocked
                        ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    border: Border.all(
                      color: _isBlocked ? Colors.redAccent : (isDark ? Colors.white10 : Colors.grey.shade200),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: CommonText(
                      'Block Slot',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontWeight: FontWeight.w600,
                        fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.034,
                        color: _isBlocked ? Colors.redAccent : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (isAlreadyBlocked) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(fieldBorderRadius),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: CommonText(
                    'This slot is currently blocked. Click below to unblock it and make it available for patient bookings.',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.030,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<SlotBloc>().add(
                BlockSlotEvent(slotId: widget.slot.id, block: false),
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
              elevation: 0,
            ),
            child: CommonText(
              'Unblock This Slot',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTab ? displayWidth(context) * 0.022 : displayWidth(context) * 0.035,
                fontFamily: appPoppinFont,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ] else if (_isBlocked) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(fieldBorderRadius),
              border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: CommonText(
                    'This slot will be marked unavailable for patient booking sessions.',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.030,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.read<SlotBloc>().add(
                BlockSlotEvent(slotId: widget.slot.id, block: true),
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
              elevation: 0,
            ),
            child: CommonText(
              'Block This Slot',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTab ? displayWidth(context) * 0.022 : displayWidth(context) * 0.035,
                fontFamily: appPoppinFont,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(fieldBorderRadius),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: CommonText(
                    'This slot is currently active and available for patient bookings. You can switch to "Block Slot" above to disable it.',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.030,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
              foregroundColor: isDark ? Colors.white : Colors.black87,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
              elevation: 0,
            ),
            child: CommonText(
              'Close',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTab ? displayWidth(context) * 0.022 : displayWidth(context) * 0.035,
                fontFamily: appPoppinFont,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }



  Widget _buildAppointmentMetaBox(
      BuildContext context, {
        required String title,
        required String value,
        required double labelSize,
        bool isFullWidth = false,required bool isTab
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? darkModeBorderColor : const Color(0xFFE2E8F0),width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            title,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab? displayWidth(context) * 0.02:displayWidth(context) * 0.03,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 4),
          CommonText(
            value,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize:isTab? displayWidth(context) * 0.02: displayWidth(context) * 0.035,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : textLightModeColor,
            ),
          ),
        ],
      ),
    );
  }
}