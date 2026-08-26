import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../di/dependency_injection.dart';
import '../appointments/appointment_bloc/appointment_bloc.dart';
import '../consent/patient_consent_approval_screen.dart';
import 'appointments/patient_appointments_screen.dart';
import 'dashboard/patient_dashboard_screen.dart';
import 'profile/patient_profile_passport_screen.dart';

class PatientMainShellScreen extends StatefulWidget {
  final int initialIndex;

  const PatientMainShellScreen({super.key, this.initialIndex = 0});

  @override
  State<PatientMainShellScreen> createState() => _PatientMainShellScreenState();
}

class _PatientMainShellScreenState extends State<PatientMainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final List<Widget> pages = [
      PatientDashboardScreen(onNavigateTab: _onTabSelected),
      PatientAppointmentsScreen(onNavigateTab: _onTabSelected),
      const PatientConsentApprovalScreen(showBackButton: false),
      const PatientProfilePassportScreen(),
    ];

    return MultiBlocProvider(
      providers: [
        BlocProvider<AppointmentBloc>(
          create: (_) => sl<AppointmentBloc>()..add(LoadAppointmentsEvent()),
        ),
      ],
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabSelected,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: primaryColor,
            unselectedItemColor: isDark ? Colors.white54 : Colors.grey[500],
            selectedLabelStyle: const TextStyle(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_rounded),
                activeIcon: Icon(Icons.calendar_month_rounded),
                label: 'Appointments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.verified_user_rounded),
                activeIcon: Icon(Icons.verified_user_rounded),
                label: 'Consents',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
