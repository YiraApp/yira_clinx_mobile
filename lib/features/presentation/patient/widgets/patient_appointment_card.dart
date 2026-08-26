import 'package:flutter/material.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/utils.dart';

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

    final isCompleted = status.toLowerCase() == 'completed';
    final isCancelled = status.toLowerCase() == 'cancelled';

    final statusColor = isCancelled
        ? Colors.red
        : isCompleted
            ? const Color(0xFF64748B)
            : const Color(0xFF059669);

    final statusBg = statusColor.withValues(alpha: isDark ? 0.2 : 0.12);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(isTab ? 18 : 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Doctor Info + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          fontSize: isTab ? 16 : 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (specialty.isNotEmpty)
                        Text(
                          specialty,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    status.isEmpty ? 'Confirmed' : status,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Hospital / Facility Badge Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_hospital_rounded,
                    size: 14,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hospitalName.isNotEmpty ? hospitalName : 'Healthcare Facility',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Mode Badge (In-Person / Video)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isTeleconsultation ? Colors.amber[800]! : primaryColor).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTeleconsultation ? Icons.videocam_rounded : Icons.location_on_rounded,
                          size: 10,
                          color: isTeleconsultation ? Colors.amber[800]! : primaryColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isTeleconsultation ? 'Video' : 'In-Person',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isTeleconsultation ? Colors.amber[800]! : primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                    final link = (meetingUrl != null && meetingUrl!.trim().isNotEmpty)
                        ? meetingUrl!.trim()
                        : 'https://zoom.us';
                    await Utils.launchURL(
                      link,
                      onLaunchFailure: (err) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err)),
                          );
                        }
                      },
                    );
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
