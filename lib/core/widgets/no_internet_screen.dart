import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/services/network_services/network_bloc/network_bloc.dart';

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  bool _isChecking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    final completer = Completer<bool>();
    context.read<NetworkBloc>().add(RetryNetworkCheckEvent(completer: completer));

    final isSuccess = await completer.future;

    if (!mounted) return;

    if (!isSuccess) {
      setState(() {
        _isChecking = false;
        _errorMessage = "Unable to connect. Please check your Wi-Fi or cellular data.";
      });
    } else {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenWidth = mediaQuery.size.width;
    final isTablet = mediaQuery.size.shortestSide >= 600;

    final Color bgColor = isDarkMode ? const Color(0xff121316) : Colors.white;
    final Color titleColor = isDarkMode ? Colors.white : const Color(0xff1E293B);
    final Color bodyColor = isDarkMode ? const Color(0xff94A3B8) : const Color(0xff64748B);

    final double iconContainerSize = isTablet ? 140.0 : 108.0;
    final double iconSize = isTablet ? 64.0 : 48.0;
    final double titleFontSize = isTablet ? 26.0 : 21.0;
    final double bodyFontSize = isTablet ? 15.0 : 13.5;

    return Material(
      color: bgColor,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 48.0 : 28.0,
              vertical: 24.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),

                // Animated Glowing Icon Container
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: iconContainerSize,
                        height: iconContainerSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.red.shade50.withValues(alpha: isDarkMode ? 0.2 : 0.8),
                              Colors.red.shade100.withValues(alpha: _glowAnimation.value),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: _glowAnimation.value * 0.35),
                              blurRadius: 28,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: iconContainerSize * 0.72,
                            height: iconContainerSize * 0.72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDarkMode ? const Color(0xff221C20) : Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.wifi_off_rounded,
                              size: iconSize,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  "No Internet Connection",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 460 : 320,
                  ),
                  child: Text(
                    "You are currently offline. Please check your Wi-Fi or mobile data network and try again.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: bodyFontSize,
                      height: 1.5,
                      color: bodyColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Live Connection Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xffF1F5F9),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xffE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.shade500,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.shade400.withValues(alpha: 0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isChecking ? "Checking connection..." : "Waiting for network...",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          color: bodyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Error Message if retry failed
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _errorMessage != null
                      ? Padding(
                          key: ValueKey(_errorMessage),
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12.5,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : const SizedBox(key: ValueKey('no_error'), height: 16),
                ),

                // Try Again Button
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 380 : screenWidth,
                    minHeight: 50,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _handleRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appPrimaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: appPrimaryColor.withValues(alpha: 0.65),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: _isChecking
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "Checking Connection...",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  "Try Again",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
