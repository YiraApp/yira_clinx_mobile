
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:yiraclinics/core/constants/constants.dart';


import 'change_password_bloc/change_password_bloc.dart';

class PasswordChangeSuccessScreen extends StatefulWidget {
  final bool isUserName;

  const PasswordChangeSuccessScreen({
    super.key,
    this.isUserName = false,
  });

  @override
  State<PasswordChangeSuccessScreen> createState() => _PasswordChangeSuccessScreenState();
}

class _PasswordChangeSuccessScreenState extends State<PasswordChangeSuccessScreen> {

  @override
  void initState() {
    super.initState();
    _handleNavigationFlow();
  }

  void _handleNavigationFlow() {
    if (widget.isUserName) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    } else {
      context.read<ChangePasswordBloc>().add(OnProcessPostChangeLogout());
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isTablet = screenWidth > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseBgColor = isDark ? Colors.black : const Color(0xFFF9FAFC); // Fallback for legacy passwordChangeBg
    final titleColor = isDark ? Colors.white : const Color(0xFF080414);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: BlocListener<ChangePasswordBloc, ChangePasswordState>(
        listener: (context, state) {
          if (state is PostChangeLogoutSuccess) {

          }
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/json/success.json',
                      height: screenHeight * 0.2,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: isTablet ? 24 : screenHeight * 0.02),

                    Text(
                      'Success!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTablet ? screenWidth * 0.04 : screenWidth * 0.075,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Text(
                      widget.isUserName
                          ? 'Your username has been updated successfully!'
                          : 'Your password has been changed successfully. You’ll be redirected shortly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTablet ? screenWidth * 0.024 : screenWidth * 0.035,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}