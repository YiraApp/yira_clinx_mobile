import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/custom_dialogue/app_dialog.dart';
import '../utils/utils.dart';

class CustomUrlDialog {
  static Future<dynamic> customLauncherDialogue(
      BuildContext context,
      String title,
      String description,
      Color buttonPrimaryColor,
      String url,
      String buttonText,
      String icon, {
        bool isContactUs = false,
      }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AppDialog(
          title: title,
          message: description,
          accentColor: buttonPrimaryColor,
          badge: Padding(
            padding: const EdgeInsets.all(14),
            child: Image.asset(icon, fit: BoxFit.contain),
          ),
          content: isContactUs
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildContactGrid(context, buttonPrimaryColor, isDark),
                    const SizedBox(height: 14),
                    _buildSupportRequestLink(context, buttonPrimaryColor, url, isDark),
                  ],
                )
              : null,
          // Contact details are tapped directly, so the dialog only needs a way out.
          primaryLabel: isContactUs ? 'Close' : buttonText,
          onPrimary: () {
            if (!isContactUs && url.isNotEmpty) _launchURL(url);
            Navigator.of(context).pop();
          },
          secondaryLabel: isContactUs ? null : 'Cancel',
          onSecondary: () => Navigator.pop(context),
        );
      },
    );
  }

  static dynamic customContactLauncherDialogue(
      BuildContext context,
      String title,
      String description,
      Color buttonPrimaryColor,
      String url,
      String buttonText,
      String icon, {
        bool isContactUs = false,
      }) {
    return customLauncherDialogue(context, title, description, buttonPrimaryColor, url, buttonText, icon, isContactUs: isContactUs);
  }

  static Future<dynamic> customNotificationDialogue(
      BuildContext context,
      String title,
      String description,
      Color buttonPrimaryColor,
      VoidCallback? onDisableNotifications,
      VoidCallback? onDeny,
      )
  {
    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return AppDialog(
          title: title,
          message: description,
          icon: Icons.notifications_active_outlined,
          accentColor: buttonPrimaryColor,
          primaryLabel: 'Disable Anyway',
          onPrimary: () {
            onDisableNotifications?.call();
            Navigator.of(context).pop();
          },
          secondaryLabel: 'Keep Reminders On',
          onSecondary: () => onDeny?.call(),
        );
      },
    );
  }

  static Widget _buildContactGrid(BuildContext context, Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: _buildContactRowItem(context, Icons.alternate_email_rounded, 'contact@yira.ai', primaryColor, isDark, () {
        _launchURL('mailto:contact@yira.ai');
      }),
    );
  }

  static Widget _buildContactRowItem(BuildContext context, IconData icon, String value, Color primaryColor, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  fontFamily: appPoppinFont,
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 12, color: isDark ? Colors.white30 : Colors.black38),
          ],
        ),
      ),
    );
  }

  static Widget _buildSupportRequestLink(BuildContext context, Color primaryColor, String url, bool isDark) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Or raise a formal ticket via ',
            style: TextStyle(
              color: isDark ? textLightDarkColor : scoreSubTextColor,
              fontFamily: appPoppinFont,
              fontSize: 12.5,
            ),
          ),
          TextSpan(
            text: 'Support Request',
            style: TextStyle(
              color: primaryColor,
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                if (url.isNotEmpty) _launchURL(url);
                Navigator.of(context).pop();
              },
          ),
        ],
      ),
    );
  }

  static void _launchURL(String urlString) async {
    if (urlString.isNotEmpty) {
      await Utils.launchURL(urlString);
    }
  }
}
