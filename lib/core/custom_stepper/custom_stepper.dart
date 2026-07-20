
import 'package:flutter/material.dart';

import '../common_size_helpers/common_size_helpers.dart';
import '../constants/constants.dart';
class CustomStepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final Color selectedColor;
  final Color unselectedColor;
  final double size;

  const CustomStepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.selectedColor,
    required this.unselectedColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width:isTablet(context) ?displayWidth(context)/5.2: displayWidth(context)/3.6,
          height: size,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? selectedColor : unselectedColor,
            borderRadius: BorderRadius.circular(fieldBorderRadius), // Rounded corners
          ),
        );
      }),
    );
  }
}