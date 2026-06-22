

import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/configure_screens/widgets/update_illustration.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_button.dart';

class SoftUpdateView extends StatelessWidget {
  const SoftUpdateView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final bool isTab = isTablet(context);

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
                  const UpdateIllustration(),
                  SizedBox(height: isTab ? 48 : 40),
                  CommonText(
                    'New Update Available',
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
                    "We've made some exciting improvements on the app! Update now to enjoy the latest features and performance upgrades!",
                    textAlign: TextAlign.center,
                    maxLines: null,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: displayWidth(context) * (isTab ? 0.022 : 0.03),
                      color: Colors.grey.shade500,
                      fontFamily: appPoppinFont,
                    ),
                  ),
                  SizedBox(height: isTab ? 64 : 48),
                  if (isTab)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.primaryColor, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(fieldBorderRadius ?? 8.0),
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
                            onPressed: () {
                              // Trigger App Store URL Launcher
                            },
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
                          onPressed: () {

                          },
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: CommonText(
                            'Later',
                            style: TextStyle(
                              fontSize: displayWidth(context) * (isTab ? 0.026 : 0.036),
                              color: Colors.grey.shade500,
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