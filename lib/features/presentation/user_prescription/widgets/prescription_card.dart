import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/in_app_document_viewer.dart';
import '../../../../core/api/base_api_configuration.dart';
import '../../../../core/widgets/doctor_avatar_widget.dart';
import '../prescription_details_screen.dart';
import '../../patient/diet/diet_ui.dart';

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
            'pdfUrl': pdfUrl,
            'isSelf': isSelf,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTab = isTablet(context);
    final names = medications
        .map((m) => (m['name'] ?? '').toString().trim())
        .where((n) => n.isNotEmpty)
        .toList();
    const preview = 3;
    final shown = names.take(preview).toList();
    final more = names.length - shown.length;
    final medCount = medications.length;

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
                    // Doctor and date
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: DietUi.text(isTab ? 15.5 : 14.5, FontWeight.w700, DietUi.strong(isDark), height: 1.25),
                              ),
                              if (_specialtyOnly.isNotEmpty)
                                Text(
                                  _specialtyOnly,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isSelf) ...[
                          DietUi.pill('Self Added', const Color(0xFF6366F1), isDark),
                          const SizedBox(width: 6),
                        ],
                        DietUi.pill(_shortDate(date), primaryColor, isDark, icon: Icons.event_rounded),
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
                        children: [
                          const Icon(Icons.healing_rounded, size: 15, color: primaryColor),
                          const SizedBox(width: 8),
                          Text('Diagnosis', style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              condition,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DietUi.text(12.5, FontWeight.w600, DietUi.strong(isDark)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Medicines
                    if (shown.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final name in shown)
                            Container(
                              constraints: const BoxConstraints(maxWidth: 220),
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.medication_rounded, size: 13, color: primaryColor),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: DietUi.text(11.5, FontWeight.w600, isDark ? Colors.white : const Color(0xFF1E3A8A)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (more > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: DietUi.sunken(isDark),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: DietUi.line(isDark)),
                              ),
                              child: Text('+$more more', style: DietUi.text(11.5, FontWeight.w600, DietUi.muted(isDark))),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Footer: count, PDF and details
              Divider(height: 1, color: DietUi.line(isDark)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
                child: Row(
                  children: [
                    Icon(Icons.medication_outlined, size: 15, color: DietUi.hint(isDark)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        medCount == 0 ? 'No medicines listed' : '$medCount medicine${medCount == 1 ? '' : 's'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
                      ),
                    ),
                    if (isSelf && onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                        label: Text('Remove', style: DietUi.text(12, FontWeight.w600, const Color(0xFFEF4444))),
                      ),
                    if (_hasPdf)
                      TextButton.icon(
                        onPressed: () => _openPdf(context),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF059669),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                        label: Text('PDF', style: DietUi.text(12, FontWeight.w700, const Color(0xFF059669))),
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
                          const Icon(Icons.chevron_right_rounded, size: 18),
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
