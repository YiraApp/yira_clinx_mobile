import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/features/presentation/slot/widgets/section_card_wrapper.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/common_date_picker.dart';
import '../slot_bloc/slot_bloc.dart';
import '../../../../core/common_widgets/common_text.dart';

class ExecutionCard extends StatelessWidget {
  final SlotState state;
  final bool isTab;

  const ExecutionCard({super.key, required this.state, required this.isTab});

  @override
  Widget build(BuildContext context) {
    if (state is! SlotDataState) {
      return const SizedBox.shrink();
    }

    final dataState = state as SlotDataState;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SectionCardWrapper(
      icon: Icons.calendar_month_rounded,
      title: 'Schedule Dates',
      isTab: isTab,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardLabel(context, 'Schedule For', isDark, isTab),
          const SizedBox(height: 10),
          _buildRunModeToggle(context, dataState, isTab),
          const SizedBox(height: 20),
          _buildDatePickerTrigger(context, dataState, isDark, isTab),
        ],
      ),
    );
  }

  Widget _buildCardLabel(BuildContext context, String text, bool isDark, bool isTab) {
    return CommonText(
      text,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white70 : const Color(0xFF334155),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildRunModeToggle(BuildContext context, SlotDataState dataState, bool isTab) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleSegment(
              label: 'Single Day',
              icon: Icons.today_rounded,
              isSelected: dataState.isSingleDay,
              onTap: () => context.read<SlotBloc>().add(ChangeExecutionModeEvent(true)),
              isTab: isTab,
              primaryColor: primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ToggleSegment(
              label: 'Multiple Days',
              icon: Icons.date_range_rounded,
              isSelected: !dataState.isSingleDay,
              onTap: () => context.read<SlotBloc>().add(ChangeExecutionModeEvent(false)),
              isTab: isTab,
              primaryColor: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerTrigger(BuildContext context, SlotDataState dataState, bool isDark, isTab) {
    if (dataState.isSingleDay) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            "Select Date",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          CommonDatePicker(
            selectedDate: dataState.targetDate,
            firstDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
            onDateSelected: (DateTime chosen) {
              context.read<SlotBloc>().add(UpdateTargetDateEvent(chosen));
            },
          ),
        ],
      );
    }

    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonText(
                "Start Date",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              CommonDatePicker(
                selectedDate: dataState.startDate,
                firstDate: today,
                onDateSelected: (DateTime chosen) {
                  final difference = dataState.endDate.difference(chosen).inDays;
                  if (difference > 7) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Invalid Date Range'),
                        content: const Text('The date range cannot be greater than 7 days.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  context.read<SlotBloc>().add(
                    UpdateDateRangeEvent(
                      startDate: chosen,
                      endDate: dataState.endDate.isBefore(chosen) ? chosen : dataState.endDate,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonText(
                "End Date",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 8),
              CommonDatePicker(
                selectedDate: dataState.endDate,
                firstDate: dataState.startDate.isBefore(today) ? today : dataState.startDate,
                onDateSelected: (DateTime chosen) {
                  final difference = chosen.difference(dataState.startDate).inDays;

                  if (difference > 7) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Invalid Date Range'),
                        content: const Text('The date range cannot be greater than 7 days.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  context.read<SlotBloc>().add(
                    UpdateDateRangeEvent(
                      startDate: dataState.startDate,
                      endDate: chosen,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isTab;
  final Color primaryColor;

  const _ToggleSegment({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isTab,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white54 : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              CommonText(
                label,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.03,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}