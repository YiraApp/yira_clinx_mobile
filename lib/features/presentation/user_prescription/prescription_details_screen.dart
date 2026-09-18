import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/services/medication_reminder_service.dart';
import 'package:yiraclinics/features/data/models/medication/medication_reminder_model.dart';
import 'package:yiraclinics/features/presentation/user_prescription/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/user_prescription/widgets/convert_tablet_sheet.dart';
import '../../../di/dependency_injection.dart';
import '../../../core/common_widgets/in_app_document_viewer.dart';
import '../../../core/api/base_api_configuration.dart';
import '../../../core/widgets/doctor_avatar_widget.dart';

class PrescriptionDetailScreen extends StatelessWidget {
  final String prescriptionId;
  final Map<String, dynamic>? initialData;

  const PrescriptionDetailScreen({
    super.key,
    required this.prescriptionId,
    this.initialData,
  });

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return 'Recent Appointment';
    try {
      final dt = DateTime.parse(raw.trim());
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return raw.trim();
    }
  }

  String _cleanDoctorName(String raw) {
    String name = raw;
    if (name.contains(' - ')) {
      name = name.split(' - ').first.trim();
    }
    name = name.trim();
    if (name.isEmpty) return 'Consulting Doctor';
    if (!name.toLowerCase().startsWith('dr.') && !name.toLowerCase().startsWith('dr ')) {
      return 'Dr. $name';
    }
    return name;
  }

  String _cleanSpecialty(String rawSpecialty, String docName) {
    if (rawSpecialty.isNotEmpty && rawSpecialty.toLowerCase() != 'general physician') {
      return rawSpecialty.trim();
    }
    if (docName.contains(' - ')) {
      final parts = docName.split(' - ');
      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        return parts[1].trim();
      }
    }
    return rawSpecialty.trim().isNotEmpty ? rawSpecialty.trim() : 'Specialist Physician';
  }

  String _cleanSchedule(String rawDosage, String frequency) {
    // Strip out "1 tablet", "2 tablets", "tablet", "tablets", "capsule", "capsules", "single tablet"
    var text = rawDosage.replaceAll(RegExp(r'\b\d*\s*(tablets?|tabs?|capsules?|caps?|pills?)\b', caseSensitive: false), '').trim();
    text = text.replaceAll(RegExp(r'single\s*(tablets?|tabs?|capsules?|caps?|pills?)\b', caseSensitive: false), '').trim();
    text = text.replaceAll(RegExp(r'^[-•:,/\s]+|[-•:,/\s]+$'), '').trim();
    text = text.replaceAll(RegExp(r'\s{2,}'), ' ');
    if (text.isEmpty && frequency.isNotEmpty) {
      text = frequency.replaceAll(RegExp(r'\b\d*\s*(tablets?|tabs?|capsules?|caps?|pills?)\b', caseSensitive: false), '').trim();
      text = text.replaceAll(RegExp(r'single\s*(tablets?|tabs?|capsules?|caps?|pills?)\b', caseSensitive: false), '').trim();
      text = text.replaceAll(RegExp(r'^[-•:,/\s]+|[-•:,/\s]+$'), '').trim();
      text = text.replaceAll(RegExp(r'\s{2,}'), ' ');
    }
    if (text.isEmpty) {
      return "As directed";
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => sl<MedicationBloc>()..add(LoadPrescriptionDetails(prescriptionId)),
      child: Scaffold(
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Prescription Details",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          actions: [
            BlocBuilder<MedicationBloc, MedicationState>(
              builder: (context, state) {
                final data = state.selectedPrescriptionDetail ?? initialData;
                final customPdf = data?['pdfUrl']?.toString();
                final docName = _cleanDoctorName(data?['doctor'] ?? 'Doctor');
                return IconButton(
                  tooltip: "View Full Prescription PDF",
                  icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF059669)),
                  onPressed: () {
                    final rawBaseUrl = EnvironmentService.config.accountBaseUrl;
                    final baseUrl = rawBaseUrl.startsWith('http') ? rawBaseUrl : 'https://$rawBaseUrl';
                    final effectivePdfUrl = (customPdf != null && customPdf.trim().isNotEmpty)
                        ? (customPdf.startsWith('http') ? customPdf : '$baseUrl$customPdf')
                        : '$baseUrl/v1/api/auth/prescriptions/$prescriptionId/pdf';

                    InAppDocumentViewer.show(
                      context,
                      title: '$docName - Prescription',
                      category: 'Prescription',
                      fileUrl: effectivePdfUrl,
                      hospitalName: 'Prescription Document',
                      isAppointmentDoc: true,
                    );
                  },
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<MedicationBloc, MedicationState>(
          builder: (context, state) {
            final data = state.selectedPrescriptionDetail ?? initialData;

            if (data == null && (state.status == MedicationStatus.loading || state.status == MedicationStatus.initial)) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            if (data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 54,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Prescription details not found",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }

            final List medications = data['medications'] as List? ?? [];

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Unified Prescription Overview Card ──
                  _buildPrescriptionOverviewCard(context, data, isDark),

                  const SizedBox(height: 18),

                  // ── Prescribed Medicines (Exclusively shown here with 3D Pill Icon) ──
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/dashboard_icons/pill_prescriptions_thick.png',
                        width: 26,
                        height: 26,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.medication_rounded,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Prescribed Medicines (${medications.length})",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (medications.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2430) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "No medications listed for this prescription.",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ...medications.map((med) => _buildMedicationCard(
                          context,
                          Map<String, dynamic>.from(med),
                          isDark,
                          doctorName: _cleanDoctorName((data['doctor'] ?? '').toString()),
                          doctorPhoto: (data['doctorPhoto'] ?? '').toString(),
                          condition: (data['condition'] ?? '').toString(),
                        )),

                  const SizedBox(height: 14),

                  // ── Doctor Notes & Advice ──
                  Row(
                    children: [
                      const Icon(
                        Icons.speaker_notes_outlined,
                        color: primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Physician Advice & Notes",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildNotesBox(context, (data['notes'] ?? 'Follow-up as advised. Take medicines as prescribed.').toString(), isDark),

                  const SizedBox(height: 20),

                  // ── Full Prescription PDF Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text(
                        "View Full Prescription (PDF)",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      onPressed: () {
                        final rawBaseUrl = EnvironmentService.config.accountBaseUrl;
                        final baseUrl = rawBaseUrl.startsWith('http') ? rawBaseUrl : 'https://$rawBaseUrl';
                        final effectivePdfUrl = '$baseUrl/v1/api/auth/prescriptions/$prescriptionId/pdf';

                        InAppDocumentViewer.show(
                          context,
                          title: 'Digital Prescription',
                          category: 'Prescription',
                          fileUrl: effectivePdfUrl,
                          hospitalName: 'Yira Super Speciality Hospitals',
                          isAppointmentDoc: true,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPrescriptionOverviewCard(BuildContext context, Map<String, dynamic> data, bool isDark) {
    final String rawDoc = (data['doctor'] ?? 'Consulting Doctor').toString();
    final String rawSpecialty = (data['specialty'] ?? 'General Medicine').toString();
    final String date = (data['date'] ?? 'Recent').toString();
    final String pharmacy = (data['pharmacy'] ?? 'Yira Clinx E-Pharmacy').toString();
    final String condition = (data['condition'] ?? 'General Consultation').toString();

    final String docName = _cleanDoctorName(rawDoc);
    final String specialty = _cleanSpecialty(rawSpecialty, rawDoc);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2430) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Profile row with Digital Rx badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DoctorAvatarWidget(
                photoUrl: (data['doctorPhoto'] ?? '').toString(),
                doctorName: docName,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      docName,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      style: const TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 12, color: primaryColor),
                    SizedBox(width: 4),
                    Text(
                      "Digital Rx",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 10),

          // Metadata Grid: Diagnosis & Appointment Taken
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.healing_rounded, size: 14, color: primaryColor),
                    const SizedBox(width: 6),
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.event_available_rounded, size: 14, color: isDark ? Colors.white54 : const Color(0xFF0EA5E9)),
                    const SizedBox(width: 6),
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

          const SizedBox(height: 8),

          // Pharmacy & Facility info
          Row(
            children: [
              Icon(
                Icons.local_pharmacy_outlined,
                size: 13,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
              const SizedBox(width: 5),
              Text(
                "Pharmacy: ",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              Text(
                pharmacy,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(
    BuildContext context,
    Map<String, dynamic> med,
    bool isDark, {
    String? doctorName,
    String? doctorPhoto,
    String? condition,
  }) {
    final String name = (med['name'] ?? 'Medication').toString();
    final String rawDosage = (med['dosage'] ?? '').toString();
    final String freq = (med['frequency'] ?? '').toString();
    final String instructions = (med['instructions'] ?? 'Take as directed by doctor').toString();
    final String duration = (med['duration'] ?? '7 Days').toString();
    final String scheduleText = _cleanSchedule(rawDosage, freq);

    // Extract meal timing if mentioned
    String mealTag = '';
    final lowerInst = instructions.toLowerCase();
    if (lowerInst.contains('after food') || lowerInst.contains('after meal')) {
      mealTag = 'After Food';
    } else if (lowerInst.contains('before food') || lowerInst.contains('before meal')) {
      mealTag = 'Before Food';
    } else if (lowerInst.contains('with food') || lowerInst.contains('with meal')) {
      mealTag = 'With Food';
    } else if (lowerInst.contains('empty stomach')) {
      mealTag = 'Empty Stomach';
    } else if (lowerInst.contains('bedtime') || lowerInst.contains('at night')) {
      mealTag = 'At Bedtime';
    }

    final bool showCustomInstructions = instructions.isNotEmpty &&
        instructions.toLowerCase() != 'take as directed by doctor' &&
        (mealTag.isEmpty || instructions.toLowerCase().trim() != mealTag.toLowerCase());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2430) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3447) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Medicine Header: 3D Pill Icon + Name & Status ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Image.asset(
                  'assets/images/dashboard_icons/pill_prescriptions_thick.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.medication_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Prescribed Medication",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Administration Schedule & Timing Badges ──
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 12, color: primaryColor),
                    const SizedBox(width: 4.5),
                    Text(
                      scheduleText,
                      style: const TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (mealTag.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restaurant_rounded, size: 12, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 4.5),
                      Text(
                        mealTag,
                        style: const TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),
              if (duration.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 11.5, color: Color(0xFF0EA5E9)),
                      const SizedBox(width: 4.5),
                      Text(
                        duration,
                        style: const TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0EA5E9),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (showCustomInstructions) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151C28) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFEEF2F6),
                  width: 0.8,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      instructions,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (doctorName != null && doctorName.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFEDF2F7),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  DoctorAvatarWidget(
                    photoUrl: doctorPhoto,
                    doctorName: doctorName,
                    size: 20,
                    borderRadius: 6,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Prescribed by $doctorName",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── Convert to Medication reminder button / status badge ──
          ValueListenableBuilder<List<MedicationReminder>>(
            valueListenable: MedicationReminderService.instance.remindersNotifier,
            builder: (context, reminders, _) {
              final isConverted = MedicationReminderService.instance.isMedicineConverted(prescriptionId, name);
              final activeReminder = MedicationReminderService.instance.getReminderForMedicine(prescriptionId, name);

              if (isConverted) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      width: 0.9,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Icon(Icons.alarm_on_rounded, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          "Daily Alarm Active",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _confirmStopReminder(context, activeReminder, name),
                        borderRadius: BorderRadius.circular(7),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.alarm_off_rounded, size: 13, color: Colors.redAccent),
                              SizedBox(width: 4),
                              Text(
                                "Stop Alarm",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ConvertTabletSheet.show(
                      context,
                      medicineName: name,
                      dosage: scheduleText,
                      initialInstructions: instructions,
                      prescriptionId: prescriptionId,
                      doctorName: doctorName,
                      doctorPhoto: doctorPhoto,
                      condition: condition,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_alarm_rounded, size: 16),
                  label: const Text(
                    "Set Daily Medication Alarm",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesBox(BuildContext context, String notes, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2430) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes_rounded, size: 16, color: primaryColor),
              const SizedBox(width: 6),
              Text(
                "Doctor's Advice & Instructions",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              height: 1.5,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmStopReminder(BuildContext context, MedicationReminder? reminder, String medicineName) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.alarm_off_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text(
              "Stop Alarm?",
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to stop the daily medication alarm for $medicineName?",
          style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Keep Active",
              style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (reminder != null) {
                await MedicationReminderService.instance.deleteReminder(reminder.id);
              } else {
                await MedicationReminderService.instance.deleteMedicineReminder(prescriptionId, medicineName);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Alarm reminder stopped for $medicineName"),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF334155),
                  ),
                );
              }
            },
            child: const Text(
              "Stop Alarm",
              style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
