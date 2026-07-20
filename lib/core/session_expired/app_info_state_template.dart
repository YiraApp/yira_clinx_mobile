import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../common_widgets/common_text.dart';
import '../common_widgets/custom_button.dart';

class AppInfoStateTemplate extends StatelessWidget {
  final Widget icon;
  final String title;
  final String description;
  final String buttonText;
  final Widget buttonIcon;
  final VoidCallback onButtonPressed;

  const AppInfoStateTemplate({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.buttonIcon,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
final isTab = isTablet(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 3),
                      Center(child: icon),
                      const SizedBox(height: 36),
                      CommonText(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: null,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontFamily: appPoppinFont,
                          fontSize: isTab
                              ? displayWidth(context) * 0.035:  displayWidth(context) * 0.055,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: CommonText(
                          description,
                          maxLines: null,
                          softWrap: true,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontFamily: appPoppinFont,
                            fontSize:isTab
                                ? displayWidth(context) * 0.022:  displayWidth(context) * 0.035,
                          ),
                        ),
                      ),

                      const Spacer(flex: 4),

                      CustomElevatedButton(
                        text: buttonText,
                        icon: buttonIcon,
                        borderRadius: 30.0,
                        height: 56.0,
                        backgroundColor: theme.colorScheme.primary,
                        noElevation: true,
                        onPressed: onButtonPressed,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
