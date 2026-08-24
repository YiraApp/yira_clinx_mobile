import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/slot/slot_bloc/slot_bloc.dart';
import '../../../core/common_widgets/common_text.dart';
import 'package:intl/intl.dart';
import '../../../core/common_widgets/custom_button.dart';
import 'widgets/execution_card.dart';
import 'widgets/parameters_card.dart';
import 'widgets/slot_configuration_card.dart';
import '../../domain/entities/slot/slot_appointment_entity.dart';

class SmartSchedulerScreen extends StatefulWidget {
  const SmartSchedulerScreen({super.key});

  @override
  State<SmartSchedulerScreen> createState() => _SmartSchedulerScreenState();
}

class _SmartSchedulerScreenState extends State<SmartSchedulerScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SlotBloc>().add(GenerateTemplateSlotsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CommonAppBar(
       titleText: "Smart Scheduler",
      ),
      body: BlocConsumer<SlotBloc, SlotState>(
        buildWhen: (previous, current) => current is SlotDataState,
        listener: (context, state) {
          if (state is SlotDataState && state.deploySuccess) {
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          if (state is! SlotDataState) {
            return SmartSchedulerShimmer(isTab: isTab);
          }

          final dataState = state;

          if (dataState.isLoading) {
            return SmartSchedulerShimmer(isTab: isTab);
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
                            fontSize: isTab?  displayWidth(context) * 0.022:displayWidth(context) * 0.045,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        CommonText(
                          'Adjust algorithm parameters for the upcoming clinical block.',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize:  isTab?  displayWidth(context) * 0.018:displayWidth(context) * 0.03,
                            color: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
                            height: 1.3,
                          ),
                          maxLines: null,
                          softWrap: true,
                        ),
                        const SizedBox(height: 24),
                        ExecutionCard(state: dataState,isTab: isTab,),
                        const SizedBox(height: fieldSpace),
                        ParametersCard(state: dataState,isTab: isTab,),
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
                                  fontSize:isTab?  displayWidth(context) * 0.02: displayWidth(context) * 0.03,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              CommonText(
                                DateFormat(
                                  'EEEE, MMM dd',
                                ).format(dataState.targetDate).toUpperCase(),
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab?  displayWidth(context) * 0.018:displayWidth(context) * 0.03,
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
                            separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              return SlotConfigurationCard(
                                slot: dataState.slots[index],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => _showAddCustomSlotDialog(context, dataState),
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
                                    fontSize:isTab?  displayWidth(context) * 0.02: displayWidth(context) * 0.035,
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
                  width: displayWidth(context),
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
                      ? const Center(child: CircularProgressIndicator.adaptive())
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

  void _showAddCustomSlotDialog(BuildContext context, SlotDataState dataState) {
    TimeOfDay startTime = const TimeOfDay(hour: 17, minute: 0);
    if (dataState.slots.isNotEmpty) {
      try {
        final last = dataState.slots.last;
        final dt = DateFormat('h:mm a').parse(last.endTime);
        startTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {}
    }

    final duration = dataState.durationMinutes;
    int endTotalMin = (startTime.hour * 60 + startTime.minute + duration) % (24 * 60);
    TimeOfDay endTime = TimeOfDay(hour: endTotalMin ~/ 60, minute: endTotalMin % 60);
    String status = 'Available';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final theme = Theme.of(context);

            String formatTime(TimeOfDay t) {
              final dt = DateTime(2000, 1, 1, t.hour, t.minute);
              return DateFormat('h:mm a').format(dt);
            }

            int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_alarm_rounded, color: theme.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: CommonText(
                      'Add Custom Slot',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CommonText(
                    'Choose start and end times for this custom slot.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CommonText('Start Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final chosen = await showTimePicker(context: context, initialTime: startTime);
                                if (chosen != null) {
                                  setDialogState(() {
                                    startTime = chosen;
                                    int autoEndMin = (chosen.hour * 60 + chosen.minute + duration) % (24 * 60);
                                    endTime = TimeOfDay(hour: autoEndMin ~/ 60, minute: autoEndMin % 60);
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    CommonText(formatTime(startTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CommonText('End Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final chosen = await showTimePicker(context: context, initialTime: endTime);
                                if (chosen != null) {
                                  setDialogState(() {
                                    endTime = chosen;
                                  });
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    CommonText(formatTime(endTime), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const CommonText('Initial Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Available')),
                          selected: status == 'Available',
                          selectedColor: Colors.green.withOpacity(0.2),
                          onSelected: (val) => setDialogState(() => status = 'Available'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Blocked')),
                          selected: status == 'Blocked',
                          selectedColor: Colors.redAccent.withOpacity(0.2),
                          onSelected: (val) => setDialogState(() => status = 'Blocked'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const CommonText('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final startMin = toMinutes(startTime);
                    final endMin = toMinutes(endTime);

                    if (startMin >= endMin) {
                      _showOverlapAlertDialog(
                        context,
                        title: 'Invalid Time Range',
                        message: 'Start time (${formatTime(startTime)}) must be earlier than end time (${formatTime(endTime)}).',
                      );
                      return;
                    }

                    // Overlap check against existing slots
                    SlotEntity? conflict;
                    for (final existing in dataState.slots) {
                      int eStart = 0;
                      int eEnd = 0;
                      try {
                        final dtS = DateFormat('h:mm a').parse(existing.startTime);
                        eStart = dtS.hour * 60 + dtS.minute;
                        final dtE = DateFormat('h:mm a').parse(existing.endTime);
                        eEnd = dtE.hour * 60 + dtE.minute;
                      } catch (_) {
                        continue;
                      }

                      if (startMin < eEnd && endMin > eStart) {
                        conflict = existing;
                        break;
                      }
                    }

                    if (conflict != null) {
                      _showOverlapAlertDialog(
                        context,
                        title: 'Time Slot Overlap Detected',
                        message: 'The proposed slot (${formatTime(startTime)} - ${formatTime(endTime)}) overlaps with an existing slot:\n\n• ${conflict.startTime} - ${conflict.endTime} (${conflict.label})\n\nPlease choose a non-overlapping time range.',
                      );
                      return;
                    }

                    // No overlap -> add slot
                    context.read<SlotBloc>().add(
                      AddCustomSlotEvent(
                        startTime: formatTime(startTime),
                        endTime: formatTime(endTime),
                        label: status,
                      ),
                    );
                    Navigator.pop(dialogContext);
                  },
                  child: const CommonText('Add Slot', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showOverlapAlertDialog(BuildContext context, {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (alertContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: CommonText(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: CommonText(
          message,
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
            child: const CommonText('OK, I will adjust'),
          ),
        ],
      ),
    );
  }
}
