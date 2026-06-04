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

// Subclasses that require the index to be parsed into the constructor
class DashboardNavState extends NavigationDrawerState {
  const DashboardNavState({required int index}) : super(selectedIndex: index);
}

class AppointmentsNavState extends NavigationDrawerState {
  const AppointmentsNavState({required int index}) : super(selectedIndex: index);
}

class PatientsNavState extends NavigationDrawerState {
  const PatientsNavState({required int index}) : super(selectedIndex: index);
}

class DoctorSlotNavState extends NavigationDrawerState {
  const DoctorSlotNavState({required int index}) : super(selectedIndex: index);
}

class SettingsNavState extends NavigationDrawerState {
  const SettingsNavState({required int index}) : super(selectedIndex: index);
}