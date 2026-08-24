import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/app_bottom_nav_bar/app_bottom_nav_bar.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/features/presentation/appointments/widgets/stat_card.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/doc_appointment_card.dart';

import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/constants/constants.dart';
import '../../domain/entities/appointments/appointment_entity.dart';
import 'appointment_bloc/appointment_bloc.dart';

class AppointmentDashboardScreen extends StatefulWidget {
  final bool isShellChild;
  const AppointmentDashboardScreen({super.key, this.isShellChild = false});

  @override
  State<AppointmentDashboardScreen> createState() =>
      _AppointmentDashboardScreenState();
}

class _AppointmentDashboardScreenState extends State<AppointmentDashboardScreen> {
  Timer? _debounce;
  String _selectedDateLabel = "Today";
  DateTimeRange? _customDateRange;
  String _selectedStatus = "All Status";
  bool _showFilters = true;

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? darkModeCardColor
          : Colors.white,
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
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Update Status",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                appointment.patientName,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              ...statuses.map((s) {
                final isCurrent = appointment.statusRaw.toLowerCase() == s.toLowerCase();
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? (isDark
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Theme.of(context).primaryColor.withOpacity(0.06))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      s,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 15,
                        color: isCurrent
                            ? Theme.of(context).primaryColor
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    trailing: isCurrent
                        ? Icon(Icons.check_circle_rounded,
                            color: Theme.of(context).primaryColor, size: 22)
                        : null,
                    onTap: () {
                      Navigator.pop(dialogContext);
                      context.read<AppointmentBloc>().add(
                        UpdateAppointmentStatusEvent(
                          appointmentId: appointment.id,
                          status: s,
                        ),
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 8),
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

  // ─── Status icon helpers ──────────────────────────────────────
  IconData _statusIcon(String label) {
    switch (label.toLowerCase()) {
      case 'all status':
        return Icons.grid_view_rounded;
      case 'scheduled':
        return Icons.event_outlined;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'in progress':
        return Icons.hourglass_top_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'pending':
        return Icons.pending_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final isTab = isTablet(context);
    final width = displayWidth(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: widget.isShellChild ? null : const AppBottomNavBar(currentIndex: 1),
      body: SafeArea(
        child: BlocConsumer<AppointmentBloc, AppointmentState>(
          listener: (BuildContext context, AppointmentState state) {},
          builder: (context, state) {
            // Compute stats from loaded state
            int totalCount = 0;
            int completedCount = 0;
            int pendingCount = 0;
            List<Appointment> appointments = [];

            if (state is AppointmentLoaded) {
              appointments = state.appointments;
              completedCount = appointments
                  .where((a) => a.statusRaw.toLowerCase().contains('complete'))
                  .length;
              pendingCount = state.pendingCount > 0
                  ? state.pendingCount
                  : appointments
                      .where((a) =>
                          a.statusRaw.toLowerCase().contains('pending') ||
                          a.statusRaw.toLowerCase().contains('schedule'))
                      .length;
              totalCount = appointments.length > state.todayCount
                  ? appointments.length
                  : state.todayCount;
            }

            return Column(
              children: [
                // ─── HEADER ────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenHorizontalSpacePadding,
                    isTab ? 20 : 14,
                    screenHorizontalSpacePadding,
                    0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Appointments",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.w700,
                                fontSize: isTab ? width * 0.028 : width * 0.058,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.w400,
                                fontSize: isTab ? width * 0.015 : width * 0.03,
                                color: isDark ? Colors.white38 : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // New Appointment FAB
                      Material(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 0,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            final res = await Navigator.pushNamed(context, AppRoutes.addAppointmentScreen);
                            if (res == true && mounted) {
                              _loadWithDateFilter();
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTab ? 18 : 14,
                              vertical: isTab ? 12 : 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF2563EB),
                                  Color(0xFF3B82F6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  "New",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isTab ? width * 0.014 : width * 0.032,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ─── FIXED STAT CARDS ──────────────────────
                SizedBox(
                  height: smallDeviceHeight(context) ? 90 : 100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: screenHorizontalSpacePadding,
                    ),
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
                                  iconColor: const Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCard(
                                  isTab: isTab,
                                  title: "Completed",
                                  count: "$completedCount",
                                  subtitle: "Finished",
                                  icon: Icons.check_circle_outline,
                                  iconColor: const Color(0xFF059669),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatCard(
                                  isTab: isTab,
                                  title: "Pending",
                                  count: "$pendingCount",
                                  subtitle: "Action Needed",
                                  icon: Icons.hourglass_top_rounded,
                                  iconColor: const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  isTab: isTab,
                                  title: "Total",
                                  count: "$totalCount",
                                  subtitle: "Appointments",
                                  icon: Icons.calendar_month_outlined,
                                  iconColor: const Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: StatCard(
                                  isTab: isTab,
                                  title: "Completed",
                                  count: "$completedCount",
                                  subtitle: "Finished",
                                  icon: Icons.check_circle_outline,
                                  iconColor: const Color(0xFF059669),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: StatCard(
                                  isTab: isTab,
                                  title: "Pending",
                                  count: "$pendingCount",
                                  subtitle: "Action Needed",
                                  icon: Icons.hourglass_top_rounded,
                                  iconColor: const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                // ─── SEARCH BAR + FILTER ICON ────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: screenHorizontalSpacePadding,
                  ),
                  child: Row(
                    children: [
                      // Search field
                      Expanded(
                        child: TextField(
                          onChanged: _onSearchChanged,
                          style: TextStyle(
                            decorationThickness: 0,
                            decoration: TextDecoration.none,
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? width * 0.018 : width * 0.035,
                            color: theme.colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search patients...",
                            hintStyle: TextStyle(
                              decoration: TextDecoration.none,
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? width * 0.018 : width * 0.032,
                              color: isDark
                                  ? Colors.white.withOpacity(0.35)
                                  : textLightModeColor.withOpacity(0.4),
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 14, right: 10),
                              child: Icon(
                                Icons.search_rounded,
                                color: isDark
                                    ? Colors.white38
                                    : theme.primaryColor.withOpacity(0.6),
                                size: 22,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 46,
                              minHeight: 0,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? darkModeCardColor.withOpacity(0.6)
                                : const Color(0xFFF5F7FA),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? darkModeBorderColor
                                    : const Color(0xFFE5E7EB),
                                width: 1.0,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? darkModeBorderColor
                                    : const Color(0xFFE5E7EB),
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: isDark
                                    ? darkModeBorderFocusedColor
                                    : primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Filter icon button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _showFilters
                                ? primaryColor
                                : (isDark
                                    ? darkModeCardColor.withOpacity(0.6)
                                    : const Color(0xFFF5F7FA)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _showFilters
                                  ? primaryColor
                                  : (isDark
                                      ? darkModeBorderColor
                                      : const Color(0xFFE5E7EB)),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            _showFilters
                                ? Icons.filter_alt_rounded
                                : Icons.filter_alt_outlined,
                            size: 22,
                            color: _showFilters
                                ? Colors.white
                                : (isDark
                                    ? Colors.white54
                                    : Colors.grey.shade500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── COLLAPSIBLE FILTERS ──────────────────────
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Date chip selector
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: screenHorizontalSpacePadding,
                          ),
                          itemCount: _dateOptions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final option = _dateOptions[index];
                            final isActive = option == "Date Range"
                                ? _customDateRange != null
                                : _selectedDateLabel == option;

                            return GestureDetector(
                              onTap: () {
                                if (option == "Date Range") {
                                  _pickDateRange();
                                } else {
                                  setState(() {
                                    _selectedDateLabel = option;
                                    _customDateRange = null;
                                  });
                                  _loadWithDateFilter();
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? (isDark
                                          ? primaryColor.withOpacity(0.15)
                                          : primaryColor.withOpacity(0.08))
                                      : (isDark
                                          ? darkModeCardColor
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive
                                        ? primaryColor.withOpacity(0.5)
                                        : (isDark
                                            ? Colors.white.withOpacity(0.08)
                                            : Colors.grey.shade200),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (option == "Date Range") ...[
                                      Icon(
                                        Icons.date_range_rounded,
                                        size: 14,
                                        color: isActive
                                            ? primaryColor
                                            : (isDark
                                                ? Colors.white54
                                                : Colors.grey.shade500),
                                      ),
                                      const SizedBox(width: 5),
                                    ],
                                    Text(
                                      _customDateRange != null &&
                                              option == "Date Range"
                                          ? _selectedDateLabel
                                          : option,
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize:
                                            isTab ? width * 0.014 : width * 0.03,
                                        fontWeight: isActive
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isActive
                                            ? primaryColor
                                            : (isDark
                                                ? Colors.white60
                                                : Colors.grey.shade600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Status pill filter
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: screenHorizontalSpacePadding,
                          ),
                          itemCount: _statusOptions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final option = _statusOptions[index];
                            final isActive = _selectedStatus == option;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedStatus = option;
                                });
                                _loadWithDateFilter();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? primaryColor
                                      : (isDark
                                          ? darkModeCardColor.withOpacity(0.6)
                                          : Colors.white),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isActive
                                        ? primaryColor
                                        : (isDark
                                            ? Colors.white.withOpacity(0.08)
                                            : Colors.grey.shade200),
                                    width: 1,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color:
                                                primaryColor.withOpacity(0.2),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _statusIcon(option),
                                      size: 13,
                                      color: isActive
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white38
                                              : Colors.grey.shade400),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      option,
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: isTab
                                            ? width * 0.013
                                            : width * 0.028,
                                        fontWeight: isActive
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isActive
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.white54
                                                : Colors.grey.shade600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  crossFadeState: _showFilters
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 280),
                  sizeCurve: Curves.easeInOut,
                ),

                const SizedBox(height: 10),

                // ─── DATE & COUNT SUBTITLE ──────────────
                if (state is AppointmentLoaded)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: screenHorizontalSpacePadding,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color:
                                isDark ? Colors.white38 : Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getDateFilterSubtitle(),
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? width * 0.014 : width * 0.028,
                            color:
                                isDark ? Colors.white38 : Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? primaryColor.withOpacity(0.1)
                                : primaryColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${appointments.length} found',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? width * 0.013 : width * 0.026,
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 6),

                // ─── SCROLLABLE LIST CONTENT ───────────────
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: _buildListContent(
                        state, appointments, isDark, theme, isTab, width),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Builds only the scrollable list portion (loading / list / empty / error)
  Widget _buildListContent(
    AppointmentState state,
    List<Appointment> appointments,
    bool isDark,
    ThemeData theme,
    bool isTab,
    double width,
  ) {
    if (state is AppointmentLoading) {
      return AppointmentListShimmer(key: const ValueKey('loading'), itemCount: 4, isTab: isTab);
    }

    if (state is AppointmentLoaded) {
      if (appointments.isEmpty) {
        return _buildEmptyState(isDark, theme, isTab, width);
      }

      return RefreshIndicator(
        key: const ValueKey('loaded'),
        color: primaryColor,
        onRefresh: () async {
          _loadWithDateFilter();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView.builder(
          key: const ValueKey('appointment_list'),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: screenHorizontalSpacePadding,
          ),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];

            // Status colors
            final bool isCompleted =
                appointment.statusRaw.toLowerCase().contains('complete');
            final bool isVideo =
                appointment.type == AppointmentType.videoCall;
            Color statusColor;
            Color statusTextColor;
            String statusLabel;

            if (isCompleted) {
              statusColor = theme.primaryColor.withOpacity(0.1);
              statusTextColor = theme.primaryColor;
              statusLabel = 'Completed';
            } else if (appointment.statusRaw
                .toLowerCase()
                .contains('scheduled')) {
              statusColor = isDark
                  ? Colors.amber.withOpacity(0.15)
                  : Colors.amber.withOpacity(0.15);
              statusTextColor =
                  isDark ? Colors.amber[300]! : Colors.amber[800]!;
              statusLabel = 'Scheduled';
            } else if (appointment.statusRaw
                .toLowerCase()
                .contains('confirm')) {
              statusColor = isDark
                  ? Colors.green.withOpacity(0.15)
                  : Colors.green.withOpacity(0.15);
              statusTextColor =
                  isDark ? Colors.green[300]! : Colors.green[700]!;
              statusLabel = 'Confirmed';
            } else if (appointment.statusRaw
                .toLowerCase()
                .contains('pending')) {
              statusColor = isDark
                  ? Colors.red.withOpacity(0.15)
                  : Colors.red.withOpacity(0.15);
              statusTextColor =
                  isDark ? Colors.red[300]! : Colors.red[700]!;
              statusLabel = 'Pending';
            } else if (appointment.statusRaw
                .toLowerCase()
                .contains('progress')) {
              statusColor = isDark
                  ? Colors.blue.withOpacity(0.15)
                  : Colors.blue.withOpacity(0.15);
              statusTextColor =
                  isDark ? Colors.blue[300]! : Colors.blue[700]!;
              statusLabel = 'In Progress';
            } else {
              statusColor = isDark
                  ? Colors.grey.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.15);
              statusTextColor =
                  isDark ? Colors.grey[300]! : Colors.grey[700]!;
              statusLabel = appointment.statusRaw.isNotEmpty
                  ? appointment.statusRaw
                  : 'Scheduled';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: DocAppointmentCard(
                isTab: isTab,
                initials: _getInitials(appointment.patientName),
                name: appointment.patientName.isNotEmpty
                    ? appointment.patientName
                    : 'Unknown Patient',
                subtitle: appointment.category.isNotEmpty
                    ? appointment.category
                    : 'Consultation',
                description: appointment.reason?.isNotEmpty == true
                    ? appointment.reason!
                    : 'General Checkup',
                timeOrDate: appointment.time.isNotEmpty
                    ? appointment.time
                    : '--:-- AM',
                statusLabel: statusLabel,
                statusColor: statusColor,
                statusTextColor: statusTextColor,
                patientStatus: appointment.patientStatus,
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
                      'hospitalId':
                          appointment.hospitalId?.toString() ?? '',
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
      );
    }

    if (state is AppointmentError) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.red.withOpacity(0.1)
                      : Colors.red.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: isDark ? Colors.red[300] : Colors.red[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Something went wrong",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  context
                      .read<AppointmentBloc>()
                      .add(LoadAppointmentsEvent());
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text("Try Again"),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  textStyle: const TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink(key: ValueKey('initial'));
  }

  Widget _buildEmptyState(
      bool isDark, ThemeData theme, bool isTab, double width) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Empty state illustration container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark
                    ? primaryColor.withOpacity(0.08)
                    : primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark
                        ? primaryColor.withOpacity(0.12)
                        : primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_busy_outlined,
                    size: 32,
                    color: isDark
                        ? primaryColor.withOpacity(0.6)
                        : primaryColor.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Appointments Found",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.w700,
                fontSize: isTab ? width * 0.022 : width * 0.042,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "No appointments match your current filters.\nTry adjusting them or book a new one.",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.w400,
                fontSize: isTab ? width * 0.016 : width * 0.03,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final res = await Navigator.pushNamed(context, AppRoutes.addAppointmentScreen);
                  if (res == true && mounted) {
                    _loadWithDateFilter();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        "Book Appointment",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w600,
                          fontSize: isTab ? width * 0.016 : width * 0.032,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
