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
    final primaryColor = theme.primaryColor;

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
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Schedule deployed successfully!',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ),
            );
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
                        ExecutionCard(state: dataState, isTab: isTab),
                        const SizedBox(height: 16),
                        ParametersCard(
                          state: dataState,
                          isTab: isTab,
                        ),
                        const SizedBox(height: 24),
                        if (dataState.slots.isNotEmpty) ...[
                          _buildPreviewHeader(context, dataState, isDark, isTab, primaryColor),
                          const SizedBox(height: 14),
                          Builder(
                            builder: (context) {
                              final timelineItems = _buildTimelineItems(dataState.slots, dataState.breakTimes);
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: timelineItems.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                          const SizedBox(height: 14),
                          _buildAddCustomSlotButton(context, dataState, isDark, isTab, primaryColor),
                        ] else ...[
                          _buildEmptyState(context, dataState, isDark, isTab, primaryColor),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                _buildDeployFooter(context, dataState, isDark, isTab, primaryColor),
              ],
            ),
          );
        },
      ),
    );
  }



  Widget _buildPreviewHeader(BuildContext context, SlotDataState dataState, bool isDark, bool isTab, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [primaryColor.withValues(alpha: 0.12), primaryColor.withValues(alpha: 0.04)]
              : [primaryColor.withValues(alpha: 0.06), primaryColor.withValues(alpha: 0.02)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.view_timeline_rounded, size: 18, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText(
                  dataState.isSingleDay ? 'Slot Preview' : 'Template Preview',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.034,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (!dataState.isSingleDay)
                  CommonText(
                    'Applies to all days in range',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.025,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_rounded, size: 12, color: primaryColor),
                const SizedBox(width: 4),
                CommonText(
                  dataState.isSingleDay
                      ? DateFormat('MMM dd').format(dataState.targetDate)
                      : "${DateFormat('MMM dd').format(dataState.startDate)} - ${DateFormat('MMM dd').format(dataState.endDate)}",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.025,
                    color: primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCustomSlotButton(BuildContext context, SlotDataState dataState, bool isDark, bool isTab, Color primaryColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAddCustomSlotDialog(context, dataState),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.add_rounded, size: 16, color: primaryColor),
              ),
              const SizedBox(width: 10),
              CommonText(
                'Add Custom Slot',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.033,
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, SlotDataState dataState, bool isDark, bool isTab, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_busy_rounded, color: Colors.grey.shade400, size: 36),
          ),
          const SizedBox(height: 16),
          CommonText(
            'No Slots Generated',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.w700,
              fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.038,
            ),
          ),
          const SizedBox(height: 6),
          CommonText(
            'Adjust shift times, break times, or add custom slots to get started.',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.028,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _showAddCustomSlotDialog(context, dataState),
            icon: Icon(Icons.add_rounded, size: 18, color: primaryColor),
            label: CommonText(
              'Add Custom Slot',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w700,
                fontFamily: appPoppinFont,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeployFooter(BuildContext context, SlotDataState dataState, bool isDark, bool isTab, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      width: displayWidth(context),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary row
          if (dataState.slots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _summaryChip(
                    context,
                    Icons.event_rounded,
                    '${dataState.slots.length} Slots',
                    primaryColor,
                    isDark,
                    isTab,
                  ),
                  if (dataState.breakTimes.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    _summaryChip(
                      context,
                      Icons.coffee_rounded,
                      '${dataState.breakTimes.length} Break${dataState.breakTimes.length > 1 ? 's' : ''}',
                      Colors.amber.shade700,
                      isDark,
                      isTab,
                    ),
                  ],
                ],
              ),
            ),
          // Deploy button
          dataState.isDeploying
              ? Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(primaryColor),
                      ),
                    ),
                  ),
                )
              : CustomElevatedButton(
                  noElevation: true,
                  height: 52,
                  width: displayWidth(context),
                  text: dataState.isSingleDay
                      ? "Deploy Schedule (${dataState.slots.length} Slots)"
                      : "Deploy Schedule (${dataState.slots.length} Slots/Day)",
                  onPressed: () {
                    if (dataState.slots.isEmpty) {
                      _showPastTimeAlert(context);
                      return;
                    }
                    context.read<SlotBloc>().add(DeployScheduleEvent());
                  },
                ),
        ],
      ),
    );
  }

  Widget _summaryChip(BuildContext context, IconData icon, String label, Color color, bool isDark, bool isTab) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          CommonText(
            label,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.026,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showPastTimeAlert(BuildContext context) {
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
                'Past Time Selected',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: const CommonText(
          'Cannot generate slots for past time. The selected date or working shift has already passed. Please select a future date or time range.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(alertContext),
            child: const CommonText('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
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
            final primaryColor = theme.primaryColor;

            String formatTime(TimeOfDay t) {
              final dt = DateTime(2000, 1, 1, t.hour, t.minute);
              return DateFormat('h:mm a').format(dt);
            }

            int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_alarm_rounded, color: Colors.white, size: 20),
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
                  CommonText(
                    'Choose start and end times for this custom slot.',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDialogTimePicker(
                          context,
                          label: 'Start Time',
                          value: formatTime(startTime),
                          isDark: isDark,
                          primaryColor: primaryColor,
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDialogTimePicker(
                          context,
                          label: 'End Time',
                          value: formatTime(endTime),
                          isDark: isDark,
                          primaryColor: primaryColor,
                          onTap: () async {
                            final chosen = await showTimePicker(context: context, initialTime: endTime);
                            if (chosen != null) {
                              setDialogState(() {
                                endTime = chosen;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CommonText(
                    'Initial Status',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatusChoiceChip(
                          label: 'Available',
                          icon: Icons.check_circle_outline_rounded,
                          isSelected: status == 'Available',
                          color: const Color(0xFF10B981),
                          isDark: isDark,
                          onTap: () => setDialogState(() => status = 'Available'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatusChoiceChip(
                          label: 'Blocked',
                          icon: Icons.block_rounded,
                          isSelected: status == 'Blocked',
                          color: Colors.redAccent,
                          isDark: isDark,
                          onTap: () => setDialogState(() => status = 'Blocked'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: CommonText(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
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

  Widget _buildDialogTimePicker(
    BuildContext context, {
    required String label,
    required String value,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CommonText(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: isDark ? Colors.white60 : Colors.blueGrey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CommonText(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Icon(Icons.access_time_rounded, size: 16, color: primaryColor),
              ],
            ),
          ),
        ),
      ],
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

  bool _isOverlapping(int s1, int e1, int s2, int e2) => s1 < e2 && e1 > s2;

  List<dynamic> _buildTimelineItems(List<SlotEntity> slots, List<BreakTimeEntity> breakTimes) {
    final validSlots = slots.where((s) {
      final sStart = _timeStringToMinutes(s.startTime);
      final sEnd = _timeStringToMinutes(s.endTime);
      for (final b in breakTimes) {
        final bStart = _timeStringToMinutes(b.fromTime);
        final bEnd = _timeStringToMinutes(b.toTime);
        if (bStart < bEnd && _isOverlapping(sStart, sEnd, bStart, bEnd)) {
          return false;
        }
      }
      return true;
    }).toList();

    final List<dynamic> items = [...validSlots, ...breakTimes];
    items.sort((a, b) {
      final aTime = a is SlotEntity ? a.startTime : (a as BreakTimeEntity).fromTime;
      final bTime = b is SlotEntity ? b.startTime : (b as BreakTimeEntity).fromTime;
      return _timeStringToMinutes(aTime).compareTo(_timeStringToMinutes(bTime));
    });
    return items;
  }

  Widget _buildBreakTimelineCard(BuildContext context, BreakTimeEntity b, bool isDark, bool isTab) {
    final amberColor = isDark ? Colors.amber.shade300 : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFFFDE68A),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Left accent bar
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber, Colors.amber.withValues(alpha: 0.4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.free_breakfast_rounded,
              color: Colors.amber,
              size: 18,
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
                        fontWeight: FontWeight.w700,
                        fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.031,
                        color: amberColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: amberColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: CommonText(
                        'Break',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: amberColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                CommonText(
                  '${b.fromTime} – ${b.toTime}',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.026,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                context.read<SlotBloc>().add(RemoveBreakTimeEvent(b.id));
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOverlapAlertDialog(BuildContext context, {required String title, required String message}) {
    showDialog(
      context: context,
      builder: (alertContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 22),
            ),
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
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(alertContext),
            child: const CommonText('OK, I will adjust', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _StatusChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _StatusChoiceChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.4) : (isDark ? Colors.white12 : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? color : (isDark ? Colors.white38 : Colors.grey.shade500),
            ),
            const SizedBox(width: 6),
            CommonText(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected ? color : (isDark ? Colors.white54 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
