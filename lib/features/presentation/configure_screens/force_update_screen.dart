import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/configure_screens/widgets/update_illustration.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_button.dart';
import '../../../core/utils/utils.dart';
import '../../domain/entities/token/get_version_and_token_status_entity.dart';

class ForceUpdateView extends StatelessWidget {
  final GetVersionTokenStatusEntity getVersionTokenStatusEntity;
  const ForceUpdateView({super.key, required this.getVersionTokenStatusEntity});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    final bool isTab = isTablet(context);
    final double contentMaxWidth = isTab ? 450 : double.infinity;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Container(
              width: contentMaxWidth,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const UpdateIllustration(),
                  const SizedBox(height: 40),
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
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 56),
                  CustomElevatedButton(
                    height: isTab ? 45 : 50,
                    text: 'Update Now',
                    borderRadius: fieldBorderRadius,
                    onPressed: () {
                      if (Platform.isAndroid) {
                        Utils.launchURL(
                          getVersionTokenStatusEntity.playStoreLink,
                        );
                      } else {
                        Utils.launchURL(
                          getVersionTokenStatusEntity.appStoreLink,
                        );
                      }
                    },
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
