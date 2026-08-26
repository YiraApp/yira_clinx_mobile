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
                        if (dataState.slots.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CommonText(
                                      dataState.isSingleDay ? 'Daily Slots' : 'Daily Slots Template',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.038,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (!dataState.isSingleDay)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: CommonText(
                                          'These slots will apply to all days in date range',
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: isTab ? displayWidth(context) * 0.015 : displayWidth(context) * 0.028,
                                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CommonText(
                                  dataState.isSingleDay
                                      ? DateFormat('EEEE, MMM dd').format(dataState.targetDate)
                                      : "${DateFormat('MMM dd').format(dataState.startDate)} - ${DateFormat('MMM dd').format(dataState.endDate)}",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.028,
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final timelineItems = _buildTimelineItems(dataState.slots, dataState.breakTimes);
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: timelineItems.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final item = timelineItems[index];
                                  if (item is SlotEntity) {
                                    return SlotConfigurationCard(
                                      slot: item,
                                    );
                                  } else if (item is BreakTimeEntity) {
                                    return _buildBreakTimelineCard(context, item, isDark, isTab);
                                  }
                                  return const SizedBox.shrink();
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => _showAddCustomSlotDialog(context, dataState),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              side: BorderSide(
                                color: theme.primaryColor.withValues(alpha: 0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(fieldBorderRadius),
                              ),
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.02)
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
                                    fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.035,
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(fieldBorderRadius),
                              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.event_busy_rounded, color: Colors.grey.shade400, size: 40),
                                const SizedBox(height: 10),
                                const CommonText(
                                  'No slots generated for current parameters.',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                const CommonText(
                                  'Try adjusting shift times, break times, or add custom slots.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: () => _showAddCustomSlotDialog(context, dataState),
                                  icon: Icon(Icons.add, size: 16, color: theme.primaryColor),
                                  label: CommonText('Add Custom Slot', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: theme.primaryColor.withValues(alpha: 0.5)),
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
                          text: dataState.isSingleDay
                              ? "Deploy Schedule (${dataState.slots.length} Slots)"
                              : "Deploy Schedule (${dataState.slots.length} Slots/Day)",
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
                      color: theme.primaryColor.withValues(alpha: 0.12),
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
                          selectedColor: Colors.green.withValues(alpha: 0.2),
                          onSelected: (val) => setDialogState(() => status = 'Available'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Blocked')),
                          selected: status == 'Blocked',
                          selectedColor: Colors.redAccent.withValues(alpha: 0.2),
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

  int _timeStringToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 0;
    try {
      final cleaned = timeStr.replaceAll(RegExp(r'[\s\u00A0\u2000-\u200B\u202F]+'), ' ').trim();
      final match = RegExp(r'^(\d{1,2}):(\d{2})\s*([a-zA-Z]{2})?', caseSensitive: false).firstMatch(cleaned);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        String? ampm = match.group(3)?.toUpperCase();

        if (ampm == 'PM' && hour < 12) {
          hour += 12;
        } else if (ampm == 'AM' && hour == 12) {
          hour = 0;
        }
        return hour * 60 + minute;
      }
      DateTime dt;
      if (cleaned.toUpperCase().contains('AM') || cleaned.toUpperCase().contains('PM')) {
        try {
          dt = DateFormat('h:mm a').parse(cleaned);
        } catch (_) {
          dt = DateFormat('hh:mm a').parse(cleaned);
        }
      } else {
        dt = DateFormat('HH:mm').parse(cleaned);
      }
      return dt.hour * 60 + dt.minute;
    } catch (_) {
      return 0;
    }
  }

  List<dynamic> _buildTimelineItems(List<SlotEntity> slots, List<BreakTimeEntity> breakTimes) {
    final List<dynamic> items = [...slots, ...breakTimes];
    items.sort((a, b) {
      final aTime = a is SlotEntity ? a.startTime : (a as BreakTimeEntity).fromTime;
      final bTime = b is SlotEntity ? b.startTime : (b as BreakTimeEntity).fromTime;
      return _timeStringToMinutes(aTime).compareTo(_timeStringToMinutes(bTime));
    });
    return items;
  }

  Widget _buildBreakTimelineCard(BuildContext context, BreakTimeEntity b, bool isDark, bool isTab) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: isDark ? Colors.amber.withValues(alpha: 0.3) : const Color(0xFFFDE68A),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.free_breakfast_rounded,
              color: Colors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CommonText(
                      b.label.isNotEmpty ? b.label : 'Break Period',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontWeight: FontWeight.bold,
                        fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.032,
                        color: isDark ? Colors.amber.shade300 : const Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.amber : const Color(0xFFB45309)).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: CommonText(
                        'Break',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.amber.shade300 : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                CommonText(
                  '${b.fromTime} - ${b.toTime} • Break period (No slots scheduled)',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.026,
                    color: isDark ? Colors.white60 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              context.read<SlotBloc>().add(RemoveBreakTimeEvent(b.id));
            },
          ),
        ],
      ),
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
