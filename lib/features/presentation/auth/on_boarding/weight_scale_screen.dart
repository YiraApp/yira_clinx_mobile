import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<OnBoardingBloc, OnBoardingState>(
      listener: (context, state) {
        //
        // if (state.successMessage != null) Utils.showSnackBar(message:  state.successMessage!);
        // if (state.errorMessage != null) Utils.showErrorSnackBar(context, state.errorMessage!);
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87, size: 20),
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
          bottomNavigationBar: Container(
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
                ? const SizedBox(height: 50, child: Center(child: CircularProgressIndicator.adaptive()))
                : CustomElevatedButton(
              noElevation: true,
              height: 55,
              width: displayWidth(context),
              text: "Next Step",
              onPressed: () => context.read<OnBoardingBloc>().add(SaveOnBoardingEvent(date: todayDate)),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _buildHeaderSection(context, isDark),
                      const SizedBox(height: 30),
                      Center(child: _buildUnitSelector(context, state.currentUnit)),
                      SizedBox(height: displayHeight(context) * 0.05),
                      _buildWeightDisplay(context, state, isDark),
                      SizedBox(height: displayHeight(context) * 0.05),
                      WeightScaleRuler(
                        key: ValueKey(state.currentUnit),
                        currentValue: state.currentWeight,
                        indicatorColor: const Color(0xFF005696),
                        onChanged: (val) => context.read<OnBoardingBloc>().add(UpdateWeightEvent(val)),
                        unit: state.currentUnit,
                      ),
                      const SizedBox(height: 40),
                      _buildTipCard(context, isDark),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Current\nWeight',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: displayWidth(context) * 0.085,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildWeightDisplay(BuildContext context, OnBoardingState state, bool isDark) {
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
                  fontSize: displayWidth(context) * 0.18,
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
            'Precision is key to tracking your\nmetabolic velocity.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context) * 0.035,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
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
          _unitOption(context, 'kg', activeUnit == 'kgs'),
          _unitOption(context, 'lbs', activeUnit == 'lbs'),
        ],
      ),
    );
  }

  Widget _unitOption(BuildContext context, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => context.read<OnBoardingBloc>().add(ToggleUnitEvent(label == 'kg' ? 'kgs' : 'lbs')),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(fieldBorderRadius),
            ),
            child: const Icon(Icons.lightbulb_outline_sharp, color: Color(0xFF005696)),
          ),
          const SizedBox(width: 15),
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
                    fontSize: displayWidth(context)*0.035,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Tracking daily helps our AI understand your fluid patterns.',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context)*0.032,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}