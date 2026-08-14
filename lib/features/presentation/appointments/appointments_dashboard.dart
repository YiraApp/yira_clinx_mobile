import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/common_drop_down/common_drop_down.dart';
import 'package:yiraclinics/features/presentation/appointments/widgets/stat_card.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/doc_appointment_card.dart';

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

class _AppointmentDashboardScreenState extends State<AppointmentDashboardScreen> {
  Timer? _debounce;
  String _selectedDateLabel = "Today";
  DateTimeRange? _customDateRange;
  String _selectedStatus = "All Status";

  final List<String> _dateOptions = const [
    "Today",
    "Tomorrow",
    "Date Range",
  ];

  final List<String> _statusOptions = const [
    "All Status",
    "Scheduled",
    "Confirmed",
    "In Progress",
    "Completed",
    "Pending",
  ];

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = val.trim();
      if (query.isEmpty || query.length >= 3) {
        _loadWithDateFilter(search: query);
      }
    });
  }

  void _loadWithDateFilter({String? search, String? status}) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
    final currentStatus = status ?? _selectedStatus;
    final statusParam = currentStatus != "All Status" ? currentStatus : null;

    if (_selectedDateLabel == "Tomorrow") {
      context.read<AppointmentBloc>().add(LoadAppointmentsEvent(
        date: tomorrowStr,
        search: search,
        status: statusParam,
      ));
    } else if (_selectedDateLabel.contains("-") || _customDateRange != null) {
      if (_customDateRange != null) {
        context.read<AppointmentBloc>().add(LoadAppointmentsEvent(
          dateFrom: DateFormat('yyyy-MM-dd').format(_customDateRange!.start),
          dateTo: DateFormat('yyyy-MM-dd').format(_customDateRange!.end),
          search: search,
          status: statusParam,
        ));
      } else {
        context.read<AppointmentBloc>().add(LoadAppointmentsEvent(
          date: todayStr,
          search: search,
          status: statusParam,
        ));
      }
    } else {
      // Default: Today
      context.read<AppointmentBloc>().add(LoadAppointmentsEvent(
        date: todayStr,
        search: search,
        status: statusParam,
      ));
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: now,
        end: now.add(const Duration(days: 7)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final rangeStr = "${DateFormat('MMM d').format(picked.start)} - ${DateFormat('MMM d').format(picked.end)}";
      setState(() {
        _customDateRange = picked;
        _selectedDateLabel = rangeStr;
      });
      _loadWithDateFilter();
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  void _showStatusChangeDialog(Appointment appointment) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) {
        final statuses = [
          'Scheduled',
          'Confirmed',
          'In Progress',
          'Completed',
          'Cancelled',
        ];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Update Status for ${appointment.patientName}",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ...statuses.map((s) {
                final isCurrent = appointment.statusRaw.toLowerCase() == s.toLowerCase();
                return ListTile(
                  title: Text(
                    s,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Theme.of(context).primaryColor : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  trailing: isCurrent ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) : null,
                  onTap: () {
                    Navigator.pop(dialogContext);
                    context.read<AppointmentBloc>().add(
                      UpdateAppointmentStatusEvent(
                        appointmentId: appointment.id,
                        status: s,
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _getDateFilterSubtitle() {
    final now = DateTime.now();
    if (_selectedDateLabel == "Tomorrow") {
      return DateFormat('EEEE, MMM d').format(now.add(const Duration(days: 1)));
    } else if (_customDateRange != null) {
      return '${DateFormat('MMM d').format(_customDateRange!.start)} - ${DateFormat('MMM d').format(_customDateRange!.end)}';
    }
    return DateFormat('EEEE, MMM d').format(now);
  }

  @override
  void initState() {
    super.initState();
    context.read<AppointmentBloc>().add(LoadAppointmentsEvent());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    var isTab = isTablet(context);
    final double computedRadius = fieldBorderRadius;
    final width = displayWidth(context);

    final Color inactiveBorderColor = isDark ? darkModeBorderColor : lightModeBorderColor;
    final Color activeBorderColor = isDark ? darkModeBorderFocusedColor : lightModeBorderFocusedColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CommonAppBar(
        actions: [
          Container(
            margin: EdgeInsets.only(right: screenHorizontalSpacePadding, bottom: 10),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addAppointmentScreen);
              },
              icon: const Icon(Icons.add, size: 20, color: Colors.white),
              label: CommonText(
                "Appointment",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w500,
                  fontSize: isTab ? width * 0.012 : width * 0.028,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                elevation: 0,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: Size.zero,
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.03,
                  vertical: width * 0.018,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
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
              return const Center(child: CircularProgressIndicator.adaptive());
            }

            if (state is AppointmentLoaded) {
              final appointments = state.appointments;
              final completedCount = appointments.where((a) => a.statusRaw.toLowerCase().contains('complete')).length;
              final pendingCount = state.pendingCount > 0
                  ? state.pendingCount
                  : appointments.where((a) => a.statusRaw.toLowerCase().contains('pending') || a.statusRaw.toLowerCase().contains('schedule')).length;
              final totalCount = appointments.length > state.todayCount ? appointments.length : state.todayCount;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: screenHorizontalSpacePadding,
                  vertical: screenTopPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stat Cards: Total, Completed, Pending
                    SizedBox(
                      height: smallDeviceHeight(context) ? 90 : 100,
                      child: isTab
                          ? Row(
                              children: [
                                Expanded(
                                  child: StatCard(
                                    isTab: isTab,
                                    title: "Total",
                                    count: "$totalCount",
                                    subtitle: "Appointments",
                                    icon: Icons.calendar_month_outlined,
                                    iconColor: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: StatCard(
                                    isTab: isTab,
                                    title: "Completed",
                                    count: "$completedCount",
                                    subtitle: "Finished",
                                    icon: Icons.check_circle_outline,
                                    iconColor: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: StatCard(
                                    isTab: isTab,
                                    title: "Pending",
                                    count: "$pendingCount",
                                    subtitle: "Action Need",
                                    icon: Icons.hourglass_empty_rounded,
                                    iconColor: Colors.orange,
                                  ),
                                ),
                              ],
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: 3,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 1,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.78,
                              ),
                              itemBuilder: (context, index) {
                                switch (index) {
                                  case 0:
                                    return StatCard(
                                      isTab: isTab,
                                      title: "Total",
                                      count: "$totalCount",
                                      subtitle: "Appointments",
                                      icon: Icons.calendar_month_outlined,
                                      iconColor: Colors.blue,
                                    );
                                  case 1:
                                    return StatCard(
                                      isTab: isTab,
                                      title: "Completed",
                                      count: "$completedCount",
                                      subtitle: "Finished",
                                      icon: Icons.check_circle_outline,
                                      iconColor: Colors.green,
                                    );
                                  case 2:
                                  default:
                                    return StatCard(
                                      isTab: isTab,
                                      title: "Pending",
                                      count: "$pendingCount",
                                      subtitle: "Action Need",
                                      icon: Icons.hourglass_empty_rounded,
                                      iconColor: Colors.orange,
                                    );
                                }
                              },
                            ),
                    ),
                    const SizedBox(height: fieldSpace),

                    // Search Bar
                    TextField(
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        decorationThickness: 0,
                        decoration: TextDecoration.none,
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? width * 0.018 : width * 0.035,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search patients by name or phone...",
                        hintStyle: TextStyle(
                          decoration: TextDecoration.none,
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? width * 0.018 : width * 0.032,
                          color: isDark
                              ? Colors.white.withOpacity(0.5)
                              : textLightModeColor.withOpacity(0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: isDark ? Colors.white54 : theme.primaryColor,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? darkModeCardColor.withOpacity(0.8)
                            : lightModeTextFieldBgColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(computedRadius),
                          borderSide: BorderSide(color: inactiveBorderColor, width: 1.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(computedRadius),
                          borderSide: BorderSide(color: inactiveBorderColor, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(computedRadius),
                          borderSide: BorderSide(color: activeBorderColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status and Date Dropdowns
                    Row(
                      children: [
                        Expanded(
                          child: CommonDropdown(
                            title: "All Status",
                            selectedValue: _selectedStatus,
                            options: _statusOptions,
                            onSelected: (val) {
                              setState(() {
                                _selectedStatus = val;
                              });
                              _loadWithDateFilter();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CommonDropdown(
                            title: "Today",
                            selectedValue: _selectedDateLabel,
                            options: _dateOptions,
                            onSelected: (val) {
                              if (val == "Date Range") {
                                _pickDateRange();
                              } else {
                                setState(() {
                                  _selectedDateLabel = val;
                                  _customDateRange = null;
                                });
                                _loadWithDateFilter();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Date & count subtitle row
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: theme.hintColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getDateFilterSubtitle(),
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? width * 0.014 : width * 0.028,
                              color: theme.hintColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${appointments.length} appointments',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? width * 0.014 : width * 0.028,
                              color: theme.hintColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Appointments List
                    Expanded(
                      child: appointments.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.event_busy_outlined,
                                        size: width * 0.18,
                                        color: theme.hintColor.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      CommonText(
                                        "No Appointments Found",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontWeight: FontWeight.w600,
                                          fontSize: width * 0.04,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      CommonText(
                                        "No appointments for the selected filter criteria.",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontWeight: FontWeight.w400,
                                          fontSize: isTab ? width * 0.022 : width * 0.03,
                                          color: theme.hintColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        height: 40,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(context, AppRoutes.addAppointmentScreen);
                                          },
                                          icon: const Icon(Icons.add, size: 16),
                                          label: CommonText(
                                            "Book Appointment",
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontWeight: FontWeight.w500,
                                              fontSize: width * 0.03,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(fieldBorderRadius),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: appointments.length,
                              itemBuilder: (context, index) {
                                final appointment = appointments[index];

                                // Status colors
                                final bool isCompleted = appointment.statusRaw.toLowerCase().contains('complete');
                                final bool isVideo = appointment.type == AppointmentType.videoCall;
                                Color statusColor;
                                Color statusTextColor;
                                String statusLabel;

                                if (isCompleted) {
                                  statusColor = theme.primaryColor.withOpacity(0.1);
                                  statusTextColor = theme.primaryColor;
                                  statusLabel = 'Completed';
                                } else if (appointment.statusRaw.toLowerCase().contains('scheduled')) {
                                  statusColor = isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.withOpacity(0.15);
                                  statusTextColor = isDark ? Colors.amber[300]! : Colors.amber[800]!;
                                  statusLabel = 'Scheduled';
                                } else if (appointment.statusRaw.toLowerCase().contains('confirm')) {
                                  statusColor = isDark ? Colors.green.withOpacity(0.15) : Colors.green.withOpacity(0.15);
                                  statusTextColor = isDark ? Colors.green[300]! : Colors.green[700]!;
                                  statusLabel = 'Confirmed';
                                } else if (appointment.statusRaw.toLowerCase().contains('pending')) {
                                  statusColor = isDark ? Colors.red.withOpacity(0.15) : Colors.red.withOpacity(0.15);
                                  statusTextColor = isDark ? Colors.red[300]! : Colors.red[700]!;
                                  statusLabel = 'Pending';
                                } else if (appointment.statusRaw.toLowerCase().contains('progress')) {
                                  statusColor = isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.withOpacity(0.15);
                                  statusTextColor = isDark ? Colors.blue[300]! : Colors.blue[700]!;
                                  statusLabel = 'In Progress';
                                } else {
                                  statusColor = isDark ? Colors.grey.withOpacity(0.15) : Colors.grey.withOpacity(0.15);
                                  statusTextColor = isDark ? Colors.grey[300]! : Colors.grey[700]!;
                                  statusLabel = appointment.statusRaw.isNotEmpty ? appointment.statusRaw : 'Scheduled';
                                }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: DocAppointmentCard(
                                      isTab: isTab,
                                      initials: _getInitials(appointment.patientName),
                                      name: appointment.patientName.isNotEmpty ? appointment.patientName : 'Unknown Patient',
                                      subtitle: appointment.category.isNotEmpty ? appointment.category : 'Consultation',
                                      description: appointment.reason?.isNotEmpty == true ? appointment.reason! : 'General Checkup',
                                      timeOrDate: appointment.time.isNotEmpty ? appointment.time : '--:-- AM',
                                      statusLabel: statusLabel,
                                      statusColor: statusColor,
                                      statusTextColor: statusTextColor,
                                      isTeleConsultation: isVideo,
                                      onStatusTap: () {
                                        _showStatusChangeDialog(appointment);
                                      },
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.doctorPatientProfileScreen,
                                          arguments: {
                                            'patientId': appointment.patientUserId ?? '',
                                            'appointmentId': appointment.id,
                                            'hospitalId': appointment.hospitalId?.toString() ?? '',
                                            'orgId': appointment.orgId?.toString() ?? '',
                                            'patientName': appointment.patientName,
                                            'initialTabIndex': 0,
                                          },
                                        );
                                      },
                                    ),
                                  );
                              },
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
