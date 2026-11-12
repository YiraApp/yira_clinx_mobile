import '../../../config/app_route/app_routes.dart';
import '../../local/global_session.dart';

/// Where tapping a notification takes the user, and the words on its action.
class NotificationTarget {
  final String route;
  final Object? arguments;
  final String actionLabel;

  /// A web page to open instead of an app screen.
  final String? url;

  const NotificationTarget({required this.route, this.arguments, required this.actionLabel, this.url});

  const NotificationTarget.web(String this.url, {this.actionLabel = 'Open link'})
      : route = '',
        arguments = null;
}

/// Screens a notification may name directly in its `route`.
const _knownRoutes = {
  AppRoutes.patientDashboard,
  AppRoutes.patientAppointments,
  AppRoutes.patientDocuments,
  AppRoutes.patientDoctorSuggestions,
  AppRoutes.patientDietPlan,
  AppRoutes.patientVitalsTracking,
  AppRoutes.patientBilling,
  AppRoutes.patientQuestionnaires,
  AppRoutes.patientPolicies,
  AppRoutes.patientConsentsScreen,
  AppRoutes.patientBookAppointment,
  AppRoutes.userPrescriptionManagement,
  AppRoutes.doctorDashboard,
  AppRoutes.appointmentDashboardScreen,
};

bool _isDoctorSession() {
  final data = GlobalSession.instance.userNotifier.value?.data;
  final role = (data?.latestUserRole ?? '').toLowerCase();
  final nav = data?.navigationId?.toString().trim();
  return nav == '2' || role.contains('doctor') || role.contains('provider');
}

/// The screen a notification is about, or null when it is just a message
/// (a health tip, a broadcast) and tapping should only expand it.
NotificationTarget? notificationTargetFor({required String type, String? route, String? title, bool? isDoctor}) {
  final t = type.toUpperCase().trim();
  final r = (route ?? '').trim();
  final doctor = isDoctor ?? _isDoctorSession();

  if (r.startsWith('http://') || r.startsWith('https://') || r.startsWith('www.')) {
    return NotificationTarget.web(r.startsWith('www.') ? 'https://$r' : r, actionLabel: t.contains('OFFER') ? 'View offer' : 'Open link');
  }

  if (t.startsWith('APPOINTMENT') || t.startsWith('WHATSAPP_APPOINTMENT') || t == 'TELECONSULT_START') {
    final label = t == 'TELECONSULT_START' ? 'Join consultation' : 'View appointment';
    return doctor
        ? NotificationTarget(route: AppRoutes.appointmentDashboardScreen, actionLabel: label)
        : NotificationTarget(route: AppRoutes.patientAppointments, actionLabel: label);
  }

  if (!doctor) {
    switch (t) {
      case 'PRESCRIPTION_ADDED':
        return const NotificationTarget(route: AppRoutes.userPrescriptionManagement, actionLabel: 'View prescription');
      case 'MEDICATION_REMINDER':
        return const NotificationTarget(route: AppRoutes.userPrescriptionManagement, actionLabel: 'Open my medicines');
      case 'MEDICAL_RECORD_ADDED':
      case 'REPORT_ANALYSIS_READY':
      case 'REPORT_ANALYSIS_FAILED':
      case 'SUMMARY_BUNDLE':
      case 'WHATSAPP_SINGLE_DOCUMENT':
        return const NotificationTarget(route: AppRoutes.patientDocuments, actionLabel: 'View records');
      case 'DOCTOR_SUGGESTION':
        return const NotificationTarget(route: AppRoutes.patientDoctorSuggestions, actionLabel: 'Read suggestion');
      case 'DIET_PLAN':
        return const NotificationTarget(route: AppRoutes.patientDietPlan, actionLabel: 'Open diet plan');
      case 'CONSENT_REQUEST':
      case 'CONSENT_REQUIRED':
        return const NotificationTarget(route: AppRoutes.patientConsentsScreen, actionLabel: 'Review request');
      case 'FAMILY_LINK_REQUEST':
        return const NotificationTarget(route: AppRoutes.patientMyFamily, actionLabel: 'Review request');
      case 'FAMILY_LINKED':
      case 'FAMILY_LINK_ACCEPTED':
        return const NotificationTarget(route: AppRoutes.patientMyFamily, actionLabel: 'Open My Family');
    }
  }

  // Medicine reminders sometimes arrive as general alerts; the title says what they are.
  final lowerTitle = (title ?? '').toLowerCase();
  if (!doctor && r.isEmpty && (lowerTitle.contains('dose') || lowerTitle.contains('medicine') || lowerTitle.startsWith('💊'))) {
    return const NotificationTarget(route: AppRoutes.userPrescriptionManagement, actionLabel: 'Open my medicines');
  }

  // The server's own route, when it names a screen this app has.
  final normalised = switch (r) {
    '/prescriptions' || '/prescriptionListScreen' => doctor ? null : AppRoutes.userPrescriptionManagement,
    '/diet-plan' => AppRoutes.patientDietPlan,
    '/userTestResultScreen' => doctor ? null : AppRoutes.patientDocuments,
    _ => _knownRoutes.contains(r) ? r : null,
  };
  if (normalised == null) return null;
  // The home screen is where the user already is; don't offer it as an action.
  if (normalised == AppRoutes.patientDashboard || normalised == AppRoutes.doctorDashboard) return null;
  return NotificationTarget(route: normalised, actionLabel: 'Open');
}
