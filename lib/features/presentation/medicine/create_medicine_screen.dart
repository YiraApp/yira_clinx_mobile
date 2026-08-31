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
    final bool isTab = isTablet(context);
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final patientName = (widget.patient?.name != null && widget.patient!.name.trim().isNotEmpty)
        ? widget.patient!.name
        : "Patient Record";

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: BlocConsumer<MedicalRecordBloc, MedicalRecordState>(
        listener: (context, state) {
          if (state is MedicalRecordSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      widget.recordToEdit != null
                          ? "Medical record updated successfully!"
                          : "Medical record created successfully!",
                      style: const TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            Navigator.of(context).pop();
          } else if (state is MedicalRecordFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        builder: (context, state) {
          final selectedDate = state.selectedDate;

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Form(
              key: _formKey,
              child: Column(
              children: [
                // Clean Solid Blue Header
                SafeArea(
                  bottom: false,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.recordToEdit != null
                                    ? "Edit Medical Record"
                                    : "Create Medical Record",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                patientName,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 13 : 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Form Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Visit Context Card (Date + Visit Type Selector)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.2)
                                    : Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.event_note_rounded,
                                    size: 16,
                                    color: const Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Consultation Details",
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: isTab ? 14 : 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Date & Visit Type Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Date of Visit",
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        _buildDOBPicker(
                                          context,
                                          selectedDate,
                                          isDark,
                                          isTab,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Visit Type",
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          height: isTab ? 45 : 40,
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              isExpanded: true,
                                              value: _selectedVisitType,
                                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF2563EB)),
                                              style: TextStyle(
                                                fontFamily: appPoppinFont,
                                                fontSize: isTab ? 13 : 12,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: "New Consultation",
                                                  child: Text("New Consultation"),
                                                ),
                                                DropdownMenuItem(
                                                  value: "Follow Up",
                                                  child: Text("Follow Up"),
                                                ),
                                                DropdownMenuItem(
                                                  value: "Emergency / Walk-in",
                                                  child: Text("Emergency / Walk-in"),
                                                ),
                                              ],
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(() => _selectedVisitType = val);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 1: Clinical Assessment & Symptoms
                        ClinicalInfoSection(
                          chiefComplaintController: _chiefComplaintController,
                          symptomsController: _symptomsController,
                          physicalExamController: _physicalExamController,
                          isTab: isTab,
                        ),
                        const SizedBox(height: 16),

                        // Section 2: Vital Signs & Biometrics
                        VitalSignsSection(
                          isTab: isTab,
                          bpController: _bpController,
                          hrController: _hrController,
                          tempController: _tempController,
                          weightController: _weightController,
                          heightController: _heightController,
                          oxygenSaturationController: _oxygenSaturationController,
                        ),
                        const SizedBox(height: 16),

                        // Section 3: Diagnosis & Treatment Plan
                        DiagnosisTreatmentSection(
                          isTab: isTab,
                          diagnosisController: _diagnosisController,
                          doctorNotesController: _doctorNotesController,
                          treatmentPlanController: _treatmentPlanController,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Bottom Fixed Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? 14 : 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 7,
                          child: state is MedicalRecordLoading
                              ? const Center(
                                  child: SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                  ),
                                )
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    backgroundColor: const Color(0xFF2563EB),
                                    elevation: 2,
                                    shadowColor: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    if (_chiefComplaintController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  "Chief Complaint is mandatory",
                                                  style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.red.shade600,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                              Expanded(
                                                child: Text(
                                                  "Doctor Note is mandatory when recording consultation",
                                                  style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.red.shade600,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        widget.recordToEdit != null
                                            ? "Update Record"
                                            : "Save Record",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: isTab ? 14 : 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
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
