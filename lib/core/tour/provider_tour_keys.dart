import 'package:flutter/material.dart';

/// Global Keys registry used by the Interactive Spotlight Onboarding & Product Tour
/// to locate and highlight UI elements across provider screens.
class ProviderTourKeys {
  ProviderTourKeys._();

  // 1. Doctor Dashboard
  static GlobalKey dashboardHeaderKey = GlobalKey(debugLabel: 'tour_dash_header');
  static GlobalKey dashboardMetricsKey = GlobalKey(debugLabel: 'tour_dash_metrics');
  static GlobalKey dashboardScheduleKey = GlobalKey(debugLabel: 'tour_dash_schedule');
  static GlobalKey dashboardChartsKey = GlobalKey(debugLabel: 'tour_dash_charts');
  static GlobalKey navHomeKey = GlobalKey(debugLabel: 'tour_nav_home');
  static GlobalKey drawerMenuKey = GlobalKey(debugLabel: 'tour_drawer_menu');

  // 2. Patient Management
  static GlobalKey patientSearchKey = GlobalKey(debugLabel: 'tour_pat_search');
  static GlobalKey patientFilterPillsKey = GlobalKey(debugLabel: 'tour_pat_filters');
  static GlobalKey patientFavStarKey = GlobalKey(debugLabel: 'tour_pat_fav_star');

  // 3. Slots & Smart Scheduler
  static GlobalKey slotCalendarKey = GlobalKey(debugLabel: 'tour_slot_calendar');
  static GlobalKey slotTabsKey = GlobalKey(debugLabel: 'tour_slot_tabs');
  static GlobalKey slotFirstBookKey = GlobalKey(debugLabel: 'tour_slot_first_book');
  static GlobalKey slotFabKey = GlobalKey(debugLabel: 'tour_slot_fab');
  static GlobalKey schedulerBreaksKey = GlobalKey(debugLabel: 'tour_sched_breaks');

  /// Reset all keys with fresh GlobalKey instances to prevent duplicate key collisions during route transitions
  static void reset() {
    dashboardHeaderKey = GlobalKey(debugLabel: 'tour_dash_header');
    dashboardMetricsKey = GlobalKey(debugLabel: 'tour_dash_metrics');
    dashboardScheduleKey = GlobalKey(debugLabel: 'tour_dash_schedule');
    dashboardChartsKey = GlobalKey(debugLabel: 'tour_dash_charts');
    navHomeKey = GlobalKey(debugLabel: 'tour_nav_home');
    drawerMenuKey = GlobalKey(debugLabel: 'tour_drawer_menu');

    patientSearchKey = GlobalKey(debugLabel: 'tour_pat_search');
    patientFilterPillsKey = GlobalKey(debugLabel: 'tour_pat_filters');
    patientFavStarKey = GlobalKey(debugLabel: 'tour_pat_fav_star');

    slotCalendarKey = GlobalKey(debugLabel: 'tour_slot_calendar');
    slotTabsKey = GlobalKey(debugLabel: 'tour_slot_tabs');
    slotFirstBookKey = GlobalKey(debugLabel: 'tour_slot_first_book');
    slotFabKey = GlobalKey(debugLabel: 'tour_slot_fab');
    schedulerBreaksKey = GlobalKey(debugLabel: 'tour_sched_breaks');
  }
}
