import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/configure_screens/widgets/maintenance_illustration.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_button.dart';

class MaintenanceView extends StatelessWidget {
  const MaintenanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isTab = isTablet(context);
    final String displayMessage =
        "We're currently performing some scheduled system upgrades to serve you better. We'll be back online shortly!";
    final double contentMaxWidth = isTab ? 420.0 : double.infinity;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              width: contentMaxWidth,
              padding: EdgeInsets.symmetric(
                horizontal: isTab ? 32.0 : 24.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MaintenanceIllustration(isTab: isTab),
                  SizedBox(height: isTab ? 48 : 40),
                  CommonText(
                    'Under Maintenance',
                    textAlign: TextAlign.center,
                    maxLines: null,
                    softWrap: true,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: displayWidth(context) * (isTab ? 0.045 : 0.05),
                      fontFamily: appPoppinFont,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CommonText(
                    displayMessage,
                    textAlign: TextAlign.center,
                    maxLines: null,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: displayWidth(context) * (isTab ? 0.022 : 0.03),
                      color: Colors.grey.shade500,
                      fontFamily: appPoppinFont,
                    ),
                  ),
                  SizedBox(height: isTab ? 56 : 48),
                  CustomElevatedButton(
                    height: isTab ? 45 : 50,
                    text: 'Log Out',
                    borderRadius: fieldBorderRadius,
                    onPressed: () {},
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
