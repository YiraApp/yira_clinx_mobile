import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../common_widgets/common_text.dart';

class AppStatusStateView extends StatelessWidget {
  final Widget icon;
  final String title;
  final String description;
  final List<Widget> actions;

  const AppStatusStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double screenWidth = displayWidth(context);
    final bool isTab = isTablet(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28.0,
                    vertical: 24.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(child: icon),
                          const SizedBox(height: 36),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTab ? 40.0 : 12.0,
                            ),
                            child: CommonText(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: null,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontFamily: appPoppinFont,
                                fontSize: isTab
                                    ? (screenWidth * 0.035)
                                    : (screenWidth * 0.055),
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTab ? 60.0 : 16.0,
                            ),
                            child: CommonText(
                              description,
                              textAlign: TextAlign.center,
                              maxLines: null,
                              softWrap: true,
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                fontFamily: appPoppinFont,
                                fontSize: isTab
                                    ? (screenWidth * 0.022)
                                    : (screenWidth * 0.035),
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.85),
                              ),
                            ),
                          ),
                        ],
                      ),

                      Container(
                        margin: const EdgeInsets.only(top: 40, bottom: 10),
                        width: isTab ? 420 : double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: actions,
                        ),
                      ),
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
