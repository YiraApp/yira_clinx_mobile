import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../di/dependency_injection.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../patient_profile/patient_over_view_bloc/patient_over_view_bloc.dart';
import '../widgets/patient_appointment_card.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allAppointments = [];
  final Map<String, bool> _expandedHospitals = {};

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openBookAppointmentDialog() {
    String selectedHospital = 'Apollo City Hospital';
    String selectedSpecialty = 'Cardiology';
    String selectedDoctor = 'Dr. Sarah Jenkins';
    String selectedMode = 'In-Person';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String selectedSlot = '10:30 AM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final primaryColor = Theme.of(context).primaryColor;
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Book New Appointment',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hospital Selection
                  Text('Select Hospital / Branch', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedHospital,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: ['Apollo City Hospital', 'St. Jude Children\'s Clinic', 'Metro General Hospital']
                        .map((h) => DropdownMenuItem(value: h, child: Text(h, style: TextStyle(color: textColor))))
                        .toList(),
                    onChanged: (val) => setModalState(() => selectedHospital = val!),
                  ),
                  const SizedBox(height: 14),

                  // Specialty Selection
                  Text('Specialty / Reason', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedSpecialty,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: ['Cardiology', 'Dermatology', 'General Medicine', 'Orthopedics', 'Pediatrics']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: textColor))))
                        .toList(),
                    onChanged: (val) => setModalState(() => selectedSpecialty = val!),
                  ),
                  const SizedBox(height: 14),

                  // Doctor Selection
                  Text('Attending Physician', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedDoctor,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: ['Dr. Sarah Jenkins', 'Dr. Marcus Vance', 'Dr. Elena Rostova']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d, style: TextStyle(color: textColor))))
                        .toList(),
                    onChanged: (val) => setModalState(() => selectedDoctor = val!),
                  ),
                  const SizedBox(height: 14),

                  // Mode Selection
                  Text('Consultation Mode', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['In-Person', 'Video'].map((mode) {
                      final isSelected = selectedMode == mode;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedMode = mode),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor : (isDark ? const Color(0xFF0F172A) : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? primaryColor : Colors.transparent),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(mode == 'Video' ? Icons.video_call_rounded : Icons.local_hospital_rounded, size: 18, color: isSelected ? Colors.white : textColor),
                                  const SizedBox(width: 6),
                                  Text(mode, style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : textColor)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Time Slot Selection
                  Text('Select Time Slot', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: ['09:30 AM', '10:30 AM', '02:00 PM', '04:30 PM']
                        .map((slot) => ChoiceChip(
                              label: Text(slot),
                              selected: selectedSlot == slot,
                              selectedColor: primaryColor,
                              labelStyle: TextStyle(color: selectedSlot == slot ? Colors.white : textColor),
                              onSelected: (sel) => setModalState(() => selectedSlot = slot),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        setState(() {
                          _allAppointments.insert(0, {
                            'id': 'custom_${DateTime.now().millisecondsSinceEpoch}',
                            'doctorName': selectedDoctor,
                            'specialty': selectedSpecialty,
                            'hospitalName': selectedHospital,
                            'date': '${selectedDate.day} Aug 2026',
                            'time': selectedSlot,
                            'status': 'Scheduled',
                            'isTeleconsultation': selectedMode == 'Video',
                            'meetingUrl': selectedMode == 'Video' ? 'https://zoom.us' : null,
                          });
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Appointment booked successfully!')),
                        );
                      },
                      child: const Text('Confirm Appointment Booking', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _extractAppointmentsFromEntity(PatientOverViewEntity? entity) {
    if (entity == null || entity.data == null) return [];
    final data = entity.data!;
    final List<Map<String, dynamic>> list = [];

    if (data.appointments != null && data.appointments!.isNotEmpty) {
      for (final a in data.appointments!) {
        list.add({
          'id': a.id,
          'doctorName': a.doctorName.isNotEmpty ? (a.doctorName.startsWith('Dr') ? a.doctorName : 'Dr. ${a.doctorName}') : 'Attending Physician',
          'specialty': a.reason.isNotEmpty ? a.reason : (a.appointmentType.isNotEmpty ? a.appointmentType : 'General Practitioner'),
          'hospitalName': a.hospitalName.isNotEmpty ? a.hospitalName : 'ClinicX Health Center',
          'date': a.appointmentDate.isNotEmpty ? a.appointmentDate : 'Scheduled',
          'time': a.startTime.isNotEmpty ? a.startTime : 'Standard Slot',
          'status': a.status.isNotEmpty ? a.status : 'Scheduled',
          'isTeleconsultation': a.isTeleConsultation,
          'meetingUrl': a.meetingUrl.isNotEmpty ? a.meetingUrl : null,
        });
      }
    }

    if (data.upcomingAppointments != null && data.upcomingAppointments!.isNotEmpty) {
      for (final u in data.upcomingAppointments!) {
        final idStr = u.appointmentId ?? (u.id != null ? u.id.toString() : '');
        if (idStr.isEmpty || !list.any((x) => x['id'] == idStr)) {
          list.add({
            'id': idStr.isNotEmpty ? idStr : 'up_${list.length}',
            'doctorName': u.doctorName != null && u.doctorName!.isNotEmpty ? (u.doctorName!.startsWith('Dr') ? u.doctorName! : 'Dr. ${u.doctorName}') : 'Attending Physician',
            'specialty': u.doctorSpecialty ?? u.reason ?? u.consultationType ?? 'General Practitioner',
            'hospitalName': u.hospitalName ?? 'ClinicX Health Center',
            'date': u.formattedDate ?? u.appointmentDate ?? 'Scheduled Visit',
            'time': u.formattedTime ?? u.startTime ?? 'Scheduled Slot',
            'status': u.status ?? 'Scheduled',
            'isTeleconsultation': u.isTeleconsultation ?? false,
            'meetingUrl': u.meetingUrl,
          });
        }
      }
    }

    if (data.nextAppointment != null) {
      final n = data.nextAppointment!;
      final idStr = n.appointmentId ?? (n.id != null ? n.id.toString() : '');
      if (idStr.isEmpty || !list.any((x) => x['id'] == idStr)) {
        list.add({
          'id': idStr.isNotEmpty ? idStr : 'next_1',
          'doctorName': n.doctorName != null && n.doctorName!.isNotEmpty ? (n.doctorName!.startsWith('Dr') ? n.doctorName! : 'Dr. ${n.doctorName}') : 'Attending Physician',
          'specialty': n.doctorSpecialty ?? n.reason ?? n.consultationType ?? 'General Practitioner',
          'hospitalName': n.hospitalName ?? 'ClinicX Health Center',
          'date': n.formattedDate ?? n.appointmentDate ?? 'Scheduled Visit',
          'time': n.formattedTime ?? n.startTime ?? 'Scheduled Slot',
          'status': n.status ?? 'Scheduled',
          'isTeleconsultation': n.isTeleconsultation ?? false,
          'meetingUrl': n.meetingUrl,
        });
      }
    }

    return list;
  }

  String _selectedHospitalFilter = 'All Hospitals';

  DateTime? _parseAppointmentDate(String dateStr) {
    if (dateStr.isEmpty || dateStr.toLowerCase() == 'null' || dateStr.toLowerCase() == 'none' || dateStr.toLowerCase() == 'scheduled') {
      return null;
    }
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt != null) return dt;

      final parts = dateStr.replaceAll(',', '').trim().split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        int? day = int.tryParse(parts[0]);
        int? year = int.tryParse(parts[2]);
        String monthStr = parts[1].toLowerCase();

        if (day == null) {
          monthStr = parts[0].toLowerCase();
          day = int.tryParse(parts[1]);
          year = int.tryParse(parts[2]);
        }

        if (day != null && year != null) {
          const months = {
            'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
            'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
          };
          for (final entry in months.entries) {
            if (monthStr.startsWith(entry.key)) {
              return DateTime(year, entry.value, day);
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  bool _isUpcomingAppointment(Map<String, dynamic> item) {
    final st = item['status'].toString().toLowerCase();
    if (st.contains('cancel') || st.contains('complete') || st.contains('done')) {
      return false;
    }

    final dateStr = (item['date'] ?? item['appointmentDate'] ?? '').toString();
    final parsedDate = _parseAppointmentDate(dateStr);

    if (parsedDate != null) {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final apptDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      if (apptDay.isBefore(todayMidnight)) {
        return false;
      }
    }

    return true;
  }

  bool _isCompletedAppointment(Map<String, dynamic> item) {
    final st = item['status'].toString().toLowerCase();
    if (st.contains('complete') || st.contains('done') || st.contains('finished')) {
      return true;
    }

    final dateStr = (item['date'] ?? item['appointmentDate'] ?? '').toString();
    final parsedDate = _parseAppointmentDate(dateStr);
    if (parsedDate != null && !st.contains('cancel')) {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final apptDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      if (apptDay.isBefore(todayMidnight)) {
        return true;
      }
    }

    return false;
  }

  Widget _buildStatsHeader(List<Map<String, dynamic>> combinedList, bool isDark) {
    int total = combinedList.length;
    int upcoming = combinedList.where(_isUpcomingAppointment).length;
    int completed = combinedList.where(_isCompletedAppointment).length;
    int cancelled = combinedList.where((a) => a['status'].toString().toLowerCase().contains('cancel')).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 6),
      child: Row(
        children: [
          _buildStatCard('Total', '$total', Icons.calendar_month_rounded, const Color(0xFF4F46E5), isDark),
          const SizedBox(width: 10),
          _buildStatCard('Confirmed', '$upcoming', Icons.check_circle_rounded, const Color(0xFF10B981), isDark),
          const SizedBox(width: 10),
          _buildStatCard('Completed', '$completed', Icons.medical_services_rounded, const Color(0xFF64748B), isDark),
          const SizedBox(width: 10),
          _buildStatCard('Cancelled', '$cancelled', Icons.cancel_rounded, const Color(0xFFEF4444), isDark),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: 115,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(fontFamily: appPoppinFont, fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    final currentUser = GlobalSession.instance.userNotifier.value;
    final String userId = currentUser?.data?.id ?? currentUser?.data?.navigationId ?? '1';
    final int orgId = currentUser?.data?.latestOrgId ?? 1;
    final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;

    return BlocProvider<PatientOverViewBloc>(
      create: (_) => sl<PatientOverViewBloc>()..add(LoadPatientData(userId, orgId: orgId.toString(), hospitalId: hospitalId.toString())),
      child: BlocBuilder<PatientOverViewBloc, PatientOverViewState>(
        builder: (context, overviewState) {
          PatientOverViewEntity? entity;
          if (overviewState is LoadPatientDataState) {
            entity = overviewState.patientOverViewEntity;
          }

          final fetchedList = _extractAppointmentsFromEntity(entity);
          final combinedList = [..._allAppointments, ...fetchedList];

          final hospitalNames = {'All Hospitals', ...combinedList.map((e) => e['hospitalName'].toString()).where((h) => h.isNotEmpty)};

          List<Map<String, dynamic>> filteredList = combinedList.where((app) {
            final matchesHospital = _selectedHospitalFilter == 'All Hospitals' || app['hospitalName'].toString() == _selectedHospitalFilter;
            final matchesSearch = _searchQuery.isEmpty ||
                app['doctorName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                app['specialty'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                app['hospitalName'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesHospital && matchesSearch;
          }).toList();

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              title: const Text(
                'My Appointments',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    icon: Icon(Icons.add_circle_outline_rounded, color: primaryColor, size: 26),
                    onPressed: _openBookAppointmentDialog,
                  ),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: isDark ? Colors.white60 : Colors.grey[600],
                indicatorColor: primaryColor,
                labelStyle: const TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled'),
                ],
              ),
            ),
            body: Column(
              children: [
                // Stats summary cards row (matching Web UI)
                _buildStatsHeader(combinedList, isDark),

                // Search & Hospital Filter Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(screenHorizontalSpacePadding, 4, screenHorizontalSpacePadding, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Search by doctor, hospital...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      if (hospitalNames.length > 2) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: hospitalNames.contains(_selectedHospitalFilter) ? _selectedHospitalFilter : 'All Hospitals',
                              icon: const Icon(Icons.filter_list_rounded, size: 20),
                              items: hospitalNames.map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12)))).toList(),
                              onChanged: (val) => setState(() => _selectedHospitalFilter = val ?? 'All Hospitals'),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Tab View Content (Hospital Accordion Grouped)
                Expanded(
                  child: overviewState is LoadingPatientViewDetails
                      ? _buildShimmerLoading(context, isDark)
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAppointmentListView(context, filteredList, userId, orgId, hospitalId),
                            _buildAppointmentListView(context, filteredList.where(_isUpcomingAppointment).toList(), userId, orgId, hospitalId),
                            _buildAppointmentListView(context, filteredList.where(_isCompletedAppointment).toList(), userId, orgId, hospitalId),
                            _buildAppointmentListView(context, filteredList.where((a) => a['status'].toString().toLowerCase().contains('cancel')).toList(), userId, orgId, hospitalId),
                          ],
                        ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'fab_patient_appointments',
              backgroundColor: primaryColor,
              onPressed: _openBookAppointmentDialog,
              icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
              label: const Text('Book Appointment', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading(BuildContext context, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 8),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: BaseShimmer(
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentListView(BuildContext context, List<Map<String, dynamic>> items, String userId, int orgId, int hospitalId) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          context.read<PatientOverViewBloc>().add(LoadPatientData(userId, orgId: orgId.toString(), hospitalId: hospitalId.toString()));
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text(
                    'No appointments match your filters.',
                    style: TextStyle(fontFamily: appPoppinFont, color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Group items by hospitalName (matching web UI)
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in items) {
      final hName = (item['hospitalName'] as String?)?.isNotEmpty == true ? (item['hospitalName'] as String) : 'ClinicX Health Center';
      grouped.putIfAbsent(hName, () => []).add(item);
    }

    final hospitalKeys = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PatientOverViewBloc>().add(LoadPatientData(userId, orgId: orgId.toString(), hospitalId: hospitalId.toString()));
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 8),
        itemCount: hospitalKeys.length,
        itemBuilder: (context, index) {
          final hName = hospitalKeys[index];
          final appts = grouped[hName]!;
          final isExpanded = _expandedHospitals[hName] ?? true;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hospital Accordion Header
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedHospitals[hName] = !isExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.location_on_rounded, size: 16, color: primaryColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hName.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${appts.length} ${appts.length == 1 ? 'appointment' : 'appointments'}',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: Colors.grey[500],
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded Appointments List
                if (isExpanded) ...[
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: appts.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: PatientAppointmentCard(
                            doctorName: item['doctorName'] as String,
                            specialty: item['specialty'] as String,
                            hospitalName: item['hospitalName'] as String,
                            date: item['date'] as String,
                            time: item['time'] as String,
                            status: item['status'] as String,
                            isTeleconsultation: item['isTeleconsultation'] as bool? ?? false,
                            meetingUrl: item['meetingUrl'] as String?,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
