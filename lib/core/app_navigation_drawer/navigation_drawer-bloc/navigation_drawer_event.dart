part of 'navigation_drawer_bloc.dart';

@immutable
abstract class NavigationDrawerEvent {}

class NavItemChanged extends NavigationDrawerEvent {
  final int index;
  NavItemChanged(this.index);
}

class LogoutRequested extends NavigationDrawerEvent {}
class DashBoardNav extends NavigationDrawerEvent {}
class AppointmentsNav extends NavigationDrawerEvent {}
class PatientsNav extends NavigationDrawerEvent {}
class DoctorSlotsNav extends NavigationDrawerEvent {}
class SettingsNav extends NavigationDrawerEvent {}
