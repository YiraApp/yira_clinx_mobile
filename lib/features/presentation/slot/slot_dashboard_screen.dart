import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/features/presentation/slot/slot_bloc/slot_bloc.dart';
import 'package:yiraclinics/features/presentation/slot/slot_details_screen.dart';
import 'package:yiraclinics/features/presentation/slot/widgets/add_slot_fab.dart';
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

class SlotDashBoardScreen extends StatefulWidget {
  const SlotDashBoardScreen({super.key});

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
  void _openSlotDetailsDialog(BuildContext context, SlotEntity legacySlot) {
    SlotDetailsDialog.show(context, legacySlot);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SlotBloc, SlotState>(
      buildWhen: (previous, current) => current is SlotDataState || current is! OnTapSlotCardState,
      listener: (context, state) async {
        if (state is SlotGenNavState) {
          await Navigator.pushNamed(
            context,
            AppRoutes.smartSlotSchedulerScreen,
          );
          if (context.mounted) {
            context.read<SlotBloc>().add(InitializeSlotsEvent());
          }
        } else if(state is OnTapSlotCardState){
        }
      },
      builder: (context, state) {
        return Scaffold(
          floatingActionButton: AddSlotFab(
            onAddSlot: () {
              context.read<SlotBloc>().add(SlotGenNavEvent());
            },
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            titleSpacing: 0,
            centerTitle: false,
            leading: const BackButton(),
            title: CommonText(
              "Ocimum, Jubileehils",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: displayWidth(context) * 0.04,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.15),
                  child: Icon(
                    Icons.person,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: state is SlotDataState
                ? _buildBodyContent(context, state)
                : const Center(child: CircularProgressIndicator.adaptive()),
          ),
        );
      },
    );
  }

  Widget _buildBodyContent(BuildContext context, SlotDataState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final totalCount = state.timeSlots.length;
    final bookedCount = state.timeSlots
        .where((s) => s.status == SlotStatus.booked)
        .length;
    final availableCount = state.timeSlots
        .where((s) => s.status == SlotStatus.available)
        .length;

    final visibleSlots = state.filteredSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: screenTopPadding),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          child: AdvancedCalendar(
            onDateChanged: (date) async {},
            handlerColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.2),
            buttonPrimaryColor: primaryColor,
            weekFontSize: displayWidth(context) * 0.025,
            todayStyle: const TextStyle(fontSize: 0),
            headerStyle: TextStyle(
              fontSize: displayWidth(context) * 0.045,
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
                selectedIndex: state.selectedTabIndex,
                allCount: totalCount,
                bookedCount: bookedCount,
                availableCount: availableCount,
                onTabSelected: (index) {
                  context.read<SlotBloc>().add(ChangeFilterTabUiEvent(index));
                },
              ),
              const SizedBox(height: fieldSpace),
              _buildTimeSlotHeaderRow(Theme.of(context)),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: visibleSlots.isEmpty
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 0.0),
                      child: TimeSlotCard(
                        slot: visibleSlots[index],
                        bookSlot: () {
                          try {
                            final legacySlot = state.slots.firstWhere(
                                  (s) => s.id == visibleSlots[index].id,
                            );
                            _openSlotDetailsDialog(context, legacySlot);
                          } catch (_) {
                            final customLegacySlot = SlotEntity(
                              id: visibleSlots[index].id,
                              startTime: visibleSlots[index].time,
                              endTime: visibleSlots[index].time,
                              label: visibleSlots[index].status == SlotStatus.booked ? 'Booked' : 'Available',
                              appointment: visibleSlots[index].status == SlotStatus.booked
                                  ? SlotAppointmentEntity(
                                id: visibleSlots[index].id,
                                patientName: visibleSlots[index].patientName ?? '',
                                contactNumber: 'N/A',
                              )
                                  : null,
                            );
                            _openSlotDetailsDialog(context, customLegacySlot);
                          }
                        },
                        viewSlotDetails: () {},
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotHeaderRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CommonText(
          "Time Slots",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: displayWidth(context) * 0.039,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: CommonText(
            "Availability: 9:00 AM - 5:00 PM",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context) * 0.022,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ),
      ],
    );
  }
}
