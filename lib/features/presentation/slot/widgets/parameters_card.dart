import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/features/presentation/slot/widgets/section_card_wrapper.dart';
import '../../../../core/common_drop_down/common_drop_down.dart';
import '../../../../core/constants/constants.dart';
import '../slot_bloc/slot_bloc.dart';
import '../../../../core/common_widgets/common_text.dart';

class ParametersCard extends StatelessWidget {
  final SlotDataState state;
  final bool isTab;

  const ParametersCard({super.key, required this.state, required this.isTab});

  @override
  Widget build(BuildContext context) {
    return SectionCardWrapper(
      icon: Icons.tune_rounded,
      title: 'Parameters',
      isTab: isTab,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardLabel(context, 'Slot Duration', isTab),
                    const SizedBox(height: 8),
                    CommonDropdown(
                      title: 'Select Duration',
                      options: const ['15 Minutes', '20 Minutes', '30 Minutes', '45 Minutes', '60 Minutes'],
                      selectedValue: '${state.durationMinutes} Minutes',
                      onSelected: (String value) {
                        final int? parsedMinutes = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
                        if (parsedMinutes != null) {
                          context.read<SlotBloc>().add(ChangeDurationEvent(parsedMinutes));
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardLabel(context, 'Buffer Time', isTab),
                    const SizedBox(height: 8),
                    CommonDropdown(
                      title: 'Select Buffer',
                      options: const ['Continuous', '5 Minutes', '10 Minutes', '15 Minutes'],
                      selectedValue: state.bufferType,
                      onSelected: (String value) {
                        context.read<SlotBloc>().add(ChangeBufferEvent(value));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardLabel(context, 'From Time', isTab),
                    const SizedBox(height: 8),
                    _buildTimeSelector(context, state.fromTime, (chosenTime) {
                      _validateAndUpdateTimeRange(context, chosenTime, state.toTime);
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardLabel(context, 'To Time', isTab),
                    const SizedBox(height: 8),
                    _buildTimeSelector(context, state.toTime, (chosenTime) {
                      _validateAndUpdateTimeRange(context, state.fromTime, chosenTime);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(BuildContext context, String currentTime, Function(String) onPicked) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);

    return InkWell(
      onTap: () async {
        TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
        try {
          final dt = DateFormat('h:mm a').parse(currentTime);
          initial = TimeOfDay(hour: dt.hour, minute: dt.minute);
        } catch (_) {}

        final chosen = await showTimePicker(
          context: context,
          initialTime: initial,
        );

        if (chosen != null) {
          final dt = DateTime(2000, 1, 1, chosen.hour, chosen.minute);
          final formatted = DateFormat('h:mm a').format(dt);
          onPicked(formatted);
        }
      },
      borderRadius: BorderRadius.circular(fieldBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? darkModeCardColor : lightModeTextFieldBgColor,
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          border: Border.all(
            color: isDark ? darkModeBorderColor : lightModeBorderColor,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CommonText(
                currentTime,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : textLightModeColor,
                ),
              ),
            ),
            Icon(
              Icons.access_time_rounded,
              size: 18,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  void _validateAndUpdateTimeRange(BuildContext context, String from, String to) {
    int fromMin = 0;
    int toMin = 0;
    try {
      final dtFrom = DateFormat('h:mm a').parse(from);
      fromMin = dtFrom.hour * 60 + dtFrom.minute;
      final dtTo = DateFormat('h:mm a').parse(to);
      toMin = dtTo.hour * 60 + dtTo.minute;
    } catch (_) {}

    if (fromMin >= toMin) {
      showDialog(
        context: context,
        builder: (alertContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: CommonText(
                  'Invalid Time Range',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: CommonText(
            'From Time ($from) must be earlier than To Time ($to).',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(alertContext),
              child: const CommonText('OK'),
            ),
          ],
        ),
      );
      return;
    }

    context.read<SlotBloc>().add(
      UpdateTimeRangeEvent(fromTime: from, toTime: to),
    );
  }

  Widget _buildCardLabel(BuildContext context, String text, bool isTab) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CommonText(
      text,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white60 : Colors.blueGrey,
        letterSpacing: 0.8,
      ),
    );
  }
}