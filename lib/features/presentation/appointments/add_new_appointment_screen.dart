import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/features/presentation/appointments/appointment_bloc/appointment_bloc.dart';
import 'package:yiraclinics/features/presentation/appointments/widgets/tele_consult_widget.dart';
import '../../../core/colors/colors.dart';
import '../../../core/common_appbar/common_app_bar.dart';
import '../../../core/common_drop_down/common_drop_down.dart';
import '../../../core/common_input_fields/common_input_field_unlimited.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_button.dart';
import '../../../core/constants/constants.dart';

class AddNewAppointmentScreen extends StatefulWidget {
  const AddNewAppointmentScreen({super.key});

  @override
  State<AddNewAppointmentScreen> createState() => _AddNewAppointmentScreenState();
}

class _AddNewAppointmentScreenState extends State<AddNewAppointmentScreen> {
  final TextEditingController _patientSearchController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedSlot = "10:00 - 10:30";
  String _selectedDuration = "30 minutes";
  String _selectedVisitType = "Consultation";
  String _selectedDoctor = "Dr. Doctor";
  bool _isTeleConsultation = false;

  @override
  void dispose() {
    _patientSearchController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final bool isTab = isTablet(context);

    return BlocConsumer<AppointmentBloc, AppointmentState>(
      listener: (context, state) {
        if (state is OnAddAppointmentState) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Appointment booked successfully!")),
          );
          Navigator.pop(context);
        } else if (state is AppointmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: const CommonAppBar(
            actions: [],
            titleText: "Book Appointment",
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: screenHorizontalSpacePadding,
                vertical: screenTopPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText(
                    'Patient Name *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: titleSpace),
                  TextField(
                    controller: _patientSearchController,
                    style: TextStyle(
                      decorationThickness: 0,
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
                    ),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                      hintText: "Enter Patient Name...",
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: Colors.blueGrey,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: isDark ? darkModeCardColor.withOpacity(0.8) : lightModeTextFieldBgColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: isDark ? darkModeBorderColor : lightModeBorderColor,
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: isDark ? darkModeBorderColor : lightModeBorderColor,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: isDark ? darkModeBorderColor : lightModeBorderColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: fieldSpace),
                  CommonText(
                    'Patient Phone Number *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: titleSpace),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      decorationThickness: 0,
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
                    ),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                      hintText: "Enter 10-digit Phone Number...",
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: Colors.blueGrey,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: isDark ? darkModeCardColor.withOpacity(0.8) : lightModeTextFieldBgColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: isDark ? darkModeBorderColor : lightModeBorderColor,
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: isDark ? darkModeBorderColor : lightModeBorderColor,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: isDark ? darkModeBorderColor : lightModeBorderColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: fieldSpace),
                  CommonText(
                    'Date *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: titleSpace),
                  _buildDOBPicker(
                    context,
                    _selectedDate,
                    isDark,
                    isTab,
                  ),
                  const SizedBox(height: fieldSpace),
                  CommonText(
                    'Available slot *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: titleSpace),
                  CommonDropdown(
                    title: "Select Slot",
                    selectedValue: _selectedSlot,
                    options: const [
                      "9:00 - 9:30",
                      "9:30 - 10:00",
                      "10:00 - 10:30",
                      "10:30 - 11:00",
                      "11:00 - 11:30",
                      "11:30 - 12:00",
                      "14:00 - 14:30",
                      "15:00 - 15:30",
                    ],
                    onSelected: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSlot = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: fieldSpace),
                  CommonText(
                    'Duration',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: titleSpace),
                  CommonDropdown(
                    title: "Select Duration",
                    selectedValue: _selectedDuration,
                    options: const ["30 minutes", "45 minutes", "1 hour"],
                    onSelected: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDuration = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: fieldSpace),
                  CommonText(
                    'Visit Type *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: titleSpace),
                  CommonDropdown(
                    title: "Select type",
                    selectedValue: _selectedVisitType,
                    options: const [
                      "Consultation",
                      "Follow-up",
                      "Check-up",
                      "Tele-Consult",
                    ],
                    onSelected: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedVisitType = value;
                          if (value == "Tele-Consult") {
                            _isTeleConsultation = true;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: fieldSpace),
                  CommonText(
                    'Reason / Chief Complaint *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: titleSpace),
                  SizedBox(
                    height: 120,
                    child: CommonInputFieldUnlimited(
                      controller: _reasonController,
                      hintText: "Enter the primary reason for this visit...",
                      borderRadius: 8.0,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a reason';
                        }
                        return null;
                      },
                      onChanged: (text) {},
                    ),
                  ),
                  const SizedBox(height: fieldSpace),
                  TeleconsultationCard(
                    isTab: isTab,
                    isDark: isDark,
                    isSelected: _isTeleConsultation,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _isTeleConsultation = newValue ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: fieldSpace * 3),
                  CustomElevatedButton(
                    text: "Book Appointment",
                    onPressed: () {
                      final name = _patientSearchController.text.trim();
                      final phone = _phoneController.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter patient name")),
                        );
                        return;
                      }

                      if (phone.isEmpty || phone.length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a valid 10-digit phone number")),
                        );
                        return;
                      }

                      final startTimeStr = _selectedSlot.split(" - ").first.trim();
                      final formattedTime = startTimeStr.contains(":") ? "$startTimeStr:00" : "10:00:00";

                      context.read<AppointmentBloc>().add(
                        SubmitBookAppointmentEvent(
                          patientName: name,
                          phoneNumber: phone,
                          appointmentDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
                          startTime: formattedTime,
                          reason: _reasonController.text.trim(),
                          appointmentType: _selectedVisitType,
                          isTeleConsultation: _isTeleConsultation,
                        ),
                      );
                    },
                    width: double.infinity,
                    height: 50,
                    borderRadius: 8,
                  ),
                  const SizedBox(height: fieldSpace * 1.5),
                  SizedBox(
                    height: 50,
                    width: displayWidth(context),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? darkModeBorderColor : lightModeBorderColor),
                        foregroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(fieldBorderRadius),
                        ),
                      ),
                      child: CommonText(
                        "Discard",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w500,
                          fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDOBPicker(
    BuildContext context,
    DateTime currentDob,
    bool isDark,
    bool isTab,
  ) {
    final TextEditingController dobController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(currentDob),
    );

    return TextField(
      controller: dobController,
      readOnly: true,
      onTap: () => _showDatePicker(context, currentDob, isDark),
      style: TextStyle(
        decorationThickness: 0,
        fontFamily: appPoppinFont,
        fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
      ),
      decoration: InputDecoration(
        hintStyle: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: displayWidth(context) * 0.03,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
        suffixIcon: const Icon(
          Icons.calendar_today,
          color: Colors.blueGrey,
          size: 18,
        ),
        filled: true,
        fillColor: isDark ? darkModeCardColor.withOpacity(0.8) : lightModeTextFieldBgColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          borderSide: BorderSide(
            color: isDark ? darkModeBorderColor : lightModeBorderColor,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          borderSide: BorderSide(
            color: isDark ? darkModeBorderColor : lightModeBorderColor,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          borderSide: BorderSide(
            color: isDark ? darkModeBorderColor : lightModeBorderColor,
            width: 1.5,
          ),
        ),
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
                color: Theme.of(context).scaffoldBackgroundColor,
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
                      fontSize: displayWidth(context) * 0.035,
                      fontWeight: FontWeight.w600,
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
                            fontSize: displayWidth(context) * 0.038,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: initialDate,
                        minimumYear: 2024,
                        maximumYear: 2030,
                        itemExtent: 50,
                        onDateTimeChanged: (DateTime newDate) {
                          tempSelectedDate = newDate;
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 10,
                    ),
                    child: CustomElevatedButton(
                      text: "Confirm",
                      onPressed: () {
                        setState(() {
                          _selectedDate = tempSelectedDate;
                        });
                        Navigator.pop(context);
                      },
                      width: double.infinity,
                      height: 50,
                      borderRadius: 8,
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
}
