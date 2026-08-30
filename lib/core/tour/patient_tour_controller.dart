import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'patient_tour_keys.dart';
import 'patient_tour_model.dart';
import 'patient_tour_overlay.dart';

class PatientTourController {
  static final PatientTourController _instance = PatientTourController._internal();
  factory PatientTourController() => _instance;
  PatientTourController._internal();

  static const String _prefTourCompletedKey = 'patient_tour_has_completed_v1';

  final ValueNotifier<bool> isTourActiveNotifier = ValueNotifier<bool>(false);
  bool get isTourActive => isTourActiveNotifier.value;

  OverlayEntry? _overlayEntry;
  int _currentStepIndex = 0;
  bool _dontShowAgain = false;

  Function(int index)? _tabSwitcher;

  void registerTabSwitcher(Function(int index) switcher) {
    _tabSwitcher = switcher;
  }

  void unregisterTabSwitcher() {
    _tabSwitcher = null;
  }

  // GlobalKeys accessors
  void refreshKeys() => PatientTourKeys.refreshKeys();
  GlobalKey get headerProfileKey => PatientTourKeys.headerProfileKey;
  GlobalKey get vitalsCardKey => PatientTourKeys.vitalsCardKey;
  GlobalKey get upcomingAppointmentsKey => PatientTourKeys.upcomingAppointmentsKey;
  GlobalKey get quickServicesKey => PatientTourKeys.quickServicesKey;
  GlobalKey get dashboardNavKey => PatientTourKeys.dashboardNavKey;
  GlobalKey get apptsNavKey => PatientTourKeys.apptsNavKey;
  GlobalKey get consentsNavKey => PatientTourKeys.consentsNavKey;
  GlobalKey get profileNavKey => PatientTourKeys.profileNavKey;
  GlobalKey get apptsFilterKey => PatientTourKeys.apptsFilterKey;
  GlobalKey get apptsListKey => PatientTourKeys.apptsListKey;
  GlobalKey get consentsListKey => PatientTourKeys.consentsListKey;
  GlobalKey get passportProfileCardKey => PatientTourKeys.passportProfileCardKey;

  List<PatientTourStep> get steps => [
        // ─── 1. DASHBOARD OVERVIEW ──────────────────────────────────
        // Step 1: Profile & Family Switcher
        PatientTourStep(
          id: 'step_header_profile',
          title: 'Account & Family Switcher',
          description: 'Tap your profile name anytime to switch between family member profiles or manage your personal health credentials.',
          targetKey: headerProfileKey,
          icon: Icons.account_circle_rounded,
          position: TourCardPosition.bottom,
          tabIndex: 0,
        ),

        // Step 2: Health Vitals Card
        PatientTourStep(
          id: 'step_vitals_card',
          title: "Your Health Vitals & Daily Check",
          description: "Monitor your latest Blood Pressure, Pulse, SpO2, and Weight. Tap 'Update Vitals' to log new measurements on the spot.",
          targetKey: vitalsCardKey,
          icon: Icons.monitor_heart_rounded,
          position: TourCardPosition.bottom,
          tabIndex: 0,
        ),

        // Step 3: Upcoming Consultations & Video Calls
        PatientTourStep(
          id: 'step_upcoming_appts',
          title: "Upcoming Visits & 1-Tap Video Calls",
          description: "See your upcoming confirmed consultations. For online visits, tap 'Video Call' to join doctor video rooms with zero latency.",
          targetKey: upcomingAppointmentsKey,
          icon: Icons.video_camera_front_rounded,
          position: TourCardPosition.auto,
          tabIndex: 0,
        ),

        // Step 4: Quick Services Grid
        PatientTourStep(
          id: 'step_quick_services',
          title: 'Quick Services & Medical Records',
          description: 'Instant access to Book Appointments, Medical Records, Vitals, Doctors, and Family Profiles.',
          targetKey: quickServicesKey,
          icon: Icons.grid_view_rounded,
          position: TourCardPosition.top,
          tabIndex: 0,
        ),

        // Step 5: Bottom Navigation - Dashboard Tab
        PatientTourStep(
          id: 'step_nav_dashboard',
          title: '1. Dashboard Tab',
          description: 'Your primary homepage for daily vitals, upcoming consultation schedules, and essential health services.',
          targetKey: dashboardNavKey,
          icon: Icons.dashboard_rounded,
          position: TourCardPosition.top,
          targetPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          borderRadius: 14,
          tabIndex: 0,
        ),

        // ─── 2. APPOINTMENTS TAB ────────────────────────────────────
        // Step 6: Bottom Navigation - Appointments Tab
        PatientTourStep(
          id: 'step_nav_appts',
          title: '2. Appointments Tab',
          description: 'Switches to your appointment center to track upcoming bookings and check consultation histories.',
          targetKey: apptsNavKey,
          icon: Icons.calendar_month_rounded,
          position: TourCardPosition.top,
          targetPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          borderRadius: 14,
          tabIndex: 1,
        ),

        // Step 7: Appointments Filters & Search
        PatientTourStep(
          id: 'step_appts_filter',
          title: 'Search & Status Filters',
          description: 'Quickly filter consultations between Upcoming and Completed, or filter by Confirmed, Scheduled, and In Progress.',
          targetKey: apptsFilterKey,
          icon: Icons.filter_alt_rounded,
          position: TourCardPosition.bottom,
          tabIndex: 1,
        ),

        // ─── 3. CONSENTS TAB ────────────────────────────────────────
        // Step 8: Bottom Navigation - Consents Tab
        PatientTourStep(
          id: 'step_nav_consents',
          title: '3. Consents & Privacy Tab',
          description: 'Switches to your consent management center where you control all doctor and hospital access to your health records.',
          targetKey: consentsNavKey,
          icon: Icons.verified_user_rounded,
          position: TourCardPosition.top,
          targetPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          borderRadius: 14,
          tabIndex: 2,
        ),

        // Step 9: Consent Requests List
        PatientTourStep(
          id: 'step_consents_list',
          title: 'Secure Medical Record Consents',
          description: 'Grant or revoke permissions for consulting doctors to view your medical history with complete privacy protection.',
          targetKey: consentsListKey,
          icon: Icons.security_rounded,
          position: TourCardPosition.bottom,
          tabIndex: 2,
        ),

        // ─── 4. PROFILE & PASSPORT TAB ──────────────────────────────
        // Step 10: Bottom Navigation - Profile Tab
        PatientTourStep(
          id: 'step_nav_profile',
          title: '4. Profile & Health Passport Tab',
          description: 'Switches to your verified Health Passport, ABHA credentials, and app preferences.',
          targetKey: profileNavKey,
          icon: Icons.person_rounded,
          position: TourCardPosition.top,
          targetPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          borderRadius: 14,
          tabIndex: 3,
        ),

        // Step 11: Health Passport Card
        PatientTourStep(
          id: 'step_passport_card',
          title: 'Your Digital Health Passport',
          description: 'Your verified digital health ID card with ABHA linkage, blood group, emergency details, and QR code for rapid hospital check-in.',
          targetKey: passportProfileCardKey,
          icon: Icons.badge_rounded,
          position: TourCardPosition.bottom,
          tabIndex: 3,
        ),
      ];

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

  Future<void> startDashboardTour({
    required BuildContext context,
    bool force = false,
  }) async {
    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserKey(_prefTourCompletedKey);
      final hasCompleted = (prefs.getBool(_prefTourCompletedKey) ?? false) ||
          (prefs.getBool(userKey) ?? false);
      if (hasCompleted) return;
    }

    if (isTourActive) return;

    // Small delay to ensure widgets are built and mounted
    await Future.delayed(const Duration(milliseconds: 600));
    if (!context.mounted) return;

    _currentStepIndex = 0;
    _dontShowAgain = false;
    isTourActiveNotifier.value = true;

    _showOverlay(context);
  }

  void restartTour({required BuildContext context}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserKey(_prefTourCompletedKey);
      await prefs.setBool(_prefTourCompletedKey, false);
      await prefs.setBool(userKey, false);
    } catch (_) {}

    _dismissTour();
    if (_tabSwitcher != null) {
      _tabSwitcher!(0);
    }
    if (context.mounted) {
      startDashboardTour(context: context, force: true);
    }
  }

  void _showOverlay(BuildContext context) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      isTourActiveNotifier.value = false;
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (ctx) => PatientTourOverlay(
        steps: steps,
        currentStepIndex: _currentStepIndex,
        dontShowAgain: _dontShowAgain,
        onNext: () => nextStep(context),
        onBack: () => previousStep(context),
        onSkip: () => skipTour(),
        onDontShowAgainChanged: (val) {
          _dontShowAgain = val;
        },
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void nextStep(BuildContext context) async {
    if (_currentStepIndex < steps.length - 1) {
      _currentStepIndex++;
      final targetStep = steps[_currentStepIndex];

      if (targetStep.tabIndex != null && _tabSwitcher != null) {
        _tabSwitcher!(targetStep.tabIndex!);
        // Delay to allow tab layout and animations to settle
        await Future.delayed(const Duration(milliseconds: 250));
      }

      // Scroll into view if widget is mounted in a scrollable (e.g. Step 4 Quick Services Grid)
      if (targetStep.targetKey?.currentContext != null) {
        try {
          await Scrollable.ensureVisible(
            targetStep.targetKey!.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            alignment: 0.5,
          );
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _overlayEntry?.markNeedsBuild();
    } else {
      finishTour();
    }
  }

  void previousStep(BuildContext context) async {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      final targetStep = steps[_currentStepIndex];

      if (targetStep.tabIndex != null && _tabSwitcher != null) {
        _tabSwitcher!(targetStep.tabIndex!);
        await Future.delayed(const Duration(milliseconds: 250));
      }

      if (targetStep.targetKey?.currentContext != null) {
        try {
          await Scrollable.ensureVisible(
            targetStep.targetKey!.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
            alignment: 0.5,
          );
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _overlayEntry?.markNeedsBuild();
    }
  }

  void skipTour() {
    _dismissTour();
    _saveTourCompletion();
  }

  void finishTour() {
    _dismissTour();
    _saveTourCompletion();
  }

  void _dismissTour() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    isTourActiveNotifier.value = false;

    // Return to Tab 0 smoothly if left on another tab
    if (_tabSwitcher != null) {
      _tabSwitcher!(0);
    }
  }

  Future<void> _saveTourCompletion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserKey(_prefTourCompletedKey);
      await prefs.setBool(_prefTourCompletedKey, true);
      await prefs.setBool(userKey, true);
    } catch (_) {}
  }
}
