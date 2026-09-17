import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../../core/common_widgets/in_app_document_viewer.dart';
import '../../../../core/api/base_api_configuration.dart';
import '../prescription_details_screen.dart';

class PrescriptionCard extends StatelessWidget {
  final String id;
  final String title;
  final String condition;
  final String doctor;
  final String specialty;
  final String date;
  final String status;
  final String pharmacy;
  final List<Map<String, dynamic>> medications;

  const PrescriptionCard({
    super.key,
    required this.id,
    required this.title,
    required this.condition,
    required this.doctor,
    required this.specialty,
    required this.date,
    required this.status,
    required this.pharmacy,
    required this.medications,
  });

  bool get isActive => status.toLowerCase() == 'active';

  String get _doctorNameOnly {
    if (doctor.contains(' - ')) {
      return doctor.split(' - ').first.trim();
    }
    return doctor.trim().isNotEmpty ? doctor.trim() : 'Consulting Doctor';
  }

  String get _specialtyOnly {
    if (specialty.trim().isNotEmpty && specialty.toLowerCase() != 'general physician') {
      return specialty.trim();
    }
    if (doctor.contains(' - ')) {
      final parts = doctor.split(' - ');
      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        return parts[1].trim();
      }
    }
    return specialty.trim();
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return 'Recent Appointment';
    try {
      final dt = DateTime.parse(raw.trim());
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw.trim();
    }
  }

  void _openPdf(BuildContext context) {
    final rawBaseUrl = EnvironmentService.config.accountBaseUrl;
    final baseUrl = rawBaseUrl.startsWith('http') ? rawBaseUrl : 'https://$rawBaseUrl';
    final effectivePdfUrl = '$baseUrl/v1/api/auth/prescriptions/$id/pdf';

    InAppDocumentViewer.show(
      context,
      title: _doctorNameOnly.isNotEmpty ? '$_doctorNameOnly - Prescription' : 'Digital Prescription',
      category: 'Prescription',
      fileUrl: effectivePdfUrl,
      hospitalName: 'Yira Super Speciality Hospitals',
      isAppointmentDoc: true,
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrescriptionDetailScreen(
          prescriptionId: id,
          initialData: {
            'id': id,
            'title': title,
            'condition': condition,
            'doctor': doctor,
            'specialty': specialty,
            'date': date,
            'status': status,
            'pharmacy': pharmacy,
            'medications': medications,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2430) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Prescribed Doctor & Status Header ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor Icon Avatar
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.medical_services_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Doctor Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _doctorNameOnly,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontWeight: FontWeight.w700,
                              fontSize: isTablet(context) ? 16 : 14.5,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              height: 1.2,
                            ),
                          ),
                          if (_specialtyOnly.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _specialtyOnly,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Status Badge & PDF Action
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusBadge(isDark),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _openPdf(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: isDark ? 0.2 : 0.09),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF059669).withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.picture_as_pdf_rounded,
                                  size: 13,
                                  color: Color(0xFF059669),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  "PDF",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Streamlined Diagnosis & Appointment Taken Information ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFEDF2F7),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Diagnosis
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.healing_rounded,
                              size: 13,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            "Diagnosis: ",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              condition,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      // Appointment Taken Date
                      Row(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 13,
                            color: isDark ? Colors.white54 : const Color(0xFF0EA5E9),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            "Appointment Taken: ",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _formatDate(date),
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Prescribed Medicines Pill Action Strip (No individual tablets on main card) ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/dashboard_icons/pill_prescriptions_thick.png',
                        width: 28,
                        height: 28,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.medication_rounded,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medications.isNotEmpty
                                  ? "${medications.length} Prescribed Medicine${medications.length == 1 ? '' : 's'}"
                                  : "Prescribed Medicines",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              "Tap to view medicines & set alarms",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: primaryColor,
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

  Widget _buildStatusBadge(bool isDark) {
    final Color badgeColor = isActive ? const Color(0xFF10B981) : Colors.grey.shade500;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.5,
            height: 5.5,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4.5),
          Text(
            isActive ? 'Active' : 'Completed',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
