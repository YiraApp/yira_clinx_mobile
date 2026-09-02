import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/constants/clinx_storage_keys.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/local/shared_preferences.dart';
import 'package:yiraclinics/core/navigation_services/navigation_services.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'provider_tour_model.dart';
import 'provider_tour_overlay.dart';

class ProviderTourController {
  static final ProviderTourController _instance = ProviderTourController._internal();
  factory ProviderTourController() => _instance;
  ProviderTourController._internal();

  static const String _kTourCompletedKey = 'doctor_tour_completed_v1';
  static const String _kTourDontShowAgainKey = 'doctor_tour_dont_show_again';

  final ValueNotifier<bool> isTourActiveNotifier = ValueNotifier<bool>(false);
  bool get isTourActive => isTourActiveNotifier.value;

  // GlobalKeys for all tour targets across the Doctor Shell
  GlobalKey headerKey = GlobalKey(debugLabel: 'tour_header');
  GlobalKey metricsKey = GlobalKey(debugLabel: 'tour_metrics');
  GlobalKey scheduleKey = GlobalKey(debugLabel: 'tour_schedule');
  GlobalKey chartsKey = GlobalKey(debugLabel: 'tour_charts');
  GlobalKey profileKey = GlobalKey(debugLabel: 'tour_profile');

  GlobalKey homeNavKey = GlobalKey(debugLabel: 'tour_nav_home');
  GlobalKey apptsNavKey = GlobalKey(debugLabel: 'tour_nav_appts');
  GlobalKey patientsNavKey = GlobalKey(debugLabel: 'tour_nav_patients');
  GlobalKey slotsNavKey = GlobalKey(debugLabel: 'tour_nav_slots');

  GlobalKey apptsFilterKey = GlobalKey(debugLabel: 'tour_appts_filter');
  GlobalKey apptsListKey = GlobalKey(debugLabel: 'tour_appts_list');

  GlobalKey patientsSearchKey = GlobalKey(debugLabel: 'tour_patients_search');
  GlobalKey patientsListKey = GlobalKey(debugLabel: 'tour_patients_list');

  GlobalKey slotsCalendarKey = GlobalKey(debugLabel: 'tour_slots_calendar');
  GlobalKey slotsListKey = GlobalKey(debugLabel: 'tour_slots_list');
  GlobalKey slotsFabKey = GlobalKey(debugLabel: 'tour_slots_fab');

  void refreshKeys() {
    headerKey = GlobalKey(debugLabel: 'tour_header');
    metricsKey = GlobalKey(debugLabel: 'tour_metrics');
    scheduleKey = GlobalKey(debugLabel: 'tour_schedule');
    chartsKey = GlobalKey(debugLabel: 'tour_charts');
    profileKey = GlobalKey(debugLabel: 'tour_profile');

    homeNavKey = GlobalKey(debugLabel: 'tour_nav_home');
    apptsNavKey = GlobalKey(debugLabel: 'tour_nav_appts');
    patientsNavKey = GlobalKey(debugLabel: 'tour_nav_patients');
    slotsNavKey = GlobalKey(debugLabel: 'tour_nav_slots');

    apptsFilterKey = GlobalKey(debugLabel: 'tour_appts_filter');
    apptsListKey = GlobalKey(debugLabel: 'tour_appts_list');

    patientsSearchKey = GlobalKey(debugLabel: 'tour_patients_search');
    patientsListKey = GlobalKey(debugLabel: 'tour_patients_list');

    slotsCalendarKey = GlobalKey(debugLabel: 'tour_slots_calendar');
    slotsListKey = GlobalKey(debugLabel: 'tour_slots_list');
    slotsFabKey = GlobalKey(debugLabel: 'tour_slots_fab');
  }

  OverlayEntry? _overlayEntry;
  int _currentStepIndex = 0;
  bool _dontShowAgain = false;
  List<ProviderTourStep> _steps = [];

  // Shell integration for tab switching
  void Function(int index)? _tabSwitchCallback;

  void registerTabSwitcher(void Function(int index) switchTab) {
    _tabSwitchCallback = switchTab;
  }

  int get currentStepIndex => _currentStepIndex;

  String _getUserKey(String baseKey) {
    final phone = GlobalSession.instance.userNotifier.value?.data?.phoneNumber
        ?.replaceAll(RegExp(r'[^0-9]'), '');
    final userId = GlobalSession.instance.userNotifier.value?.data?.id;
    if (phone != null && phone.isNotEmpty) {
      return '${baseKey}_phone_$phone';
    } else if (userId != null && userId.isNotEmpty) {
      return '${baseKey}_user_$userId';
    }
    return baseKey;
  }

  bool shouldAutoStart() {
    final prefs = sl<SharedPrefsService>();
    final isNewlyRegistered =
        prefs.getValue<bool>(ClinxStorageKeys.isNewlyRegisteredUser) ?? false;
    if (!isNewlyRegistered) {
      return false; // Tour only automatically starts for newly registered users
    }

    final userCompletedKey = _getUserKey(_kTourCompletedKey);
    final userDontShowKey = _getUserKey(_kTourDontShowAgainKey);

    final isCompleted = (prefs.getValue<bool>(userCompletedKey) ?? false) ||
        (prefs.getValue<bool>(_kTourCompletedKey) ?? false);
    final dontShowAgain = (prefs.getValue<bool>(userDontShowKey) ?? false) ||
        (prefs.getValue<bool>(_kTourDontShowAgainKey) ?? false);

    return !isCompleted && !dontShowAgain;
  }

  /// Start the complete guided tour across Dashboard, Appointments, Patients, and Slots
  void startDashboardTour({
    required BuildContext context,
    bool force = false,
  }) {
    if (!force && !shouldAutoStart()) return;

    // Immediately mark as seen so role switches and tab switches never re-trigger the tour
    _saveTourCompletion();

    _steps = [
      // ─── 1. HOME DASHBOARD ───────────────────────────────────────────
      // Step 1: Clinic & Hospital Switcher
      ProviderTourStep(
        id: 'step_header',
        title: 'Clinic & Hospital Switcher',
        description: 'See your active clinic and specialty here. Tap the clinic name anytime to switch between different hospitals where you practice.',
        targetKey: headerKey,
        icon: Icons.local_hospital_rounded,
        position: TourCardPosition.bottom,
        tabIndex: 0,
      ),

      // Step 2: Today's Summary Numbers (KPIs)
      ProviderTourStep(
        id: 'step_metrics',
        title: "Today's Summary at a Glance",
        description: 'A quick overview of your day: booked patients, completed consultations, live video visits, and pending queue.',
        targetKey: metricsKey,
        icon: Icons.analytics_rounded,
        position: TourCardPosition.bottom,
        tabIndex: 0,
      ),

      // Step 3: Today's Patient Queue & Video Calls
      ProviderTourStep(
        id: 'step_schedule',
        title: "Today's Schedule & Video Calls",
        description: "Your live patient queue for today. For online visits, tap the blue 'Video Call' button to connect directly on HD video.",
        targetKey: scheduleKey,
        icon: Icons.video_camera_front_rounded,
        position: TourCardPosition.auto,
        tabIndex: 0,
      ),

      // Step 4: Practice Activity Chart
      ProviderTourStep(
        id: 'step_charts',
        title: 'Weekly Appointments Chart',
        description: 'A visual chart showing your patient visits across the week. See your busiest days and plan your practice hours easily.',
        targetKey: chartsKey,
        icon: Icons.show_chart_rounded,
        position: TourCardPosition.top,
        tabIndex: 0,
      ),

      // Step 5: Bottom Tab 1 - Home Tab
      ProviderTourStep(
        id: 'step_nav_home',
        title: '1. Home Tab',
        description: 'Tap here anytime to return to this main dashboard overview, daily summary, and live patient queue.',
        targetKey: homeNavKey,
        icon: Icons.dashboard_rounded,
        position: TourCardPosition.top,
        targetPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        borderRadius: 14,
        tabIndex: 0,
      ),

      // ─── 2. APPOINTMENTS TAB ─────────────────────────────────────────
      // Step 6: Appointments Tab Navigation
      ProviderTourStep(
        id: 'step_nav_appts',
        title: '2. Appointments Tab',
        description: 'Switches to your full appointment management center to view and organize all patient visits.',
        targetKey: apptsNavKey,
        icon: Icons.calendar_month_rounded,
        position: TourCardPosition.top,
        targetPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        borderRadius: 14,
        tabIndex: 1,
      ),

      // Step 7: Date & Status Filters
      ProviderTourStep(
        id: 'step_appts_filter',
        title: 'Date & Status Filters',
        description: 'Quickly filter appointments by Today, Tomorrow, Date Range, or Status like Confirmed, In Progress, and Completed.',
        targetKey: apptsFilterKey,
        icon: Icons.filter_alt_rounded,
        position: TourCardPosition.bottom,
        tabIndex: 1,
      ),

      // Step 8: Appointments List & New Booking
      ProviderTourStep(
        id: 'step_appts_list',
        title: 'Appointments List & Quick Actions',
        description: "View patient tokens, consultation types, and contact info. Tap the '+ New' button at the top right to book a new appointment on the spot.",
        targetKey: apptsListKey,
        icon: Icons.event_available_rounded,
        position: TourCardPosition.top,
        tabIndex: 1,
      ),

      // ─── 3. PATIENTS DIRECTORY TAB ───────────────────────────────────
      // Step 9: Patients Tab Navigation
      ProviderTourStep(
        id: 'step_nav_patients',
        title: '3. Patients Directory Tab',
        description: 'Switches to your complete patient directory, medical records, and quick search.',
        targetKey: patientsNavKey,
        icon: Icons.people_alt_rounded,
        position: TourCardPosition.top,
        targetPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        borderRadius: 14,
        tabIndex: 2,
      ),

      // Step 10: Patient Search & Filter Chips
      ProviderTourStep(
        id: 'step_patients_search',
        title: 'Search & Quick Filters',
        description: 'Search any registered patient instantly by name or phone number, and filter by your Starred Favorites or Gender.',
        targetKey: patientsSearchKey,
        icon: Icons.search_rounded,
        position: TourCardPosition.bottom,
        tabIndex: 2,
      ),

      // Step 11: Patient Directory Cards & Star Favorites
      ProviderTourStep(
        id: 'step_patients_list',
        title: 'Patient Records & Star Favorites (★)',
        description: 'Tap any patient to view their clinical history and prescriptions. Tap the star (★) to bookmark frequent patients for fast access.',
        targetKey: patientsListKey,
        icon: Icons.star_rounded,
        position: TourCardPosition.top,
        tabIndex: 2,
      ),

      // ─── 4. SLOTS & SCHEDULE TAB ─────────────────────────────────────
      // Step 12: Slots Tab Navigation
      ProviderTourStep(
        id: 'step_nav_slots',
        title: '4. Slots & Schedule Tab',
        description: 'Switches to your live slot booking and daily consultation calendar.',
        targetKey: slotsNavKey,
        icon: Icons.schedule_rounded,
        position: TourCardPosition.top,
        targetPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        borderRadius: 14,
        tabIndex: 3,
      ),

      // Step 13: Calendar Week Bar
      ProviderTourStep(
        id: 'step_slots_calendar',
        title: 'Interactive Calendar Bar',
        description: 'Select any day of the week to inspect your morning, afternoon, and evening consultation timings.',
        targetKey: slotsCalendarKey,
        icon: Icons.calendar_today_rounded,
        position: TourCardPosition.bottom,
        tabIndex: 3,
      ),

      // Step 14: Available & Booked Slot Cards
      ProviderTourStep(
        id: 'step_slots_list',
        title: 'Available & Booked Slots',
        description: 'Green slots are open for walk-in bookings. Blue slots show booked patients—tap any slot for full booking details.',
        targetKey: slotsListKey,
        icon: Icons.grid_view_rounded,
        position: TourCardPosition.top,
        tabIndex: 3,
      ),

      // Step 15: Smart Slot Scheduler FAB (+)
      ProviderTourStep(
        id: 'step_slots_fab',
        title: 'Smart Slot Scheduler (+)',
        description: 'Tap this floating button to auto-generate weekly shifts, set custom slot intervals, and configure lunch breaks in seconds!',
        targetKey: slotsFabKey,
        icon: Icons.add_circle_outline_rounded,
        position: TourCardPosition.top,
        tabIndex: 3,
      ),

      // ─── 5. PROFILE & SETTINGS ───────────────────────────────────────
      // Step 16: Profile, Settings & Tour Restart
      ProviderTourStep(
        id: 'step_profile',
        title: 'Profile, Settings & Tour Restart',
        description: 'Tap your profile photo to update account details, switch clinics, change theme/language, or restart this tour anytime from Settings!',
        targetKey: profileKey,
        icon: Icons.account_circle_rounded,
        position: TourCardPosition.bottom,
        tabIndex: 0,
      ),
    ];

    _removeOverlay();
    _currentStepIndex = 0;
    _dontShowAgain = false;

    // Enable demo test data across all screens
    isTourActiveNotifier.value = true;

    _showCurrentStep(context);
  }

  void _showCurrentStep(BuildContext context) async {
    if (!context.mounted || _currentStepIndex >= _steps.length) {
      _completeTour();
      return;
    }

    final step = _steps[_currentStepIndex];

    // Automatically open that tab!
    if (step.tabIndex != null && _tabSwitchCallback != null) {
      _tabSwitchCallback!(step.tabIndex!);
      await Future.delayed(const Duration(milliseconds: 180));
    }

    // Scroll into view if widget is mounted in a scrollable (e.g. Step 4 Charts or Schedule)
    if (step.targetKey?.currentContext != null) {
      try {
        await Scrollable.ensureVisible(
          step.targetKey!.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: 0.5,
        );
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!context.mounted) return;

    _removeOverlay();

    final overlay = Overlay.of(context, rootOverlay: true);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => ProviderTourOverlay(
        steps: _steps,
        currentStepIndex: _currentStepIndex,
        dontShowAgain: _dontShowAgain,
        onNext: () => nextStep(context),
        onBack: () => previousStep(context),
        onSkip: () => skipTour(),
        onDontShowAgainChanged: (val) {
          _dontShowAgain = val;
          _overlayEntry?.markNeedsBuild();
        },
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void nextStep(BuildContext context) {
    if (_currentStepIndex < _steps.length - 1) {
      _currentStepIndex++;
      _showCurrentStep(context);
    } else {
      _completeTour();
    }
  }

  void previousStep(BuildContext context) {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      _showCurrentStep(context);
    }
  }

  void skipTour() {
    _completeTour();
  }

  void restartTour() {
    final prefs = sl<SharedPrefsService>();
    final userCompletedKey = _getUserKey(_kTourCompletedKey);
    final userDontShowKey = _getUserKey(_kTourDontShowAgainKey);

    prefs.setValue(userCompletedKey, false);
    prefs.setValue(_kTourCompletedKey, false);
    prefs.setValue(userDontShowKey, false);
    prefs.setValue(_kTourDontShowAgainKey, false);

    _removeOverlay();
    isTourActiveNotifier.value = false;

    final nav = NavigationService.navigatorKey.currentState;
    nav?.pushNamedAndRemoveUntil(
      AppRoutes.doctorDashboard,
      (route) => false,
    );
  }

  Future<void> _saveTourCompletion() async {
    final prefs = sl<SharedPrefsService>();
    final userCompletedKey = _getUserKey(_kTourCompletedKey);
    final userDontShowKey = _getUserKey(_kTourDontShowAgainKey);

    await prefs.setValue(ClinxStorageKeys.isNewlyRegisteredUser, false);
    await prefs.setValue(userCompletedKey, true);
    await prefs.setValue(_kTourCompletedKey, true);
    await prefs.setValue(userDontShowKey, true);
    await prefs.setValue(_kTourDontShowAgainKey, true);

    try {
      final rawPrefs = await SharedPreferences.getInstance();
      await rawPrefs.setBool(ClinxStorageKeys.isNewlyRegisteredUser, false);
      await rawPrefs.setBool(userCompletedKey, true);
      await rawPrefs.setBool(_kTourCompletedKey, true);
      await rawPrefs.setBool(userDontShowKey, true);
      await rawPrefs.setBool(_kTourDontShowAgainKey, true);
    } catch (_) {}
  }

  Future<void> _completeTour() async {
    await _saveTourCompletion();

    // Return cleanly to Home Tab
    _tabSwitchCallback?.call(0);
    _removeOverlay();

    // Disable test mock data immediately, restoring 100% real live data
    isTourActiveNotifier.value = false;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
