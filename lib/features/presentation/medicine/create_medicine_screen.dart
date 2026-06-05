import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/clinical_info_session.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/diagnosis_treatment_section.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/medical_patient_info_card.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/section_header.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/vital_signs_section.dart';

import '../../../core/colors/colors.dart';
import '../../../core/common_drop_down/common_drop_down.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_border_button.dart';
import '../../../core/common_widgets/custom_button.dart';
import 'medical_record_bloc/medical_record_bloc.dart';

class CreateMedicalRecordScreen extends StatefulWidget {
  const CreateMedicalRecordScreen({super.key});

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
  final TextEditingController _treatmentPlanController =
      TextEditingController();
  final TextEditingController _oxygenSaturationController =
      TextEditingController();

  String _selectedVisitType = "New Consultation";

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CommonAppBar(
        titleText:"Create New Medical Record",
        actions: [],
      ),
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: screenHorizontalSpacePadding,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: "Patient Information"),
                        const SizedBox(height: 12),
                        MedicalPatientInfoCard(
                          name: "Demo Manikanta",
                          patientId: '1434',
                        ),
                        const SizedBox(height: fieldSpace),
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
                                      fontSize: displayWidth(context) * 0.032,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildDOBPicker(
                                    context,
                                    state.selectedDate ?? DateTime(2000, 1, 1),
                                    isDark,
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
                                      fontSize: displayWidth(context) * 0.032,
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
                        ),
                        const SizedBox(height: 24),

                        VitalSignsSection(
                          bpController: _bpController,
                          hrController: _hrController,
                          tempController: _tempController,
                          weightController: _weightController,
                          heightController: _heightController,
                          oxygenSaturationController:
                              _oxygenSaturationController,
                        ),
                        const SizedBox(height: 24),
                        DiagnosisTreatmentSection(
                          diagnosisController: _diagnosisController,
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
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: state is MedicalRecordLoading
                            ? const Center(child: CircularProgressIndicator())
                            : CustomElevatedButton(
                                noElevation: true,
                                height: buttonHeight,
                                width: displayWidth(context),
                                text: "Create Record",
                                onPressed: () {},
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
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Theme.of(context).scaffoldBackgroundColor
                    : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5,
                    width: 45,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(fieldBorderRadius),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "Select Date",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: displayWidth(context) * 0.045,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: displayHeight(context) / 3.5,
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        brightness: isDark ? Brightness.dark : Brightness.light,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: displayWidth(context) * 0.05,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: initialDate,
                        maximumDate: DateTime.now(),
                        minimumYear: 1900,
                        itemExtent: 50,
                        onDateTimeChanged: (DateTime newDate) {
                          tempSelectedDate = newDate;
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    child: CustomElevatedButton(
                      text: "Confirm",
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      width: double.infinity,
                      height: 55,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDOBPicker(
    BuildContext context,
    DateTime? currentDob,
    bool isDark,
  ) {
    final DateTime displayDate = currentDob ?? DateTime(2000, 1, 1);
    final age = DateTime.now().year - displayDate.year;

    return InkWell(
      onTap: () => _showDatePicker(context, displayDate, isDark),
      borderRadius: BorderRadius.circular(fieldBorderRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(fieldBorderRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: primaryColor, size: 18),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM dd, yyyy').format(displayDate),
                  style: TextStyle(
                    fontSize: displayWidth(context) * 0.032,
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

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      context.read<MedicalRecordBloc>().add(
        SaveMedicalRecordEvent(
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
          treatmentPlan: _treatmentPlanController.text,
        ),
      );
    }
  }
}
