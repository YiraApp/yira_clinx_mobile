import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/prescribed_medication_card.dart';
import 'package:yiraclinics/features/domain/entities/patient_profile/patient_profile_entity.dart';
import '../../../core/common_input_fields/common_input_field_unlimited.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/custom_border_button.dart';
import '../../../core/common_widgets/custom_button.dart';
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
                    Text("Prescription saved!"),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
            Navigator.pop(context);
          } else if (state.status == PrescriptionStatus.submitFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    state.errorMessage ?? "Failed to save prescription"),
                backgroundColor: Colors.red.shade600,
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
                isDark ? const Color(0xFF0F1117) : const Color(0xFFF5F6FA),

            // ── Bottom: Cancel + Save ──
            bottomNavigationBar: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom + 6
                    : 12,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1D27) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CommonBorderButton(
                      height: buttonHeight,
                      text: 'Cancel',
                      onPressed: isSubmitting ? () {} : () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CustomElevatedButton(
                      noElevation: true,
                      height: buttonHeight,
                      width: displayWidth(context),
                      text: isSubmitting ? "Saving..." : "Save",
                      onPressed: isSubmitting
                          ? null
                          : () {
                              if (state.medications.isEmpty) {
                                _showValidationError(context, "Add at least one medication");
                                return;
                              }

                              // Validate all mandatory fields for EVERY medication card
                              for (int i = 0; i < state.medications.length; i++) {
                                final med = state.medications[i];
                                final medNum = i + 1;
                                final label = state.medications.length > 1
                                    ? ' for Medication $medNum'
                                    : '';

                                if (med.name.trim().isEmpty) {
                                  _showValidationError(context, "Medication Name is required$label");
                                  return;
                                }
                                if (med.dosage == null || med.dosage!.trim().isEmpty) {
                                  _showValidationError(context, "Dosage is required$label");
                                  return;
                                }
                                if (med.frequency == null || med.frequency!.trim().isEmpty) {
                                  _showValidationError(context, "Frequency is required$label");
                                  return;
                                }
                                if (med.duration == null || med.duration!.trim().isEmpty) {
                                  _showValidationError(context, "Duration is required$label");
                                  return;
                                }
                                if (med.route == null || med.route!.trim().isEmpty) {
                                  _showValidationError(context, "Route is required$label");
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
                    ),
                  ),
                ],
              ),
            ),

            // ── App Bar ──
            appBar: AppBar(
              backgroundColor:
                  isDark ? const Color(0xFF1A1D27) : Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'New Prescription',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              centerTitle: true,
            ),

            // ── Body ──
            body: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Medication cards ──
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

                  // ── + Add Medication button ──
                  InkWell(
                    onTap: () {
                      context
                          .read<PrescriptionBloc>()
                          .add(AddEmptyMedication());
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.4),
                          style: BorderStyle.solid,
                        ),
                        color: theme.primaryColor.withValues(alpha: 0.04),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 20,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add Medication',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Notes section ──
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1D27) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.grey.shade200,
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes (Optional)',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: CommonInputFieldUnlimited(
                            controller: _notesController,
                            hintText: "Special instructions...",
                            borderRadius: fieldBorderRadius,
                            validator: (value) => null,
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

  void _showValidationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
