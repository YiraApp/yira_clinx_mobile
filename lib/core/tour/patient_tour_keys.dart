import 'package:flutter/material.dart';

/// GlobalKeys used by the Patient Spotlight Tour to locate and highlight UI elements across tabs.
class PatientTourKeys {
  // Tab 0: Dashboard
  static GlobalKey headerProfileKey = GlobalKey(debugLabel: 'patient_tour_header_profile');
  static GlobalKey vitalsCardKey = GlobalKey(debugLabel: 'patient_tour_vitals_card');
  static GlobalKey upcomingAppointmentsKey = GlobalKey(debugLabel: 'patient_tour_upcoming_appts');
  static GlobalKey quickServicesKey = GlobalKey(debugLabel: 'patient_tour_quick_services');

  // Bottom Navigation Bar Tabs
  static GlobalKey dashboardNavKey = GlobalKey(debugLabel: 'patient_tour_nav_dashboard');
  static GlobalKey apptsNavKey = GlobalKey(debugLabel: 'patient_tour_nav_appts');
  static GlobalKey consentsNavKey = GlobalKey(debugLabel: 'patient_tour_nav_consents');
  static GlobalKey profileNavKey = GlobalKey(debugLabel: 'patient_tour_nav_profile');

  // Tab 1: Appointments Screen
  static GlobalKey apptsFilterKey = GlobalKey(debugLabel: 'patient_tour_appts_filter');
  static GlobalKey apptsListKey = GlobalKey(debugLabel: 'patient_tour_appts_list');

  // Tab 2: Consents Screen
  static GlobalKey consentsListKey = GlobalKey(debugLabel: 'patient_tour_consents_list');

  // Tab 3: Profile Screen
  static GlobalKey passportProfileCardKey = GlobalKey(debugLabel: 'patient_tour_passport_card');

  static void refreshKeys() {
    headerProfileKey = GlobalKey(debugLabel: 'patient_tour_header_profile');
    vitalsCardKey = GlobalKey(debugLabel: 'patient_tour_vitals_card');
    upcomingAppointmentsKey = GlobalKey(debugLabel: 'patient_tour_upcoming_appts');
    quickServicesKey = GlobalKey(debugLabel: 'patient_tour_quick_services');

    dashboardNavKey = GlobalKey(debugLabel: 'patient_tour_nav_dashboard');
    apptsNavKey = GlobalKey(debugLabel: 'patient_tour_nav_appts');
    consentsNavKey = GlobalKey(debugLabel: 'patient_tour_nav_consents');
    profileNavKey = GlobalKey(debugLabel: 'patient_tour_nav_profile');

    apptsFilterKey = GlobalKey(debugLabel: 'patient_tour_appts_filter');
    apptsListKey = GlobalKey(debugLabel: 'patient_tour_appts_list');

    consentsListKey = GlobalKey(debugLabel: 'patient_tour_consents_list');

    passportProfileCardKey = GlobalKey(debugLabel: 'patient_tour_passport_card');
  }
}
