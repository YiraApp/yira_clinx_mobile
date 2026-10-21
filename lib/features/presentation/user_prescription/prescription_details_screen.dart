import 'package:yiraclinics/core/custom_dialogue/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/services/medication_reminder_service.dart';
import 'package:yiraclinics/features/data/models/medication/medication_reminder_model.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';
import 'package:yiraclinics/features/presentation/user_prescription/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/user_prescription/widgets/convert_tablet_sheet.dart';
import '../../../di/dependency_injection.dart';
import '../../../core/common_widgets/in_app_document_viewer.dart';
import '../../../core/api/base_api_configuration.dart';
import '../../../core/widgets/doctor_avatar_widget.dart';

class PrescriptionDetailScreen extends StatelessWidget {
  final String prescriptionId;
  final Map<String, dynamic>? initialData;

  /// For tests: a ready bloc, so nothing is loaded from the API.
  @visibleForTesting
  final MedicationBloc? bloc;

  const PrescriptionDetailScreen({
    super.key,
    required this.prescriptionId,
    this.initialData,
    this.bloc,
  });

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return 'Recent Appointment';
    try {
      final dt = DateTime.parse(raw.trim());
      return DateFormat('d MMM yyyy').format(dt);
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

  static const Color _green = Color(0xFF10B981);
  static const Color _violet = Color(0xFF8B5CF6);

  bool _hasPdf(Map<String, dynamic>? data) {
    final url = data?['pdfUrl']?.toString().trim() ?? '';
    return url.isNotEmpty && url.toLowerCase() != 'null';
  }

  void _openPdf(BuildContext context, Map<String, dynamic> data) {
    final rawBaseUrl = EnvironmentService.config.accountBaseUrl;
    final baseUrl = rawBaseUrl.startsWith('http') ? rawBaseUrl : 'https://$rawBaseUrl';
    final url = data['pdfUrl'].toString().trim();
    InAppDocumentViewer.show(
      context,
      title: '${_cleanDoctorName((data['doctor'] ?? 'Doctor').toString())} - Prescription',
      category: 'Prescription',
      fileUrl: url.startsWith('http') ? url : '$baseUrl$url',
      hospitalName: 'Prescription Document',
      isAppointmentDoc: true,
    );
  }

  /// "After Food" and similar, when the instructions mention it.
  String _mealTag(String instructions) {
    final lower = instructions.toLowerCase();
    if (lower.contains('after food') || lower.contains('after meal')) return 'After Food';
    if (lower.contains('before food') || lower.contains('before meal')) return 'Before Food';
    if (lower.contains('with food') || lower.contains('with meal')) return 'With Food';
    if (lower.contains('empty stomach')) return 'Empty Stomach';
    if (lower.contains('bedtime') || lower.contains('at night')) return 'At Bedtime';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffold = BlocBuilder<MedicationBloc, MedicationState>(
      builder: (context, state) {
        final data = state.selectedPrescriptionDetail ?? initialData;
        final subtitle = data == null
            ? null
            : [
                _cleanDoctorName((data['doctor'] ?? '').toString()),
                _formatDate((data['date'] ?? '').toString()),
              ].join(' · ');

        return Scaffold(
          backgroundColor: DietUi.background(isDark),
          appBar: DietUi.appBar(
            context,
            isDark,
            title: 'Prescription',
            subtitle: subtitle,
            actions: [
              if (_hasPdf(data))
                DietUi.actionIcon(
                  Icons.picture_as_pdf_rounded,
                  isDark,
                  () => _openPdf(context, data!),
                  tooltip: 'View prescription PDF',
                ),
              if (data != null && data['isSelf'] == true)
                DietUi.actionIcon(
                  Icons.delete_outline_rounded,
                  isDark,
                  () => _confirmDeletePrescription(context, data),
                  tooltip: 'Remove prescription',
                ),
            ],
          ),
          body: _buildBody(context, state, data, isDark),
        );
      },
    );

    if (bloc != null) return BlocProvider.value(value: bloc!, child: scaffold);
    return BlocProvider(
      create: (context) => sl<MedicationBloc>()..add(LoadPrescriptionDetails(prescriptionId)),
      child: scaffold,
    );
  }

  Widget _buildBody(BuildContext context, MedicationState state, Map<String, dynamic>? data, bool isDark) {
    if (data == null && (state.status == MedicationStatus.loading || state.status == MedicationStatus.initial)) {
      Widget block(double h) => Container(
            height: h,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: DietUi.card(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DietUi.line(isDark)),
            ),
          );
      return ListView(padding: const EdgeInsets.all(16), children: [block(200), block(160), block(160)]);
    }

    if (data == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            decoration: DietUi.cardDecoration(isDark),
            child: Column(
              children: [
                DietUi.iconBadge(Icons.description_outlined, DietUi.slate, isDark, size: 60, iconSize: 28),
                const SizedBox(height: 14),
                Text('Prescription not found', style: DietUi.text(15.5, FontWeight.w700, DietUi.strong(isDark))),
                const SizedBox(height: 6),
                Text(
                  'It may have been removed. Go back and pull down to refresh your prescriptions.',
                  textAlign: TextAlign.center,
                  style: DietUi.text(12.5, FontWeight.w400, DietUi.muted(isDark), height: 1.45),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final medications = (data['medications'] as List? ?? []).map((m) => Map<String, dynamic>.from(m as Map)).toList();
    final notes = (data['notes'] ?? '').toString().trim();

    return ValueListenableBuilder<List<MedicationReminder>>(
      valueListenable: MedicationReminderService.instance.remindersNotifier,
      builder: (context, _, _) {
        final withReminder = medications
            .where((m) => MedicationReminderService.instance.isMedicineConverted(prescriptionId, (m['name'] ?? '').toString()))
            .length;

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildOverviewCard(data, medications.length, withReminder, isDark),
            const SizedBox(height: 20),
            DietUi.sectionLabel(
              'MEDICINES · ${medications.length}',
              isDark,
              trailing: medications.isEmpty
                  ? null
                  : Text(
                      '$withReminder with reminders',
                      style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
                    ),
            ),
            if (medications.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: DietUi.cardDecoration(isDark),
                child: Text(
                  'No medicines are listed on this prescription.',
                  style: DietUi.text(12.5, FontWeight.w500, DietUi.muted(isDark)),
                ),
              )
            else
              for (final med in medications)
                _buildMedicationCard(
                  context,
                  med,
                  isDark,
                  doctorName: _cleanDoctorName((data['doctor'] ?? '').toString()),
                  doctorPhoto: (data['doctorPhoto'] ?? '').toString(),
                  condition: (data['condition'] ?? '').toString(),
                ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildNotesCard(notes, isDark),
            ],
            if (_hasPdf(data)) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _openPdf(context, data),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    side: const BorderSide(color: Color(0xFF059669)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: Text('View full prescription (PDF)', style: DietUi.text(13, FontWeight.w600, const Color(0xFF059669))),
                ),
              ),
            ],
            if (data['isSelf'] == true) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDeletePrescription(context, data),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: Text('Remove this prescription', style: DietUi.text(13, FontWeight.w600, const Color(0xFFEF4444))),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _confirmDeletePrescription(BuildContext context, Map<String, dynamic> data) {
    final title = (data['title'] ?? data['condition'] ?? 'Prescription').toString();
    showDialog(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: "Remove Prescription?",
        message: "Are you sure you want to remove \"$title\"? This will permanently delete the prescription and any reminders created from it.",
        tone: AppDialogTone.danger,
        icon: Icons.delete_forever_rounded,
        primaryLabel: "Remove",
        onPrimary: () async {
          Navigator.pop(dialogContext);
          final activeBloc = bloc ?? context.read<MedicationBloc>();
          final success = await activeBloc.deletePrescription(prescriptionId);
          if (context.mounted && success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Prescription removed successfully'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Color(0xFF0F766E),
              ),
            );
          }
        },
        secondaryLabel: "Cancel",
        onSecondary: () => Navigator.pop(dialogContext),
      ),
    );
  }

  Widget _buildOverviewCard(Map<String, dynamic> data, int medicineCount, int withReminder, bool isDark) {
    final rawDoc = (data['doctor'] ?? 'Consulting Doctor').toString();
    final docName = _cleanDoctorName(rawDoc);
    final specialty = _cleanSpecialty((data['specialty'] ?? '').toString(), rawDoc);
    final condition = (data['condition'] ?? 'General Consultation').toString();
    final date = _formatDate((data['date'] ?? '').toString());

    Widget tile(IconData icon, Color color, String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DietUi.sunken(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DietUi.line(isDark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 5),
                  Text(label, style: DietUi.text(10.5, FontWeight.w500, DietUi.muted(isDark))),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DietUi.text(13, FontWeight.w700, DietUi.strong(isDark), height: 1.3),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DietUi.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DoctorAvatarWidget(photoUrl: (data['doctorPhoto'] ?? '').toString(), doctorName: docName, size: 50),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(docName, maxLines: 1, overflow: TextOverflow.ellipsis, style: DietUi.text(15.5, FontWeight.w700, DietUi.strong(isDark))),
                    Text(specialty, maxLines: 1, overflow: TextOverflow.ellipsis, style: DietUi.text(12, FontWeight.w500, primaryColor)),
                  ],
                ),
              ),
              if (data['isSelf'] == true)
                DietUi.pill('Self Added', const Color(0xFF6366F1), isDark, icon: Icons.person_rounded)
              else
                DietUi.pill('Digital Rx', primaryColor, isDark, icon: Icons.verified_rounded),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tile(Icons.healing_rounded, primaryColor, 'Diagnosis', condition),
                const SizedBox(width: 10),
                tile(Icons.event_available_rounded, const Color(0xFF0EA5E9), 'Prescribed on', date),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.medication_outlined, size: 15, color: DietUi.hint(isDark)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$medicineCount medicine${medicineCount == 1 ? '' : 's'} · $withReminder reminder${withReminder == 1 ? '' : 's'} on',
                  style: DietUi.text(12, FontWeight.w500, DietUi.muted(isDark)),
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
    final name = (med['name'] ?? 'Medication').toString();
    final freq = (med['frequency'] ?? '').toString();
    final instructions = (med['instructions'] ?? 'Take as directed by doctor').toString();
    final duration = (med['duration'] ?? '').toString().trim();
    final scheduleText = _cleanSchedule((med['dosage'] ?? '').toString(), freq);
    final mealTag = _mealTag(instructions);
    final showInstructions = instructions.isNotEmpty &&
        instructions.toLowerCase() != 'take as directed by doctor' &&
        instructions.toLowerCase().trim() != mealTag.toLowerCase();

    final reminder = MedicationReminderService.instance.getReminderForMedicine(prescriptionId, name);
    final isOn = MedicationReminderService.instance.isMedicineConverted(prescriptionId, name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: DietUi.cardDecoration(isDark, borderColor: isOn ? _green.withValues(alpha: 0.4) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DietUi.iconBadge(Icons.medication_rounded, primaryColor, isDark, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: DietUi.text(14.5, FontWeight.w700, DietUi.strong(isDark), height: 1.25)),
                          if (duration.isNotEmpty)
                            Text('For $duration', style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    DietUi.pill(scheduleText, primaryColor, isDark, icon: Icons.access_time_filled_rounded),
                    if (mealTag.isNotEmpty) DietUi.pill(mealTag, _violet, isDark, icon: Icons.restaurant_rounded),
                  ],
                ),
                if (showInstructions) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
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
                          child: Icon(Icons.info_outline_rounded, size: 15, color: _green),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(instructions, style: DietUi.text(12, FontWeight.w400, DietUi.body(isDark), height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Reminder for this medicine
          Divider(height: 1, color: DietUi.line(isDark)),
          if (isOn)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, size: 17, color: _green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily reminder on', style: DietUi.text(12.5, FontWeight.w700, _green)),
                        if (reminder != null && reminder.times.isNotEmpty)
                          Text(
                            reminder.times.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark)),
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _confirmStopReminder(context, reminder, name),
                    style: TextButton.styleFrom(foregroundColor: DietUi.red, visualDensity: VisualDensity.compact),
                    child: Text('Turn off', style: DietUi.text(12, FontWeight.w700, DietUi.red)),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () => ConvertTabletSheet.show(
                    context,
                    medicineName: name,
                    dosage: scheduleText,
                    initialInstructions: instructions,
                    prescriptionId: prescriptionId,
                    doctorName: doctorName,
                    doctorPhoto: doctorPhoto,
                    condition: condition,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_alert_rounded, size: 17),
                  label: Text('Set daily reminder', style: DietUi.text(12.5, FontWeight.w600, primaryColor)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String notes, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DietUi.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DietUi.iconBadge(Icons.speaker_notes_outlined, primaryColor, isDark, size: 32, iconSize: 17),
              const SizedBox(width: 10),
              Text("Doctor's advice", style: DietUi.text(14, FontWeight.w700, DietUi.strong(isDark))),
            ],
          ),
          const SizedBox(height: 10),
          Text(notes, style: DietUi.text(12.5, FontWeight.w400, DietUi.body(isDark), height: 1.5)),
        ],
      ),
    );
  }

  void _confirmStopReminder(BuildContext context, MedicationReminder? reminder, String medicineName) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Turn off reminder?',
        message: 'You will no longer get daily reminders for $medicineName.',
        tone: AppDialogTone.danger,
        icon: Icons.notifications_off_rounded,
        primaryLabel: 'Turn off',
        onPrimary: () async {
          Navigator.pop(ctx);
          if (reminder != null) {
            await MedicationReminderService.instance.deleteReminder(reminder.id);
          } else {
            await MedicationReminderService.instance.deleteMedicineReminder(prescriptionId, medicineName);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reminder turned off for $medicineName'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        secondaryLabel: 'Keep',
        onSecondary: () => Navigator.pop(ctx),
      ),
    );
  }
}
