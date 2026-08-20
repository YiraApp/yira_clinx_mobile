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
      icon: Icons.settings_outlined,
      title: 'Execution',
       isTab: isTab,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardLabel(context, 'Run Mode', isDark,isTab),
          const SizedBox(height: 8),
          _buildRunModeToggle(context, dataState,isTab),
          const SizedBox(height: 20),
          _buildDatePickerTrigger(context, dataState, isDark,isTab),
        ],
      ),
    );
  }

  Widget _buildCardLabel(BuildContext context, String text, bool isDark,bool isTab) {
    return CommonText(
      text,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize:isTab? displayWidth(context)*0.018: displayWidth(context) * 0.032,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white60 : Colors.blueGrey,
      ),
    );
  }

  Widget _buildRunModeToggle(BuildContext context, SlotDataState dataState,bool isTab) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? theme.inputDecorationTheme.fillColor : const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleSegment(
              label: 'Single Day',
              isSelected: dataState.isSingleDay,
              onTap: () => context.read<SlotBloc>().add(ChangeExecutionModeEvent(true)), isTab: isTab,
            ),
          ),
          Expanded(
            child: _ToggleSegment(
              label: 'Date Range',
              isSelected: !dataState.isSingleDay,
              onTap: () => context.read<SlotBloc>().add(ChangeExecutionModeEvent(false)), isTab: isTab
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerTrigger(BuildContext context, SlotDataState dataState, bool isDark,isTab) {
    if (dataState.isSingleDay) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            "Select Date",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab?  displayWidth(context) * 0.018: displayWidth(context) * 0.032,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          CommonDatePicker(
            selectedDate: dataState.targetDate,
            onDateSelected: (DateTime chosen) {
              context.read<SlotBloc>().add(UpdateTargetDateEvent(chosen));
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonText(
          "Start Date",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize:isTab?  displayWidth(context) * 0.018: displayWidth(context) * 0.032,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        CommonDatePicker(
          selectedDate: dataState.startDate,
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
        const SizedBox(height: 20),
        CommonText(
          "End Date",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize:isTab?  displayWidth(context) * 0.018: displayWidth(context) * 0.032,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),
        CommonDatePicker(
          selectedDate: dataState.endDate,
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
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isTab;

  const _ToggleSegment({required this.label, required this.isSelected, required this.onTap, required this.isTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(fieldBorderRadius),
        ),
        child: Center(
          child: CommonText(
            label,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize:isTab?  displayWidth(context) * 0.018: displayWidth(context) * 0.032,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF495057)),
            ),
          ),
        ),
      ),
    );
  }
}