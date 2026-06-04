import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/features/presentation/appointments/widgets/appointment_tab_content.dart';
import 'package:yiraclinics/features/presentation/appointments/widgets/stat_card.dart';

import '../../../core/common_drop_down/common_drop_down.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/constants/constants.dart';
import '../../domain/entities/appointments/appointment_entity.dart';
import 'appointment_bloc/appointment_bloc.dart';

class AppointmentDashboardScreen extends StatefulWidget {
  const AppointmentDashboardScreen({super.key});

  @override
  State<AppointmentDashboardScreen> createState() =>
      _AppointmentDashboardScreenState();
}

class _AppointmentDashboardScreenState extends State<AppointmentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<AppointmentBloc>().add(LoadAppointmentsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: screenHorizontalSpacePadding),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(
                Icons.add,
                size: displayWidth(context) * 0.035,
                color: Colors.white,
              ),
              label: CommonText(
                "Appointment",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w500,
                  fontSize: displayWidth(context) * 0.028,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
                padding: EdgeInsets.symmetric(
                  horizontal: displayWidth(context) * 0.03,
                  vertical: displayWidth(context) * 0.018,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<AppointmentBloc, AppointmentState>(
          listener: (BuildContext context, AppointmentState state) {},
          builder: (context, state) {
            if (state is AppointmentLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AppointmentLoaded) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stat Cards Grid Track
                    SizedBox(
                      height: smallDeviceHeight(context) ? 90 : 100,
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2.0,
                          vertical: 2.0,
                        ),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: 3,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.78,
                            ),
                        itemBuilder: (context, index) {
                          switch (index) {
                            case 0:
                              return StatCard(
                                title: "Today",
                                count: "${state.todayCount}",
                                subtitle: "Apps",
                                icon: Icons.calendar_today_outlined,
                                iconColor: Colors.blue,
                              );
                            case 1:
                              return StatCard(
                                title: "Confirmed",
                                count: "${state.confirmedCount}",
                                subtitle: "Ready",
                                icon: Icons.check_circle,
                                iconColor: Colors.green,
                              );
                            case 2:
                            default:
                              return StatCard(
                                title: "Pending",
                                count: "${state.pendingCount}",
                                subtitle: "Need Info",
                                icon: Icons.error_outline,
                                iconColor: Colors.red,
                              );
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: fieldSpace),

                    // Tab Navigation Switcher
                    Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white10.withOpacity(0.02)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        labelColor: isDark
                            ? Colors.white
                            : Colors.blue.shade900,
                        unselectedLabelColor: Colors.grey,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: displayWidth(context) * 0.032,
                          fontFamily: appPoppinFont,
                        ),
                        tabs: const [
                          Tab(text: "Schedule"),
                          Tab(text: "Queue"),
                          Tab(text: "Teleconsult"),
                        ],
                      ),
                    ),
                    const SizedBox(height: fieldSpace),

                    // Search Input Layout
                    TextField(
                      onChanged: (val) {},
                      style: TextStyle(
                        decorationThickness: 0,
                        fontFamily: appPoppinFont,
                        fontSize: displayWidth(context) * 0.034,
                      ),
                      decoration: InputDecoration(
                        hintStyle: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: displayWidth(context) * 0.034,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                        ),
                        hintText: "Search Patients...",
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.blueGrey,
                          size: 18,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? darkModeCardColor
                            : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.3),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: fieldSpace),

                    // Filter Drops Selection Row
                    Row(
                      children: [
                        Expanded(
                          child: CommonDropdown(
                            title: "All Status",
                            selectedValue: state.selectedSlot,
                            options: const [
                              "All Status",
                              "Scheduled",
                              "Confirmed",
                              "In-Progress",
                              "Completed",
                            ],
                            onSelected: (value) {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CommonDropdown(
                            title: "To Day",
                            selectedValue: state.selectedSlot,
                            options: const [
                              "To Day",
                              "Tomorrow",
                              "Up Coming",
                              "All Dates",
                            ],
                            onSelected: (value) {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: fieldSpace),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          AppointmentTabContent(
                            appointments: state.appointments,
                            emptyMessage:
                                "No appointments scheduled for today.",
                            onBookAppointment: () {},
                            tabTitle: 'Scheduled',
                            tabIndex: 1,
                          ),

                          AppointmentTabContent(
                            appointments: state.appointments
                                .where(
                                  (a) => a.type == AppointmentType.inClinic,
                                )
                                .toList(),
                            emptyMessage:
                                "No patients currently waiting in queue.",
                            onBookAppointment: () {},
                            tabTitle: 'Queue',
                            tabIndex: 2,
                          ),

                          AppointmentTabContent(
                            appointments: state.appointments
                                .where(
                                  (a) => a.type == AppointmentType.videoCall,
                                )
                                .toList(),
                            emptyMessage:
                                "No video medical consultations scheduled.",
                            onBookAppointment: () {},
                            tabTitle: 'Tele Conference',
                            tabIndex: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is AppointmentError) {
              return Center(child: Text(state.message));
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
