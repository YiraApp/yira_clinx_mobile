import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/app_navigation_drawer/app_navigation_drawer.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../di/dependency_injection.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../patient_profile/patient_over_view_bloc/patient_over_view_bloc.dart';
import '../widgets/health_passport_card.dart';
import '../widgets/patient_appointment_card.dart';
import '../widgets/patient_vitals_grid.dart';
import '../widgets/update_vitals_sheet.dart';
import '../../upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import '../../../../core/shimmer_widgets/over_view_shimmer_card.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';

class PatientDashboardScreen extends StatefulWidget {
  final Function(int index)? onNavigateTab;

  const PatientDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  Map<String, String> _vitalsData = {
    'bp': '120/80',
    'bpSystolic': '120',
    'bpDiastolic': '80',
    'pulse': '72',
    'temp': '98.6',
    'spO2': '98',
    'weight': '68',
    'height': '172',
    'lastUpdated': 'Today',
  };

  void _openUpdateVitalsSheet() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UpdateVitalsSheet(
        currentVitals: _vitalsData,
        onSave: (updated) {
          setState(() {
            _vitalsData = updated;
          });
        },
      ),
    );
    if (result != null) {
      setState(() {
        _vitalsData = result;
      });
    }
  }

  void _showQrDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Digital Health Passport QR', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 150, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 16),
            const Text('Scan at Clinic Desk for Immediate Check-in', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold)),
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
    final isTab = isTablet(context);
    final adaptiveTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final orgId = currentUser?.data?.latestOrgId?.toString() ?? '1';
    final hospitalId = currentUser?.data?.latestHospitalId?.toString() ?? '1';
    final firstName = currentUser?.data?.firstName ?? '';
    final lastName = currentUser?.data?.lastName ?? '';
    final patientName = '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : 'Ch. Raja Vardan';

    return MultiBlocProvider(
      providers: [
        BlocProvider<PatientOverViewBloc>(
          create: (_) => sl<PatientOverViewBloc>()..add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId)),
        ),
        BlocProvider<UploadedBloc>(
          create: (_) => sl<UploadedBloc>()..add(FetchUploadedRecords(patientId: userId, limit: 2)),
        ),
      ],
      child: BlocBuilder<PatientOverViewBloc, PatientOverViewState>(
        builder: (context, state) {
          PatientOverViewEntity? overViewEntity;
          if (state is LoadPatientDataState) {
            overViewEntity = state.patientOverViewEntity;
          }

          final isLoading = state is LoadingPatientViewDetails || state is PatientOverViewInitial || overViewEntity == null;

          final data = overViewEntity?.data;
          final bloodGroup = data?.medicalInformation?.bloodGroup ?? '';
          final emergencyPhone = data?.contactInformation?.emergencyContact?.phone ?? '';
          final policyName = data?.insurance?.policyName ?? '';
          final policyNumber = data?.insurance?.policyNumber ?? '';
          final nextAppointment = data?.nextAppointment;
          final nextAppointmentDate = nextAppointment?.formattedDate ?? nextAppointment?.appointmentDate ?? data?.visitHistory?.nextScheduledAppointment;
          final hasNextAppointment = nextAppointment != null || (nextAppointmentDate != null &&
              nextAppointmentDate.trim().isNotEmpty &&
              nextAppointmentDate.trim().toLowerCase() != 'null' &&
              nextAppointmentDate.trim().toLowerCase() != 'none');

          final latestVitals = data?.latestVitals;
          if (latestVitals != null) {
            final bpVal = latestVitals.bloodPressure?.value;
            final pulseVal = latestVitals.pulse?.value;
            final tempVal = latestVitals.temperature?.value;
            final spo2Val = latestVitals.spo2?.value;
            final weightVal = latestVitals.weight?.value;
            final heightVal = latestVitals.height?.value;

            bool isValidVital(String? val) => val != null && val.trim().isNotEmpty && val.trim().toLowerCase() != 'none' && val.trim().toLowerCase() != 'null' && val.trim().toLowerCase() != 'n/a';

            if (isValidVital(bpVal)) _vitalsData['bp'] = bpVal!;
            if (isValidVital(pulseVal)) _vitalsData['pulse'] = pulseVal!;
            if (isValidVital(tempVal)) _vitalsData['temp'] = tempVal!;
            if (isValidVital(spo2Val)) _vitalsData['spO2'] = spo2Val!;
            if (isValidVital(weightVal)) _vitalsData['weight'] = weightVal!;
            if (isValidVital(heightVal)) _vitalsData['height'] = heightVal!;
          }

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            drawer: const AppNavigationDrawer(),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                  Text(
                    patientName,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 20 : 17,
                      fontWeight: FontWeight.bold,
                      color: adaptiveTextColor,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.notifications_none_outlined, color: adaptiveTextColor),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new notifications.')),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: screenHorizontalSpacePadding),
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onNavigateTab != null) {
                        widget.onNavigateTab!(3);
                      }
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: primaryColor.withOpacity(0.15),
                      child: Icon(Icons.person, color: primaryColor, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                context.read<PatientOverViewBloc>().add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId));
                context.read<UploadedBloc>().add(FetchUploadedRecords(patientId: userId, limit: 2));
                await Future.delayed(const Duration(milliseconds: 600));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // 1. Digital Health Passport Card
                    isLoading
                        ? _buildHealthPassportShimmer(context, isDark, primaryColor)
                        : HealthPassportCard(
                            patientName: patientName,
                            mrnNumber: 'MRN-${userId.length > 6 ? userId.substring(0, 6).toUpperCase() : '998241'}',
                            bloodGroup: bloodGroup,
                            emergencyContact: emergencyPhone,
                            insurancePolicy: '$policyName #$policyNumber',
                            onShowQrCode: _showQrDialog,
                          ),
                    const SizedBox(height: 20),

              // 2. Upcoming Appointment Header & Card (Smooth transition when loaded)
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                child: isLoading
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNextAppointmentShimmer(context, isDark),
                          const SizedBox(height: 20),
                        ],
                      )
                    : hasNextAppointment
                        ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Next Appointment',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: adaptiveTextColor,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  if (widget.onNavigateTab != null) {
                                    widget.onNavigateTab!(1);
                                  }
                                },
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                child: Text(
                                  'View All',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          PatientAppointmentCard(
                            doctorName: nextAppointment?.doctorName ?? 'Attending Physician',
                            specialty: nextAppointment?.doctorSpecialty ?? nextAppointment?.reason ?? nextAppointment?.consultationType ?? data?.summary ?? 'General Practitioner',
                            hospitalName: nextAppointment?.hospitalName ?? 'ClinicX Health Center',
                            date: nextAppointment?.formattedDate ?? nextAppointmentDate ?? 'Scheduled Visit',
                            time: nextAppointment?.formattedTime ?? nextAppointment?.startTime ?? 'Scheduled Slot',
                            status: nextAppointment?.status ?? 'Scheduled',
                            isTeleconsultation: nextAppointment?.isTeleconsultation ?? false,
                            meetingUrl: nextAppointment?.meetingUrl,
                            onTap: () {
                              if (widget.onNavigateTab != null) {
                                widget.onNavigateTab!(1);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),

              // 3. Quick Action Shortcuts Grid
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: adaptiveTextColor,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildActionShortcut(
                      context: context,
                      title: 'Book Visit',
                      icon: Icons.calendar_month_rounded,
                      color: Colors.blue,
                      onTap: () {
                        if (widget.onNavigateTab != null) {
                          widget.onNavigateTab!(1);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionShortcut(
                      context: context,
                      title: 'My Records',
                      icon: Icons.folder_shared_rounded,
                      color: Colors.teal,
                      onTap: () {
                        if (widget.onNavigateTab != null) {
                          widget.onNavigateTab!(2);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionShortcut(
                      context: context,
                      title: 'Log Vitals',
                      icon: Icons.edit_note_rounded,
                      color: const Color(0xFFE11D48),
                      onTap: _openUpdateVitalsSheet,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionShortcut(
                      context: context,
                      title: 'My Profile',
                      icon: Icons.person_pin_rounded,
                      color: Colors.indigo,
                      onTap: () {
                        if (widget.onNavigateTab != null) {
                          widget.onNavigateTab!(3);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Health Vitals Overview Grid
              isLoading
                  ? _buildVitalsGridShimmer(context, isDark)
                  : PatientVitalsGrid(
                      vitals: _vitalsData,
                      onUpdateVitals: _openUpdateVitalsSheet,
                    ),
              const SizedBox(height: 24),

              // 5. Recent Clinical Records Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Clinical Records',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: adaptiveTextColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (widget.onNavigateTab != null) {
                        widget.onNavigateTab!(2);
                      }
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text(
                      'View Vault',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              BlocBuilder<UploadedBloc, UploadedBlocState>(
                builder: (context, state) {
                  if (state.status == UploadedStatus.initial || state.status == UploadedStatus.loading) {
                    return _buildRecentRecordsShimmer(context, isDark);
                  }
                  final docs = state.allRecords.take(2).toList();
                  if (docs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'No recent clinical documents available',
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: Colors.grey[500]),
                      ),
                    );
                  }

                  return Column(
                    children: docs.map((doc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildClinicalRecordItem(
                          context: context,
                          title: doc.fileName,
                          date: '${doc.uploadDate.day}/${doc.uploadDate.month}/${doc.uploadDate.year}',
                          hospital: '🏥 Yira Health Network',
                          type: doc.category.isNotEmpty ? doc.category : 'Medical Report',
                          typeColor: doc.category.toLowerCase().contains('lab') ? Colors.purple : Colors.blue,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  },
),
);
  }

  Widget _buildActionShortcut({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicalRecordItem({
    required BuildContext context,
    required String title,
    required String date,
    required String hospital,
    required String type,
    required Color typeColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.description_rounded, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$hospital • $date',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: typeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthPassportShimmer(BuildContext context, bool isDark, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
      ),
      child: BaseShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 80, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                Container(width: 50, height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
              ],
            ),
            const SizedBox(height: 10),
            Container(width: 180, height: 22, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 6),
            Container(width: 110, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Container(height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextAppointmentShimmer(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
      ),
      child: BaseShimmer(
        child: Row(
          children: [
            Container(width: 48, height: 48, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 140, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(width: 100, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(width: 160, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsShimmer(BuildContext context, bool isDark) {
    return Row(
      children: List.generate(4, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 3 ? 0 : 10),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
            ),
            child: BaseShimmer(
              child: Column(
                children: [
                  Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(height: 8),
                  Container(width: 45, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVitalsGridShimmer(BuildContext context, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
          ),
          child: BaseShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    Container(width: 40, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
                Container(width: 70, height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                Container(width: 90, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentRecordsShimmer(BuildContext context, bool isDark) {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200),
          ),
          child: BaseShimmer(
            child: Row(
              children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 160, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(width: 100, height: 11, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
