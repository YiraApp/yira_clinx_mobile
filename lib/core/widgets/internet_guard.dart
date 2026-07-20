// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:lottie/lottie.dart';
// import 'package:yiraclinics/config/yira_colors/yira_colors.dart' hide textLightModeColor, lightGreenColor;
// import 'package:yiraclinics/core/colors/colors.dart';
// import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
// import 'package:yiraclinics/core/constants/constants.dart';
//
// import '../services/network_services/domain/neetwork_repo/network_repo.dart';
// import '../services/network_services/network_bloc/network_bloc.dart';
//
// class InternetGuard extends StatelessWidget {
//   final Widget? child;
//
//   const InternetGuard({super.key, this.child});
//
//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.ltr,
//       child: Material(
//         type: MaterialType.transparency,
//         child: Stack(
//           children: [
//             if (child != null) child!,
//             BlocBuilder<NetworkBloc, NetworkState>(
//               buildWhen: (previous, current) => previous.status != current.status,
//               builder: (context, state) {
//                 if (state.status == NetworkStatus.offline) {
//                   return const _PremiumOfflineOverlay();
//                 }
//                 return const SizedBox.shrink();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _PremiumOfflineOverlay extends StatelessWidget {
//   const _PremiumOfflineOverlay();
//
//   @override
//   Widget build(BuildContext context) {
//     final double screenWidth = displayWidth(context);
//     final bool isTabletDevice = isTablet(context);
//     final ThemeData theme = Theme.of(context);
//     final bool isDarkMode = theme.brightness == Brightness.dark;
//
//     final Color cardBackground = isDarkMode
//         ? cardPopUpMenuColor.withOpacity(1)
//         : Colors.white.withOpacity(1);
//
//     final Color titleColor = isDarkMode
//         ? textDarkModePrimaryColor
//         : textLightModeColor;
//
//     final Color bodyColor = isDarkMode
//         ? textLightDarkColor
//         : dialogueSubTextColor;
//
//     final Color iconWrapperBg = isDarkMode
//         ? lightModeBorderColor.withOpacity(0.15)
//         : Colors.white;
//
//     final double cardPaddingHorizontal = isTabletDevice ? 40.0 : 24.0;
//     final double cardPaddingVertical = isTabletDevice ? 48.0 : 32.0;
//
//     final double titleFontSize = isTabletDevice
//         ? screenWidth * 0.028
//         : screenWidth * 0.054;
//
//     final double bodyFontSize = isTabletDevice
//         ? screenWidth * 0.018
//         : screenWidth * 0.034;
//
//     final double pillFontSize = isTabletDevice
//         ? screenWidth * 0.015
//         : screenWidth * 0.030;
//
//     final double lottieAssetHeight = isTabletDevice ? 110.0 : 75.0;
//
//     return Positioned.fill(
//       child: AbsorbPointer(
//         absorbing: true,
//         child: Container(
//           color: isDarkMode ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.12),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
//             child: Center(
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 curve: Curves.easeOut,
//                 padding: EdgeInsets.symmetric(
//                   horizontal: cardPaddingHorizontal,
//                   vertical: cardPaddingVertical,
//                 ),
//                 margin: const EdgeInsets.symmetric(horizontal: 32),
//                 constraints: BoxConstraints(
//                   minWidth: isTabletDevice ? 460.0 : screenWidth * 0.85,
//                   maxWidth: 500.0,
//                 ),
//                 decoration: BoxDecoration(
//                   color: cardBackground,
//                   borderRadius: BorderRadius.circular(isTabletDevice ? 36 : 28),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.06),
//                       blurRadius: 32,
//                       offset: const Offset(0, 16),
//                     ),
//                   ],
//                 ),
//                 child: TweenAnimationBuilder<double>(
//                   tween: Tween(begin: 0.94, end: 1.0),
//                   duration: const Duration(milliseconds: 400),
//                   curve: Curves.fastOutSlowIn,
//                   builder: (context, value, child) {
//                     return Transform.scale(scale: value, child: child);
//                   },
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Container(
//                         padding: EdgeInsets.all(isTabletDevice ? 22 : 16),
//                         decoration: BoxDecoration(
//                           color: iconWrapperBg,
//                           shape: BoxShape.circle,
//                           boxShadow: [
//                             BoxShadow(
//                               color: lightModeBorderFocusedColor.withOpacity(isDarkMode ? 0.2 : 0.1),
//                               blurRadius: 10,
//                               spreadRadius: 2,
//                             )
//                           ],
//                         ),
//                         child: Lottie.asset(
//                           'assets/images/no_internet.json',
//                           height: lottieAssetHeight,
//                           fit: BoxFit.contain,
//                           repeat: true,
//                           errorBuilder: (context, error, stackTrace) {
//                             return Icon(
//                               Icons.wifi_off_rounded,
//                               size: isTabletDevice ? 65 : 45,
//                               color: lightModeBorderFocusedColor,
//                             );
//                           },
//                         ),
//                       ),
//                       SizedBox(height: isTabletDevice ? 32 : 24),
//                       Text(
//                         "Connection Interrupted",
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: titleFontSize,
//                           fontWeight: FontWeight.w700,
//                           color: titleColor,
//                           fontFamily: appPoppinFont,
//                           letterSpacing: -0.3,
//                           decoration: TextDecoration.none,
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       Text(
//                         "We are waiting for your network connection to stabilize. Please check your data or Wi-Fi settings.",
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: bodyFontSize,
//                           color: bodyColor,
//                           fontWeight: FontWeight.w400,
//                           height: 1.5,
//                           fontFamily: appPoppinFont,
//                           decoration: TextDecoration.none,
//                         ),
//                       ),
//                       SizedBox(height: isTabletDevice ? 32 : 24),
//                       Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: isTabletDevice ? 20 : 14,
//                           vertical: isTabletDevice ? 10 : 8,
//                         ),
//                         decoration: BoxDecoration(
//                           color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.5),
//                           borderRadius: BorderRadius.circular(100),
//                           border: Border.all(
//                             color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
//                             width: 1,
//                           ),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const _LivePulseDot(),
//                             const SizedBox(width: 8),
//                             Text(
//                               "Reconnecting smoothly...",
//                               style: TextStyle(
//                                 fontSize: pillFontSize,
//                                 color: bodyColor,
//                                 fontWeight: FontWeight.w600,
//                                 fontFamily: appPoppinFont,
//                                 decoration: TextDecoration.none,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _LivePulseDot extends StatefulWidget {
//   const _LivePulseDot();
//
//   @override
//   State<_LivePulseDot> createState() => _LivePulseDotState();
// }
//
// class _LivePulseDotState extends State<_LivePulseDot> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: Tween<double>(begin: 0.3, end: 1.0).animate(
//         CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//       ),
//       child: Container(
//         width: 8,
//         height: 8,
//         decoration: BoxDecoration(
//           color: lightGreenColor,
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: lightGreenColor,
//               blurRadius: 4,
//               spreadRadius: 1,
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart' hide textLightModeColor, lightGreenColor;
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../services/network_services/domain/neetwork_repo/network_repo.dart';
import '../services/network_services/network_bloc/network_bloc.dart';

class InternetGuard extends StatelessWidget {
  final Widget? child;

  const InternetGuard({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            if (child != null) child!,
            BlocBuilder<NetworkBloc, NetworkState>(
              buildWhen: (previous, current) => previous.status != current.status,
              builder: (context, state) {
                final bool isOffline = state.status == NetworkStatus.offline;

                // Using an AnimatedPositioned to slide the banner smoothly from the bottom boundary
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.fastOutSlowIn,
                  left: 0,
                  right: 0,
                  bottom: isOffline ? 0 : -100, // Hides offscreen when online
                  child: const _OfflineBottomBanner(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBottomBanner extends StatelessWidget {
  const _OfflineBottomBanner();

  @override
  Widget build(BuildContext context) {
    final double screenWidth = displayWidth(context);
    final bool isTabletDevice = isTablet(context);

    // Getting safe bottom padding (e.g., notch/home indicator space on iOS devices)
    final double safeBottomPadding = MediaQuery.paddingOf(context).bottom;

    final double fontSize = isTabletDevice
        ? screenWidth * 0.016
        : screenWidth * 0.034;

    final double iconSize = isTabletDevice ? 22.0 : 18.0;

    return Container(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 14.0,
        bottom: safeBottomPadding > 0 ? safeBottomPadding + 8.0 : 14.0,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade700, // Solid premium red background alert matrix
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: Colors.white,
            size: iconSize,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "No Internet Connection. Waiting for network to stabilize...",
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                fontFamily: appPoppinFont,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const _LivePulseDot(),
        ],
      ),
    );
  }
}

class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot();

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white54,
              blurRadius: 4,
              spreadRadius: 1,
            )
          ],
        ),
      ),
    );
  }
}