import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/clinical_info_session.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/clinical_note_sections.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/vital_signs_section.dart';

import '../../../core/colors/colors.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
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
  // Diagnosis and plan are not on the form any more (as on the web); an edited record keeps the
  // values it already had.
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _treatmentPlanController =
      TextEditingController();
  final TextEditingController _oxygenSaturationController =
      TextEditingController();
  final _allergiesController = TextEditingController();
  final _respiratoryRateController = TextEditingController();
  final _cvsController = TextEditingController();
  final _rsController = TextEditingController();
  final _abdomenController = TextEditingController();
  final _cnsController = TextEditingController();
  final _hpiController = TextEditingController();
  final _familyHistoryController = TextEditingController();
  final _pastHistoryController = TextEditingController();
  final _currentMedicationsController = TextEditingController();

  static const _visitTypes = ["New Consultation", "Follow Up", "Emergency / Walk-in"];
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
      _treatmentPlanController.text = rec.treatmentPlan ?? '';
      _bpController.text = rec.bloodPressure ?? '';
      _hrController.text = rec.heartRate ?? '';
      _tempController.text = rec.temperature ?? '';
      _weightController.text = rec.weight ?? '';
      _heightController.text = rec.height ?? '';
      _oxygenSaturationController.text = rec.spo2 ?? '';
      _respiratoryRateController.text = rec.respiratoryRate ?? '';
      _allergiesController.text = rec.allergies ?? '';
      _cvsController.text = rec.cvsExamination ?? '';
      _rsController.text = rec.respiratoryExamination ?? '';
      _abdomenController.text = rec.abdomenExamination ?? '';
      _cnsController.text = rec.cnsExamination ?? '';
      _hpiController.text = rec.historyOfPresentIllness ?? '';
      _familyHistoryController.text = rec.familyHistory ?? '';
      _pastHistoryController.text = rec.pastHistory ?? '';
      _currentMedicationsController.text = rec.currentMedications ?? '';
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
    _treatmentPlanController.dispose();
    _oxygenSaturationController.dispose();
    for (final c in [
      _allergiesController, _respiratoryRateController, _cvsController, _rsController, _abdomenController,
      _cnsController, _hpiController, _familyHistoryController, _pastHistoryController, _currentMedicationsController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The note fields by their API keys. All are sent so a cleared field is cleared on the server.
  Map<String, String> _clinicalNote() => {
        'allergies': _allergiesController.text,
        'respiratoryRate': _respiratoryRateController.text,
        'cvsExamination': _cvsController.text,
        'respiratoryExamination': _rsController.text,
        'abdomenExamination': _abdomenController.text,
        'cnsExamination': _cnsController.text,
        'historyOfPresentIllness': _hpiController.text,
        'familyHistory': _familyHistoryController.text,
        'pastHistory': _pastHistoryController.text,
        'currentMedications': _currentMedicationsController.text,
      };

  /// What the preview shows, in the order the record prints on the prescription.
  RecordPreviewData _previewData() {
    List<MapEntry<String, String>> filled(List<MapEntry<String, String>> entries) =>
        entries.where((e) => e.value.trim().isNotEmpty).map((e) => MapEntry(e.key, e.value.trim())).toList();
    // Same rules as the web preview and the PDF: a unit is added only to a plain number, and a
    // temperature from 50 up is Fahrenheit, below it Celsius.
    final plainNumber = RegExp(r'^\d+(\.\d+)?$');
    String unit(String value, String suffix) {
      final v = value.trim();
      return plainNumber.hasMatch(v) ? '$v $suffix' : v;
    }
    final temp = _tempController.text.trim();
    final bp = _bpController.text.trim();
    return RecordPreviewData(
      allergies: _allergiesController.text.trim(),
      vitals: filled([
        MapEntry("Temp", unit(temp, (double.tryParse(temp) ?? 0) >= 50 ? "°F" : "°C")),
        MapEntry("Pulse", unit(_hrController.text, "/min")),
        MapEntry("BP", RegExp(r'^\d{2,3}\s*/\s*\d{2,3}$').hasMatch(bp) ? "${bp.replaceAll(RegExp(r'\s+'), '')} mmHg" : bp),
        MapEntry("RR", unit(_respiratoryRateController.text, "/min")),
        MapEntry("SpO2", unit(_oxygenSaturationController.text, "%")),
        MapEntry("Weight", unit(_weightController.text, "kg")),
        MapEntry("Height", unit(_heightController.text, "cm")),
      ]),
      generalExamination: _physicalExamController.text.trim(),
      systemic: filled([
        MapEntry("CVS", _cvsController.text),
        MapEntry("RS", _rsController.text),
        MapEntry("P/A", _abdomenController.text),
        MapEntry("CNS", _cnsController.text),
      ]),
      history: filled([
        MapEntry("Chief Complaints (C/O)", _chiefComplaintController.text),
        MapEntry("Symptoms", _symptomsController.text),
        MapEntry("History of Present Illness (H/O)", _hpiController.text),
        MapEntry("Family History", _familyHistoryController.text),
        MapEntry("Relevant Past / Comorbid History", _pastHistoryController.text),
        MapEntry("Current Medications", _currentMedicationsController.text),
      ]),
    );
  }

  Future<void> _previewAndSave(BuildContext context) async {
    FocusScope.of(context).unfocus();
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
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<MedicalRecordBloc>();
    // OK saves the record; Edit goes back to the form with everything as it was.
    final save = await showRecordPreview(context, _previewData(), isEdit: widget.recordToEdit != null);
    if (!save || !mounted) return;
    bloc.add(
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
        spo2: _oxygenSaturationController.text,
        diagnosis: _diagnosisController.text,
        treatmentPlan: _treatmentPlanController.text,
        clinicalNote: _clinicalNote(),
      ),
    );
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
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
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
                            color: isDark ? const Color(0xFF232323) : Colors.white,
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
                                      color: isDark ? Colors.white : const Color(0xFF121212),
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
                                            color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              isExpanded: true,
                                              value: _selectedVisitType,
                                              dropdownColor: isDark ? const Color(0xFF232323) : Colors.white,
                                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF2563EB)),
                                              style: TextStyle(
                                                fontFamily: appPoppinFont,
                                                fontSize: isTab ? 13 : 12,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white : const Color(0xFF121212),
                                              ),
                                              // A saved record may have another type (e.g. "Consultation"); it stays selectable.
                                              items: [
                                                for (final type in {..._visitTypes, _selectedVisitType})
                                                  DropdownMenuItem(value: type, child: Text(type)),
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

                        // The same order as the web and the prescription PDF: allergies, then
                        // examination and vitals, then the clinical history.
                        AllergiesSection(controller: _allergiesController, isTab: isTab),
                        const SizedBox(height: 16),

                        VitalSignsSection(
                          isTab: isTab,
                          bpController: _bpController,
                          hrController: _hrController,
                          tempController: _tempController,
                          weightController: _weightController,
                          heightController: _heightController,
                          oxygenSaturationController: _oxygenSaturationController,
                          respiratoryRateController: _respiratoryRateController,
                        ),
                        const SizedBox(height: 16),

                        ExaminationSection(
                          generalController: _physicalExamController,
                          cvsController: _cvsController,
                          rsController: _rsController,
                          abdomenController: _abdomenController,
                          cnsController: _cnsController,
                          isTab: isTab,
                        ),
                        const SizedBox(height: 16),

                        ClinicalInfoSection(
                          chiefComplaintController: _chiefComplaintController,
                          symptomsController: _symptomsController,
                          physicalExamController: _physicalExamController,
                          isTab: isTab,
                          showExamination: false,
                          title: "Clinical History & Presentation",
                          subtitle: "Complaints, present illness and past history",
                          icon: Icons.history_edu_outlined,
                          extraFields: historyNoteFields(
                            hpiController: _hpiController,
                            familyController: _familyHistoryController,
                            pastController: _pastHistoryController,
                            medicinesController: _currentMedicationsController,
                          ),
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
                    color: isDark ? const Color(0xFF232323) : Colors.white,
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
                                color: isDark ? Colors.grey.shade300 : const Color(0xFF4A4A4A),
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
                                  onPressed: () => _previewAndSave(context),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.visibility_outlined, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Preview",
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
