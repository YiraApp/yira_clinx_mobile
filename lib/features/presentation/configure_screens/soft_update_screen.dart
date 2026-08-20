import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/common_widgets/common_text.dart';
import 'package:yiraclinics/core/common_widgets/custom_button.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/features/domain/entities/token/get_version_and_token_status_entity.dart';

import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/utils.dart';

class SoftUpdateView extends StatelessWidget {
  final GetVersionTokenStatusEntity getVersionTokenStatusEntity;
  const SoftUpdateView({super.key, required this.getVersionTokenStatusEntity});

  void _onLaterPressed(BuildContext context) {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final payload = currentUser?.data;
    final navigationId = payload?.navigationId;
    final navigationRoutes = const {
      '1': AppRoutes.doctorDashboard,
      '2': AppRoutes.doctorDashboard,
    };
    final coreRoute = navigationRoutes[navigationId] ?? AppRoutes.doctorDashboard;

    Navigator.pushNamedAndRemoveUntil(
      context,
      coreRoute,
      (route) => false,
    );
  }

  void _onUpdatePressed() {
    final String storeUrl = Platform.isAndroid
        ? (getVersionTokenStatusEntity.playStoreLink.isNotEmpty
            ? getVersionTokenStatusEntity.playStoreLink
            : 'https://play.google.com/store/apps/details?id=ai.yira.clinicx')
        : (getVersionTokenStatusEntity.appStoreLink.isNotEmpty
            ? getVersionTokenStatusEntity.appStoreLink
            : 'https://apps.apple.com/app/yira-clinx/id6741477759');
    Utils.launchURL(storeUrl);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: displayWidth(context) * (isTab ? 0.08 : 0.06),
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTab ? 500 : double.infinity,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/soft_update_img.png',
                      height: displayHeight(context) * (isTab ? 0.28 : 0.22),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.system_update_rounded,
                        size: 80,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: isTab ? 36 : 28),
                  CommonText(
                    'Time to Upgrade!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: displayWidth(context) * (isTab ? 0.045 : 0.05),
                      fontFamily: appPoppinFont,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CommonText(
                    "We've made some exciting improvements on the app! Update now to enjoy the latest features and performance upgrades!",
                    textAlign: TextAlign.center,
                    maxLines: null,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: displayWidth(context) * (isTab ? 0.022 : 0.03),
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                      fontFamily: appPoppinFont,
                    ),
                  ),
                  SizedBox(height: isTab ? 64 : 48),
                  if (isTab)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _onLaterPressed(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: theme.primaryColor,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  fieldBorderRadius,
                                ),
                              ),
                            ),
                            child: CommonText(
                              'Later',
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontFamily: appPoppinFont,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomElevatedButton(
                            height: 48,
                            text: 'Update Now',
                            borderRadius: fieldBorderRadius,
                            onPressed: _onUpdatePressed,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        CustomElevatedButton(
                          height: 50,
                          text: 'Update Now',
                          borderRadius: fieldBorderRadius,
                          onPressed: _onUpdatePressed,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => _onLaterPressed(context),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: CommonText(
                            'Later',
                            style: TextStyle(
                              fontSize:
                                  displayWidth(context) *
                                  (isTab ? 0.022 : 0.035),
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontFamily: appPoppinFont,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
