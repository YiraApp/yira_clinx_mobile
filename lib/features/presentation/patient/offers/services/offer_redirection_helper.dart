import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../config/app_route/app_routes.dart';
import '../../appointments/patient_book_appointment_sheet.dart';
import '../../documents/patient_documents_screen.dart';
import '../models/offer_banner_model.dart';

class OfferRedirectionHelper {
  static Future<void> handleRedirection(
    BuildContext context,
    OfferBannerModel banner, {
    VoidCallback? onBeforeRedirect,
  }) async {
    final type = banner.redirectionType.toLowerCase().trim();

    onBeforeRedirect?.call();

    if (type == 'browser') {
      final rawUrl = banner.redirectionUrl?.trim() ?? '';
      if (rawUrl.isEmpty) return;

      try {
        final uri = Uri.parse(
          rawUrl.startsWith('http://') || rawUrl.startsWith('https://')
              ? rawUrl
              : 'https://$rawUrl',
        );
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $rawUrl')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening link: $e')),
          );
        }
      }
    } else {
      // In-App Redirection
      final route = banner.inAppRoute?.trim() ?? '';
      if (route.isEmpty) return;

      if (route == '/patientBookAppointment' || route == 'book_appointment') {
        PatientBookAppointmentSheet.show(context);
      } else if (route == '/patientDocuments' || route == AppRoutes.patientDocuments) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PatientDocumentsScreen()),
        );
      } else if (route == '/patientVitalsTracking' || route == AppRoutes.patientVitalsTracking) {
        Navigator.pushNamed(context, AppRoutes.patientVitalsTracking);
      } else if (route == '/patientMyDoctors' || route == AppRoutes.patientMyDoctors) {
        Navigator.pushNamed(context, AppRoutes.patientMyDoctors);
      } else if (route == '/patientDoctorSuggestions' || route == AppRoutes.patientDoctorSuggestions) {
        Navigator.pushNamed(context, AppRoutes.patientDoctorSuggestions);
      } else if (route == '/patientMyFamily' || route == AppRoutes.patientMyFamily) {
        Navigator.pushNamed(context, AppRoutes.patientMyFamily);
      } else if (route == '/patientProfile' || route == AppRoutes.patientProfile) {
        Navigator.pushNamed(context, AppRoutes.patientProfile);
      } else {
        try {
          Navigator.pushNamed(context, route);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening feature: ${banner.title}')),
            );
          }
        }
      }
    }
  }
}
