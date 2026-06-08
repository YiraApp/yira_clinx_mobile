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

class AddNewAppointmentScreen extends StatelessWidget {
  AddNewAppointmentScreen({super.key});
  final TextEditingController _reasonController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final double width = displayWidth(context);
    final bool isTab = isTablet(context);
    return BlocConsumer<AppointmentBloc, AppointmentState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: CommonAppBar(
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
                crossAxisAlignment: .start,
                children: [
                  CommonText(
                    'Patient Search *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize:isTab?displayWidth(context) * 0.02:  displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: titleSpace),
                  TextField(
                    onChanged: (val) {},
                    style: TextStyle(
                      decorationThickness: 0,
                      fontFamily: appPoppinFont,
                      fontSize: isTab?displayWidth(context) * 0.018: displayWidth(context) * 0.03,
                    ),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize:isTab?displayWidth(context) * 0.018:  displayWidth(context) * 0.03,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                      hintText: "Search Patient...",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.blueGrey,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: isDark? darkModeCardColor.withOpacity(0.8):lightModeTextFieldBgColor,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),

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
                  SizedBox(height: fieldSpace),
                  CommonText(
                    'Date *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab?displayWidth(context) * 0.02: displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: titleSpace),
                  _buildDOBPicker(
                    context,
                    state.selectedDob ?? DateTime(2000, 1, 1),
                    isDark,isTab
                  ),
                  SizedBox(height: fieldSpace),
                  CommonText(
                    'Available slot *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize:isTab?displayWidth(context) * 0.02:  displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: titleSpace),
                  CommonDropdown(
                    title: "Select Slot",
                    selectedValue: state.selectedSlot,
                    options: const [
                      "9:00 - 9:30",
                      "9:30 - 10:00",
                      "10:00 - 10:30",
                      "10:30 - 11:00",
                      "11:00 - 11:30",
                      "11:30 - 12:00",
                    ],
                    onSelected: (value) {},
                  ),
                  SizedBox(height: fieldSpace),
                  CommonText(
                    'Duration',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize:isTab?displayWidth(context) * 0.02:  displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: titleSpace),
                  CommonDropdown(
                    title: "Select Duration",
                    selectedValue: state.selectedSlot,
                    options: const ["30 minutes", "45 minutes", "1 hour"],
                    onSelected: (value) {},
                  ),
                  SizedBox(height: fieldSpace),
                  CommonText(
                    'Visit Type *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab?displayWidth(context) * 0.02: displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: titleSpace),
                  CommonDropdown(
                    title: "Select type",
                    selectedValue: state.selectedSlot,
                    options: const [
                      "Consultation",
                      "Follow-up",
                      "Check-up",
                      "Tele-Consult",
                    ],
                    onSelected: (value) {},
                  ),
                  SizedBox(height: fieldSpace),
                  CommonText(
                    'Assign Doctor *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab?displayWidth(context) * 0.02: displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: titleSpace),
                  CommonDropdown(
                    title: "Select Doctor",
                    selectedValue: state.selectedSlot,
                    options: const [
                      "Dr. Madhu - Dentist",
                      "Dr. Surya - Dentist",
                      "Dr. Bhargava - Dentist",
                    ],
                    onSelected: (value) {},
                  ),
                  SizedBox(height: fieldSpace),
                  CommonText(
                    'Reason/ Chief Complaint *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize:isTab?displayWidth(context) * 0.02:  displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: titleSpace),
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
                  SizedBox(height: fieldSpace),
                  TeleconsultationCard(
                    isTab: isTab,
                    isDark: isDark,
                    isSelected: true,
                    onChanged: (bool? newValue) {},
                  ),
                  SizedBox(height: fieldSpace*3),
                  CustomElevatedButton(
                    text: "Book Appointment",
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    width: double.infinity,
                    height: 50,
                    borderRadius: 8,
                  ),
                  SizedBox(height: fieldSpace*1.5),
                  SizedBox(
                    height: 50,
                    width: displayWidth(context),
                    child: OutlinedButton(
                      onPressed: () {},
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
                          fontSize: isTab?displayWidth(context) * 0.02: displayWidth(context) * 0.032,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
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
                      horizontal: 50,
                      vertical: 10,
                    ),
                    child: CustomElevatedButton(
                      text: "Confirm",
                      onPressed: () {
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

  Widget _buildDOBPicker(
    BuildContext context,
    DateTime? currentDob,
    bool isDark,
      bool isTab
  ) {
    final DateTime displayDate = currentDob ?? DateTime(2000, 1, 1);

    final TextEditingController dobController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(displayDate),
    );

    return TextField(
      controller: dobController,
      readOnly: true,
      onTap: () => _showDatePicker(context, displayDate, isDark),
      style: TextStyle(
        decorationThickness: 0,
        fontFamily: appPoppinFont,
        fontSize:isTab?displayWidth(context) * 0.018:  displayWidth(context) * 0.03,
      ),

      decoration: InputDecoration(
        hintStyle: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: displayWidth(context) * 0.03,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
        suffixIcon: const Icon(
          Icons.calendar_today,
          color: Colors.blueGrey,
          size: 18,
        ),
        filled: true,
        fillColor: isDark? darkModeCardColor.withOpacity(0.8):lightModeTextFieldBgColor,
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
}
