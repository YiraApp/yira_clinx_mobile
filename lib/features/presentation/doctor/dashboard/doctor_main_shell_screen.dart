import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/app_bottom_nav_bar/app_bottom_nav_bar.dart';
import 'package:yiraclinics/core/app_navigation_drawer/navigation_drawer-bloc/navigation_drawer_bloc.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/presentation/appointments/appointment_bloc/appointment_bloc.dart';
import 'package:yiraclinics/features/presentation/appointments/appointments_dashboard.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/doctor_dashboard_bloc/doctor_dashboard_bloc.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/doctor_dashboard_screen.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/patient_dashboard_bloc/dashboard_bloc.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/patient_management_screen.dart';
import 'package:yiraclinics/features/presentation/slot/slot_bloc/slot_bloc.dart';
import 'package:yiraclinics/features/presentation/slot/slot_dashboard_screen.dart';

class DoctorMainShellScreen extends StatefulWidget {
  final int initialIndex;

  const DoctorMainShellScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<DoctorMainShellScreen> createState() => _DoctorMainShellScreenState();
}

class _DoctorMainShellScreenState extends State<DoctorMainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NavigationDrawerBloc>.value(
          value: sl<NavigationDrawerBloc>()..add(const InitializeDrawerData()),
        ),
        BlocProvider<DoctorDashboardBloc>.value(
          value: sl<DoctorDashboardBloc>()..add(FetchDoctorDashboardData()),
        ),
        BlocProvider<AppointmentBloc>.value(
          value: sl<AppointmentBloc>()..add(LoadAppointmentsEvent()),
        ),
        BlocProvider<DashboardBloc>.value(
          value: sl<DashboardBloc>()..add(const GetDashboardData()),
        ),
        BlocProvider<SlotBloc>.value(
          value: sl<SlotBloc>()..add(InitializeSlotsEvent()),
        ),
      ],
      child: BlocListener<NavigationDrawerBloc, NavigationDrawerState>(
        listener: (context, state) {
          if (state is DashboardNavState) {
            _onTabTapped(0);
          } else if (state is AppointmentsNavState) {
            _onTabTapped(1);
          } else if (state is PatientsNavState) {
            _onTabTapped(2);
          } else if (state is DoctorSlotNavState) {
            _onTabTapped(3);
          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              DoctorDashboardScreen(isShellChild: true),
              AppointmentDashboardScreen(isShellChild: true),
              PatientManagementScreen(isShellChild: true),
              SlotDashBoardScreen(isShellChild: true),
            ],
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        ),
      ),
    );
  }
}
