import 'package:flutter/material.dart';
import '../../../../core/utils/display_format.dart';
import 'package:flutter/services.dart';
import '../../../../core/common_widgets/in_app_document_viewer.dart';
import '../../../../core/api/base_api_configuration.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/utils/utils.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import '../../patient/diet/diet_ui.dart';
import 'record_tab_ui.dart';

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

  bool _isPatient() {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final roleName = (currentUser?.data?.latestUserRole ?? '').toLowerCase().trim();
    final roleId = (currentUser?.data?.latestRoleId ?? '').toUpperCase().trim();
    return roleName.contains('patient') ||
        roleName == 'user' ||
        roleId == '4FC67429-28AE-4106-93EF-436228282ED0';
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
          color: isDark ? const Color(0xFF232323) : Colors.white,
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
                  RecordCardHeader(
                    icon: Icons.medication_outlined,
                    title: "Prescription Details",
                    subtitle: [
                      _formatPrescriptionDateTime(pres),
                      if (pres.doctorName.isNotEmpty) pres.doctorName,
                    ].join(' · '),
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
                      const RecordSectionTitle(icon: Icons.medical_information_outlined, title: "Diagnoses"),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: pres.diagnoses.map((d) => RecordPill("${d.name}${d.icd10.isNotEmpty ? ' (${d.icd10})' : ''}")).toList(),
                      ),
                      const SizedBox(height: 18),
                    ],
                    RecordSectionTitle(icon: Icons.medication_outlined, title: "Medications (${pres.medications.length})"),
                    const SizedBox(height: 10),
                    if (pres.medications.isNotEmpty)
                      ...pres.medications.map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildInfoContainer(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(m.name, style: DietUi.text(13.5, FontWeight.w600, RecordUi.ink(isDark))),
                                    ),
                                    if (m.dosage.isNotEmpty) ...[const SizedBox(width: 8), RecordPill(m.dosage)],
                                  ],
                                ),
                                if (m.frequency.isNotEmpty || m.duration.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
                                      if (m.frequency.isNotEmpty) RecordMeta(icon: Icons.schedule, text: m.frequency),
                                      if (m.duration.isNotEmpty) RecordMeta(icon: Icons.timelapse, text: m.duration),
                                    ],
                                  ),
                                ],
                                if (m.instructions.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  RecordField(label: "Instructions", value: m.instructions),
                                ],
                              ],
                            ),
                          ))
                    else
                      Text(
                        "No specific medicines listed.",
                        style: DietUi.text(12, FontWeight.w400, DietUi.muted(isDark)),
                      ),
                    if (!_isPatient() && pres.notes.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      RecordField(label: "Doctor Notes", value: pres.notes),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: RecordPrimaryButton(
                        label: "View Full Prescription (PDF)",
                        icon: Icons.picture_as_pdf_outlined,
                        onPressed: () {
                          final rawBaseUrl = EnvironmentService.config.accountBaseUrl;
                          final baseUrl = rawBaseUrl.startsWith('http') ? rawBaseUrl : 'https://$rawBaseUrl';
                          final effectivePdfUrl = '$baseUrl/v1/api/auth/prescriptions/${pres.id}/pdf';

                          InAppDocumentViewer.show(
                            context,
                            title: pres.doctorName.isNotEmpty ? '${pres.doctorName} - Prescription' : 'Digital Prescription',
                            category: 'Prescription',
                            fileUrl: effectivePdfUrl,
                            hospitalName: 'Yira Super Speciality Hospitals',
                            isAppointmentDoc: true,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (onPrescribeTap != null)
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: RecordSecondaryButton(
                          label: "Open in Prescriptions Tab",
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () {
                            Navigator.pop(ctx);
                            onPrescribeTap?.call();
                          },
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
          color: isDark ? const Color(0xFF232323) : Colors.white,
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
            RecordCardHeader(
              icon: Icons.edit_note_rounded,
              title: note.doctorName.isNotEmpty ? note.doctorName : "Clinical Note",
              subtitle: note.createdAt.isNotEmpty ? "Recorded on: ${note.createdAt}" : null,
              trailing: RecordIconAction(
                icon: Icons.copy_rounded,
                tooltip: "Copy Note",
                onTap: () {
                  Clipboard.setData(ClipboardData(text: note.notes));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Clinical note copied to clipboard")),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoContainer(
              children: [
                Text(
                  note.notes.isNotEmpty ? note.notes : "No note content recorded.",
                  style: DietUi.text(13, FontWeight.w400, DietUi.body(isDark), height: 1.5),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (onNoteTap != null)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: RecordSecondaryButton(
                  label: "Open in Notes Tab",
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () {
                    Navigator.pop(ctx);
                    onNoteTap?.call();
                  },
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
              color: isDark ? const Color(0xFF121212) : Colors.white,
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
                    color: isDark ? const Color(0xFF232323) : const Color(0xFFF8FAFC),
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
                                "${doc.category} · ${doc.type}",
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
                    color: isDark ? const Color(0xFF232323) : const Color(0xFFF8FAFC),
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
          color: isDark ? const Color(0xFF232323) : Colors.white,
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
            RecordCardHeader(
              icon: Icons.description_outlined,
              title: doc.fileName.isNotEmpty ? doc.fileName : "Medical Document",
              subtitle: "${doc.category} · ${doc.type}",
            ),
            const SizedBox(height: 18),
            _buildInfoContainer(
              children: [
                _buildGridRow([
                  RecordField(label: "Document Type", value: doc.type.isNotEmpty ? doc.type : "Lab / Clinical Report"),
                  RecordField(label: "Category", value: doc.category.isNotEmpty ? doc.category : "General"),
                ]),
                if (doc.createdAt.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  RecordField(label: "Upload Date", value: doc.createdAt),
                ],
              ],
            ),
            const SizedBox(height: 20),
            if (url.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: RecordPrimaryButton(
                  label: "View Document",
                  icon: Icons.visibility_outlined,
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
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                alignment: Alignment.center,
                child: Text(
                  "No electronic document file attached.",
                  style: DietUi.text(12, FontWeight.w400, DietUi.muted(isDark)),
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
          color: isDark ? const Color(0xFF232323) : Colors.white,
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
            RecordCardHeader(
              icon: Icons.assignment_outlined,
              title: rec.recordType.isNotEmpty ? rec.recordType : "Medical Record",
              subtitle: rec.createdAt.isNotEmpty ? "Recorded on: ${rec.createdAt}" : null,
            ),
            const SizedBox(height: 20),
            if (url.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: RecordPrimaryButton(
                  label: "View Medical Record",
                  icon: Icons.visibility_outlined,
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
            color: isDark ? const Color(0xFF232323) : Colors.white,
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
                    RecordCardHeader(
                      icon: appt.isTeleConsultation ? Icons.videocam_outlined : Icons.calendar_month_outlined,
                      title: "Appointment Details",
                      subtitle: appt.tokenNumber.isNotEmpty
                          ? "Token #${appt.tokenNumber} · ID: ${appt.id}"
                          : "Appointment ID: ${appt.id}",
                    ),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerLeft, child: RecordStatusPill(humanizeStatus(appt.status))),
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
                      RecordSectionTitle(icon: Icons.access_time_rounded, title: "Schedule & Timing"),
                      const SizedBox(height: 10),
                      _buildInfoContainer(
                        children: [
                          _buildGridRow([
                            RecordField(
                              label: "Appointment Date",
                              value: appt.appointmentDate.isNotEmpty ? appt.appointmentDate : "Not Set",
                            ),
                            RecordField(
                              label: "Slot Timing",
                              value: appt.startTime.isNotEmpty
                                  ? (appt.endTime.isNotEmpty ? "${formatClockTime(appt.startTime)} - ${formatClockTime(appt.endTime)}" : formatClockTime(appt.startTime))
                                  : "Unscheduled",
                            ),
                          ]),
                          const SizedBox(height: 10),
                          _buildGridRow([
                            RecordField(
                              label: "Duration",
                              value: appt.duration.isNotEmpty ? appt.duration : "15 mins",
                            ),
                            RecordField(
                              label: "Token Number",
                              value: appt.tokenNumber.isNotEmpty ? "#${appt.tokenNumber}" : "General Queue",
                            ),
                          ]),
                          const SizedBox(height: 10),
                          _buildGridRow([
                            RecordField(
                              label: "Consultation Type",
                              value: appt.isTeleConsultation ? "Video Call (Zoom)" : "In-Clinic Visit",
                            ),
                            RecordField(
                              label: "Payment Mode",
                              value: appt.isTeleConsultation ? "Paid Online (Razorpay)" : "Pay at Clinic Reception",
                            ),
                          ]),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 2️⃣ CLINICAL CONDITION & REASON
                      RecordSectionTitle(icon: Icons.healing_rounded, title: "Clinical Condition & Reason"),
                      const SizedBox(height: 10),
                      _buildInfoContainer(
                        children: [
                          RecordField(
                            label: "Chief Complaint / Condition",
                            value: appt.condition.isNotEmpty ? appt.condition : "General Consultation",
                          ),
                          if (appt.reason.isNotEmpty && appt.reason != appt.condition) ...[
                            const SizedBox(height: 10),
                            RecordField(
                              label: "Reason for Visit",
                              value: appt.reason,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 3️⃣ PRESCRIPTIONS
                      RecordSectionTitle(icon: Icons.medication_liquid_rounded, title: "Prescriptions (${appt.prescriptions.length})"),
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

                      // 4️⃣ CLINICAL NOTES (Visible to Doctors only; hidden for Patients)
                      if (!_isPatient()) ...[
                        RecordSectionTitle(icon: Icons.edit_note_rounded, title: "Clinical Notes (${appt.clinicalNotes.length})"),
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
                            children: [
                              RecordField(
                                label: "Appointment Notes",
                                value: appt.notes,
                              ),
                            ],
                          )
                        else
                          _buildEmptyTile("No clinical notes recorded for this appointment", Icons.edit_note_outlined, isDark),
                        const SizedBox(height: 18),
                      ],

                      // 5️⃣ DOCUMENTS & LAB REPORTS
                      RecordSectionTitle(icon: Icons.folder_shared_outlined, title: "Documents & Reports (${appt.documents.length})"),
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
                      RecordSectionTitle(icon: Icons.assignment_outlined, title: "Medical Records & Diagnoses (${appt.medicalRecords.length})"),
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
                      RecordSectionTitle(icon: Icons.local_hospital_outlined, title: "Provider & Facility"),
                      const SizedBox(height: 10),
                      _buildInfoContainer(
                        children: [
                          _buildGridRow([
                            RecordField(
                              label: "Consulting Doctor",
                              value: appt.doctorName.isNotEmpty ? appt.doctorName : "Assigned Physician",
                            ),
                            RecordField(
                              label: "Mode",
                              value: appt.appointmentType,
                            ),
                          ]),
                          if (appt.hospitalName.isNotEmpty || appt.location.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildGridRow([
                              RecordField(
                                label: "Hospital / Clinic",
                                value: appt.hospitalName.isNotEmpty ? appt.hospitalName : appt.location,
                              ),
                              if (appt.hospitalPhone.isNotEmpty)
                                RecordField(
                                  label: "Helpline",
                                  value: appt.hospitalPhone,
                                ),
                            ]),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: RecordPrimaryButton(label: "Done", onPressed: () => Navigator.pop(ctx)),
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

  String _formatPrescriptionDateTime(AppointmentPrescriptionEntity pres) {
    final rawDate = pres.date.trim();
    final rawTime = pres.time.trim();

    // 1. If rawDate is an ISO datetime string or contains parseable date & time
    final parsed = DateTime.tryParse(rawDate);
    if (parsed != null) {
      final local = parsed.toLocal();
      const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      final datePart = "${months[local.month - 1]} ${local.day}, ${local.year}";

      String timePart = rawTime;
      if (timePart.isEmpty && (local.hour != 0 || local.minute != 0)) {
        final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
        final min = local.minute < 10 ? "0${local.minute}" : "${local.minute}";
        final ampm = local.hour >= 12 ? "PM" : "AM";
        timePart = "$hour:$min $ampm";
      }

      return timePart.isNotEmpty ? "$datePart · $timePart" : datePart;
    }

    // 2. If rawDate is already formatted (e.g. "Mar 18, 2026")
    if (rawDate.isNotEmpty) {
      if (rawTime.isNotEmpty) {
        if (rawDate.toLowerCase().contains(rawTime.toLowerCase())) {
          return rawDate;
        }
        return "$rawDate · $rawTime";
      }
      return rawDate;
    }

    // 3. If rawDate is empty but rawTime exists
    if (rawTime.isNotEmpty) {
      return rawTime;
    }

    return "Date not specified";
  }

  Widget _buildPrescriptionCard(
    BuildContext context,
    AppointmentPrescriptionEntity pres,
    bool isDark,
    Color primaryColor,
  ) {
    return _sheetCard(
      onTap: () => _viewPrescriptionDetails(context, pres, isDark, primaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecordCardHeader(
            icon: Icons.medication_outlined,
            title: pres.doctorName.isNotEmpty
                ? "Dr. ${pres.doctorName.replaceFirst('Dr. ', '')}"
                : _formatPrescriptionDateTime(pres),
            subtitle: pres.doctorName.isNotEmpty ? _formatPrescriptionDateTime(pres) : null,
            trailing: RecordIconAction(
              icon: Icons.picture_as_pdf_outlined,
              tooltip: "View PDF",
              onTap: () {
                final rawBaseUrl = EnvironmentService.config.accountBaseUrl;
                final baseUrl = rawBaseUrl.startsWith('http') ? rawBaseUrl : 'https://$rawBaseUrl';
                final effectivePdfUrl = '$baseUrl/v1/api/auth/prescriptions/${pres.id}/pdf';

                InAppDocumentViewer.show(
                  context,
                  title: pres.doctorName.isNotEmpty ? '${pres.doctorName} - Prescription' : 'Digital Prescription',
                  category: 'Prescription',
                  fileUrl: effectivePdfUrl,
                  hospitalName: 'Yira Super Speciality Hospitals',
                  isAppointmentDoc: true,
                );
              },
            ),
          ),
          if (pres.diagnoses.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: pres.diagnoses.map((d) => RecordPill("${d.name}${d.icd10.isNotEmpty ? ' (${d.icd10})' : ''}")).toList(),
            ),
          ],
          if (pres.medications.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...pres.medications.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: RecordMedicineLine(
                    name: m.name,
                    detail: [
                      if (m.dosage.isNotEmpty) m.dosage,
                      if (m.frequency.isNotEmpty) m.frequency,
                      if (m.duration.isNotEmpty) m.duration,
                    ].join(' · '),
                  ),
                )),
          ],
          const SizedBox(height: 2),
          const RecordCardLink(),
        ],
      ),
    );
  }

  Widget _buildClinicalNoteCard(
    BuildContext context,
    AppointmentClinicalNoteEntity note,
    bool isDark,
    Color primaryColor,
  ) {
    return _sheetCard(
      onTap: () => _viewClinicalNoteDetails(context, note, isDark, primaryColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecordSectionTitle(
            icon: Icons.edit_note_rounded,
            title: note.doctorName.isNotEmpty ? note.doctorName : "Doctor's Note",
          ),
          const SizedBox(height: 8),
          Text(
            note.notes,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DietUi.text(13, FontWeight.w400, DietUi.body(isDark), height: 1.4),
          ),
          const SizedBox(height: 4),
          const RecordCardLink(label: "Read Note"),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    AppointmentDocumentEntity doc,
    bool isDark,
    Color primaryColor,
  ) {
    return _sheetCard(
      onTap: () => _viewDocumentDetails(context, doc, isDark, primaryColor),
      child: Column(
        children: [
          RecordCardHeader(
            icon: Icons.description_outlined,
            title: doc.fileName,
            subtitle: "${doc.category} · ${doc.type}${doc.createdAt.isNotEmpty ? ' · ${doc.createdAt}' : ''}",
          ),
          const RecordCardLink(label: "View"),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordCard(
    BuildContext context,
    AppointmentMedicalRecordEntity rec,
    bool isDark,
    Color primaryColor,
  ) {
    return _sheetCard(
      onTap: () => _viewMedicalRecordDetails(context, rec, isDark, primaryColor),
      child: Column(
        children: [
          RecordCardHeader(
            icon: Icons.assignment_outlined,
            title: rec.recordType,
            subtitle: rec.createdAt.isNotEmpty ? "Recorded on: ${rec.createdAt}" : null,
          ),
          const RecordCardLink(label: "View"),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  REUSABLE HELPER WIDGETS
  // ═══════════════════════════════════════════════

  Widget _buildEmptyTile(String text, IconData icon, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(color: RecordUi.soft(isDark), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: DietUi.muted(isDark)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: DietUi.text(11.5, FontWeight.w400, DietUi.muted(isDark)))),
        ],
      ),
    );
  }

  Widget _buildInfoContainer({required List<Widget> children}) {
    return SizedBox(
      width: double.infinity,
      child: RecordCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  /// A card with a gap beneath it, full width in a sheet's left-aligned column.
  Widget _sheetCard({required VoidCallback onTap, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(width: double.infinity, child: RecordCard(onTap: onTap, child: child)),
    );
  }

  Widget _buildGridRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: children.map((c) => Expanded(child: c)).toList(),
    );
  }

  // ═══════════════════════════════════════════════
  //  MAIN BUILD — TIMELINE CARD LAYOUT
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = DietUi.blue;

    if (appointments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: RecordEmptyState(
          icon: Icons.event_busy_outlined,
          title: "No Appointments Found",
          message: "No past or upcoming appointments\nrecorded for this patient.",
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appointments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appt = appointments[index];

        final bool isPatientUser = _isPatient();
        final int presCount = appt.prescriptions.length;
        final int notesCount = isPatientUser ? 0 : appt.clinicalNotes.length;
        final int docsCount = appt.documents.length;
        final int recsCount = appt.medicalRecords.length;
        final int totalRecords = presCount + notesCount + docsCount + recsCount;

        return RecordCard(
          onTap: () => _showAppointmentDetailSheet(context, appt, isDark, primaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecordCardHeader(
                icon: appt.isTeleConsultation ? Icons.videocam_outlined : Icons.calendar_month_outlined,
                title: appt.appointmentDate.isNotEmpty ? appt.appointmentDate : "Appointment #${index + 1}",
                subtitle: [
                  if (appt.tokenNumber.isNotEmpty) "Token #${appt.tokenNumber}",
                  if (appt.startTime.isNotEmpty) formatClockTime(appt.startTime),
                ].join(' · '),
                trailing: RecordStatusPill(humanizeStatus(appt.status)),
              ),
              if (appt.condition.isNotEmpty || appt.reason.isNotEmpty) ...[
                const SizedBox(height: 12),
                RecordField(
                  label: appt.condition.isNotEmpty ? "Condition" : "Reason for Visit",
                  value: appt.condition.isNotEmpty ? appt.condition : appt.reason,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  RecordMeta(
                    icon: appt.isTeleConsultation ? Icons.videocam_outlined : Icons.location_on_outlined,
                    text: [
                      if (appt.appointmentType.isNotEmpty) appt.appointmentType,
                      appt.isTeleConsultation ? "Paid Online" : "Pay at Clinic",
                    ].join(' · '),
                  ),
                  if (appt.doctorName.isNotEmpty) RecordMeta(icon: Icons.person_outline_rounded, text: appt.doctorName),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (totalRecords > 0)
                    RecordMeta(
                      icon: Icons.folder_outlined,
                      text: "$totalRecords ${totalRecords == 1 ? 'record' : 'records'}",
                    ),
                  const Expanded(child: RecordCardLink()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
