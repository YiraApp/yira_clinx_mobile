import 'package:flutter/material.dart';
import 'package:yiraclinics/core/custom_dialogue/app_dialog.dart';

import '../../config/app_route/app_routes.dart';
import '../../di/dependency_injection.dart';
import '../local/flutter_secure_storage.dart';
import '../local/shared_preferences.dart';

class SignOutAlert {
  static Future<void> showSignCustomDialog(
    BuildContext ctx,
    Color buttonPrimaryColor,
  ) {
    bool isSignOut = false;

    return showDialog<void>(
      barrierDismissible: false,
      context: ctx,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AppDialog(
              title: 'Confirm Sign Out?',
              message:
                  'Sign out of your clinic management dashboard? This will disconnect your device from the live patient queue and automated documentation workflow until your next login.',
              icon: Icons.logout_rounded,
              accentColor: buttonPrimaryColor,
              primaryLabel: 'Sign Out',
              isPrimaryLoading: isSignOut,
              onPrimary: () async {
                setDialogState(() {
                  isSignOut = true;
                });

                try {
                  await sl<SecureStorageService>().clearAllSecureData();
                  await sl<SharedPrefsService>().clearAll();

                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.signIn,
                      (route) => false,
                    );
                  }
                } catch (e) {
                  setDialogState(() {
                    isSignOut = false;
                  });
                }
              },
              secondaryLabel: 'Cancel',
              onSecondary: () => Navigator.pop(context),
            );
          },
        );
      },
    );
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}
