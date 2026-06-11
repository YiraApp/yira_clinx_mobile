import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../common_size_helpers/common_size_helpers.dart';
import '../common_widgets/common_buttons.dart';
import '../common_widgets/common_text.dart';
import '../common_widgets/custom_button.dart';

class CustomUrlDialog {
  static customLauncherDialogue(
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
        return isTablet(context)
            ? _buildTabletLauncher(context, title, description, buttonPrimaryColor, url, buttonText, icon, isContactUs)
            : _buildMobileLauncher(context, title, description, buttonPrimaryColor, url, buttonText, icon, isContactUs);
      },
    );
  }

  static Widget _buildTabletLauncher(
      BuildContext context,
      String title,
      String description,
      Color buttonPrimaryColor,
      String url,
      String buttonText,
      String icon,
      bool isContactUs,
      )
  {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: BorderSide(
          color: isDark ? buttonPrimaryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF13161F) : const Color(0xFFFAFAFA),
      title: Column(
        children: [
          Container(
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: buttonPrimaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: displayHeight(context) * 0.08,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: buttonPrimaryColor.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Image.asset(icon),
          ),
          const SizedBox(height: 16),
          CommonText(
            title,
            maxLines: 2,
            softWrap: true,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: displayWidth(context) * 0.026,fontFamily: appPoppinFont,
              color: isDark ? sideMenuDividerColor : textLightModeColor,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2230) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
            ),
            child: CommonText(
              description,
              textAlign: TextAlign.center,
              maxLines: null,
              softWrap: true,
              style: TextStyle(
                fontSize: displayWidth(context) * 0.018,fontFamily: appPoppinFont,
                color: isDark ? textLightDarkColor : dialogueSubTextColor,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: isContactUs ? displayHeight(context) * 0.025 : displayHeight(context) * 0.02),
          if (isContactUs) ...[
            _buildContactGrid(context, buttonPrimaryColor, isDark),
          ],
          SizedBox(height: isContactUs ? displayHeight(context) * 0.02 : displayHeight(context) * 0.015),
          _buildActionButtons(context, isContactUs, buttonPrimaryColor, buttonText, url, displayWidth(context) * 0.02, displayHeight(context) * 0.045, isDark,isTablet(context)),
        ],
      ),
    );
  }

  static Widget _buildMobileLauncher(
      BuildContext context,
      String title,
      String description,
      Color buttonPrimaryColor,
      String url,
      String buttonText,
      String icon,
      bool isContactUs,
      )
  {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: BorderSide(
          color: isDark ? buttonPrimaryColor.withOpacity(0.2) : Colors.grey.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      backgroundColor: isDark ? const Color(0xFF13161F) : const Color(0xFFFAFAFA),
      title: Column(
        children: [
          Container(
            width: 35,
            height: 4,
            decoration: BoxDecoration(
              color: buttonPrimaryColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: displayHeight(context) * 0.08,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: buttonPrimaryColor.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Image.asset(icon),
          ),
          const SizedBox(height: 14),
          CommonText(
            title,
            maxLines: 2,
            softWrap: true,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: displayWidth(context) * 0.055,fontFamily: appPoppinFont,
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2230) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
            ),
            child: CommonText(
              description,
              textAlign: TextAlign.center,
              maxLines: 6,
              softWrap: true,
              style: TextStyle(
                fontSize: displayWidth(context) * 0.032,fontFamily: appPoppinFont,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
          ),
          SizedBox(height: isContactUs ? displayHeight(context) * 0.025 : displayHeight(context) * 0.02),
          if (isContactUs) ...[
            _buildContactGrid(context, buttonPrimaryColor, isDark),
          ],
          SizedBox(height: isContactUs ? displayHeight(context) * 0.02 : displayHeight(context) * 0.015),
          _buildActionButtons(context, isContactUs, buttonPrimaryColor, buttonText, url, displayWidth(context) * 0.038, displayHeight(context) * 0.052, isDark,isTablet(context)),
        ],
      ),
    );
  }

  static customContactLauncherDialogue(
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

  static customNotificationDialogue(
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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isTab = isTablet(context);

        return AlertDialog(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
            side: BorderSide(
              color: isDark ? buttonPrimaryColor.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF13161F) : const Color(0xFFFAFAFA),
          title: Column(
            children: [
              Container(
                width: 35,
                height: 4,
                decoration: BoxDecoration(
                  color: buttonPrimaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Icon(Icons.notifications_active_outlined, size: isTab ? 45 : 55, color: buttonPrimaryColor),
              const SizedBox(height: 14),
              CommonText(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
                style: TextStyle(
                  fontSize: isTab ? displayWidth(context) * 0.026 : 20,fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2230) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CommonText(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  softWrap: true,
                  style: TextStyle(
                    fontSize: isTab ? displayWidth(context) * 0.019 : displayWidth(context) * 0.033,
                    fontWeight: FontWeight.w400,fontFamily: appPoppinFont,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  CustomElevatedButton(
                    height: isTab ? displayHeight(context) * 0.045 : displayHeight(context) * 0.052,
                    width: displayWidth(context) / 2,
                    text: "Disable Anyway",
                    backgroundColor: buttonPrimaryColor,
                    textColor: Colors.white,
                    onPressed: () {
                      onDisableNotifications?.call();
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 8),
                  CommonButtons.getTextButton(
                    'Keep Reminders On',
                    context,
                    isDark ? buttonPrimaryColor : Colors.black87,
                    isTab ? displayWidth(context) * 0.021 : displayWidth(context) * 0.036,
                    false,
                    FontWeight.w600,
                        () => onDeny?.call(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

static Widget _buildContactGrid(BuildContext context, Color primaryColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191D29) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildContactRowItem(context, Icons.phone_in_talk_rounded, '8121005474', primaryColor, isDark, () {
            _launchURL('tel:+918121005474');
          }),
          const SizedBox(height: 8),
          _buildContactRowItem(context, Icons.alternate_email_rounded, 'contact@yira.ai', primaryColor, isDark, () {
            _launchURL('mailto:contact@yira.ai');
          }),
        ],
      ),
    );
  }

  static Widget _buildContactRowItem(BuildContext context, IconData icon, String value, Color primaryColor, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222736) : Colors.white,
          borderRadius: BorderRadius.circular(12),

        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: CommonText(
                value,
                style: TextStyle(
                  fontSize: isTablet(context) ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,fontFamily: appPoppinFont,
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

  static Widget _buildActionButtons(
      BuildContext context,
      bool isContactUs,
      Color primaryColor,
      String buttonText,
      String url,
      double cancelFontSize,
      double actionHeight,
      bool isDark,
      bool isTab
      ) {
    return Column(
      children: [
        if (isContactUs) ...[
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Or raise a formal ticket via ',
                  style: TextStyle(
                    color: isDark ? textLightDarkColor : scoreSubTextColor,fontFamily: appPoppinFont,
                    fontSize: isTablet(context) ? displayWidth(context) * 0.016 : displayWidth(context) * 0.03,
                  ),
                ),
                TextSpan(
                  text: 'Support Request',
                  style: TextStyle(
                    color: primaryColor,fontFamily: appPoppinFont,
                    fontSize: isTablet(context) ? displayWidth(context) * 0.016 : displayWidth(context) * 0.03,
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
          ),
          const SizedBox(height: 16),
        ] else ...[
          CustomElevatedButton(
            height:isTab? 42: actionHeight,
            width:isTab?  displayWidth(context) / 2.5: displayWidth(context) / 1.8,
            text: buttonText,
            backgroundColor: primaryColor,
            textColor: Colors.white,
            onPressed: () {
              if (url.isNotEmpty) _launchURL(url);
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 8),
        ],
        CommonButtons.getTextButton(
          'Dismiss',
          context,
          isDark ? headingsDarkColor : Colors.black54,
          cancelFontSize,
          false,
          FontWeight.w600,
              () => Navigator.pop(context),
        ),
      ],
    );
  }

  static void _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);

  }
}