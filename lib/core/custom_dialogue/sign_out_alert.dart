import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/common_widgets/common_text.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../config/app_route/app_routes.dart';
import '../../di/dependency_injection.dart';
import '../local/flutter_secure_storage.dart';

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
        final bool isTab = isTablet(context);
        final double width = displayWidth(context);
        final double height = displayHeight(context);

        final double targetDialogWidth = isTab ? 420.0 : width * 0.85;

        return Dialog(
          elevation: 12,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isTab ? 0.0 : 24.0,
            vertical: 24.0,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
          child: StatefulBuilder(
            builder: (ctx, setDialogState) {
              return Container(
                constraints: BoxConstraints(
                  maxWidth: targetDialogWidth,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? darkModeCardColor
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: isTab ? 20.0 : height * 0.018,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: buttonPrimaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      width: double.infinity,
                      child: CommonText(
                        'Confirm Sign Out?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 18 : width * 0.042,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: CommonText(
                              maxLines: null,
                              softWrap: true,
                              textAlign: TextAlign.center,
                              'Sign out of your clinic management dashboard? This will disconnect your device from the live patient queue and automated documentation workflow until your next login.',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? 14 : width * 0.034,
                                color: isDark(context) ? Colors.white60 : Colors.grey[600],
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isDark(context)
                                            ? Colors.white24
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                  child: CommonText(
                                    'Cancel',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: isTab ? 14 : width * 0.036,
                                      color: isDark(context) ? Colors.white70 : Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: isSignOut
                                    ? Center(
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        buttonPrimaryColor,
                                      ),
                                    ),
                                  ),
                                )
                                    : TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: buttonPrimaryColor,
                                    minimumSize: const Size(double.infinity, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () async {
                                    setDialogState(() {
                                      isSignOut = true;
                                    });

                                    try {
                                      await sl<SecureStorageService>().clearAllSecureData();
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
                                  child: CommonText(
                                    'Ok',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: isTab ? 14 : width * 0.036,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}