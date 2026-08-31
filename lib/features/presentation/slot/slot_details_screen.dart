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
  bool _isBookingMode = true;
  bool _isSubmitting = false;

  late final TextEditingController _patientNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _reasonController;
  String _selectedType = 'Regular Check-up';

  final List<String> _appointmentTypes = const [
    'Regular Check-up',
    'Follow-up',
    'General Consultation',
    'Emergency',
  ];

  @override
  void initState() {
    super.initState();
    _isBookingMode = widget.slot.label != 'Blocked' && !widget.slot.hasAppointment;
    _patientNameController = TextEditingController();
    _phoneController = TextEditingController();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submitBooking() {
    final name = _patientNameController.text.trim();
    final phone = _phoneController.text.trim();
    final reason = _reasonController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter patient name'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (phone.isEmpty || phone.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number (at least 7 digits)'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    context.read<SlotBloc>().add(
      BookAppointmentEvent(
        slotId: widget.slot.id,
        patientName: name,
        contactNumber: phone,
        startTime: widget.slot.startTime,
        reason: reason.isNotEmpty ? reason : 'General Consultation',
        appointmentType: _selectedType,
      ),
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appointment booked for $name!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    final double headlineSize = isTab ? displayWidth(context) * 0.022 : displayWidth(context) * 0.042;
    final double labelSize = isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032;
    final double valueSize = isTab ? displayWidth(context) * 0.022 : displayWidth(context) * 0.038;

    return AlertDialog(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      titlePadding: const EdgeInsets.only(top: 20, left: 20, right: 16, bottom: 0),
      contentPadding: const EdgeInsets.only(top: 14, left: 20, right: 20, bottom: 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.slot.hasAppointment
                  ? Icons.calendar_today_rounded
                  : (widget.slot.label == 'Blocked' ? Icons.block_rounded : Icons.person_add_alt_1_rounded),
              color: widget.slot.label == 'Blocked' ? Colors.redAccent : primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText(
                  widget.slot.hasAppointment
                      ? 'Booked Appointment'
                      : (widget.slot.label == 'Blocked' ? 'Blocked Slot' : 'Book Appointment'),
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w700,
                    fontSize: headlineSize,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                CommonText(
                  'Slot: ${widget.slot.startTime} - ${widget.slot.endTime}',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w600,
                    fontSize: labelSize,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: displayWidth(context),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
                  const SizedBox(width: 10),
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
              const SizedBox(height: 18),

              widget.slot.hasAppointment
                  ? _buildBookedAppointmentView(context, labelSize, isTab)
                  : _buildUnbookedSlotForm(context, theme, labelSize, isTab),
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
        border: Border.all(color: const Color(0xFFD2E3FC).withValues(alpha: 0.4), width: 0.5),
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

    if (isAlreadyBlocked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(fieldBorderRadius),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.block_rounded, color: Colors.redAccent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: CommonText(
                    'This slot is currently blocked. Click below to unblock it and make it available for patient bookings.',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.028,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              context.read<SlotBloc>().add(
                BlockSlotEvent(slotId: widget.slot.id, block: false),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
            label: CommonText(
              'Unblock This Slot',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.034,
                fontFamily: appPoppinFont,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
              elevation: 0,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Selector (Book Patient vs Block Slot)
        Container(
          width: double.infinity,
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(fieldBorderRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isBookingMode = true),
                  borderRadius: BorderRadius.circular(fieldBorderRadius - 2),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isBookingMode
                          ? (isDark ? primaryColor : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(fieldBorderRadius - 2),
                      boxShadow: _isBookingMode && !isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 18,
                          color: _isBookingMode
                              ? (isDark ? Colors.white : primaryColor)
                              : (isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                        const SizedBox(width: 6),
                        CommonText(
                          'Book Patient',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontWeight: FontWeight.w600,
                            fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.028,
                            color: _isBookingMode
                                ? (isDark ? Colors.white : primaryColor)
                                : (isDark ? Colors.white60 : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isBookingMode = false),
                  borderRadius: BorderRadius.circular(fieldBorderRadius - 2),
                  child: Container(
                    decoration: BoxDecoration(
                      color: !_isBookingMode
                          ? (isDark ? const Color(0xFF7F1D1D) : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(fieldBorderRadius - 2),
                      boxShadow: !_isBookingMode && !isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.block_rounded,
                          size: 16,
                          color: !_isBookingMode
                              ? (isDark ? Colors.white : Colors.redAccent)
                              : (isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                        const SizedBox(width: 6),
                        CommonText(
                          'Block Slot',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontWeight: FontWeight.w600,
                            fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.028,
                            color: !_isBookingMode
                                ? (isDark ? Colors.white : Colors.redAccent)
                                : (isDark ? Colors.white60 : Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        if (_isBookingMode) ...[
          // Patient Name Field
          _buildInputLabel('Patient Full Name *', isDark, isTab),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _patientNameController,
            hintText: 'e.g. Ramesh Kumar',
            icon: Icons.person_outline_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // Contact Number Field
          _buildInputLabel('Mobile Phone Number *', isDark, isTab),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _phoneController,
            hintText: 'e.g. 9876543210',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // Appointment Type Selector Chips
          _buildInputLabel('Consultation Type', isDark, isTab),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _appointmentTypes.map((type) {
              final isSelected = _selectedType == type;
              return InkWell(
                onTap: () => setState(() => _selectedType = type),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.12)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? Colors.white12 : Colors.grey.shade300),
                      width: isSelected ? 1.2 : 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(Icons.check_circle_rounded, size: 14, color: primaryColor),
                        const SizedBox(width: 4),
                      ],
                      CommonText(
                        type,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 13 : 11.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? primaryColor
                              : (isDark ? Colors.white70 : Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Reason / Symptoms (Optional)
          _buildInputLabel('Reason / Symptoms (Optional)', isDark, isTab),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _reasonController,
            hintText: 'e.g. Fever, Follow-up checkup',
            icon: Icons.medical_services_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          // Confirm Booking Button
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitBooking,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_circle_rounded, size: 20),
            label: CommonText(
              _isSubmitting ? 'Booking Appointment...' : 'Confirm & Book Appointment',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.033,
                fontFamily: appPoppinFont,
                letterSpacing: 0.3,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
              elevation: 2,
            ),
          ),
        ] else ...[
          // Block Slot Mode
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A1515) : const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(fieldBorderRadius),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: CommonText(
                    'This slot will be marked unavailable for patient booking sessions.',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.028,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              context.read<SlotBloc>().add(
                BlockSlotEvent(slotId: widget.slot.id, block: true),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.block_rounded, size: 18),
            label: CommonText(
              'Block This Slot',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.034,
                fontFamily: appPoppinFont,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
              elevation: 0,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputLabel(String label, bool isDark, bool isTab) {
    return CommonText(
      label,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.028,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : const Color(0xFF334155),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 13.5,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 13,
            color: isDark ? Colors.white30 : Colors.grey.shade400,
          ),
          prefixIcon: Icon(icon, size: 20, color: isDark ? Colors.white54 : Colors.grey.shade500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
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