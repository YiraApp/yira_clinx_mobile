part of 'navigation_drawer_bloc.dart';

@immutable
class NavigationDrawerState {
  final int selectedIndex;
  final String doctorName;
  final String doctorRole;
  final String? profileImageUrl;

  const NavigationDrawerState({
    this.selectedIndex = 0,
    this.doctorName = "Dr. Bhargava Narasimha",
    this.doctorRole = "Chief Medical Officer",
    this.profileImageUrl,
  });

  NavigationDrawerState copyWith({
    int? selectedIndex,
    String? doctorName,
    String? doctorRole,
    String? profileImageUrl,
  }) {
    return NavigationDrawerState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      doctorName: doctorName ?? this.doctorName,
      doctorRole: doctorRole ?? this.doctorRole,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}

class DashboardNavState extends NavigationDrawerState {
  const DashboardNavState() : super(selectedIndex: 0);
}

class AppointmentsNavState extends NavigationDrawerState {
  const AppointmentsNavState() : super(selectedIndex: 1);
}

class PatientsNavState extends NavigationDrawerState {
  const PatientsNavState() : super(selectedIndex: 2);
}

class DoctorSlotNavState extends NavigationDrawerState {
  const DoctorSlotNavState() : super(selectedIndex: 2);
}

class SettingsNavState extends NavigationDrawerState {
  const SettingsNavState() : super(selectedIndex: 2);
}