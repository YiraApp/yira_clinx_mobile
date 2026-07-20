part of 'navigation_drawer_bloc.dart';

@immutable
abstract class NavigationDrawerEvent {
  const NavigationDrawerEvent();
}

class InitializeDrawerData extends NavigationDrawerEvent {
  const InitializeDrawerData();
}

class NavItemChanged extends NavigationDrawerEvent {
  final int index;
  const NavItemChanged(this.index);
}

class DashBoardNav extends NavigationDrawerEvent {
  const DashBoardNav();
}
class OrgSwitchNav extends NavigationDrawerEvent {
  const OrgSwitchNav();
}
class AppointmentsNav extends NavigationDrawerEvent {
  const AppointmentsNav();
}

class PatientsNav extends NavigationDrawerEvent {
  const PatientsNav();
}

class DoctorSlotsNav extends NavigationDrawerEvent {
  const DoctorSlotsNav();
}

class SettingsNav extends NavigationDrawerEvent {
  const SettingsNav();
}

class ContactNavEvent extends NavigationDrawerEvent {
  const ContactNavEvent();
}

class PrivacyNavEvent extends NavigationDrawerEvent {
  const PrivacyNavEvent();
}

class ReadAboutUsNavEvent extends NavigationDrawerEvent {
  const ReadAboutUsNavEvent();
}

class LogoutNavEvent extends NavigationDrawerEvent {
  const LogoutNavEvent();
}