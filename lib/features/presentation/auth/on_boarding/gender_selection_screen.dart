import 'package:flutter/cupertino.dart'; // Added for CupertinoDatePicker
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../../core/common_widgets/custom_button.dart';
import 'on_boarding_bloc/on_boarding_bloc.dart';

class GenderAgeSelectionScreen extends StatelessWidget {
  const GenderAgeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<OnBoardingBloc, OnBoardingState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new,
                  color: isDark ? Colors.white : Colors.black87, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          bottomNavigationBar: _buildBottomButton(context, state),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _buildHeaderSection(context, "Tell us about\nyourself"),
                const SizedBox(height: 40),

                _buildSubHeading(context,"Select Gender"),
                const SizedBox(height: 16),
                _buildGenderSelector(context, state.selectedGender, isDark),

                const SizedBox(height: 40),

                _buildSubHeading(context,"Date of Birth"),
                const SizedBox(height: 16),
                _buildDOBPicker(context, state.selectedDob ?? DateTime(2000, 1, 1), isDark),

                const SizedBox(height: 40),
                _buildTipCard(context, isDark),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildHeaderSection(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: displayWidth(context) * 0.08,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.2,
      ),
    );
  }

  Widget _buildSubHeading(BuildContext context,String title) {
    return Text(
      title,
      style:  TextStyle(
        fontFamily: appPoppinFont,
        fontSize: displayWidth(context) * 0.038,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildGenderSelector(BuildContext context, String currentGender, bool isDark) {
    return Row(
      children: [
        _genderCard(context, "Male", Icons.male_rounded, currentGender == "Male", isDark),
        const SizedBox(width: 12),
        _genderCard(context, "Female", Icons.female_rounded, currentGender == "Female", isDark),
        const SizedBox(width: 12),
        _genderCard(context, "Other", Icons.transgender_rounded, currentGender == "Other", isDark),
      ],
    );
  }

  Widget _genderCard(BuildContext context, String label, IconData icon, bool isSelected, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<OnBoardingBloc>().add(UpdateGenderEvent(label)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
            borderRadius: BorderRadius.circular(fieldBorderRadius),
            border: Border.all(
              color: isSelected ? primaryColor : (isDark ? Colors.white10 : Colors.grey.shade200),
              width: 2,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black45),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: displayWidth(context)*0.035,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showDatePicker(BuildContext context, DateTime initialDate, bool isDark) {
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
                color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                    "Select Birthday",
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: CustomElevatedButton(
                      text: "Confirm",
                      onPressed: () {
                        context.read<OnBoardingBloc>().add(UpdateDOBEvent(tempSelectedDate));
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
  Widget _buildDOBPicker(BuildContext context, DateTime? currentDob, bool isDark) {
    final DateTime displayDate = currentDob ?? DateTime(2000, 1, 1);
    final age = DateTime.now().year - displayDate.year;

    return InkWell(
      onTap: () => _showDatePicker(context, displayDate, isDark),
      borderRadius: BorderRadius.circular(fieldBorderRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.transparent : Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(fieldBorderRadius),
              ),
              child: Icon(Icons.calendar_month_rounded, color: primaryColor),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Date of Birth",
                  style: TextStyle(
                    fontSize: displayWidth(context)*0.03,
                    fontFamily: appPoppinFont,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('MMMM dd, yyyy').format(displayDate),
                  style:  TextStyle(
                    fontSize: displayWidth(context)*0.036,
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
                gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)]),
                borderRadius: BorderRadius.circular(fieldBorderRadius),
              ),
              child: Text(
                "$age yrs",
                style:  TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: displayWidth(context)*0.03,fontFamily: appPoppinFont,),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.blue.withOpacity(0.1), Colors.purple.withOpacity(0.1)]
              : [const Color(0xFFF2F6FF), const Color(0xFFF9FAFF)],
        ),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, color: primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Gender and age help our medical AI provide hyper-accurate health risk assessments.',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: displayWidth(context) * 0.032,
                color: isDark ? Colors.white70 : Colors.blueGrey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, OnBoardingState state) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 10, 24, MediaQuery.of(context).padding.bottom + 10),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomElevatedButton(
        noElevation: true,
        height: 58,
        width: double.infinity,
        text: "Continue",
        onPressed: () => Navigator.pushNamed(context, '/heightScale'),
      ),
    );
  }
}