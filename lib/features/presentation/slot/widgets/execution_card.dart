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

  const ExecutionCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SectionCardWrapper(
      icon: Icons.settings_outlined,
      title: 'Execution',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardLabel(context, 'Run Mode',isDark),
          const SizedBox(height: 8),
          _buildRunModeToggle(context),
          const SizedBox(height: 20),
          // _buildCardLabel(context, state.isSingleDay ? 'Target Date' : 'Target Date Range'),
          // const SizedBox(height: 12),
          _buildDatePickerTrigger(context,isDark),
        ],
      ),
    );
  }

  Widget _buildCardLabel(BuildContext context, String text,bool isDark) {
    return CommonText(
      text,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: displayWidth(context) * 0.032,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white60 : Colors.blueGrey,
      ),
    );
  }

  Widget _buildRunModeToggle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? theme.inputDecorationTheme.fillColor : const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleSegment(
              label: 'Single Day',
              isSelected: state.isSingleDay,
              onTap: () => context.read<SlotBloc>().add(ChangeExecutionModeEvent(true)),
            ),
          ),
          Expanded(
            child: _ToggleSegment(
              label: 'Date Range',
              isSelected: !state.isSingleDay,
              onTap: () => context.read<SlotBloc>().add(ChangeExecutionModeEvent(false)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerTrigger(BuildContext context,bool isDark) {
    if (state.isSingleDay) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommonText(
            "Select Date",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context) * 0.032,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          CommonDatePicker(
            selectedDate: state.targetDate,
            onDateSelected: (DateTime chosen) {
              context
                  .read<SlotBloc>()
                  .add(UpdateTargetDateEvent(chosen));
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
            fontSize: displayWidth(context) * 0.032,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 8),

        CommonDatePicker(
          selectedDate: state.startDate,
          onDateSelected: (DateTime chosen) {
            final difference =
                state.endDate.difference(chosen).inDays;

            if (difference > 7) {
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                  content: Text(
                    'The date range cannot be greater than 7 days.', style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.032,
                    fontWeight: FontWeight.w600,
                  )
                  ),
                ),
              );
              return;
            }

            context.read<SlotBloc>().add(
              UpdateDateRangeEvent(
                startDate: chosen,
                endDate: state.endDate.isBefore(chosen)
                    ? chosen
                    : state.endDate,
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        CommonText(
          "End Date",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: displayWidth(context) * 0.032,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.blueGrey,

          ),
        ),
        const SizedBox(height: 8),

        /// END DATE
        CommonDatePicker(
          selectedDate: state.endDate,
          onDateSelected: (DateTime chosen) {
            final difference =
                chosen.difference(state.startDate).inDays;

            if (difference > 7) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'The date range cannot be greater than 7 days.',
                  ),
                ),
              );
              return;
            }

            context.read<SlotBloc>().add(
              UpdateDateRangeEvent(
                startDate: state.startDate,
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

  const _ToggleSegment({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: CommonText(
            label,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context) * 0.032,
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