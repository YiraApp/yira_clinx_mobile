import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/clinical_info_session.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/diagnosis_treatment_section.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/vital_signs_section.dart';

import '../../../core/colors/colors.dart';
import '../../../core/common_drop_down/common_drop_down.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_border_button.dart';
import '../../../core/common_widgets/custom_button.dart';
import 'medical_record_bloc/medical_record_bloc.dart';

import 'package:yiraclinics/features/domain/entities/medicine/medical_history_entity.dart';
import 'package:yiraclinics/features/domain/entities/patient_profile/patient_profile_entity.dart';

class CreateMedicalRecordScreen extends StatefulWidget {
  final PatientProfileEntity? patient;
  final MedicalRecordBriefEntity? recordToEdit;
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;

  const CreateMedicalRecordScreen({
    super.key,
    this.patient,
    this.recordToEdit,
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
  });

  @override
  State<CreateMedicalRecordScreen> createState() =>
      _CreateMedicalRecordScreenState();
}

class _CreateMedicalRecordScreenState extends State<CreateMedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _chiefComplaintController =
      TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _physicalExamController = TextEditingController();
  final TextEditingController _bpController = TextEditingController();
  final TextEditingController _hrController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _doctorNotesController = TextEditingController();
  final TextEditingController _treatmentPlanController =
      TextEditingController();
  final TextEditingController _oxygenSaturationController =
      TextEditingController();

  String _selectedVisitType = "New Consultation";

  @override
  void initState() {
    super.initState();
    if (widget.recordToEdit != null) {
      final rec = widget.recordToEdit!;
      _chiefComplaintController.text = rec.chiefComplaint;
      _symptomsController.text = rec.symptoms ?? '';
      _physicalExamController.text = rec.physicalExamination ?? '';
      _diagnosisController.text = rec.diagnosis;
      _doctorNotesController.text = rec.treatmentPlan ?? '';
      _treatmentPlanController.text = rec.treatmentPlan ?? '';
      _bpController.text = rec.bloodPressure ?? '';
      _hrController.text = rec.heartRate ?? '';
      _tempController.text = rec.temperature ?? '';
      _weightController.text = rec.weight ?? '';
      _heightController.text = rec.height ?? '';
      if (rec.title.isNotEmpty) {
        _selectedVisitType = rec.title;
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _chiefComplaintController.dispose();
    _symptomsController.dispose();
    _physicalExamController.dispose();
    _bpController.dispose();
    _hrController.dispose();
    _tempController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _diagnosisController.dispose();
    _doctorNotesController.dispose();
    _treatmentPlanController.dispose();
    _oxygenSaturationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTab = isTablet(context);
    final theme = Theme.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<MedicalRecordBloc, MedicalRecordState>(
        listener: (context, state) {
          if (state is MedicalRecordSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Medical record created successfully!'),
              ),
            );
            Navigator.of(context).pop();
          } else if (state is MedicalRecordFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage)));
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                // Top Sheet Header Design
                SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.recordToEdit != null
                                  ? "Edit Medical Record"
                                  : "Create Medical Record",
                              style: const TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: screenHorizontalSpacePadding,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CommonText(
                                    "Date",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontFamily: appPoppinFont,
                                      color: Colors.grey,
                                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildDOBPicker(
                                    context,
                                    state.selectedDate,
                                    isDark,
                                    isTab,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CommonText(
                                    "Visit Type",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontFamily: appPoppinFont,
                                      color: Colors.grey,
                                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  CommonDropdown(
                                    title: "Select Visit Type",
                                    options: const [
                                      "New Consultation",
                                      "Follow Up",
                                    ],
                                    selectedValue: _selectedVisitType,
                                    onSelected: (String val) {
                                      setState(() {
                                        _selectedVisitType = val;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        ClinicalInfoSection(
                          chiefComplaintController: _chiefComplaintController,
                          symptomsController: _symptomsController,
                          physicalExamController: _physicalExamController,
                          isTab: isTab,
                        ),
                        const SizedBox(height: 24),

                        VitalSignsSection(
                          isTab: isTab,
                          bpController: _bpController,
                          hrController: _hrController,
                          tempController: _tempController,
                          weightController: _weightController,
                          heightController: _heightController,
                          oxygenSaturationController: _oxygenSaturationController,
                        ),
                        const SizedBox(height: 24),
                        DiagnosisTreatmentSection(
                          isTab: isTab,
                          diagnosisController: _diagnosisController,
                          doctorNotesController: _doctorNotesController,
                          treatmentPlanController: _treatmentPlanController,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: theme.colorScheme.surface,
                  child: Row(
                    children: [
                      Expanded(
                        child: CommonBorderButton(
                          height: buttonHeight,
                          text: 'Cancel',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: state is MedicalRecordLoading
                            ? const Center(child: CircularProgressIndicator.adaptive())
                            : CustomElevatedButton(
                                noElevation: true,
                                height: buttonHeight,
                                width: displayWidth(context),
                                text: widget.recordToEdit != null
                                    ? "Update Record"
                                    : "Create Record",
                                onPressed: () {
                                  if (_chiefComplaintController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                                            SizedBox(width: 8),
                                            Text("Chief Complaint is mandatory"),
                                          ],
                                        ),
                                        backgroundColor: Colors.red.shade600,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final doctorNotes = _doctorNotesController.text.trim();
                                  final treatmentPlan = _treatmentPlanController.text.trim();

                                  if (doctorNotes.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                                            SizedBox(width: 8),
                                            Text("Doctor Note is mandatory when adding a record"),
                                          ],
                                        ),
                                        backgroundColor: Colors.red.shade600,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final combinedTreatment = treatmentPlan.isNotEmpty && treatmentPlan != doctorNotes
                                      ? "Doctor Notes: $doctorNotes\n\nPlan: $treatmentPlan"
                                      : doctorNotes;

                                  if (_formKey.currentState!.validate()) {
                                    context.read<MedicalRecordBloc>().add(
                                      SaveMedicalRecordEvent(
                                        recordId: widget.recordToEdit?.id,
                                        patientId: widget.patientId ?? widget.patient?.id,
                                        appointmentId: widget.appointmentId,
                                        hospitalId: widget.hospitalId,
                                        orgId: widget.orgId,
                                        visitType: _selectedVisitType,
                                        chiefComplaint: _chiefComplaintController.text,
                                        symptoms: _symptomsController.text,
                                        physicalExamination: _physicalExamController.text,
                                        bp: _bpController.text,
                                        hr: _hrController.text,
                                        temperature: _tempController.text,
                                        weight: _weightController.text,
                                        height: _heightController.text,
                                        diagnosis: _diagnosisController.text,
                                        treatmentPlan: combinedTreatment,
                                      ),
                                    );
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDatePicker(
    BuildContext context,
    DateTime initialDate,
    bool isDark,
  ) {
    DateTime tempSelectedDate = initialDate;

    showModalBottomSheet(
      isDismissible: false,
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? darkModeCardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                    onPressed: () => Navigator.of(modalContext).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                    onPressed: () {
                      context.read<MedicalRecordBloc>().add(
                        ChangeSelectedDateEvent(tempSelectedDate),
                      );
                      Navigator.of(modalContext).pop();
                    },
                  ),
                ],
              ),
              const Divider(height: 0),
              SizedBox(
                height: 200,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: isDark ? Brightness.dark : Brightness.light,
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: initialDate,
                    minimumDate: DateTime(1900),
                    maximumDate: DateTime.now(),
                    onDateTimeChanged: (DateTime newDate) {
                      tempSelectedDate = newDate;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDOBPicker(
    BuildContext context,
    DateTime displayDate,
    bool isDark,
    bool isTab,
  ) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _showDatePicker(context, displayDate, isDark);
      },
      child: Container(
        height: isTab ? 45 : 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
          color: isDark ? Colors.transparent : Colors.grey.shade50,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: primaryColor,
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Text(
                  DateFormat('MMMM dd, yyyy').format(displayDate),
                  style: TextStyle(
                    fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
