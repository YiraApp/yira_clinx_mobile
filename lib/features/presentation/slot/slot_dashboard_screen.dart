import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/app_bottom_nav_bar/app_bottom_nav_bar.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/features/presentation/slot/slot_bloc/slot_bloc.dart';
import 'package:yiraclinics/features/presentation/slot/slot_details_screen.dart';

import 'package:yiraclinics/features/presentation/slot/widgets/slot_filter_tabs.dart';
import 'package:yiraclinics/features/presentation/slot/widgets/time_slot_card.dart';
import '../../../core/colors/colors.dart' hide darkModeBgColor;
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/constants/constants.dart';
import '../../../core/widgets/calendar/advanced_calendar.dart';
import '../../../core/widgets/calendar/advanced_calendar_controller.dart';
import '../../domain/entities/slot/slot_appointment_entity.dart';
import '../../domain/entities/slot/time_slot_entity.dart';
import '../../../../core/tour/provider_tour_controller.dart';
import '../../../../core/tour/provider_tour_mock_data.dart';

class SlotDashBoardScreen extends StatefulWidget {
  final bool isShellChild;
  const SlotDashBoardScreen({super.key, this.isShellChild = false});

  @override
  State<SlotDashBoardScreen> createState() => _SlotDashBoardScreenState();
}

class _SlotDashBoardScreenState extends State<SlotDashBoardScreen> {
  final _calendarControllerToday = AdvancedCalendarController.today();
  final events = <DateTime>[DateTime.now()];
  final ScrollController _scrollController = ScrollController();
  DateTime? _lastAutoScrolledDate;
  int? _lastAutoScrolledTab;

  @override
  void initState() {
    context.read<SlotBloc>().add(InitializeSlotsEvent());
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openSlotDetailsDialog(BuildContext context, SlotEntity legacySlot,bool isTab) {
    SlotDetailsDialog.show(context, legacySlot);
  }

  @override
  Widget build(BuildContext context) {
    final bool isTab = isTablet(context);
    return ValueListenableBuilder<bool>(
      valueListenable: ProviderTourController().isTourActiveNotifier,
      builder: (context, isTourActive, _) {
        return BlocConsumer<SlotBloc, SlotState>(
          buildWhen: (previous, current) => current is SlotDataState,
          listener: (context, state) {
            if (state is SlotDataState) {
              if (state.isLoading) {
                _lastAutoScrolledDate = null;
              } else if (state.timeSlots.isNotEmpty) {
                final visibleItems = _buildVisibleItems(state);
                _checkAndScrollToPresentSlot(state, visibleItems);
              }
            }
          },
          builder: (context, state) {
            final effectiveState = isTourActive
                ? ProviderTourMockData.demoSlotDataState
                : (state is SlotDataState ? state : null);

            return Scaffold(
              floatingActionButton: FloatingActionButton(
                key: (widget.isShellChild && isTourActive) ? ProviderTourController().slotsFabKey : null,
                backgroundColor: primaryColor,
                shape: const CircleBorder(),
                onPressed: () async {
                  await Navigator.pushNamed(
                    context,
                    AppRoutes.smartSlotSchedulerScreen,
                  );
                  if (context.mounted) {
                    context.read<SlotBloc>().add(InitializeSlotsEvent());
                  }
                },
                child: const Icon(Icons.event, color: Colors.white),
              ),
              bottomNavigationBar: widget.isShellChild ? null : const AppBottomNavBar(currentIndex: 3),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: SafeArea(
                child: effectiveState != null
                    ? _buildBodyContent(context, effectiveState, isTab, isTourActive)
                    : SlotDashboardShimmer(isTab: isTab),
              ),
            );
          },
        );
      },
    );
  }

  int _timeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 0;
    try {
      final cleaned = timeStr.replaceAll(RegExp(r'[\s\u00A0\u2000-\u200B\u202F]+'), ' ').trim();
      final match = RegExp(r'^(\d{1,2}):(\d{2})\s*([a-zA-Z]{2})?', caseSensitive: false).firstMatch(cleaned);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        String? ampm = match.group(3)?.toUpperCase();
        if (ampm == 'PM' && hour < 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        return hour * 60 + minute;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  bool _isSlotPast(DateTime? date, String timeStr) {
    if (date == null) return false;
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) {
      try {
        final clean = timeStr.trim();
        if (clean.isEmpty) return false;
        final firstPart = clean.contains(' - ') ? clean.split(' - ').first.trim() : clean;
        final isPM = firstPart.toUpperCase().contains('PM');
        final isAM = firstPart.toUpperCase().contains('AM');
        final digitsOnly = firstPart.replaceAll(RegExp(r'[^0-9:]'), '');
        final parts = digitsOnly.split(':');
        if (parts.isEmpty) return false;
        int hour = int.parse(parts[0]);
        int minute = parts.length > 1 ? int.parse(parts[1]) : 0;
        if (isPM && hour < 12) hour += 12;
        if (isAM && hour == 12) hour = 0;
        final slotTime = DateTime(date.year, date.month, date.day, hour, minute);
        return slotTime.isBefore(now);
      } catch (_) {
        return false;
      }
    } else {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final todayOnly = DateTime(now.year, now.month, now.day);
      return dateOnly.isBefore(todayOnly);
    }
  }

  int _findPresentTimeSlotIndex(List<dynamic> visibleItems) {
    if (visibleItems.isEmpty) return 0;
    final now = DateTime.now();
    final currentMins = now.hour * 60 + now.minute;

    for (int i = 0; i < visibleItems.length; i++) {
      final item = visibleItems[i];
      final timeStr = item is TimeSlot ? item.time : (item as BreakTimeEntity).fromTime;
      final slotStartMins = _timeToMinutes(timeStr);

      int slotDuration = 15;
      if (item is TimeSlot) {
        final match = RegExp(r'(\d+)').firstMatch(item.duration);
        if (match != null) {
          slotDuration = int.tryParse(match.group(1)!) ?? 15;
        }
      } else if (item is BreakTimeEntity) {
        final endMins = _timeToMinutes(item.toTime);
        if (endMins > slotStartMins) {
          slotDuration = endMins - slotStartMins;
        }
      }

      final slotEndMins = slotStartMins + slotDuration;

      // If current time is within this slot or this is the first slot starting at or after now
      if (currentMins < slotEndMins) {
        return i;
      }
    }

    return visibleItems.length - 1;
  }

  void _checkAndScrollToPresentSlot(SlotDataState state, List<dynamic> visibleItems) {
    final now = DateTime.now();
    final isToday = state.targetDate.year == now.year &&
        state.targetDate.month == now.month &&
        state.targetDate.day == now.day;

    if (!isToday || visibleItems.isEmpty || state.isLoading) return;

    final dateKey = DateTime(state.targetDate.year, state.targetDate.month, state.targetDate.day);
    if (_lastAutoScrolledDate == dateKey && _lastAutoScrolledTab == state.selectedTabIndex) {
      return;
    }

    _lastAutoScrolledDate = dateKey;
    _lastAutoScrolledTab = state.selectedTabIndex;

    final targetIndex = _findPresentTimeSlotIndex(visibleItems);
    if (targetIndex <= 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final double itemHeight = isTablet(context) ? 95.0 : 82.0;
      final double targetOffset = targetIndex * itemHeight;
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double clampedOffset = targetOffset.clamp(0.0, maxScroll);

      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
      );
    });
  }

  List<dynamic> _buildVisibleItems(SlotDataState state) {
    final List<dynamic> items = [];
    final selectedTab = state.selectedTabIndex;

    // Collect effective breaks (from state or auto-detected gaps)
    final List<BreakTimeEntity> effectiveBreaks = List<BreakTimeEntity>.from(state.breakTimes);
    if (effectiveBreaks.isEmpty && state.timeSlots.length > 1) {
      final sortedSlots = List<TimeSlot>.from(state.timeSlots)
        ..sort((a, b) => _timeToMinutes(a.time).compareTo(_timeToMinutes(b.time)));
      for (int i = 0; i < sortedSlots.length - 1; i++) {
        final currentMins = _timeToMinutes(sortedSlots[i].time);
        final nextMins = _timeToMinutes(sortedSlots[i + 1].time);
        int slotDur = 15;
        final durMatch = RegExp(r'(\d+)').firstMatch(sortedSlots[i].duration);
        if (durMatch != null) slotDur = int.tryParse(durMatch.group(1)!) ?? 15;
        final endMins = currentMins + slotDur;
        if (nextMins - endMins >= 15) {
          final fromDt = DateTime(2000, 1, 1, endMins ~/ 60, endMins % 60);
          final toDt = DateTime(2000, 1, 1, nextMins ~/ 60, nextMins % 60);
          effectiveBreaks.add(BreakTimeEntity(
            id: 'gap_break_${effectiveBreaks.length + 1}',
            fromTime: DateFormat('hh:mm a').format(fromDt),
            toTime: DateFormat('hh:mm a').format(toDt),
            label: 'Break ${effectiveBreaks.length + 1}',
          ));
        }
      }
    }

    // Filter timeSlots that don't fall into any break period
    final nonBreakTimeSlots = state.timeSlots.where((s) {
      final sMin = _timeToMinutes(s.time);
      for (final b in effectiveBreaks) {
        final bStart = _timeToMinutes(b.fromTime);
        final bEnd = _timeToMinutes(b.toTime);
        if (bStart < bEnd && sMin >= bStart && sMin < bEnd) {
          return false;
        }
      }
      return true;
    }).toList();

    if (selectedTab == 0) {
      // All tab: include non-break slots + break periods
      items.addAll(nonBreakTimeSlots);
      items.addAll(effectiveBreaks);
    } else if (selectedTab == 1) {
      items.addAll(nonBreakTimeSlots.where((s) => s.status == SlotStatus.booked));
    } else if (selectedTab == 2) {
      items.addAll(nonBreakTimeSlots.where((s) => s.status == SlotStatus.available));
    } else if (selectedTab == 3) {
      items.addAll(nonBreakTimeSlots.where((s) => s.status == SlotStatus.blocked));
    } else if (selectedTab == 4) {
      items.addAll(effectiveBreaks);
    }

    items.sort((a, b) {
      final aTime = a is TimeSlot ? a.time : (a as BreakTimeEntity).fromTime;
      final bTime = b is TimeSlot ? b.time : (b as BreakTimeEntity).fromTime;
      return _timeToMinutes(aTime).compareTo(_timeToMinutes(bTime));
    });

    return items;
  }

  Widget _buildBodyContent(BuildContext context, SlotDataState state, bool isTab, bool isTourActive) {
    // Build effective breaks list for counters
    final List<BreakTimeEntity> effectiveBreaks = List<BreakTimeEntity>.from(state.breakTimes);
    if (effectiveBreaks.isEmpty && state.timeSlots.length > 1) {
      final sortedSlots = List<TimeSlot>.from(state.timeSlots)
        ..sort((a, b) => _timeToMinutes(a.time).compareTo(_timeToMinutes(b.time)));
      for (int i = 0; i < sortedSlots.length - 1; i++) {
        final currentMins = _timeToMinutes(sortedSlots[i].time);
        final nextMins = _timeToMinutes(sortedSlots[i + 1].time);
        int slotDur = 15;
        final durMatch = RegExp(r'(\d+)').firstMatch(sortedSlots[i].duration);
        if (durMatch != null) slotDur = int.tryParse(durMatch.group(1)!) ?? 15;
        final endMins = currentMins + slotDur;
        if (nextMins - endMins >= 15) {
          final fromDt = DateTime(2000, 1, 1, endMins ~/ 60, endMins % 60);
          final toDt = DateTime(2000, 1, 1, nextMins ~/ 60, nextMins % 60);
          effectiveBreaks.add(BreakTimeEntity(
            id: 'gap_break_${effectiveBreaks.length + 1}',
            fromTime: DateFormat('hh:mm a').format(fromDt),
            toTime: DateFormat('hh:mm a').format(toDt),
            label: 'Break ${effectiveBreaks.length + 1}',
          ));
        }
      }
    }

    final totalCount = state.timeSlots.length;
    final bookedCount = state.timeSlots
        .where((s) => s.status == SlotStatus.booked)
        .length;
    final availableCount = state.timeSlots
        .where((s) => s.status == SlotStatus.available)
        .length;
    final blockedCount = state.timeSlots
        .where((s) => s.status == SlotStatus.blocked)
        .length;
    final breakCount = effectiveBreaks.length;

    final visibleItems = _buildVisibleItems(state);
    if (!state.isLoading && visibleItems.isNotEmpty) {
      _checkAndScrollToPresentSlot(state, visibleItems);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: screenTopPadding),
        Container(
          key: (widget.isShellChild && isTourActive) ? ProviderTourController().slotsCalendarKey : null,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: AdvancedCalendar(
            onDateChanged: (date) {
              context.read<SlotBloc>().add(InitializeSlotsEvent(targetDate: date));
            },
            handlerColor: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.2),
            buttonPrimaryColor: primaryColor,
            weekFontSize: displayWidth(context) * 0.025,
            todayStyle: const TextStyle(fontSize: 0),
            headerStyle: TextStyle(
              fontSize: isTab ? displayWidth(context) * 0.022 : displayWidth(context) * 0.045,
              fontFamily: appPoppinFont,
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
            innerDot: false,
            showNavigationArrows: false,
            controller: _calendarControllerToday,
            events: events,
            startWeekDay: 1,
            weekColor: isDark ? Colors.white : Colors.black,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: screenHorizontalSpacePadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: fieldSpace),
              SlotFilterTabs(
                isTab: isTab,
                selectedIndex: state.selectedTabIndex,
                allCount: totalCount + breakCount,
                bookedCount: bookedCount,
                availableCount: availableCount,
                blockedCount: blockedCount,
                breakCount: breakCount,
                onTabSelected: (index) {
                  context.read<SlotBloc>().add(ChangeFilterTabUiEvent(index));
                },
              ),
              const SizedBox(height: fieldSpace),
              _buildTimeSlotHeaderRow(Theme.of(context), isTab),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: Container(
            key: (widget.isShellChild && isTourActive) ? ProviderTourController().slotsListKey : null,
            child: state.isLoading
                ? TimeSlotListShimmer(itemCount: 5, isTab: isTab)
                : visibleItems.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.event_note_rounded,
                                size: 48,
                                color: isDark ? Colors.white38 : Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CommonText(
                              state.timeSlots.isEmpty
                                  ? "No slots scheduled for this date"
                                  : "No ${['slots', 'booked slots', 'available slots', 'blocked slots', 'breaks'][state.selectedTabIndex.clamp(0, 4)]} for this date",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.w600,
                                fontSize: isTab ? 16 : 15,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CommonText(
                              state.timeSlots.isEmpty
                                  ? "Configure consultation hours and generate your schedule for this date."
                                  : "All scheduled slots appear under the 'All' tab.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? 13 : 12,
                                color: isDark ? Colors.white38 : Colors.grey.shade500,
                              ),
                            ),
                            if (state.timeSlots.isEmpty) ...[
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    AppRoutes.smartSlotSchedulerScreen,
                                  );
                                  if (context.mounted) {
                                    context.read<SlotBloc>().add(InitializeSlotsEvent(targetDate: state.targetDate));
                                  }
                                },
                                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                label: const CommonText(
                                  "Add Slots",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: screenHorizontalSpacePadding,
                        vertical: 0.0,
                      ),
                      itemCount: visibleItems.length,
                      itemBuilder: (context, index) {
                        final item = visibleItems[index];
                        if (item is BreakTimeEntity) {
                          return _buildDashboardBreakCard(context, item, isDark, isTab);
                        }
                        final timeSlotItem = item as TimeSlot;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 0.0),
                          child: TimeSlotCard(
                            isTab: isTab,
                            slot: timeSlotItem,
                            targetDate: state.targetDate,
                            bookSlot: () {
                              if (_isSlotPast(state.targetDate, timeSlotItem.time) && timeSlotItem.status != SlotStatus.booked) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Cannot book an appointment for past time.",
                                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 13),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFF334155),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              if (timeSlotItem.status == SlotStatus.available) {
                                final currentUser = GlobalSession.instance.userNotifier.value?.data;
                                final doctorId = (currentUser?.id != null && currentUser!.id!.trim().isNotEmpty)
                                    ? currentUser.id!.trim()
                                    : (currentUser?.navigationId != null && currentUser!.navigationId!.trim().isNotEmpty)
                                        ? currentUser.navigationId!.trim()
                                        : '1';
                                final doctorName = currentUser != null
                                    ? "Dr. ${currentUser.firstName ?? currentUser.email?.split('@').first ?? ''}"
                                    : '';

                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.addAppointmentScreen,
                                  arguments: {
                                    'date': state.targetDate,
                                    'targetDate': state.targetDate,
                                    'slot': timeSlotItem.time,
                                    'time': timeSlotItem.time,
                                    'startTime': timeSlotItem.time,
                                    'doctorId': doctorId,
                                    'doctorName': doctorName,
                                  },
                                ).then((_) {
                                  if (context.mounted) {
                                    context.read<SlotBloc>().add(InitializeSlotsEvent());
                                  }
                                });
                                return;
                              }

                              try {
                                final legacySlot = state.slots.firstWhere(
                                  (s) => s.id == timeSlotItem.id,
                                );
                                _openSlotDetailsDialog(context, legacySlot, isTab);
                              } catch (_) {
                                String slotLabel = 'Available';
                                if (timeSlotItem.status == SlotStatus.booked) {
                                  slotLabel = 'Booked';
                                } else if (timeSlotItem.status == SlotStatus.blocked) {
                                  slotLabel = 'Blocked';
                                }

                                final customLegacySlot = SlotEntity(
                                  id: timeSlotItem.id,
                                  startTime: timeSlotItem.time,
                                  endTime: timeSlotItem.time,
                                  label: slotLabel,
                                  appointment: timeSlotItem.status == SlotStatus.booked
                                      ? SlotAppointmentEntity(
                                          id: timeSlotItem.appointmentId ?? timeSlotItem.id,
                                          patientName: timeSlotItem.patientName ?? '',
                                          contactNumber: 'N/A',
                                          reason: timeSlotItem.reason,
                                        )
                                      : null,
                                );
                                _openSlotDetailsDialog(context, customLegacySlot, isTab);
                              }
                            },
                            viewSlotDetails: () {},
                          ),
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardBreakCard(BuildContext context, BreakTimeEntity b, bool isDark, bool isTab) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.coffee_rounded,
              color: Colors.amber,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
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
                        fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.034,
                        color: isDark ? Colors.amber.shade300 : const Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.amber : const Color(0xFFB45309)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: CommonText(
                        'Break',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.amber.shade300 : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                CommonText(
                  '${b.fromTime} - ${b.toTime} • Break Period (No appointments)',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.026,
                    color: isDark ? Colors.white60 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotHeaderRow(ThemeData theme, bool isTab) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CommonText(
          "Consultation Slots",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.038,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
