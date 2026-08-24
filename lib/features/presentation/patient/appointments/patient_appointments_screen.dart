import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../di/dependency_injection.dart';
import '../../../domain/entities/appointments/appointment_entity.dart';
import '../../appointments/appointment_bloc/appointment_bloc.dart';
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: ['Apollo City Hospital', 'Yira Clinx Medical Center', 'Skin & Health Care Clinic']
                        .map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13))))
                        .toList(),
                    onChanged: (val) => setModalState(() => selectedHospital = val!),
                  ),
                  const SizedBox(height: 14),

                  // Doctor / Specialty
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Specialty', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedSpecialty,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              ),
                              items: ['Cardiology', 'General Practice', 'Dermatology', 'Orthopedics']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12))))
                                  .toList(),
                              onChanged: (val) => setModalState(() => selectedSpecialty = val!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Healthcare Provider', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: selectedDoctor,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              ),
                              items: ['Dr. Sarah Jenkins', 'Dr. Rajesh Nagalingam', 'Dr. Ananya Sharma']
                                  .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12))))
                                  .toList(),
                              onChanged: (val) => setModalState(() => selectedDoctor = val!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Consultation Mode
                  Text('Consultation Mode', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('In-Person Visit')),
                          selected: selectedMode == 'In-Person',
                          selectedColor: primaryColor,
                          labelStyle: TextStyle(color: selectedMode == 'In-Person' ? Colors.white : textColor, fontWeight: FontWeight.bold),
                          onSelected: (sel) => setModalState(() => selectedMode = 'In-Person'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Video Teleconsultation')),
                          selected: selectedMode == 'Video',
                          selectedColor: const Color(0xFF059669),
                          labelStyle: TextStyle(color: selectedMode == 'Video' ? Colors.white : textColor, fontWeight: FontWeight.bold),
                          onSelected: (sel) => setModalState(() => selectedMode = 'Video'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Time Slots
                  Text('Available Time Slot', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
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
                            'doctorName': selectedDoctor,
                            'specialty': selectedSpecialty,
                            'hospitalName': selectedHospital,
                            'date': '${selectedDate.day} Aug 2026',
                            'time': '$selectedSlot - ${selectedSlot.replaceAll("AM", "").replaceAll("PM", "")}30',
                            'status': 'Upcoming',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    return BlocProvider<AppointmentBloc>(
      create: (_) => sl<AppointmentBloc>()..add(LoadAppointmentsEvent()),
      child: BlocBuilder<AppointmentBloc, AppointmentState>(
        builder: (context, state) {
          List<Map<String, dynamic>> currentList = [];
          if (state is AppointmentLoaded) {
            currentList = state.appointments.map((a) => {
              'doctorName': a.patientName.isNotEmpty ? a.patientName : 'Doctor',
              'specialty': a.category.isNotEmpty ? a.category : 'General Consultation',
              'hospitalName': 'ClinicX Hospital Center',
              'date': a.time.isNotEmpty ? a.time : 'Scheduled',
              'time': a.duration.isNotEmpty ? a.duration : 'Standard Slot',
              'status': a.statusRaw.isNotEmpty ? a.statusRaw : 'Upcoming',
              'isTeleconsultation': a.type == AppointmentType.videoCall,
              'meetingUrl': a.type == AppointmentType.videoCall ? 'https://zoom.us' : null,
            }).toList();
          }

          List<Map<String, dynamic>> filteredList = currentList.where((app) {
            final matchesSearch = app['doctorName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                app['specialty'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesSearch;
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(screenHorizontalSpacePadding),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by doctor name or specialty...',
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

          // Tab View Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentListView(context, filteredList),
                _buildAppointmentListView(context, filteredList.where((a) => a['status'] == 'Upcoming').toList()),
                _buildAppointmentListView(context, filteredList.where((a) => a['status'] == 'Completed').toList()),
                _buildAppointmentListView(context, filteredList.where((a) => a['status'] == 'Cancelled').toList()),
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

  Widget _buildAppointmentListView(BuildContext context, List<Map<String, dynamic>> items) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AppointmentBloc>().add(LoadAppointmentsEvent());
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        'No appointments found.',
                        style: TextStyle(fontFamily: appPoppinFont, color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
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
              },
            ),
    );
  }
}
