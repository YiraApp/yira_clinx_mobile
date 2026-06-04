import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/features/presentation/slot/widgets/section_card_wrapper.dart';
import '../../../../core/common_drop_down/common_drop_down.dart';
import '../../../../core/constants/constants.dart';
import '../slot_bloc/slot_bloc.dart';
import '../../../../core/common_widgets/common_text.dart';
class ParametersCard extends StatelessWidget {
  final SlotState state;

  const ParametersCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SectionCardWrapper(
      icon: Icons.tune_rounded,
      title: 'Parameters',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardLabel(context, 'Slot Duration'),
                const SizedBox(height: 8),
                CommonDropdown(
                  title: 'Select Duration',
                  options: const ['15', '20', '30', '45', '60'],
                  selectedValue: '${state.durationMinutes} Minutes',
                  onSelected: (String value) {
                    final int? parsedMinutes = int.tryParse(value);
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
                _buildCardLabel(context, 'Buffer Time'),
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
    );
  }

  Widget _buildCardLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CommonText(
      text,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: displayWidth(context) * 0.032,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white60 : Colors.blueGrey,
        letterSpacing: 0.8,
      ),
    );
  }
}