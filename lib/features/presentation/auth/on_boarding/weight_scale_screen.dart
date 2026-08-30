import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../../../config/yira_colors/yira_colors.dart';
import '../../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../../core/common_widgets/custom_button.dart';
import '../../../../../core/weight_custom_painter/weight_ruler.dart';
import 'on_boarding_bloc/on_boarding_bloc.dart';

class WeightScaleScreen extends StatelessWidget {
  const WeightScaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    final double screenWidth = displayWidth(context);

    // Calculate dynamic horizontal padding for tablet viewports to perfectly center a 550px workspace
    final double tabletPadding = isTab ? (screenWidth - 550) / 2 : 0.0;

    return BlocConsumer<OnBoardingBloc, OnBoardingState>(
      listener: (context, state) {
        if (state.isCompleted || state.successMessage != null) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.userConfiguration,
            (route) => false,
          );
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: Padding(
              padding: EdgeInsets.only(left: isTab ? tabletPadding + 8 : 8.0),
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
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.04),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTab ? tabletPadding : 0.0,
                ),
                child: _buildBottomButton(context, state, todayDate),
              ),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Pin rendering boundary references to a max layout scale of 550px for tablet symmetry
                final double referenceWidth = isTab ? 550 : screenWidth;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
                        child: _buildUnitSelector(
                          context,
                          state.currentUnit,
                          isDark,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildWeightDisplay(
                        context,
                        state,
                        isDark,
                        referenceWidth,isTab
                      ),
                      const SizedBox(height: 32),
                      WeightScaleRuler(
                        key: ValueKey(state.currentUnit),
                        currentValue: state.currentWeight,
                        indicatorColor: const Color(0xFF005696),
                        onChanged: (val) => context.read<OnBoardingBloc>().add(
                          UpdateWeightEvent(val),
                        ),
                        unit: state.currentUnit,
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildHeaderSection(
    BuildContext context,
    bool isDark,
    double referenceWidth,bool isTab
  ) {
    return Text(
      'Your Current\nWeight',
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: isTab ? referenceWidth * 0.062: referenceWidth * 0.085,
        fontWeight: FontWeight.w700,
        height: 1.1,
      ),
    );
  }

  Widget _buildWeightDisplay(
    BuildContext context,
    OnBoardingState state,
    bool isDark,
    double referenceWidth,bool isTab
  ) {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                state.currentWeight.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: referenceWidth * 0.18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                  color: isDark ? Colors.white : const Color(0xFF1D1D35),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 18, left: 8),
                child: Text(
                  state.currentUnit,
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
            'Precision is key to tracking your\nmetabolic velocity.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? referenceWidth * 0.024: referenceWidth * 0.035,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSelector(
    BuildContext context,
    String activeUnit,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.grey.withOpacity(0.09),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _unitOption(context, 'kg', activeUnit == 'kgs', isDark),
          _unitOption(context, 'lbs', activeUnit == 'lbs', isDark),
        ],
      ),
    );
  }

  Widget _unitOption(
    BuildContext context,
    String label,
    bool isSelected,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => context.read<OnBoardingBloc>().add(
        ToggleUnitEvent(label == 'kg' ? 'kgs' : 'lbs'),
      ),
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
                  ),
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

  Widget _buildTipCard(
    BuildContext context,
    bool isDark,
    double referenceWidth,bool isTab
  ) {
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: !isDark
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: const Icon(
              Icons.lightbulb_outline_sharp,
              color: Color(0xFF005696),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consistency over Intensity',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1D1D35),
                    fontSize: isTab ? referenceWidth * 0.024: referenceWidth * 0.035,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tracking daily helps our AI understand your fluid patterns.',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? referenceWidth * 0.024: referenceWidth * 0.032,
                    color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    OnBoardingState state,
    String date,
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
              text: "Complete Profile",
              onPressed: () {
                context.read<OnBoardingBloc>().add(SaveOnBoardingEvent(date: date));
              },
            ),
    );
  }
}
