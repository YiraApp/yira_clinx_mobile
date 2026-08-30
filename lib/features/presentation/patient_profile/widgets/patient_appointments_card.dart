import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/common_widgets/in_app_document_viewer.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/utils.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';

class PatientAppointmentsCard extends StatelessWidget {
  final List<PatientAppointmentEntity> appointments;
  final bool isTab;
  final PatientProfileEntity? patient;
  final VoidCallback? onPrescribeTap;
  final VoidCallback? onNoteTap;

  const PatientAppointmentsCard({
    super.key,
    required this.appointments,
    required this.isTab,
    this.patient,
    this.onPrescribeTap,
    this.onNoteTap,
  });

  // ═══════════════════════════════════════════════
  //  STATUS COLORS
  // ═══════════════════════════════════════════════

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case "COMPLETED":
        return const Color(0xFF10B981);
      case "CONFIRMED":
        return const Color(0xFF2563EB);
      case "IN PROGRESS":
      case "IN_PROGRESS":
        return const Color(0xFF8B5CF6);
      case "CANCELLED":
        return const Color(0xFFEF4444);
      case "PENDING":
      case "PAYMENT PENDING":
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF0284C7);
    }
  }

  // ═══════════════════════════════════════════════
  //  1️⃣ PRESCRIPTION DETAIL SHEET
  // ═══════════════════════════════════════════════

  void _viewPrescriptionDetails(
    BuildContext context,
    AppointmentPrescriptionEntity pres,
    bool isDark,
    Color primaryColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 25,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEC4899).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.medication_liquid_rounded,
                              color: Color(0xFFEC4899),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Prescription Details",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontWeight: FontWeight.w700,
                                  fontSize: isTab ? 17 : 16,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                pres.date.isNotEmpty ? "Date: ${pres.date}" : "ID: ${pres.id}",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 11.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (pres.doctorName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pres.doctorName,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pres.diagnoses.isNotEmpty) ...[
                      Text(
                        "DIAGNOSES",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: pres.diagnoses
                            .map((d) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    "🩺 ${d.name}${d.icd10.isNotEmpty ? ' (${d.icd10})' : ''}",
                                    style: const TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Text(
                      "MEDICATIONS (${pres.medications.length})",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (pres.medications.isNotEmpty)
                      ...pres.medications.map((m) => Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.name,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    if (m.dosage.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEC4899).withValues(alpha: isDark ? 0.2 : 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          m.dosage,
                                          style: const TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFEC4899),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (m.frequency.isNotEmpty) ...[
                                      Icon(Icons.schedule, size: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        m.frequency,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11.5,
                                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    if (m.duration.isNotEmpty) ...[
                                      Icon(Icons.timelapse, size: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        m.duration,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11.5,
                                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (m.instructions.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      "Instructions: ${m.instructions}",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ))
                    else
                      Text(
                        "No specific medicines listed.",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    if (pres.notes.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        "DOCTOR NOTES",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pres.notes,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (onPrescribeTap != null)
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            onPrescribeTap?.call();
                          },
                          icon: Icon(Icons.arrow_forward_rounded, size: 16, color: primaryColor),
                          label: Text(
                            "Open in Prescriptions Tab",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  2️⃣ CLINICAL NOTE DETAIL SHEET
  // ═══════════════════════════════════════════════

  void _viewClinicalNoteDetails(
    BuildContext context,
    AppointmentClinicalNoteEntity note,
    bool isDark,
    Color primaryColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Color(0xFF06B6D4), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.doctorName.isNotEmpty ? note.doctorName : "Clinical Note",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (note.createdAt.isNotEmpty)
                        Text(
                          "Recorded on: ${note.createdAt}",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: "Copy Note",
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: note.notes));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Clinical note copied to clipboard")),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                note.notes.isNotEmpty ? note.notes : "No note content recorded.",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (onNoteTap != null)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onNoteTap?.call();
                  },
                  icon: Icon(Icons.arrow_forward_rounded, size: 16, color: primaryColor),
                  label: Text(
                    "Open in Notes Tab",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  3️⃣ DOCUMENT DETAIL SHEET
  // ═══════════════════════════════════════════════

  void _viewDocumentDetails(
    BuildContext context,
    AppointmentDocumentEntity doc,
    bool isDark,
    Color primaryColor,
  ) {
    final String url = doc.fileUrl.trim();
    final String lower = (url.isNotEmpty ? url : doc.fileName).toLowerCase();

    final bool isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');

    if (isImage && url.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogCtx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogCtx).size.height * 0.85,
              maxWidth: MediaQuery.of(dialogCtx).size.width * 0.95,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.fileName.isNotEmpty ? doc.fileName : "Document Image",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "${doc.category} • ${doc.type}",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      color: Colors.black,
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 5.0,
                        child: Center(
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: primaryColor,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Could not load image preview",
                                    style: TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () => Utils.launchURL(url),
                                    child: const Text("Open in Browser"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          doc.createdAt.isNotEmpty ? "Uploaded: ${doc.createdAt}" : "",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => Utils.launchURL(url),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text("Open External"),
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
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 25,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF8B5CF6), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.fileName.isNotEmpty ? doc.fileName : "Medical Document",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "${doc.category} • ${doc.type}",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildGridRow([
                    _buildInfoTile(
                      label: "Document Type",
                      value: doc.type.isNotEmpty ? doc.type : "Lab / Clinical Report",
                      icon: Icons.category_outlined,
                      isDark: isDark,
                    ),
                    _buildInfoTile(
                      label: "Category",
                      value: doc.category.isNotEmpty ? doc.category : "General",
                      icon: Icons.folder_outlined,
                      isDark: isDark,
                    ),
                  ]),
                  if (doc.createdAt.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildInfoTile(
                      label: "Upload Date",
                      value: doc.createdAt,
                      icon: Icons.calendar_today_outlined,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (url.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    InAppDocumentViewer.show(
                      context,
                      title: doc.fileName.isNotEmpty ? doc.fileName : "Medical Document",
                      category: doc.category.isNotEmpty ? doc.category : "General",
                      fileUrl: url,
                      fileType: doc.type.isNotEmpty ? doc.type : "PDF",
                      date: doc.createdAt,
                      isAppointmentDoc: true,
                    );
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text(
                    "View Document",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                alignment: Alignment.center,
                child: Text(
                  "No electronic document file attached.",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  4️⃣ MEDICAL RECORD DETAIL SHEET
  // ═══════════════════════════════════════════════

  void _viewMedicalRecordDetails(
    BuildContext context,
    AppointmentMedicalRecordEntity rec,
    bool isDark,
    Color primaryColor,
  ) {
    final String url = rec.fileUrl.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment_outlined, color: Color(0xFF10B981), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.recordType.isNotEmpty ? rec.recordType : "Medical Record",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (rec.createdAt.isNotEmpty)
                        Text(
                          "Recorded on: ${rec.createdAt}",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (url.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    InAppDocumentViewer.show(
                      context,
                      title: rec.recordType.isNotEmpty ? rec.recordType : "Medical Record",
                      category: "Medical Record",
                      fileUrl: url,
                      fileType: "PDF",
                      date: rec.createdAt,
                      isAppointmentDoc: true,
                    );
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: const Text(
                    "View Medical Record",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  5️⃣ FULL APPOINTMENT DETAIL SHEET
  // ═══════════════════════════════════════════════

  void _showAppointmentDetailSheet(
    BuildContext context,
    PatientAppointmentEntity appt,
    bool isDark,
    Color primaryColor,
  ) {
    final statusColor = _getStatusColor(appt.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.92,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 25,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  appt.isTeleConsultation
                                      ? Icons.videocam_rounded
                                      : Icons.calendar_month_rounded,
                                  color: primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Appointment Details",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontWeight: FontWeight.w700,
                                        fontSize: isTab ? 18 : 16.5,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      appt.tokenNumber.isNotEmpty
                                          ? "Token #${appt.tokenNumber} • ID: ${appt.id}"
                                          : "Appointment ID: ${appt.id}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            appt.status.toUpperCase(),
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1️⃣ SCHEDULE & TIMING
                      _buildSectionHeader(
                        number: "1",
                        title: "Schedule & Timing",
                        icon: Icons.access_time_rounded,
                        color: const Color(0xFF3B82F6),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoContainer(
                        isDark: isDark,
                        children: [
                          _buildGridRow([
                            _buildInfoTile(
                              label: "Appointment Date",
                              value: appt.appointmentDate.isNotEmpty ? appt.appointmentDate : "Not Set",
                              icon: Icons.calendar_today_outlined,
                              isDark: isDark,
                            ),
                            _buildInfoTile(
                              label: "Slot Timing",
                              value: appt.startTime.isNotEmpty
                                  ? (appt.endTime.isNotEmpty ? "${appt.startTime} - ${appt.endTime}" : appt.startTime)
                                  : "Unscheduled",
                              icon: Icons.schedule_outlined,
                              isDark: isDark,
                            ),
                          ]),
                          const SizedBox(height: 10),
                          _buildGridRow([
                            _buildInfoTile(
                              label: "Duration",
                              value: appt.duration.isNotEmpty ? appt.duration : "15 mins",
                              icon: Icons.timelapse_outlined,
                              isDark: isDark,
                            ),
                            _buildInfoTile(
                              label: "Token Number",
                              value: appt.tokenNumber.isNotEmpty ? "#${appt.tokenNumber}" : "General Queue",
                              icon: Icons.confirmation_number_outlined,
                              isDark: isDark,
                            ),
                          ]),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 2️⃣ CLINICAL CONDITION & REASON
                      _buildSectionHeader(
                        number: "2",
                        title: "Clinical Condition & Reason",
                        icon: Icons.healing_rounded,
                        color: const Color(0xFFF59E0B),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoContainer(
                        isDark: isDark,
                        children: [
                          _buildInfoTile(
                            label: "Chief Complaint / Condition",
                            value: appt.condition.isNotEmpty ? appt.condition : "General Consultation",
                            icon: Icons.medical_services_outlined,
                            isDark: isDark,
                            valueStyle: TextStyle(
                              fontFamily: appPoppinFont,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                            ),
                          ),
                          if (appt.reason.isNotEmpty && appt.reason != appt.condition) ...[
                            const SizedBox(height: 10),
                            _buildInfoTile(
                              label: "Reason for Visit",
                              value: appt.reason,
                              icon: Icons.notes_outlined,
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 3️⃣ PRESCRIPTIONS
                      _buildSectionHeader(
                        number: "3",
                        title: "Prescriptions (${appt.prescriptions.length})",
                        icon: Icons.medication_liquid_rounded,
                        color: const Color(0xFFEC4899),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      if (appt.prescriptions.isNotEmpty)
                        ...appt.prescriptions.map((p) => _buildPrescriptionCard(
                              context,
                              p,
                              isDark,
                              primaryColor,
                            ))
                      else
                        _buildEmptyTile("No prescriptions issued for this appointment", Icons.medication_outlined, isDark),

                      const SizedBox(height: 18),

                      // 4️⃣ CLINICAL NOTES
                      _buildSectionHeader(
                        number: "4",
                        title: "Clinical Notes (${appt.clinicalNotes.length})",
                        icon: Icons.edit_note_rounded,
                        color: const Color(0xFF06B6D4),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      if (appt.clinicalNotes.isNotEmpty)
                        ...appt.clinicalNotes.map((n) => _buildClinicalNoteCard(
                              context,
                              n,
                              isDark,
                              primaryColor,
                            ))
                      else if (appt.notes.isNotEmpty)
                        _buildInfoContainer(
                          isDark: isDark,
                          children: [
                            _buildInfoTile(
                              label: "Appointment Notes",
                              value: appt.notes,
                              icon: Icons.note_outlined,
                              isDark: isDark,
                            ),
                          ],
                        )
                      else
                        _buildEmptyTile("No clinical notes recorded for this appointment", Icons.edit_note_outlined, isDark),

                      const SizedBox(height: 18),

                      // 5️⃣ DOCUMENTS & LAB REPORTS
                      _buildSectionHeader(
                        number: "5",
                        title: "Documents & Reports (${appt.documents.length})",
                        icon: Icons.folder_shared_outlined,
                        color: const Color(0xFF8B5CF6),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      if (appt.documents.isNotEmpty)
                        ...appt.documents.map((d) => _buildDocumentCard(
                              context,
                              d,
                              isDark,
                              primaryColor,
                            ))
                      else
                        _buildEmptyTile("No medical documents attached to this appointment", Icons.file_present_outlined, isDark),

                      const SizedBox(height: 18),

                      // 6️⃣ MEDICAL RECORDS
                      _buildSectionHeader(
                        number: "6",
                        title: "Medical Records & Diagnoses (${appt.medicalRecords.length})",
                        icon: Icons.assignment_outlined,
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      if (appt.medicalRecords.isNotEmpty)
                        ...appt.medicalRecords.map((r) => _buildMedicalRecordCard(
                              context,
                              r,
                              isDark,
                              primaryColor,
                            ))
                      else
                        _buildEmptyTile("No separate medical records linked to this appointment", Icons.assignment_turned_in_outlined, isDark),

                      const SizedBox(height: 18),

                      // 7️⃣ PROVIDER & FACILITY DETAILS
                      _buildSectionHeader(
                        number: "7",
                        title: "Provider & Facility",
                        icon: Icons.local_hospital_outlined,
                        color: const Color(0xFF64748B),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoContainer(
                        isDark: isDark,
                        children: [
                          _buildGridRow([
                            _buildInfoTile(
                              label: "Consulting Doctor",
                              value: appt.doctorName.isNotEmpty ? appt.doctorName : "Assigned Physician",
                              icon: Icons.health_and_safety_outlined,
                              isDark: isDark,
                            ),
                            _buildInfoTile(
                              label: "Mode",
                              value: appt.appointmentType,
                              icon: appt.isTeleConsultation
                                  ? Icons.videocam_outlined
                                  : Icons.domain_outlined,
                              isDark: isDark,
                            ),
                          ]),
                          if (appt.hospitalName.isNotEmpty || appt.location.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildGridRow([
                              _buildInfoTile(
                                label: "Hospital / Clinic",
                                value: appt.hospitalName.isNotEmpty ? appt.hospitalName : appt.location,
                                icon: Icons.location_city_outlined,
                                isDark: isDark,
                              ),
                              if (appt.hospitalPhone.isNotEmpty)
                                _buildInfoTile(
                                  label: "Helpline",
                                  value: appt.hospitalPhone,
                                  icon: Icons.phone_in_talk_outlined,
                                  isDark: isDark,
                                ),
                            ]),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            "Done",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  //  SUB-CARD BUILDERS (Detail Sheet)
  // ═══════════════════════════════════════════════

  Widget _buildPrescriptionCard(
    BuildContext context,
    AppointmentPrescriptionEntity pres,
    bool isDark,
    Color primaryColor,
  ) {
    return InkWell(
      onTap: () => _viewPrescriptionDetails(context, pres, isDark, primaryColor),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medication_liquid_rounded, size: 16, color: Color(0xFFEC4899)),
                    const SizedBox(width: 6),
                    Text(
                      "Prescription • ${pres.date}",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "View Details",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: primaryColor),
                  ],
                ),
              ],
            ),
            if (pres.diagnoses.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: pres.diagnoses
                    .map((d) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "🩺 ${d.name}${d.icd10.isNotEmpty ? ' (${d.icd10})' : ''}",
                            style: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
            if (pres.medications.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...pres.medications.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.circle, size: 6, color: Color(0xFFEC4899)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.name,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                [
                                  if (m.dosage.isNotEmpty) m.dosage,
                                  if (m.frequency.isNotEmpty) m.frequency,
                                  if (m.duration.isNotEmpty) m.duration,
                                ].join(" • "),
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalNoteCard(
    BuildContext context,
    AppointmentClinicalNoteEntity note,
    bool isDark,
    Color primaryColor,
  ) {
    return InkWell(
      onTap: () => _viewClinicalNoteDetails(context, note, isDark, primaryColor),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF06B6D4)),
                    const SizedBox(width: 6),
                    Text(
                      note.doctorName.isNotEmpty ? note.doctorName : "Doctor's Note",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "Read Note",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: primaryColor),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              note.notes,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    AppointmentDocumentEntity doc,
    bool isDark,
    Color primaryColor,
  ) {
    return InkWell(
      onTap: () => _viewDocumentDetails(context, doc, isDark, primaryColor),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_outlined, color: Color(0xFF8B5CF6), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    "${doc.category} • ${doc.type}${doc.createdAt.isNotEmpty ? ' • ${doc.createdAt}' : ''}",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  "View",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.open_in_new_rounded, size: 12, color: primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalRecordCard(
    BuildContext context,
    AppointmentMedicalRecordEntity rec,
    bool isDark,
    Color primaryColor,
  ) {
    return InkWell(
      onTap: () => _viewMedicalRecordDetails(context, rec, isDark, primaryColor),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.assignment_outlined, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.recordType,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (rec.createdAt.isNotEmpty)
                    Text(
                      "Recorded on: ${rec.createdAt}",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 10.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  "View",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.open_in_new_rounded, size: 12, color: primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  REUSABLE HELPER WIDGETS
  // ═══════════════════════════════════════════════

  Widget _buildEmptyTile(String text, IconData icon, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.3) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white38 : Colors.grey.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11.5,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String number,
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: isTab ? 13.5 : 12.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoContainer({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildGridRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((c) => Expanded(child: c)).toList(),
    );
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    TextStyle? valueStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: valueStyle ??
              TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  //  MAIN BUILD — TIMELINE CARD LAYOUT
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    if (appointments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withValues(alpha: 0.15),
                    primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.event_busy_rounded, size: 28, color: primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              "No Appointments Found",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.w700,
                fontSize: isTab ? 16 : 15,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "No past or upcoming appointments\nrecorded for this patient.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12.5,
                height: 1.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final appt = appointments[index];
        final statusColor = _getStatusColor(appt.status);

        final int presCount = appt.prescriptions.length;
        final int notesCount = appt.clinicalNotes.length;
        final int docsCount = appt.documents.length;
        final int recsCount = appt.medicalRecords.length;
        final int totalRecords = presCount + notesCount + docsCount + recsCount;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAppointmentDetailSheet(context, appt, isDark, primaryColor),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.025),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Row: Date, Token & Status Badge ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (appt.tokenNumber.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  "#${appt.tokenNumber}",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                appt.appointmentDate.isNotEmpty
                                    ? appt.appointmentDate
                                    : "Appointment #${index + 1}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTab ? 14 : 13.5,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Clean status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: isDark ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              appt.status.toUpperCase(),
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // ── Second Row: Time & Type ──
                  Row(
                    children: [
                      if (appt.startTime.isNotEmpty) ...[
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 3.5),
                        Text(
                          appt.startTime,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                      Icon(
                        appt.isTeleConsultation
                            ? Icons.videocam_rounded
                            : Icons.location_on_rounded,
                        size: 12,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 3.5),
                      Expanded(
                        child: Text(
                          appt.appointmentType,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // ── Condition / Reason Box (if present) ──
                  if (appt.condition.isNotEmpty || appt.reason.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medical_services_rounded,
                            size: 13,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              appt.condition.isNotEmpty
                                  ? appt.condition
                                  : appt.reason,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.w500,
                                fontSize: 11.5,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Footer: Doctor Name & Attached Records ──
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Doctor name
                      if (appt.doctorName.isNotEmpty)
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 13,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  appt.doctorName,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Spacer(),

                      // Records summary (if any)
                      if (totalRecords > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                size: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$totalRecords ${totalRecords == 1 ? 'record' : 'records'}",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
