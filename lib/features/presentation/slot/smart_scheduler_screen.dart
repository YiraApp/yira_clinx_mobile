import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/slot/slot_bloc/slot_bloc.dart';
import '../../../core/common_widgets/common_text.dart';
import 'package:intl/intl.dart';
import '../../../core/common_widgets/custom_button.dart';
import 'widgets/execution_card.dart';
import 'widgets/parameters_card.dart';
import 'widgets/slot_configuration_card.dart';

class SmartSchedulerScreen extends StatefulWidget {
  const SmartSchedulerScreen({super.key});

  @override
  State<SmartSchedulerScreen> createState() => _SmartSchedulerScreenState();
}

class _SmartSchedulerScreenState extends State<SmartSchedulerScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SlotBloc>().add(InitializeSlotsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CommonAppBar(
       titleText: "Smart Scheduler",
      ),
      body: BlocConsumer<SlotBloc, SlotState>(
        buildWhen: (previous, current) => current is SlotDataState,
        listener: (context, state) {
          if (state is SlotDataState && state.deploySuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: theme.colorScheme.primary,
                content: Text(
                  'Schedule Deployed Successfully!',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.03,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is! SlotDataState) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            );
          }

          final dataState = state;

          if (dataState.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: screenHorizontalSpacePadding,
                      vertical: screenTopPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonText(
                          'Configure Optimization Engine',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: displayWidth(context) * 0.045,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        CommonText(
                          'Adjust algorithm parameters for the upcoming clinical block.',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: displayWidth(context) * 0.03,
                            color: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
                            height: 1.3,
                          ),
                          maxLines: null,
                          softWrap: true,
                        ),
                        const SizedBox(height: 24),
                        ExecutionCard(state: dataState),
                        const SizedBox(height: fieldSpace),
                        ParametersCard(state: dataState),
                        const SizedBox(height: inputFieldBorderRadius),
                        if (dataState.isSingleDay &&
                            dataState.slots.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CommonText(
                                'Daily Slots',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: displayWidth(context) * 0.03,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              CommonText(
                                DateFormat(
                                  'EEEE, MMM dd',
                                ).format(dataState.targetDate).toUpperCase(),
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: displayWidth(context) * 0.03,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey.shade500,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (dataState.isSingleDay) ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dataState.slots.length,
                            separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return SlotConfigurationCard(
                                slot: dataState.slots[index],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => context.read<SlotBloc>().add(
                              AddCustomSlotEvent(),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              side: BorderSide(
                                color: theme.primaryColor.withOpacity(0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(fieldBorderRadius),
                              ),
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.02)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 18,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                CommonText(
                                  'Add Custom Slot',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: displayWidth(context) * 0.035,
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black26 : Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: dataState.isDeploying
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : CustomElevatedButton(
                          noElevation: true,
                          height: 50,
                          width: displayWidth(context),
                          text: "Deploy Schedular",
                          onPressed: () => context.read<SlotBloc>().add(
                            DeployScheduleEvent(),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
