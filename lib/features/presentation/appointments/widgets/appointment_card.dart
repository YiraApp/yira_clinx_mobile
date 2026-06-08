import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/colors/colors.dart';
import '../../../../core/constants/constants.dart';
import '../../../domain/entities/appointments/appointment_entity.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onEdit;
  final bool isTeleConsultation;
  final bool isPatientProfile;
final bool isTab;
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onEdit,
    required this.isTeleConsultation,  this.isPatientProfile = false, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;

    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        statusBgColor = isDark ? const Color(0xFF2E7D32).withOpacity(0.2) : const Color(0xFFE8F5E9);
        statusTextColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
        statusLabel = "Confirmed";
        break;
      case AppointmentStatus.paymentPending:
        statusBgColor = isDark ? const Color(0xFFC62828).withOpacity(0.2) : const Color(0xFFFFEBEE);
        statusTextColor = isDark ? const Color(0xFFE57373) : const Color(0xFFC62828);
        statusLabel = "Payment Pending";
        break;
      case AppointmentStatus.pendingInfo:
        statusBgColor = isDark ? const Color(0xFFEF6C00).withOpacity(0.2) : const Color(0xFFFFF3E0);
        statusTextColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00);
        statusLabel = "Need Info";
        break;
    }

    final tokenBgColor = isDark ? Colors.white.withOpacity(0.1) : theme.primaryColor.withOpacity(0.15);

    return Container(
      margin: const EdgeInsets.only(bottom: fieldSpace),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.2), width: 0.5) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 2.5, color: theme.primaryColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 10, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                appointment.type == AppointmentType.videoCall
                                    ? Icons.videocam_outlined
                                    : Icons.access_time_rounded,
                                size: 16,
                                color: theme.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                appointment.time,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab?displayWidth(context) * 0.018: displayWidth(context) * 0.032,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                " - ${appointment.duration}",
                                style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize:isTab?displayWidth(context) * 0.018:  displayWidth(context) * 0.032),
                              ),
                            ],
                          ),
                          isPatientProfile? SizedBox.shrink(): Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: tokenBgColor,
                              borderRadius: BorderRadius.circular(fieldBorderRadius),
                            ),
                            child: Text(
                              appointment.tokenNumber,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize:isTab?displayWidth(context) * 0.018:  displayWidth(context) * 0.028,
                                fontFamily: appPoppinFont,
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.primaryColor,
                            child: Text(
                              appointment.patientName.isNotEmpty
                                  ? appointment.patientName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join()
                                  : '',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: appPoppinFont,
                                fontSize: isTab?displayWidth(context) * 0.018: displayWidth(context) * 0.031,
                              ),
                            ),
                          ),
                          const SizedBox(width: fieldSpace),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment.patientName,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: isTab?displayWidth(context) * 0.02: displayWidth(context) * 0.035,
                                    fontFamily: appPoppinFont,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.phone, size: 14, color: theme.hintColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      appointment.phoneNumber,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontFamily: appPoppinFont,
                                        fontSize: isTab?displayWidth(context) * 0.018: displayWidth(context) * 0.032,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      appointment.category == "Follow-up" ? Icons.history : Icons.medical_services_outlined,
                                      size: 14,
                                      color: theme.hintColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      appointment.category,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontFamily: appPoppinFont,
                                        fontSize: isTab?displayWidth(context) * 0.018: displayWidth(context) * 0.032,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      appointment.type == AppointmentType.videoCall ? Icons.videocam : Icons.location_on_outlined,
                                      size: 14,
                                      color: theme.hintColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      appointment.type == AppointmentType.videoCall ? "Video Call" : "In-Clinic",
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontFamily: appPoppinFont,
                                        fontSize:isTab?displayWidth(context) * 0.018:  displayWidth(context) * 0.032,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(fieldBorderRadius),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusTextColor,
                                fontWeight: FontWeight.w600,
                                fontFamily: appPoppinFont,
                                fontSize:isTab?displayWidth(context) * 0.016:  displayWidth(context) * 0.032,
                              ),
                            ),
                          ),
                          isPatientProfile? SizedBox.shrink():  Row(
                            children: [
                              if (isTeleConsultation)
                                 Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: IconButton(
                                    onPressed: () {},
                                    icon: Icon(
                                      Icons.video_call_rounded,
                                      color: isDark ? const Color(0xFF64B5F6) : theme.primaryColor,
                                    ),
                                    tooltip: 'Start Video Consultation',
                                    splashRadius: 15,
                                  ),
                                ),
                               IconButton(
                                onPressed: onEdit,
                                icon: Icon(Icons.edit_note_outlined, color: theme.hintColor),
                                splashRadius: 15,
                              ),
                            ],
                          )
                        ],
                      ),
                      isPatientProfile? SizedBox(height: 10,):SizedBox.shrink()
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}