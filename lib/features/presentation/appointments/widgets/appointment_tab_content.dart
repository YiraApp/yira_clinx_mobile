import 'package:flutter/material.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/utils.dart';
import '../../../domain/entities/appointments/appointment_entity.dart';
import '../../doctor/dashboard/widgets/doc_appointment_card.dart';

class AppointmentTabContent extends StatelessWidget {
  final List<Appointment> appointments;
  final String tabTitle;
  final String emptyMessage;
  final VoidCallback? onBookAppointment;
  final int? tabIndex;
  final bool isTab;
  final void Function(Appointment appointment)? onCardTap;

  const AppointmentTabContent({
    super.key,
    required this.appointments,
    required this.tabTitle,
    required this.emptyMessage,
    this.onBookAppointment,
    this.tabIndex,
    required this.isTab,
    this.onCardTap,
  });

  String _getInitials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'P';
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    if (appointments.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  size: displayWidth(context) * 0.18,
                  color: Theme.of(context).hintColor.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                CommonText(
                  "No Records Available",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w600,
                    fontSize: displayWidth(context) * 0.04,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                CommonText(
                  emptyMessage,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w400,
                    fontSize: isTab ? displayWidth(context) * 0.022 : displayWidth(context) * 0.03,
                    color: Theme.of(context).hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: onBookAppointment,
                    icon: const Icon(Icons.add, size: 16),
                    label: CommonText(
                      "Book Appointment",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontWeight: FontWeight.w500,
                        fontSize: displayWidth(context) * 0.03,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonText(
                tabTitle,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.036,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: fieldSpace),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: appointments.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final appointment = appointments[index];

              // Determine status color
              final bool isCompleted = appointment.statusRaw.toLowerCase().contains('complete');
              final bool isVideo = appointment.type == AppointmentType.videoCall;
              Color statusColor;
              Color statusTextColor;
              String statusLabel;

              switch (appointment.status) {
                case AppointmentStatus.confirmed:
                  statusColor = isDark ? Colors.green.withOpacity(0.15) : Colors.green.withOpacity(0.15);
                  statusTextColor = isDark ? Colors.green[300]! : Colors.green[700]!;
                  statusLabel = isCompleted ? 'Completed' : 'Confirmed';
                  break;
                case AppointmentStatus.paymentPending:
                  statusColor = isDark ? Colors.red.withOpacity(0.15) : Colors.red.withOpacity(0.15);
                  statusTextColor = isDark ? Colors.red[300]! : Colors.red[700]!;
                  statusLabel = 'Payment Pending';
                  break;
                case AppointmentStatus.pendingInfo:
                  statusColor = isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.withOpacity(0.15);
                  statusTextColor = isDark ? Colors.orange[300]! : Colors.orange[700]!;
                  statusLabel = 'Need Info';
                  break;
              }

              // Override for completed
              if (isCompleted) {
                statusColor = primaryColor.withOpacity(0.1);
                statusTextColor = primaryColor;
                statusLabel = 'Completed';
              }

              // Override for scheduled (default)
              if (appointment.statusRaw.toLowerCase().contains('scheduled')) {
                statusColor = isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.withOpacity(0.15);
                statusTextColor = isDark ? Colors.amber[300]! : Colors.amber[800]!;
                statusLabel = 'Scheduled';
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: DocAppointmentCard(
                  isTab: isTab,
                  initials: _getInitials(appointment.patientName),
                  name: appointment.patientName.isNotEmpty ? appointment.patientName : 'Unknown Patient',
                  subtitle: appointment.category.isNotEmpty ? appointment.category : 'Consultation',
                  description: appointment.reason?.isNotEmpty == true ? appointment.reason! : 'General Checkup',
                  timeOrDate: appointment.time.isNotEmpty ? appointment.time : '--:-- AM',
                  statusLabel: statusLabel,
                  statusColor: statusColor,
                  statusTextColor: statusTextColor,
                  patientStatus: appointment.patientStatus,
                  isTeleConsultation: isVideo,
                  onJoinCall: () async {
                    final meetingUrl = appointment.meetingUrl;
                    if (meetingUrl != null && meetingUrl.isNotEmpty) {
                      await Utils.launchURL(
                        meetingUrl,
                        onLaunchFailure: (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err)),
                            );
                          }
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No Zoom meeting link found for this appointment.')),
                      );
                    }
                  },
                  onTap: () {
                    onCardTap?.call(appointment);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}