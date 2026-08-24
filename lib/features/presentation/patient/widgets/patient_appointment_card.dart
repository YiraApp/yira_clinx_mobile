import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';

class PatientAppointmentCard extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final String hospitalName;
  final String date;
  final String time;
  final String status;
  final bool isTeleconsultation;
  final String? meetingUrl;
  final VoidCallback? onTap;

  const PatientAppointmentCard({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.hospitalName,
    required this.date,
    required this.time,
    required this.status,
    this.isTeleconsultation = false,
    this.meetingUrl,
    this.onTap,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'D';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    final statusColor = status.toLowerCase() == 'cancelled'
        ? Colors.red
        : status.toLowerCase() == 'completed'
            ? Colors.grey
            : isTeleconsultation
                ? Colors.amber[800]!
                : Colors.green[700]!;

    final statusBg = statusColor.withOpacity(0.12);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(isTab ? 18 : 15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Row: Doctor Info + Mode Badge
            Row(
              children: [
                CircleAvatar(
                  radius: isTab ? 26 : 22,
                  backgroundColor: primaryColor.withOpacity(0.12),
                  child: Text(
                    _getInitials(doctorName),
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: isTab ? 16 : 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$specialty • $hospitalName',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTeleconsultation ? Icons.videocam_rounded : Icons.location_on_rounded,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isTeleconsultation ? 'Video Consult' : 'In-Person',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Date & Time Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    date,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time_rounded, size: 14, color: primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    time,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),

            // Video Teleconsultation Button (If video and active)
            if (isTeleconsultation && status.toLowerCase() != 'completed' && status.toLowerCase() != 'cancelled') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final link = meetingUrl ?? 'https://zoom.us';
                    final uri = Uri.parse(link);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Launching Teleconsultation Video Call...')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.video_call_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Join Video Teleconsultation',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
