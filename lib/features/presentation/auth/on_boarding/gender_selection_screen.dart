import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../../core/common_widgets/custom_button.dart';
import '../../../../core/common_drop_down/common_drop_down.dart';
import '../../../../core/common_input_fields/common_input_field.dart';
import '../../../../core/common_widgets/common_text.dart';
import 'on_boarding_bloc/on_boarding_bloc.dart';

class GenderAgeSelectionScreen extends StatelessWidget {
  GenderAgeSelectionScreen({super.key});

  final TextEditingController emergencyNameController = TextEditingController();
  final TextEditingController emergencyMobileController = TextEditingController();
  final FocusNode emergencyNameFocus = FocusNode();
  final FocusNode emergencyMobileFocus = FocusNode();

  final List<String> indianRelations = [
    'Self', 'Father', 'Mother', 'Husband', 'Wife', 'Son', 'Daughter',
    'Brother', 'Sister', 'Grandfather', 'Grandmother', 'Grandson', 'Granddaughter',
    'Father-in-law', 'Mother-in-law', 'Son-in-law', 'Daughter-in-law',
    'Brother-in-law', 'Sister-in-law', 'Uncle', 'Aunt', 'Nephew', 'Niece',
    'Cousin', 'Guardian', 'Caregiver', 'Friend', 'Relative', 'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    final double screenWidth = displayWidth(context);

    // Calculate dynamic horizontal padding for tablets to naturally center the content
    final double tabletPadding = isTab ? (screenWidth - 550) / 2 : 0.0;

    return BlocConsumer<OnBoardingBloc, OnBoardingState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Padding(
              padding: EdgeInsets.only(left: isTab ? 8 : 8.0),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                  width: 1,
                ),
              ),
            ),
            // Padding strategy ensures structural buttons stay visible regardless of nested alignment constraints
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isTab ? tabletPadding : 0.0),
                child: _buildBottomButton(context, state),
              ),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // referenceWidth determines responsive typography size scaling safely
                final double referenceWidth = isTab ? 550 : screenWidth;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    screenHorizontalSpacePadding + tabletPadding,
                    8,
                    screenHorizontalSpacePadding + tabletPadding,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(context, isTab? "Tell us about\nyourself":"Tell us about\nyourself", referenceWidth,isTab),
                      const SizedBox(height: 32),

                      _buildSubHeading(context, "Select Gender", referenceWidth, isTab),
                      const SizedBox(height: titleSpace),
                      _buildGenderSelector(context, state.selectedGender, isDarkMode, referenceWidth,isTab),

                      const SizedBox(height: fieldSpace * 1.2),

                      _buildSubHeading(context, "Date of Birth", referenceWidth, isTab),
                      const SizedBox(height: titleSpace),
                      _buildDOBPicker(
                        context,
                        state.selectedDob ?? DateTime(2000, 1, 1),
                        isDarkMode,
                        referenceWidth,
                        isTab,
                        tabletPadding,
                      ),

                      const SizedBox(height: fieldSpace * 1.2),

                      _buildSubHeading(context, "Blood Group", referenceWidth, isTab),
                      const SizedBox(height: titleSpace),
                      CommonDropdown(
                        title: "Select Blood Group",
                        selectedValue: state.selectedBloodGroup,
                        options: const ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                        onSelected: (value) {
                          if (value != null) {
                            context.read<OnBoardingBloc>().add(UpdateBloodGroupEvent(value));
                          }
                        },
                      ),

                      const SizedBox(height: fieldSpace * 1.8),

                      // ====== BEAUTIFIED SEPARATE EMERGENCY CONTACT CARD ======
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? theme.colorScheme.surface.withOpacity(0.4)
                              : theme.primaryColor.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(fieldBorderRadius ?? 16),
                          border: Border.all(
                            color: isDarkMode ? Colors.white10 : theme.primaryColor.withOpacity(0.08),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDarkMode ? 0.15 : 0.02),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.shade100.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.health_and_safety_rounded,
                                    color: Colors.redAccent.shade200,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CommonText(
                                        'Emergency Contact',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: referenceWidth * (isTab ? 0.028 : 0.038),
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      CommonText(
                                        'Optional info for safety monitoring updates',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: referenceWidth * (isTab ? 0.022 : 0.026),
                                          color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Divider(height: 1, thickness: 0.5),
                            ),

                            CommonText(
                              'Contact Name',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: referenceWidth * (isTab ? 0.026 : 0.032),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: titleSpace),
                            CommonInputAddRecordTextField(
                              hintText: "Enter Contact Name",
                              controller: emergencyNameController,
                              focusNode: emergencyNameFocus,
                              requestFocusNode: emergencyMobileFocus,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: fieldSpace),

                            CommonText(
                              'Mobile Number',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: referenceWidth * (isTab ? 0.026 : 0.032),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: titleSpace),
                            CommonInputAddRecordTextField(
                              keyboardType: TextInputType.phone,
                              prefixIcon: CountryCodePicker(
                                showFlag: false,
                                showFlagDialog: true,
                                initialSelection: 'IN',
                                favorite: const ['IN', 'US'],
                                textStyle: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: referenceWidth * (isTab ? 0.026 : 0.035),
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                                dialogBackgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                                dialogTextStyle: TextStyle(
                                  fontFamily: appPoppinFont,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                                searchStyle: TextStyle(
                                  fontFamily: appPoppinFont,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                                searchDecoration: InputDecoration(
                                  prefixIcon: Icon(Icons.search, color: isDarkMode ? Colors.white70 : Colors.grey),
                                  hintText: "Search Country",
                                  hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: isDarkMode ? Colors.white24 : Colors.black12),
                                  ),
                                ),
                                onChanged: (country) {},
                              ),
                              borderRadius: fieldBorderRadius,
                              hintText: "Mobile number",
                              controller: emergencyMobileController,
                              focusNode: emergencyMobileFocus,
                              textInputAction: TextInputAction.none,
                              inputFormatter: [
                                LengthLimitingTextInputFormatter(10),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                            const SizedBox(height: fieldSpace),

                            CommonText(
                              'Relation Type',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: referenceWidth * (isTab ? 0.026 : 0.032),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: titleSpace),
                            CommonDropdown(
                              title: "Select Relation Type",
                              selectedValue: state.selectedEmergencyRelation,
                              options: indianRelations,
                              onSelected: (value) {
                                if (value != null) {
                                  context.read<OnBoardingBloc>().add(UpdateEmergencyRelationEvent(value));
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: fieldSpace * 1.5),
                      _buildTipCard(context, isDarkMode, referenceWidth,isTab),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context, String title, double referenceWidth,bool isTab) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize:isTab ? referenceWidth * 0.062: referenceWidth * 0.082,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.15,
      ),
    );
  }

  Widget _buildSubHeading(BuildContext context, String title, double referenceWidth, bool isTab) {
    return CommonText(
      title,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: referenceWidth * (isTab ? 0.024 : 0.035),
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildGenderSelector(BuildContext context, String currentGender, bool isDark, double referenceWidth,bool isTab) {
    return Row(
      children: [
        _genderCard(context, "Male", Icons.male_rounded, currentGender == "Male", isDark, referenceWidth,isTab),
        const SizedBox(width: 12),
        _genderCard(context, "Female", Icons.female_rounded, currentGender == "Female", isDark, referenceWidth,isTab),
        const SizedBox(width: 12),
        _genderCard(context, "Other", Icons.transgender_rounded, currentGender == "Other", isDark, referenceWidth,isTab),
      ],
    );
  }

  Widget _genderCard(BuildContext context, String label, IconData icon, bool isSelected, bool isDark, double referenceWidth,bool isTab) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<OnBoardingBloc>().add(UpdateGenderEvent(label)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.primaryColor
                : (isDark ? Colors.white.withOpacity(0.04) : Colors.white),
            borderRadius: BorderRadius.circular(fieldBorderRadius ?? 14),
            border: Border.all(
              color: isSelected
                  ? theme.primaryColor
                  : (isDark ? Colors.white10 : Colors.grey.shade200),
              width: 1.8,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize:isTab? referenceWidth * 0.028: referenceWidth * 0.034,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDatePicker(BuildContext context, DateTime initialDate, bool isDark, double referenceWidth, double tabletPadding) {
    DateTime tempSelectedDate = initialDate;
    final theme = Theme.of(context);

    showModalBottomSheet(
      isDismissible: false,
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: tabletPadding),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.only(top: 14, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 5, width: 40,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Select Birthday",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: referenceWidth * 0.044,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: displayHeight(context) / 3.8,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      brightness: isDark ? Brightness.dark : Brightness.light,
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: referenceWidth * 0.048,
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
                      itemExtent: 48,
                      onDateTimeChanged: (DateTime newDate) {
                        tempSelectedDate = newDate;
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: CustomElevatedButton(
                    text: "Confirm",
                    onPressed: () {
                      context.read<OnBoardingBloc>().add(UpdateDOBEvent(tempSelectedDate));
                      Navigator.pop(context);
                    },
                    width: double.infinity,
                    height: 54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDOBPicker(BuildContext context, DateTime? currentDob, bool isDark, double referenceWidth, bool isTab, double tabletPadding) {
    final DateTime displayDate = currentDob ?? DateTime(2000, 1, 1);
    final age = DateTime.now().year - displayDate.year;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _showDatePicker(context, displayDate, isDark, referenceWidth, tabletPadding),
      borderRadius: BorderRadius.circular(fieldBorderRadius ?? 14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(fieldBorderRadius ?? 14),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.calendar_month_rounded, color: theme.primaryColor, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText(
                  'Date of Birth',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: referenceWidth * (isTab ? 0.024 : 0.03),
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMMM dd, yyyy').format(displayDate),
                  style: TextStyle(
                    fontSize: referenceWidth * (isTab ? 0.028 : 0.036),
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$age yrs",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: referenceWidth * (isTab ? 0.024 : 0.03),
                  fontFamily: appPoppinFont,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, bool isDark, double referenceWidth,bool isTab) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.blue.withOpacity(0.06), Colors.purple.withOpacity(0.06)]
              : [const Color(0xFFF4F7FF), const Color(0xFFFAFBFF)],
        ),
        borderRadius: BorderRadius.circular(fieldBorderRadius ?? 14),
        border: Border.all(
          color: isDark ? Colors.blue.withOpacity(0.1) : Colors.blue.withOpacity(0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: theme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Gender and age help our medical AI provide hyper-accurate health risk assessments.',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize:isTab? referenceWidth * 0.024: referenceWidth * 0.032,
                color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, OnBoardingState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: state.isLoading
          ? const SizedBox(height: 56, child: Center(child: CircularProgressIndicator.adaptive()))
          : CustomElevatedButton(
        noElevation: true,
        height: 56,
        width: double.infinity,
        text: "Continue",
        onPressed: () => Navigator.pushNamed(context, AppRoutes.heightScale),
      ),
    );
  }
}