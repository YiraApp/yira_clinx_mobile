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
          const SizedBox(height: 20),
          _buildBreakTimesSection(context, state, isTab),
        ],
      ),
    );
  }

  Widget _buildBreakTimesSection(BuildContext context, SlotDataState state, bool isTab) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.schedule_rounded, size: 18, color: primaryColor),
            const SizedBox(width: 6),
            _buildCardLabel(context, 'Break Times (Optional)', isTab),
          ],
        ),
        const SizedBox(height: 4),
        CommonText(
          'Slots falling within break timings will not be generated.',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.026,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        if (state.breakTimes.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(fieldBorderRadius),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.coffee_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 4),
                          CommonText(
                            'Break 1',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonText(
                            'From Time',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildTimeSelector(context, '01:00 PM', (newFrom) {
                            _validateAndAddNewBreakInline(context, newFrom, '02:00 PM');
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonText(
                            'To Time',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildTimeSelector(context, '02:00 PM', (newTo) {
                            _validateAndAddNewBreakInline(context, '01:00 PM', newTo);
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.breakTimes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final b = state.breakTimes[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.coffee_rounded, size: 14, color: primaryColor),
                                  const SizedBox(width: 4),
                                  CommonText(
                                    'Break ${index + 1}',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_calculateDurationStr(b.fromTime, b.toTime).isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: CommonText(
                                  _calculateDurationStr(b.fromTime, b.toTime),
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CommonText(
                                'From Time',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white60 : Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildTimeSelector(context, b.fromTime, (newFrom) {
                                _validateAndUpdateBreak(context, b, newFrom, b.toTime);
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CommonText(
                                'To Time',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white60 : Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildTimeSelector(context, b.toTime, (newTo) {
                                _validateAndUpdateBreak(context, b, b.fromTime, newTo);
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              _showAddBreakDialog(context);
            },
            icon: Icon(Icons.add_rounded, size: 18, color: primaryColor),
            label: CommonText(
              'Add Another Break',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.03,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 42),
              side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(fieldBorderRadius),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showAddBreakDialog(BuildContext context) {
    final slotBloc = context.read<SlotBloc>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final workStart = _parseTimeToMinutes(state.fromTime);
    final workEnd = _parseTimeToMinutes(state.toTime);

    // Pick a default break time within working hours
    TimeOfDay fromTime = const TimeOfDay(hour: 13, minute: 0);
    TimeOfDay toTime = const TimeOfDay(hour: 14, minute: 0);

    final defaultStartMin = 13 * 60;
    final defaultEndMin = 14 * 60;

    if (workStart <= defaultStartMin && workEnd >= defaultEndMin) {
      fromTime = const TimeOfDay(hour: 13, minute: 0);
      toTime = const TimeOfDay(hour: 14, minute: 0);
    } else {
      final midMin = (workStart + workEnd) ~/ 2;
      final startH = (midMin ~/ 60) % 24;
      final endH = ((midMin + 60) ~/ 60) % 24;
      fromTime = TimeOfDay(hour: startH, minute: 0);
      toTime = TimeOfDay(hour: endH, minute: 0);
    }

    if (state.breakTimes.isNotEmpty) {
      final lastBreak = state.breakTimes.last;
      try {
        final lastEndMin = _parseTimeToMinutes(lastBreak.toTime);
        final candidateStartMin = lastEndMin + 60;
        final candidateEndMin = candidateStartMin + 60;
        if (candidateEndMin <= workEnd) {
          fromTime = TimeOfDay(hour: (candidateStartMin ~/ 60) % 24, minute: candidateStartMin % 60);
          toTime = TimeOfDay(hour: (candidateEndMin ~/ 60) % 24, minute: candidateEndMin % 60);
        }
      } catch (_) {}
    }

    String formatTime(TimeOfDay t) {
      final dt = DateTime(2000, 1, 1, t.hour, t.minute);
      return DateFormat('hh:mm a').format(dt);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? dialogError;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(fieldBorderRadius),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.free_breakfast_rounded,
                      color: theme.primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: CommonText(
                      'Add Break Time',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonText(
                      'Slots falling within break hours will be removed and remaining slots will be reallocated automatically.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (dialogError != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CommonText(
                                dialogError!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CommonText(
                                'From Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: ctx,
                                    initialTime: fromTime,
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      fromTime = picked;
                                      dialogError = null;
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(fieldBorderRadius),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                                    border: Border.all(
                                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      CommonText(
                                        formatTime(fromTime),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Icon(Icons.access_time_rounded, size: 16, color: theme.primaryColor),
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
                              CommonText(
                                'To Time',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.blueGrey.shade700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: ctx,
                                    initialTime: toTime,
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      toTime = picked;
                                      dialogError = null;
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(fieldBorderRadius),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                                    border: Border.all(
                                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      CommonText(
                                        formatTime(toTime),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Icon(Icons.access_time_rounded, size: 16, color: theme.primaryColor),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final fromMin = _parseTimeToMinutes(formatTime(fromTime));
                    final toMin = _parseTimeToMinutes(formatTime(toTime));
                    final now = DateTime.now();
                    final bool isToday = state.isSingleDay &&
                        state.targetDate.year == now.year &&
                        state.targetDate.month == now.month &&
                        state.targetDate.day == now.day;
                    final int nowMinutes = now.hour * 60 + now.minute;

                    // Validation 0: Past break time today
                    if (isToday && toMin <= nowMinutes) {
                      setDialogState(() {
                        dialogError = 'Cannot add break for a past time (${formatTime(fromTime)} - ${formatTime(toTime)}).';
                      });
                      _showWarningDialog(
                        context,
                        'Past Time Selected',
                        'Cannot add break for a past time. The selected time (${formatTime(fromTime)} - ${formatTime(toTime)}) has already passed today.',
                      );
                      return;
                    }

                    // Validation 1: From < To
                    if (fromMin >= toMin) {
                      setDialogState(() {
                        dialogError = 'From Time (${formatTime(fromTime)}) must be earlier than To Time (${formatTime(toTime)}).';
                      });
                      _showWarningDialog(
                        context,
                        'Invalid Break Time',
                        'From Time (${formatTime(fromTime)}) must be earlier than To Time (${formatTime(toTime)}).',
                      );
                      return;
                    }

                    // Validation 2: Within working hours
                    if (fromMin < workStart || toMin > workEnd) {
                      setDialogState(() {
                        dialogError = 'Break time must fall within working shift hours (${state.fromTime} - ${state.toTime}).';
                      });
                      _showWarningDialog(
                        context,
                        'Break Outside Shift Hours',
                        'Break time (${formatTime(fromTime)} - ${formatTime(toTime)}) must fall within working shift hours (${state.fromTime} - ${state.toTime}).',
                      );
                      return;
                    }

                    // Validation 3: Overlapping breaks
                    for (final b in state.breakTimes) {
                      final bStart = _parseTimeToMinutes(b.fromTime);
                      final bEnd = _parseTimeToMinutes(b.toTime);
                      if (fromMin < bEnd && toMin > bStart) {
                        setDialogState(() {
                          dialogError = 'This break overlaps with existing ${b.label.isNotEmpty ? b.label : 'Break'} (${b.fromTime} - ${b.toTime}).';
                        });
                        _showWarningDialog(
                          context,
                          'Overlapping Breaks',
                          'This break overlaps with existing ${b.label.isNotEmpty ? b.label : 'Break'} (${b.fromTime} - ${b.toTime}).',
                        );
                        return;
                      }
                    }

                    // Check for overlapping slots
                    final overlappingSlots = state.slots.where((s) {
                      final sStart = _parseTimeToMinutes(s.startTime);
                      final sEnd = _parseTimeToMinutes(s.endTime);
                      return _isOverlapping(fromMin, toMin, sStart, sEnd);
                    }).toList();

                    Navigator.pop(dialogContext);

                    if (overlappingSlots.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (confirmContext) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
                          title: const Row(
                            children: [
                              Icon(Icons.auto_fix_high_rounded, color: Colors.orangeAccent, size: 26),
                              SizedBox(width: 10),
                              Expanded(
                                child: CommonText(
                                  'Remove Overlapping Slots?',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CommonText(
                                '${overlappingSlots.length} timeslot(s) falling within ${formatTime(fromTime)} - ${formatTime(toTime)} will be removed.',
                                style: const TextStyle(fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 10),
                              const CommonText(
                                'Remaining slots will be automatically reallocated around this break. Do you want to proceed?',
                                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(confirmContext),
                              child: const CommonText('Cancel', style: TextStyle(color: Colors.grey)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.pop(confirmContext);
                                slotBloc.add(
                                  AddBreakTimeEvent(
                                    fromTime: formatTime(fromTime),
                                    toTime: formatTime(toTime),
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Break added! ${overlappingSlots.length} slot(s) removed & reallocated.'),
                                    backgroundColor: Colors.green.shade700,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: const CommonText('OK, Remove & Re-align', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    } else {
                      slotBloc.add(
                        AddBreakTimeEvent(
                          fromTime: formatTime(fromTime),
                          toTime: formatTime(toTime),
                        ),
                      );
                    }
                  },
                  child: const CommonText(
                    'Add Break',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showWarningDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (alertContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
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
            child: const CommonText('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }



  bool _isOverlapping(int start1, int end1, int start2, int end2) {
    return start1 < end2 && end1 > start2;
  }

  int _parseTimeToMinutes(String timeStr) {
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

  String _calculateDurationStr(String from, String to) {
    final fromMin = _parseTimeToMinutes(from);
    final toMin = _parseTimeToMinutes(to);
    if (toMin <= fromMin) return '';
    final diff = toMin - fromMin;
    final hours = diff ~/ 60;
    final mins = diff % 60;
    if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
    if (hours > 0) return '${hours}h';
    return '${mins}m';
  }

  void _validateAndAddNewBreakInline(BuildContext context, String from, String to) {
    final state = context.read<SlotBloc>().state;
    if (state is! SlotDataState) return;

    final fromMin = _parseTimeToMinutes(from);
    final toMin = _parseTimeToMinutes(to);

    final now = DateTime.now();
    final bool isToday = state.isSingleDay &&
        state.targetDate.year == now.year &&
        state.targetDate.month == now.month &&
        state.targetDate.day == now.day;
    final int nowMinutes = now.hour * 60 + now.minute;

    if (isToday && toMin <= nowMinutes) {
      _showWarningDialog(
        context,
        'Past Time Selected',
        'Cannot add break for a past time. The selected time ($from - $to) has already passed today.',
      );
      return;
    }

    if (fromMin >= toMin) {
      _showWarningDialog(
        context,
        'Invalid Break Time',
        'Break From Time ($from) must be earlier than To Time ($to).',
      );
      return;
    }

    final workStart = _parseTimeToMinutes(state.fromTime);
    final workEnd = _parseTimeToMinutes(state.toTime);

    if (fromMin < workStart || toMin > workEnd) {
      _showWarningDialog(
        context,
        'Break Outside Working Hours',
        'Break time ($from - $to) must fall within working shift hours (${state.fromTime} - ${state.toTime}).',
      );
      return;
    }

    // Check overlap with other breaks
    for (final other in state.breakTimes) {
      final oStart = _parseTimeToMinutes(other.fromTime);
      final oEnd = _parseTimeToMinutes(other.toTime);
      if (fromMin < oEnd && toMin > oStart) {
        _showWarningDialog(
          context,
          'Overlapping Breaks',
          'This break ($from - $to) overlaps with existing ${other.label} (${other.fromTime} - ${other.toTime}).',
        );
        return;
      }
    }

    final overlappingSlots = state.slots.where((s) {
      final sStart = _parseTimeToMinutes(s.startTime);
      final sEnd = _parseTimeToMinutes(s.endTime);
      return _isOverlapping(fromMin, toMin, sStart, sEnd);
    }).toList();

    if (overlappingSlots.isNotEmpty) {
      showDialog(
        context: context,
        builder: (confirmContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
          title: const Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, color: Colors.orangeAccent, size: 26),
              SizedBox(width: 10),
              Expanded(
                child: CommonText(
                  'Remove Overlapping Slots?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonText(
                'Break ($from - $to) overlaps with ${overlappingSlots.length} timeslot(s).',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
              const CommonText(
                'Overlapping slots will be removed, and all remaining slots will be automatically reallocated around this break. Do you want to proceed?',
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(confirmContext),
              child: const CommonText('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(confirmContext);
                context.read<SlotBloc>().add(
                  AddBreakTimeEvent(
                    fromTime: from,
                    toTime: to,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Break added! ${overlappingSlots.length} slot(s) removed & reallocated.'),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const CommonText('OK, Remove & Re-align', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    context.read<SlotBloc>().add(
      AddBreakTimeEvent(
        fromTime: from,
        toTime: to,
      ),
    );
  }

  void _validateAndUpdateBreak(BuildContext context, dynamic b, String from, String to) {
    final fromMin = _parseTimeToMinutes(from);
    final toMin = _parseTimeToMinutes(to);

    final now = DateTime.now();
    final bool isToday = state.isSingleDay &&
        state.targetDate.year == now.year &&
        state.targetDate.month == now.month &&
        state.targetDate.day == now.day;
    final int nowMinutes = now.hour * 60 + now.minute;

    if (isToday && toMin <= nowMinutes) {
      _showWarningDialog(
        context,
        'Past Time Selected',
        'Cannot update break for a past time. The selected time ($from - $to) has already passed today.',
      );
      return;
    }

    if (fromMin >= toMin) {
      _showWarningDialog(
        context,
        'Invalid Break Time',
        'Break From Time ($from) must be earlier than To Time ($to).',
      );
      return;
    }

    final workStart = _parseTimeToMinutes(state.fromTime);
    final workEnd = _parseTimeToMinutes(state.toTime);

    if (fromMin < workStart || toMin > workEnd) {
      _showWarningDialog(
        context,
        'Break Outside Working Hours',
        'Break time ($from - $to) must fall within working shift hours (${state.fromTime} - ${state.toTime}).',
      );
      return;
    }

    // Check overlap with other breaks
    for (final other in state.breakTimes) {
      if (other.id == b.id) continue;
      final oStart = _parseTimeToMinutes(other.fromTime);
      final oEnd = _parseTimeToMinutes(other.toTime);
      if (fromMin < oEnd && toMin > oStart) {
        _showWarningDialog(
          context,
          'Overlapping Breaks',
          'This break ($from - $to) overlaps with existing ${other.label} (${other.fromTime} - ${other.toTime}).',
        );
        return;
      }
    }

    final overlappingSlots = state.slots.where((s) {
      final sStart = _parseTimeToMinutes(s.startTime);
      final sEnd = _parseTimeToMinutes(s.endTime);
      return _isOverlapping(fromMin, toMin, sStart, sEnd);
    }).toList();

    if (overlappingSlots.isNotEmpty) {
      showDialog(
        context: context,
        builder: (confirmContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fieldBorderRadius)),
          title: const Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, color: Colors.orangeAccent, size: 26),
              SizedBox(width: 10),
              Expanded(
                child: CommonText(
                  'Remove Overlapping Slots?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonText(
                'Updated break ($from - $to) overlaps with ${overlappingSlots.length} timeslot(s).',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
              const CommonText(
                'Overlapping slots will be removed, and all remaining slots will be automatically reallocated around this break. Do you want to proceed?',
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(confirmContext),
              child: const CommonText('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(confirmContext);
                context.read<SlotBloc>().add(
                  UpdateBreakTimeEvent(
                    breakId: b.id,
                    fromTime: from,
                    toTime: to,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Break updated! ${overlappingSlots.length} slot(s) removed & reallocated.'),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const CommonText('OK, Remove & Re-align', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    context.read<SlotBloc>().add(
      UpdateBreakTimeEvent(
        breakId: b.id,
        fromTime: from,
        toTime: to,
      ),
    );
  }

  Widget _buildTimeSelector(BuildContext context, String currentTime, Function(String) onPicked) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTab = isTablet(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final totalMinutes = _parseTimeToMinutes(currentTime);
          final initial = TimeOfDay(hour: (totalMinutes ~/ 60) % 24, minute: totalMinutes % 60);

          final chosen = await showTimePicker(
            context: context,
            initialTime: initial,
          );

          if (chosen != null) {
            final dt = DateTime(2000, 1, 1, chosen.hour, chosen.minute);
            final formatted = DateFormat('hh:mm a').format(dt);
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
      ),
    );
  }

  void _validateAndUpdateTimeRange(BuildContext context, String from, String to) {
    final fromMin = _parseTimeToMinutes(from);
    final toMin = _parseTimeToMinutes(to);

    if (fromMin >= toMin) {
      _showWarningDialog(
        context,
        'Invalid Time Range',
        'Working From Time ($from) must be earlier than To Time ($to).',
      );
      return;
    }

    final state = context.read<SlotBloc>().state;
    if (state is SlotDataState) {
      final now = DateTime.now();
      final bool isToday = state.isSingleDay &&
          state.targetDate.year == now.year &&
          state.targetDate.month == now.month &&
          state.targetDate.day == now.day;
      final int nowMinutes = now.hour * 60 + now.minute;

      if (isToday && toMin <= nowMinutes) {
        _showWarningDialog(
          context,
          'Past Time Selected',
          'Cannot generate slots for past time. The entire shift ($from - $to) has already passed today. Please select a future time range.',
        );
        return;
      }
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