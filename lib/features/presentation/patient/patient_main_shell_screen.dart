import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/tour/patient_tour_controller.dart';
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
    PatientTourController().refreshKeys();
    _currentIndex = widget.initialIndex;
    PatientTourController().registerTabSwitcher((index) {
      if (mounted) {
        setState(() {
          _currentIndex = index;
        });
      }
    });
  }

  @override
  void dispose() {
    PatientTourController().unregisterTabSwitcher();
    super.dispose();
  }

  void _onTabSelected(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
  }

  GlobalKey? _getTourKey(int index) {
    switch (index) {
      case 0:
        return PatientTourController().dashboardNavKey;
      case 1:
        return PatientTourController().apptsNavKey;
      case 2:
        return PatientTourController().consentsNavKey;
      case 3:
        return PatientTourController().profileNavKey;
      default:
        return null;
    }
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

    final navItems = [
      {'label': 'Dashboard', 'icon': Icons.dashboard_rounded, 'outlined': Icons.dashboard_outlined},
      {'label': 'Appointments', 'icon': Icons.calendar_month_rounded, 'outlined': Icons.calendar_month_outlined},
      {'label': 'Consents', 'icon': Icons.verified_user_rounded, 'outlined': Icons.verified_user_outlined},
      {'label': 'Profile', 'icon': Icons.person_rounded, 'outlined': Icons.person_outline_rounded},
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
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  final isSelected = index == _currentIndex;
                  final key = _getTourKey(index);

                  return Expanded(
                    child: InkWell(
                      key: key,
                      onTap: () => _onTabSelected(index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            (isSelected ? item['icon'] : item['outlined']) as IconData,
                            size: 22,
                            color: isSelected
                                ? primaryColor
                                : (isDark ? Colors.white54 : Colors.grey[500]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['label'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 10.5,
                              color: isSelected
                                  ? primaryColor
                                  : (isDark ? Colors.white54 : Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
