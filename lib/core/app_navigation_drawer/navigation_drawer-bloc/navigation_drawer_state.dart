part of 'navigation_drawer_bloc.dart';

@immutable
class NavigationDrawerState  {
  final int selectedIndex;
  final String doctorName;
  final String doctorRole;
  final String? profileImageUrl;
  final String appVersion;

  const NavigationDrawerState({
    this.selectedIndex = 0,
    this.doctorName = '',
    this.doctorRole = '',
    this.profileImageUrl,
    this.appVersion = 'V1.0.0',
  });

  const NavigationDrawerState._withVersion({
    required this.selectedIndex,
    required this.appVersion,
    this.doctorName = '',
    this.doctorRole = '',
    this.profileImageUrl,
  });

  NavigationDrawerState copyWith({
    int? selectedIndex,
    String? doctorName,
    String? doctorRole,
    String? profileImageUrl,
    String? appVersion,
  }) {
    return NavigationDrawerState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      doctorName: doctorName ?? this.doctorName,
      doctorRole: doctorRole ?? this.doctorRole,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}

class DashboardNavState extends NavigationDrawerState {
  const DashboardNavState({required int index, String version = 'V1.0.0'})
      : super._withVersion(selectedIndex: index, appVersion: version);
}
class OrgSwitchNavState extends NavigationDrawerState {
  const OrgSwitchNavState({required int index, String version = 'V1.0.0'})
      : super._withVersion(selectedIndex: index, appVersion: version);
}
class AppointmentsNavState extends NavigationDrawerState {
  const AppointmentsNavState({required int index, String version = 'V1.0.0'})
      : super._withVersion(selectedIndex: index, appVersion: version);
}

class PatientsNavState extends NavigationDrawerState {
  const PatientsNavState({required int index, String version = 'V1.0.0'})
      : super._withVersion(selectedIndex: index, appVersion: version);
}

class DoctorSlotNavState extends NavigationDrawerState {
  const DoctorSlotNavState({required int index, String version = 'V1.0.0'})
      : super._withVersion(selectedIndex: index, appVersion: version);
}

class SettingsNavState extends NavigationDrawerState {
  const SettingsNavState({required int index, String version = 'V1.0.0'})
      : super._withVersion(selectedIndex: index, appVersion: version);
}

class ContactNavState extends NavigationDrawerState {
  const ContactNavState({String version = 'V1.0.0'})
      : super._withVersion(selectedIndex: 5, appVersion: version);
}

class PrivacyNavState extends NavigationDrawerState {
  const PrivacyNavState({String version = 'V1.0.0'})
      : super._withVersion(selectedIndex: 6, appVersion: version);
}

class ReadAboutUsNavState extends NavigationDrawerState {
  const ReadAboutUsNavState({String version = 'V1.0.0'})
      : super._withVersion(selectedIndex: 4, appVersion: version);
}

class LogoutNavState extends NavigationDrawerState {
  const LogoutNavState({String version = 'V1.0.0'})
      : super._withVersion(selectedIndex: 0, appVersion: version);
}