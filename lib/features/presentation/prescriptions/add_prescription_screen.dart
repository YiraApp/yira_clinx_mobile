import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/prescribed_medication_card.dart';
import 'package:yiraclinics/features/domain/entities/patient_profile/patient_profile_entity.dart';
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

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
          patientId: widget.patient?.id,
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
                    Text("Prescription saved successfully!"),
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
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),

            // ── App Bar ──
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Prescribe Medication',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 18 : 16.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                        foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
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
                              if (state.medications.isEmpty) {
                                _showValidationError(context, "Please add at least one medication.");
                                return;
                              }

                              for (int i = 0; i < state.medications.length; i++) {
                                final med = state.medications[i];
                                final medNum = i + 1;
                                final label = state.medications.length > 1
                                    ? ' for Medication #$medNum'
                                    : '';

                                if (med.name.trim().isEmpty) {
                                  _showValidationError(context, "Medication name is required$label.");
                                  return;
                                }
                                if (med.dosage == null || med.dosage!.trim().isEmpty) {
                                  _showValidationError(context, "Dosage is required$label.");
                                  return;
                                }
                                if (med.frequency == null || med.frequency!.trim().isEmpty) {
                                  _showValidationError(context, "Frequency is required$label.");
                                  return;
                                }
                                if (med.duration == null || med.duration!.trim().isEmpty) {
                                  _showValidationError(context, "Duration is required$label.");
                                  return;
                                }
                                if (med.route == null || med.route!.trim().isEmpty) {
                                  _showValidationError(context, "Route is required$label.");
                                  return;
                                }
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
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
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

                  // ── Notes & Advice Section ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
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
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                                    color: isAdded ? _primaryBlue : (isDark ? Colors.white70 : const Color(0xFF475569)),
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
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter special instructions or diet advice...",
                            hintStyle: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12,
                              color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
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
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
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
