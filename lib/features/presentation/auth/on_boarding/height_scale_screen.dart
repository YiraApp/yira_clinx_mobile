import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../../../config/yira_colors/yira_colors.dart';
import '../../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../../core/common_widgets/custom_button.dart';
import '../../../../../core/height_custom_painter/height_ruler.dart';
import 'on_boarding_bloc/on_boarding_bloc.dart';

class HeightScaleScreen extends StatelessWidget {
  const HeightScaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<OnBoardingBloc, OnBoardingState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new,
                  color: isDark ? Colors.white : Colors.black87, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Personal Health',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: displayWidth(context) * 0.045,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomButton(context, state, todayDate, isDark),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildHeaderSection(context, isDark),
                const SizedBox(height: 20),
                Center(child: _buildUnitSelector(context, state.currentHeightUnit)),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 15,
                        child: VerticalHeightRuler(
                          key: ValueKey(state.currentHeightUnit),
                          currentValue: state.currentHeight,
                          unit: state.currentHeightUnit,
                          onChanged: (val) => context.read<OnBoardingBloc>().add(UpdateHeightEvent(val)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 25,
                        child: _buildHeightDisplay(context, state, isDark),
                      ),
                    ],
                  ),
                ),
                _buildTipCard(context, isDark),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context, bool isDark) {
    return Text(
      'What is Your\nHeight?',
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: displayWidth(context) * 0.085,
        fontWeight: FontWeight.w700,
        height: 1.1,
      ),
    );
  }

  Widget _buildHeightDisplay(BuildContext context, OnBoardingState state, bool isDark) {
    final String formattedHeight = state.currentHeightUnit == 'in'
        ? state.currentHeight.toStringAsFixed(1)
        : state.currentHeight.toStringAsFixed(0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formattedHeight,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                    color: isDark ? Colors.white : const Color(0xFF1D1D35),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Text(
                state.currentHeightUnit,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: displayWidth(context) * 0.06,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Accurate height helps us\ncalculate your BMI and BMR.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: displayWidth(context) * 0.035,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitSelector(BuildContext context, String activeUnit) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.09),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _unitOption(context, 'cm', activeUnit == 'cm'),
          _unitOption(context, 'in', activeUnit == 'in'),
        ],
      ),
    );
  }

  Widget _unitOption(BuildContext context, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => context.read<OnBoardingBloc>().add(ToggleHeightUnitEvent(label)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(fieldBorderRadius),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: appPoppinFont,
            color: isSelected ? primaryColor : Colors.grey,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, OnBoardingState state, String date, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          screenHorizontalSpacePadding,
          10,
          screenHorizontalSpacePadding,
          MediaQuery.of(context).padding.bottom + 10
      ),
      decoration: BoxDecoration(
        color: isDark ? newDarkModeBgColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: state.isLoading
          ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()))
          : CustomElevatedButton(
        noElevation: true,
        height: 55,
        width: displayWidth(context),
        text: "Complete Profile",
        onPressed: () => context.read<OnBoardingBloc>().add(SaveOnBoardingEvent(date: date)),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF2F6FF),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF005696)),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              'Your height usually stays constant, but tracking it helps in monitoring postural health.',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: displayWidth(context) * 0.032,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}