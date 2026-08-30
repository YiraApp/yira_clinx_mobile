import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/app_bottom_nav_bar/app_bottom_nav_bar.dart';
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
import 'package:yiraclinics/core/tour/provider_tour_controller.dart';
import 'package:yiraclinics/core/tour/provider_tour_mock_data.dart';

class SlotDashBoardScreen extends StatefulWidget {
  final bool isShellChild;
  const SlotDashBoardScreen({super.key, this.isShellChild = false});

  @override
  State<SlotDashBoardScreen> createState() => _SlotDashBoardScreenState();
}

class _SlotDashBoardScreenState extends State<SlotDashBoardScreen> {
  final _calendarControllerToday = AdvancedCalendarController.today();
  final events = <DateTime>[DateTime.now()];

  @override
  void initState() {
    context.read<SlotBloc>().add(InitializeSlotsEvent());
    super.initState();
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
          listener: (context, state) {},
          builder: (context, state) {
            final effectiveState = isTourActive
                ? ProviderTourMockData.demoSlotDataState
                : (state is SlotDataState ? state : null);

            return Scaffold(
              floatingActionButton: FloatingActionButton(
                key: ProviderTourController().slotsFabKey,
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
                    ? _buildBodyContent(context, effectiveState, isTab)
                    : SlotDashboardShimmer(isTab: isTab),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBodyContent(BuildContext context, SlotDataState state, bool isTab) {
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

    final visibleSlots = state.filteredSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: screenTopPadding),
        Container(
          key: ProviderTourController().slotsCalendarKey,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: AdvancedCalendar(
            onDateChanged: (date) {
              context.read<SlotBloc>().add(UpdateTargetDateEvent(date));
              context.read<SlotBloc>().add(InitializeSlotsEvent());
            },
            handlerColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.2),
            buttonPrimaryColor: primaryColor,
            weekFontSize: displayWidth(context) * 0.025,
            todayStyle: const TextStyle(fontSize: 0),
            headerStyle: TextStyle(
              fontSize: isTab ? displayWidth(context) * 0.022 : displayWidth(context) * 0.045,
              fontFamily: appPoppinFont,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              fontWeight: FontWeight.w500,
            ),
            innerDot: false,
            showNavigationArrows: false,
            controller: _calendarControllerToday,
            events: events,
            startWeekDay: 1,
            weekColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
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
                allCount: totalCount,
                bookedCount: bookedCount,
                availableCount: availableCount,
                blockedCount: blockedCount,
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
            key: ProviderTourController().slotsListKey,
            child: state.isLoading
                ? TimeSlotListShimmer(itemCount: 5, isTab: isTab)
                : visibleSlots.isEmpty
                    ? const Center(
                        child: CommonText("No time slots found for this selection."),
                      )
                    : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: screenHorizontalSpacePadding,
                    vertical: 0.0,
                  ),
                  itemCount: visibleSlots.length,
                  itemBuilder: (context, index) {
                    final item = visibleSlots[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 0.0),
                      child: TimeSlotCard(
                        isTab: isTab,
                        slot: item,
                        bookSlot: () {
                          try {
                            final legacySlot = state.slots.firstWhere(
                              (s) => s.id == item.id,
                            );
                            _openSlotDetailsDialog(context, legacySlot, isTab);
                          } catch (_) {
                            String slotLabel = 'Available';
                            if (item.status == SlotStatus.booked) {
                              slotLabel = 'Booked';
                            } else if (item.status == SlotStatus.blocked) {
                              slotLabel = 'Blocked';
                            }

                            final customLegacySlot = SlotEntity(
                              id: item.id,
                              startTime: item.time,
                              endTime: item.time,
                              label: slotLabel,
                              appointment: item.status == SlotStatus.booked
                                  ? SlotAppointmentEntity(
                                      id: item.appointmentId ?? item.id,
                                      patientName: item.patientName ?? '',
                                      contactNumber: 'N/A',
                                      reason: item.reason,
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

  Widget _buildTimeSlotHeaderRow(ThemeData theme,bool isTab) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CommonText(
          "Time Slots",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize:  isTab?displayWidth(context) * 0.02:displayWidth(context) * 0.039,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
