import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/core/utils/utils.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/appointments/appointment_entity.dart';
import 'package:yiraclinics/features/presentation/appointments/appointment_bloc/appointment_bloc.dart';
import 'package:yiraclinics/features/presentation/appointments/widgets/stat_card.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/doc_appointment_card.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  final Function(int index)? onNavigateTab;

  const PatientAppointmentsScreen({super.key, this.onNavigateTab});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
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
    "Cancelled",
  ];

  @override
  void initState() {
    super.initState();
    _loadWithDateFilter();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = val.trim();
      _loadWithDateFilter(search: query.isNotEmpty ? query : null);
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
    } else if (_customDateRange != null) {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final isTab = isTablet(context);
    final width = displayWidth(context);
    final primaryColor = theme.primaryColor;

    final currentUser = GlobalSession.instance.userNotifier.value;
    final currentUserId = currentUser?.data?.id ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocConsumer<AppointmentBloc, AppointmentState>(
          listener: (BuildContext context, AppointmentState state) {},
          builder: (context, state) {
            int totalCount = 0;
            int completedCount = 0;
            int pendingCount = 0;
            List<Appointment> allAppointments = [];

            if (state is AppointmentLoaded) {
              allAppointments = state.appointments;
              completedCount = allAppointments
                  .where((a) => a.statusRaw.toLowerCase().contains('complete'))
                  .length;
              pendingCount = allAppointments
                  .where((a) =>
                      a.statusRaw.toLowerCase().contains('pending') ||
                      a.statusRaw.toLowerCase().contains('schedule') ||
                      a.statusRaw.toLowerCase().contains('confirm'))
                  .length;
              totalCount = allAppointments.length;
            }

            final searchQuery = _searchController.text.trim().toLowerCase();
            final filteredAppointments = allAppointments.where((a) {
              final matchesSearch = searchQuery.isEmpty ||
                  (a.doctorName?.toLowerCase().contains(searchQuery) == true) ||
                  a.patientName.toLowerCase().contains(searchQuery) ||
                  a.category.toLowerCase().contains(searchQuery) ||
                  (a.hospitalName?.toLowerCase().contains(searchQuery) == true);

              if (!matchesSearch) return false;

              if (_selectedStatus != "All Status") {
                if (!a.statusRaw.toLowerCase().contains(_selectedStatus.toLowerCase())) {
                  return false;
                }
              }

              return true;
            }).toList();

            return Column(
              children: [
                // ─── 1. EXACT PROVIDER HEADER ──────────────────────
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
                      // Book New Appointment Action Button
                      Material(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 0,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            await Navigator.pushNamed(context, AppRoutes.addAppointmentScreen);
                            if (mounted) {
                              context.read<AppointmentBloc>().add(LoadAppointmentsEvent());
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
                                  color: primaryColor.withValues(alpha: 0.3),
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

                // ─── 2. FIXED STAT CARDS (EXACT PROVIDER LAYOUT) ────
                SizedBox(
                  height: smallDeviceHeight(context) ? 90 : 100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: screenHorizontalSpacePadding,
                    ),
                    child: Row(
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
                            subtitle: "Total Done",
                            icon: Icons.check_circle_outline,
                            iconColor: const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatCard(
                            isTab: isTab,
                            title: "Upcoming",
                            count: "$pendingCount",
                            subtitle: "Scheduled",
                            icon: Icons.hourglass_top_rounded,
                            iconColor: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ─── 3. DATE SELECTOR & FILTER BAR ────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: screenHorizontalSpacePadding,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        ..._dateOptions.map((opt) {
                          final isSelected = _selectedDateLabel == opt ||
                              (opt == "Date Range" && _customDateRange != null && !_dateOptions.sublist(0, 2).contains(_selectedDateLabel));
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (opt == "Date Range") {
                                  _pickDateRange();
                                } else {
                                  setState(() {
                                    _customDateRange = null;
                                    _selectedDateLabel = opt;
                                  });
                                  _loadWithDateFilter();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  opt,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected
                                        ? primaryColor
                                        : (isDark ? Colors.white60 : Colors.grey.shade600),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            _showFilters ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
                            size: 20,
                            color: _showFilters ? primaryColor : (isDark ? Colors.white60 : Colors.grey.shade600),
                          ),
                          onPressed: () => setState(() => _showFilters = !_showFilters),
                          tooltip: 'Toggle Filters',
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── 4. SEARCH & STATUS FILTERS (COLLAPSIBLE) ──────
                if (_showFilters) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search doctor, hospital, specialty...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
                      children: _statusOptions.map((status) {
                        final isSelected = _selectedStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ChoiceChip(
                            label: Text(
                              status,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) {
                              setState(() => _selectedStatus = status);
                              _loadWithDateFilter(status: status);
                            },
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            selectedColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? primaryColor : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // ─── 5. APPOINTMENTS LIST (DOC APPOINTMENT CARD) ────
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<AppointmentBloc>().add(LoadAppointmentsEvent());
                      await Future.delayed(const Duration(milliseconds: 600));
                    },
                    child: state is AppointmentLoading
                        ? _buildAppointmentsShimmer(context, isDark)
                        : filteredAppointments.isEmpty
                            ? Center(
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.event_busy_outlined,
                                          size: 64,
                                          color: theme.hintColor.withValues(alpha: 0.3),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          "No Appointments Found",
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontWeight: FontWeight.w600,
                                            fontSize: isTab ? 18 : 15,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No appointments matching the selected date or filter.',
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: isTab ? 14 : 12,
                                            color: theme.hintColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 20),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await Navigator.pushNamed(context, AppRoutes.addAppointmentScreen);
                                            if (mounted) {
                                              context.read<AppointmentBloc>().add(LoadAppointmentsEvent());
                                            }
                                          },
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text(
                                            "Book Appointment",
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: screenHorizontalSpacePadding,
                                  vertical: 4,
                                ),
                                itemCount: filteredAppointments.length,
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                itemBuilder: (context, index) {
                                  final appointment = filteredAppointments[index];
                                  final docName = appointment.doctorName ?? 'Consulting Doctor';
                                  final initials = docName.isNotEmpty ? docName[0].toUpperCase() : 'DR';
                                  final hospitalName = (appointment.hospitalName != null && appointment.hospitalName!.isNotEmpty)
                                      ? appointment.hospitalName!
                                      : ((appointment.hospitalId != null && appointment.hospitalId == 19) ? 'Yira Hospitals' : 'Yira Clinx Center');
                                  final statusLabel = appointment.statusRaw.isNotEmpty ? appointment.statusRaw : 'Confirmed';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10.0),
                                    child: DocAppointmentCard(
                                      initials: initials,
                                      name: docName,
                                      subtitle: hospitalName,
                                      description: appointment.category.isNotEmpty ? appointment.category : 'General Consultation',
                                      timeOrDate: '${appointment.time} • ${appointment.duration}',
                                      statusLabel: statusLabel,
                                      statusColor: const Color(0xFF059669),
                                      statusTextColor: Colors.white,
                                      isTab: isTab,
                                      isTeleConsultation: appointment.type == AppointmentType.videoCall,
                                      onJoinCall: () {
                                        final url = appointment.meetingUrl;
                                        if (url != null && url.isNotEmpty) {
                                          Utils.launchURL(
                                            url,
                                            onLaunchFailure: (err) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                              }
                                            },
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('No meeting link available.')),
                                          );
                                        }
                                      },
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          AppRoutes.doctorPatientProfileScreen,
                                          arguments: {
                                            'patientId': appointment.patientUserId ?? currentUserId,
                                            'appointmentId': appointment.id,
                                            'hospitalId': appointment.hospitalId?.toString() ?? '1',
                                            'orgId': appointment.orgId?.toString() ?? '1',
                                            'patientName': appointment.patientName.isNotEmpty ? appointment.patientName : 'Patient',
                                            'initialStatus': appointment.statusRaw,
                                            'initialTabIndex': 0,
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppointmentsShimmer(BuildContext context, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 8),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: BaseShimmer(
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
