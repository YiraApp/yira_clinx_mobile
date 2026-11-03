import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/in_app_document_viewer.dart';
import '../../../../core/api/base_api_configuration.dart';
import '../../../../core/widgets/doctor_avatar_widget.dart';
import '../prescription_details_screen.dart';
import '../../patient/diet/diet_ui.dart';
import '../../patient_profile/widgets/record_tab_ui.dart';
import '../../../domain/entities/prescriptions/lab_test_entity.dart';
import 'package:yiraclinics/core/widgets/phosphor_icons.dart';

class PrescriptionCard extends StatelessWidget {
  final String id;
  final String title;
  final String condition;
  final String doctor;
  final String specialty;
  final String? doctorPhoto;
  final String date;
  final String status;
  final String pharmacy;
  final List<Map<String, dynamic>> medications;
  final List<PrescribedLabTest> labTests;
  final String? pdfUrl;
  final bool isSelf;
  final VoidCallback? onDelete;

  const PrescriptionCard({
    super.key,
    required this.id,
    required this.title,
    required this.condition,
    required this.doctor,
    required this.specialty,
    this.doctorPhoto,
    required this.date,
    required this.status,
    required this.pharmacy,
    required this.medications,
    this.labTests = const [],
    this.pdfUrl,
    this.isSelf = false,
    this.onDelete,
  });

  String get _doctorNameOnly {
    String name = doctor;
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

  /// "15 Oct" this year, "15 Oct 2025" otherwise, so the doctor's name has room.
  String _shortDate(String raw) {
    final dt = DateTime.tryParse(raw.trim());
    if (dt == null) return raw.trim().isEmpty ? 'Recent' : raw.trim();
    return DateFormat(dt.year == DateTime.now().year ? 'd MMM' : 'd MMM yyyy').format(dt);
  }

  bool get _hasPdf =>
      pdfUrl != null &&
      pdfUrl!.trim().isNotEmpty &&
      pdfUrl!.trim().toLowerCase() != 'null';

  void _openPdf(BuildContext context) {
    if (!_hasPdf) return;
    final rawBaseUrl = EnvironmentService.config.accountBaseUrl;
    final baseUrl = rawBaseUrl.startsWith('http') ? rawBaseUrl : 'https://$rawBaseUrl';
    final effectivePdfUrl = (pdfUrl != null && pdfUrl!.trim().isNotEmpty)
        ? (pdfUrl!.startsWith('http') ? pdfUrl! : '$baseUrl$pdfUrl')
        : '$baseUrl/v1/api/auth/prescriptions/$id/pdf';

    InAppDocumentViewer.show(
      context,
      title: _doctorNameOnly.isNotEmpty ? '$_doctorNameOnly - Prescription' : 'Digital Prescription',
      category: 'Prescription',
      fileUrl: effectivePdfUrl,
      hospitalName: _specialtyOnly.isNotEmpty ? _specialtyOnly : 'Yira Super Speciality Hospitals',
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
            'doctorPhoto': doctorPhoto,
            'date': date,
            'status': status,
            'pharmacy': pharmacy,
            'medications': medications,
            'labTests': labTests,
            'pdfUrl': pdfUrl,
            'isSelf': isSelf,
          },
        ),
      ),
    );
  }

  /// "1-0-1 · 5 Days" style summary of how to take a medicine.
  String _howToTake(Map<String, dynamic> m) {
    final freq = (m['frequency'] ?? '').toString().trim();
    var dosage = (m['dosage'] ?? '').toString().trim();
    if (freq.isNotEmpty && dosage.endsWith(' - $freq')) {
      dosage = dosage.substring(0, dosage.length - freq.length - 3).trim();
    }
    final duration = (m['duration'] ?? '').toString().trim();
    return [dosage, freq, duration].where((p) => p.isNotEmpty).toSet().join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTab = isTablet(context);
    final meds = medications
        .where((m) => (m['name'] ?? '').toString().trim().isNotEmpty)
        .toList();
    const preview = 3;
    final shown = meds.take(preview).toList();
    final more = meds.length - shown.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: DietUi.cardDecoration(isDark),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDetails(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Who prescribed it and when
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DoctorAvatarWidget(photoUrl: doctorPhoto, doctorName: _doctorNameOnly, size: isTab ? 46 : 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _doctorNameOnly,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: DietUi.text(isTab ? 15.5 : 14.5, FontWeight.w700, DietUi.strong(isDark), height: 1.25),
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (_specialtyOnly.isNotEmpty)
                                    Text(
                                      _specialtyOnly,
                                      style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
                                    ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PhosphorIcon(PhosphorIconsBold.calendarBlank, size: 13, color: DietUi.hint(isDark)),
                                      const SizedBox(width: 3),
                                      Text(_shortDate(date), style: DietUi.text(11.5, FontWeight.w600, DietUi.muted(isDark))),
                                    ],
                                  ),
                                  if (isSelf) DietUi.pill('Added by you', const Color(0xFF6366F1), isDark),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Diagnosis
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: DietUi.sunken(isDark),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DietUi.line(isDark)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: PhosphorIcon(PhosphorIconsBold.stethoscope, size: 15, color: primaryColor),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: 'Diagnosis  ', style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark))),
                                  TextSpan(text: condition, style: DietUi.text(12.5, FontWeight.w600, DietUi.strong(isDark))),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Medicines, one per line with how to take them
                    if (shown.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'MEDICINES · ${meds.length}',
                        style: DietUi.text(10.5, FontWeight.w700, DietUi.muted(isDark)).copyWith(letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 6),
                      for (final m in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const PhosphorIcon(PhosphorIconsBold.pill, size: 15, color: primaryColor),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (m['name'] ?? '').toString().trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: DietUi.text(12.5, FontWeight.w600, DietUi.strong(isDark)),
                                    ),
                                    if (_howToTake(m).isNotEmpty)
                                      Text(
                                        _howToTake(m),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark)),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (more > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 36),
                          child: Text(
                            '+ $more more medicine${more == 1 ? '' : 's'}',
                            style: DietUi.text(11.5, FontWeight.w600, primaryColor),
                          ),
                        ),
                    ] else if (labTests.isEmpty) ...[
                      const SizedBox(height: 10),
                      Text('No medicines listed', style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark))),
                    ],

                    // Lab tests the doctor ordered
                    if (labTests.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'LAB TESTS · ${labTests.length}',
                        style: DietUi.text(10.5, FontWeight.w700, DietUi.muted(isDark)).copyWith(letterSpacing: 0.6),
                      ),
                      const SizedBox(height: 6),
                      RecordLabTestLines(tests: labTests, limit: preview),
                    ],
                  ],
                ),
              ),

              // Actions
              Divider(height: 1, color: DietUi.line(isDark)),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
                child: Row(
                  children: [
                    if (isSelf && onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const PhosphorIcon(PhosphorIconsBold.trash, size: 15, color: Color(0xFFEF4444)),
                        label: Text('Remove', style: DietUi.text(12, FontWeight.w600, const Color(0xFFEF4444))),
                      ),
                    const Spacer(),
                    if (_hasPdf)
                      TextButton.icon(
                        onPressed: () => _openPdf(context),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF059669),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const PhosphorIcon(PhosphorIconsBold.filePdf, size: 15),
                        label: Text('View PDF', style: DietUi.text(12, FontWeight.w700, const Color(0xFF059669))),
                      ),
                    TextButton(
                      onPressed: () => _navigateToDetails(context),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View details', style: DietUi.text(12, FontWeight.w700, primaryColor)),
                          const SizedBox(width: 2),
                          const PhosphorIcon(PhosphorIconsBold.caretRight, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
