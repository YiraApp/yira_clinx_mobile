
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_route/app_routes.dart';
import '../common_widgets/custom_border_button.dart';
import '../common_widgets/custom_button.dart';
import 'app_status_view.dart';

class ServerDownScreen extends StatelessWidget {
  const ServerDownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppStatusStateView(
      icon: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.red.withOpacity(0.12) : const Color(0xFFFFEBEB),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(
          Icons.warning_amber_rounded,
          size: 48,
          color: Color(0xFFD92D20),
        ),
      ),
      title: 'Something went wrong',
      description: "We're having trouble retrieving this clinical information. Please try again in a few moments, or contact system support if the error persists.",
      actions: [
        CustomElevatedButton(
          height: 50,
          text: 'Try again',
          icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
          backgroundColor: theme.colorScheme.primary,
          textColor: Colors.white,
          noElevation: true,
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.initial,
                (route) => false,
              );
            }
          },
        ),

        const SizedBox(height: 12),
        CommonBorderButton(
          text: 'Contact Us',
          icon: Icons.mail_outline_rounded,
          height: 50.0,
          borderColor: theme.colorScheme.primary,
          textColor: theme.colorScheme.primary,
          onPressed: () async {
            final Uri emailUri = Uri(
              scheme: 'mailto',
              path: 'support@yiralife.com',
              queryParameters: {
                'subject': 'Support Request - Yira Clinx App Error',
              },
            );
            if (await canLaunchUrl(emailUri)) {
              await launchUrl(emailUri);
            }
          },
        ),
      ],
    );
  }
}