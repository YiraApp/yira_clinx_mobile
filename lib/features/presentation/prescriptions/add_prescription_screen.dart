import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/lab_test_picker_sheet.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/lab_tests_section.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/prescribed_medication_card.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/lab_test_entity.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/prescription_item.dart';
import 'package:yiraclinics/features/domain/entities/patient_profile/patient_profile_entity.dart';
import 'package:yiraclinics/features/domain/entities/medicine/medical_history_entity.dart';
import 'package:yiraclinics/features/domain/repositories/medicine/medical_history_repo.dart';
import 'package:yiraclinics/features/presentation/medicine/create_medicine_screen.dart';
import 'package:yiraclinics/features/presentation/medicine/medical_record_bloc/medical_record_bloc.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../di/dependency_injection.dart';

class AddPrescriptionRecordScreen extends StatefulWidget {
  final PatientProfileEntity? patient;
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;

  const AddPrescriptionRecordScreen({
    super.key,
    this.patient,
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
  });

  @override
  State<AddPrescriptionRecordScreen> createState() =>
      _AddPrescriptionRecordScreenState();
}

/// Why this prescription cannot be issued yet, or null when it can. The screen
/// opens with one empty medicine row, so with lab tests ordered an untouched row
/// counts as no medicine rather than as an unfinished one.
@visibleForTesting
String? prescriptionValidationError(List<MedicationItem> medications, List<PrescribedLabTest> labTests) {
  bool untouched(MedicationItem med) =>
      [med.name, med.dosage, med.frequency, med.duration, med.route, med.instructions]
          .every((field) => (field ?? '').trim().isEmpty);

  if (labTests.isEmpty && medications.every(untouched)) {
    return "Please add at least one medication or lab test.";
  }

  for (int i = 0; i < medications.length; i++) {
    final med = medications[i];
    if (labTests.isNotEmpty && untouched(med)) continue;

    final label = medications.length > 1 ? ' for Medication #${i + 1}' : '';
    if (med.name.trim().isEmpty) return "Medication name is required$label.";
    if (med.dosage == null || med.dosage!.trim().isEmpty) return "Dosage is required$label.";
    if (med.frequency == null || med.frequency!.trim().isEmpty) return "Frequency is required$label.";
    if (med.duration == null || med.duration!.trim().isEmpty) return "Duration is required$label.";
    if (med.route == null || med.route!.trim().isEmpty) return "Route is required$label.";
  }
  return null;
}

class _AddPrescriptionRecordScreenState
    extends State<AddPrescriptionRecordScreen> {
  late final TextEditingController _notesController;
  static const Color _primaryBlue = Color(0xFF2563EB);

  static const List<String> _quickAdviceTags = [
    'Take after meals',
    'Take before meals',
    'Drink plenty of fluids',
    'Complete full course',
    'Avoid cold beverages',
    'Review in 7 days',
    'Review in 14 days',
    'Rest adequately',
  ];

  // This visit's medical record: added or edited from here without leaving the prescription, and
  // printed on its PDF.
  MedicalRecordBriefEntity? _record;
  bool _recordLoading = false;

  String? get _patientId => widget.patientId ?? widget.patient?.id;

  /// A record belongs to a visit, so it can be added here only when the prescription has one.
  bool get _hasVisit =>
      (widget.appointmentId?.trim().isNotEmpty ?? false) && (_patientId?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    if (!_hasVisit) return;
    setState(() => _recordLoading = true);
    try {
      final records = await sl<MedicalHistoryRepository>().fetchMedicalRecords(
        patientId: _patientId,
        appointmentId: widget.appointmentId,
        hospitalId: widget.hospitalId,
        orgId: widget.orgId,
      );
      records.sort((a, b) => b.recordDate.compareTo(a.recordDate));
      if (mounted) setState(() => _record = records.isEmpty ? null : records.first);
    } catch (_) {
      // The card then offers to add one; the prescription itself is unaffected.
    } finally {
      if (mounted) setState(() => _recordLoading = false);
    }
  }

  Future<void> _openRecordForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BlocProvider<MedicalRecordBloc>(
          create: (_) => sl<MedicalRecordBloc>(),
          child: CreateMedicalRecordScreen(
            patient: widget.patient,
            recordToEdit: _record,
            patientId: _patientId,
            appointmentId: widget.appointmentId,
            hospitalId: widget.hospitalId,
            orgId: widget.orgId,
          ),
        ),
      ),
    );
    if (mounted) _loadRecord();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// The hospital whose lab tests to offer: this visit's, or the doctor's latest.
  String? get _labHospitalId {
    final own = widget.hospitalId?.trim() ?? '';
    if (own.isNotEmpty) return own;
    final latest = GlobalSession.instance.userNotifier.value?.data?.latestHospitalId;
    return latest != null && latest > 0 ? latest.toString() : null;
  }

  void _appendAdvice(String advice) {
    final current = _notesController.text.trim();
    if (current.isEmpty) {
      _notesController.text = advice;
    } else if (!current.contains(advice)) {
      _notesController.text = '$current. $advice';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool isTab = isTablet(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => sl<PrescriptionBloc>()
        ..add(LoadPrescriptionData(
          patientId: widget.patientId ?? widget.patient?.id,
          appointmentId: widget.appointmentId,
          hospitalId: widget.hospitalId,
          orgId: widget.orgId,
        )),
      child: BlocConsumer<PrescriptionBloc, PrescriptionState>(
        listener: (context, state) {
          if (state.additionalNotes.isNotEmpty && _notesController.text.isEmpty) {
            _notesController.text = state.additionalNotes;
          }
          if (state.status == PrescriptionStatus.submitSuccess &&
              state.errorMessage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Prescription issued & digital PDF generated!",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF059669),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
            Navigator.pop(context, true);
          } else if (state.status == PrescriptionStatus.submitFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    state.errorMessage ?? "Failed to save prescription"),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        builder: (context, state) {
          final medCount = state.medications.length;
          final bool isSubmitting = state.status == PrescriptionStatus.submitLoading;

          return Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),

            // ── App Bar ──
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF232323) : Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isDark ? Colors.white : const Color(0xFF121212),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Prescribe Medication',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 18 : 16.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF121212),
                ),
              ),
              centerTitle: true,
            ),

            // ── Bottom Action Bar ──
            bottomNavigationBar: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 6
                    : 12,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232323) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF64748B).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : const Color(0xFF4A4A4A),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFCBD5E1),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () {
                              final problem = prescriptionValidationError(state.medications, state.labTests);
                              if (problem != null) {
                                _showValidationError(context, problem);
                                return;
                              }

                              context.read<PrescriptionBloc>().add(
                                    SubmitPrescription(
                                      patientId: widget.patientId ??
                                          widget.patient?.id ??
                                          '',
                                      appointmentId: widget.appointmentId,
                                      hospitalId: widget.hospitalId,
                                      orgId: widget.orgId,
                                      additionalNotes: _notesController.text,
                                      medicalRecordId: _record?.id,
                                    ),
                                  );
                            },
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: Text(
                        isSubmitting ? "Saving..." : "Issue Prescription",
                        style: const TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            body: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Patient Info Card (If available) ──
                  if (widget.patient != null) ...[
                    _buildPatientBanner(widget.patient!, isDark, isTab),
                    const SizedBox(height: 14),
                  ],

                  if (_hasVisit) ...[
                    _buildMedicalRecordCard(isDark),
                    const SizedBox(height: 14),
                  ],

                  // ── Section Title: Prescribed Medications ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medication_liquid_outlined, color: _primaryBlue, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Medications',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 16 : 14.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF121212),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$medCount Item${medCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Medication Cards List ──
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: medCount,
                    itemBuilder: (context, index) {
                      final item = state.medications[index];
                      return PrescribedPrescriptionCard(
                        key: ValueKey(item.id),
                        index: index + 1,
                        isTab: isTab,
                        medicineName: item.name,
                        currentDosage: item.dosage,
                        currentFreq: item.frequency,
                        currentDuration: item.duration,
                        currentRoute: item.route,
                        currentInstructions: item.instructions,
                        showRemove: medCount > 1,
                        onRemove: () {
                          context
                              .read<PrescriptionBloc>()
                              .add(RemoveMedication(item.id));
                        },
                        onDrugSelected: (name, dosage, route) {
                          context
                              .read<PrescriptionBloc>()
                              .add(UpdateMedicationDetails(
                                id: item.id,
                                name: name,
                                dosage: dosage,
                                route: route,
                              ));
                        },
                        onDosageChanged: (val) {
                          context
                              .read<PrescriptionBloc>()
                              .add(UpdateMedicationDetails(
                                id: item.id,
                                dosage: val,
                              ));
                        },
                        onFreqChanged: (val) {
                          context
                              .read<PrescriptionBloc>()
                              .add(UpdateMedicationDetails(
                                id: item.id,
                                frequency: val,
                              ));
                        },
                        onDurationChanged: (val) {
                          context
                              .read<PrescriptionBloc>()
                              .add(UpdateMedicationDetails(
                                id: item.id,
                                duration: val,
                              ));
                        },
                        onRouteChanged: (val) {
                          context
                              .read<PrescriptionBloc>()
                              .add(UpdateMedicationDetails(
                                id: item.id,
                                route: val,
                              ));
                        },
                        onInstructionsChanged: (val) {
                          context
                              .read<PrescriptionBloc>()
                              .add(UpdateMedicationDetails(
                                id: item.id,
                                instructions: val,
                              ));
                        },
                      );
                    },
                  ),

                  // ── + Add Medication Button ──
                  InkWell(
                    onTap: () {
                      context
                          .read<PrescriptionBloc>()
                          .add(AddEmptyMedication());
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _primaryBlue.withValues(alpha: 0.4),
                          style: BorderStyle.solid,
                          width: 1.2,
                        ),
                        color: _primaryBlue.withValues(alpha: isDark ? 0.15 : 0.04),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 18,
                            color: _primaryBlue,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Add Another Medication',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: _primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Lab Tests ──
                  LabTestsSection(
                    tests: state.labTests,
                    onAdd: () => LabTestPickerSheet.show(
                      context,
                      bloc: context.read<PrescriptionBloc>(),
                      hospitalId: _labHospitalId,
                    ),
                    onRemove: (test) => context.read<PrescriptionBloc>().add(RemoveLabTest(test.key)),
                    onPriorityChanged: (test, priority) => context
                        .read<PrescriptionBloc>()
                        .add(UpdateLabTest(key: test.key, priority: priority)),
                    onInstructionsChanged: (test, instructions) => context
                        .read<PrescriptionBloc>()
                        .add(UpdateLabTest(key: test.key, instructions: instructions)),
                  ),

                  const SizedBox(height: 18),

                  // ── Notes & Advice Section ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF232323) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : const Color(0xFF64748B).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notes_rounded, size: 16, color: _primaryBlue),
                            const SizedBox(width: 6),
                            Text(
                              'Clinical Advice & Notes (Optional)',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF121212),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Quick Advice Tags
                        Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: _quickAdviceTags.map((tag) {
                            final isAdded = _notesController.text.contains(tag);
                            return InkWell(
                              onTap: () => _appendAdvice(tag),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: isAdded
                                      ? _primaryBlue.withValues(alpha: isDark ? 0.25 : 0.12)
                                      : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isAdded
                                        ? _primaryBlue
                                        : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  '+ $tag',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 10.5,
                                    fontWeight: isAdded ? FontWeight.bold : FontWeight.w500,
                                    color: isAdded ? _primaryBlue : (isDark ? Colors.white70 : const Color(0xFF4A4A4A)),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),

                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12.5,
                            color: isDark ? Colors.white : const Color(0xFF121212),
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter special instructions or diet advice...",
                            hintStyle: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12,
                              color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientBanner(PatientProfileEntity patient, bool isDark, bool isTab) {
    final name = patient.name.trim().isNotEmpty
        ? patient.name.trim()
        : 'Patient Profile';
    final initials = name.isNotEmpty
        ? name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : 'PT';
    final gender = patient.gender;
    final bloodGroup = patient.bloodGroup.isNotEmpty ? 'Blood: ${patient.bloodGroup}' : '';
    final details = [gender, bloodGroup].where((s) => s.isNotEmpty).join(' • ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF121212),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    details,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Active Patient',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The visit's medical record, with a button to add or edit it.
  Widget _buildMedicalRecordCard(bool isDark) {
    final record = _record;
    final summary = record == null
        ? ''
        : [
            if (record.chiefComplaint.trim().isNotEmpty) 'C/O: ${record.chiefComplaint.trim()}',
            if ((record.allergies ?? '').trim().isNotEmpty) 'Allergies: ${record.allergies!.trim()}',
          ].join(' · ');
    final subtitle = _recordLoading && record == null
        ? 'Checking this visit for a record'
        : record == null
            ? 'Not added yet. It prints on the prescription PDF.'
            : (summary.isEmpty ? 'Added for this visit' : summary);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_outlined, color: _primaryBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical record',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF121212),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _recordLoading ? null : _openRecordForm,
            icon: Icon(record == null ? Icons.add_rounded : Icons.edit_outlined, size: 16),
            label: Text(
              record == null ? 'Add' : 'Edit',
              style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryBlue,
              side: BorderSide(color: _primaryBlue.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _showValidationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12.5),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
