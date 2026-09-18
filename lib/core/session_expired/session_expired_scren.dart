import 'package:flutter/material.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import '../../di/dependency_injection.dart';
import '../local/flutter_secure_storage.dart';
import '../local/shared_preferences.dart';
import 'app_info_state_template.dart';

class SessionExpiredScreen extends StatelessWidget {
  const SessionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppInfoStateTemplate(
      icon: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.amber.withValues(alpha: 0.15)
              : const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          Icons.timer_off_outlined,
          size: 48,
          color: isDark ? Colors.amberAccent : const Color(0XFFB68A1C),
        ),
      ),
      title: 'Session expired',
      description:
          "For your security, you've been signed out after a period of inactivity.",
      buttonText: 'Sign in again',
      onButtonPressed: () async {
        try {
          await sl<SecureStorageService>().clearAllSecureData();
          await sl<SharedPrefsService>().clearAll();
        } catch (_) {}
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.signIn, (route) => false);
        }
      },
      buttonIcon: const Icon(Icons.logout),
    );
  }
}
