import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../../../config/yira_colors/yira_colors.dart';
import '../../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../../core/common_widgets/custom_button.dart';
import '../../../../../core/height_custom_painter/height_ruler.dart';
import '../../../../config/app_route/app_routes.dart';
import 'on_boarding_bloc/on_boarding_bloc.dart';

class HeightScaleScreen extends StatelessWidget {
  const HeightScaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    final double screenWidth = displayWidth(context);

    // Calculate dynamic horizontal padding for tablet viewports to center a 550px workspace
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
            centerTitle: true,
            leading: Padding(
              padding: EdgeInsets.only(left: isTab ?  8 : 8.0),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: isDark ? Colors.white : Colors.black87,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            title: Text(
              'Personal Health',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: (isTab ? 550 : screenWidth) * 0.045,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? newDarkModeBgColor : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isTab ? tabletPadding : 0.0),
                child: _buildBottomButton(context, state, todayDate, isDark, isTab),
              ),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine layout calculation width limits safely across form targets
                final double referenceWidth = isTab ? 550 : screenWidth;

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenHorizontalSpacePadding + tabletPadding,
                    10,
                    screenHorizontalSpacePadding + tabletPadding,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(context, isDark, referenceWidth,isTab),
                      const SizedBox(height: 20),
                      Center(
                        child: _buildUnitSelector(context, state.currentHeightUnit, isDark),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 15,
                              child: VerticalHeightRuler(
                                key: ValueKey(state.currentHeightUnit),
                                currentValue: state.currentHeight,
                                unit: state.currentHeightUnit,
                                onChanged: (val) => context
                                    .read<OnBoardingBloc>()
                                    .add(UpdateHeightEvent(val)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 25,
                              child: _buildHeightDisplay(context, state, isDark, referenceWidth,isTab),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTipCard(context, isDark, referenceWidth,isTab),
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

  Widget _buildHeaderSection(BuildContext context, bool isDark, double referenceWidth,bool isTab) {
    return Text(
      'What is Your\nHeight?',
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: isTab ? referenceWidth * 0.062: referenceWidth * 0.085,
        fontWeight: FontWeight.w700,
        height: 1.1,
      ),
    );
  }

  Widget _buildHeightDisplay(
      BuildContext context,
      OnBoardingState state,
      bool isDark,
      double referenceWidth,bool isTab
      ) {
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
                    fontSize: referenceWidth * 0.18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2,
                    color: isDark ? Colors.white : const Color(0xFF1D1D35),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                state.currentHeightUnit,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: referenceWidth * 0.06,
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
            fontSize: isTab ? referenceWidth * 0.024: referenceWidth * 0.035,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildUnitSelector(BuildContext context, String activeUnit, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.09),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _unitOption(context, 'cm', activeUnit == 'cm', isDark),
          _unitOption(context, 'in', activeUnit == 'in', isDark),
        ],
      ),
    );
  }

  Widget _unitOption(BuildContext context, String label, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () =>
          context.read<OnBoardingBloc>().add(ToggleHeightUnitEvent(label)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white.withOpacity(0.15) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          boxShadow: isSelected && !isDark
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]
              : [],
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: appPoppinFont,
            color: isSelected ? primaryColor : Colors.grey.shade500,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(
      BuildContext context,
      OnBoardingState state,
      String date,
      bool isDark,
      bool isTab,
      ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: state.isLoading
          ? const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator.adaptive()),
      )
          : CustomElevatedButton(
        noElevation: true,
        height: 56,
        width: double.infinity,
        text: "Continue",
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.weightScale),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, bool isDark, double referenceWidth , bool isTab) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(color: Colors.blue.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF005696), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your height usually stays constant, but tracking it helps in monitoring postural health.',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize:isTab ? referenceWidth * 0.024:  referenceWidth * 0.032,
                color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}