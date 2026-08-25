import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/features/domain/entities/send_otp/send_otp_entity.dart';
import 'package:yiraclinics/features/presentation/auth/login_bloc/login_bloc.dart';

import '../../../core/colors/colors.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/custom_button.dart';
import '../../../core/constants/constants.dart';
import '../../../core/fcm_token/fcm_token_helper.dart';
import '../../../core/models/select_role_model.dart';

class VerifyOtpScreen extends StatefulWidget {
  final SendOtpEntity sendOtpEntity;
  const VerifyOtpScreen({super.key, required this.sendOtpEntity});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController otpController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  String _cachedFcmToken = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceToken();
  }

  Future<void> _loadDeviceToken() async {
    final String token = await FcmTokenHelper.getProductionFcmToken();
    if (mounted && token.isNotEmpty) {
      setState(() {
        _cachedFcmToken = token;
      });
      debugPrint("Auth Configuration - Device token initialized successfully.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTab = isTablet(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = displayHeight(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTab ? 550 : double.infinity,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double referenceWidth = isTab
                    ? constraints.maxWidth
                    : screenWidth;

                return BlocConsumer<LoginBloc, LogInState>(
                  buildWhen: (previous, current) =>
                      current is TimerTick ||
                      current is TimerFinished ||
                      current is SendOtpLoading ||
                      current is ReSendOtpLoading ||
                      current is SignInLoading ||
                      current is LoginLoading ||
                      current is SignInError,
                  listener: (context, state) {
                    switch (state) {
                      case LoginSuccess():
                        final payload = state.loginEntity.data;
                        if (payload != null &&
                            payload.roleCount == 1 &&
                            payload.hospitalCount == 1 &&
                            payload.organizationCount == 1) {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.userConfiguration,
                            (route) => false,
                          );
                        } else {
                          SelectRoleModel data = SelectRoleModel(
                            state.loginEntity.data?.roles ?? [],
                            false,
                          );
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.selectRoleScreen,
                            (route) => false,
                            arguments: data,
                          );
                        }
                        break;
                      default:
                        break;
                    }
                  },
                  builder: (context, state) {
                    int displaySeconds = 0;
                    bool isButtonActive = false;

                    if (state is TimerTick) {
                      displaySeconds = state.secondsRemaining;
                      isButtonActive = false;
                    } else if (state is TimerFinished) {
                      displaySeconds = 0;
                      isButtonActive = true;
                    } else if (state is SignInLoading) {
                      isButtonActive = false;
                    } else {
                      isButtonActive = true;
                    }
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenHorizontalSpacePadding,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: screenHeight * 0.02),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: SvgPicture.asset(
                                      'assets/images/svgs/ic_apps_logo.svg',
                                      width: isTab ? 65 : 60,
                                      height: isTab ? 65 : 60,
                                    ),
                                  ),

                                  SizedBox(height: screenHeight * 0.03),
                                  Text(
                                    'Verification Code',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: isTab
                                          ? referenceWidth * 0.035
                                          : displayWidth(context) * 0.065,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTab
                                          ? referenceWidth * 0.02
                                          : screenHorizontalSpacePadding,
                                    ),
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          "We've sent a 6-digit code to ",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: isTab
                                                ? referenceWidth * 0.022
                                                : screenWidth * 0.033,
                                          ),
                                        ),
                                        Text(
                                          '${context.read<LoginBloc>().currentCountryCode}-${widget.sendOtpEntity.data?.contact}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: isTab
                                                ? referenceWidth * 0.022
                                                : screenWidth * 0.033,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(
                                    height:
                                        screenHeight * (isTab ? 0.05 : 0.045),
                                  ),

                                  SizedBox(
                                    width: isTab
                                        ? referenceWidth * 0.7
                                        : screenWidth * 0.82,
                                    child: PinCodeTextField(
                                      backgroundColor: Colors.transparent,
                                      autoDisposeControllers: false,
                                      controller: otpController,
                                      appContext: context,
                                      pastedTextStyle: TextStyle(
                                        fontFamily: appPoppinFont,
                                        color: Colors.green.shade600,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      length: 6,
                                      obscureText: true,
                                      obscuringCharacter: '*',
                                      hintCharacter: '*',
                                      hintStyle: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: isTab
                                            ? referenceWidth * 0.022
                                            : screenWidth * 0.03,
                                      ),
                                      animationType: AnimationType.fade,
                                      validator: (v) {
                                        if (v == null || v.length < 6) {
                                          return "Please enter a valid 6-digit OTP";
                                        }
                                        return null;
                                      },
                                      pinTheme: PinTheme(
                                        borderRadius: BorderRadius.circular(
                                          fieldBorderRadius,
                                        ),
                                        inactiveColor: notificationSwitchColor,
                                        activeColor: primaryColor,
                                        selectedColor: primaryColor,
                                        shape: PinCodeFieldShape.box,
                                        borderWidth: 1.0,
                                        fieldHeight: isTab
                                            ? referenceWidth * 0.09
                                            : screenWidth * 0.11,
                                        fieldWidth: isTab
                                            ? referenceWidth * 0.09
                                            : screenWidth * 0.11,
                                        inactiveFillColor: Theme.of(
                                          context,
                                        ).cardColor,
                                        activeFillColor: Theme.of(
                                          context,
                                        ).cardColor,
                                        selectedFillColor: Theme.of(
                                          context,
                                        ).cardColor,
                                      ),
                                      cursorColor: Colors.grey,
                                      animationDuration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      textStyle: TextStyle(
                                        fontSize: isTab
                                            ? referenceWidth * 0.03
                                            : 16,
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      onCompleted: (pinCode) {
                                        final String activeCountryCode = context
                                            .read<LoginBloc>()
                                            .currentCountryCode;
                                        context.read<LoginBloc>().add(
                                          OnTapMobileSignInEvent(
                                            mobileNumber:
                                                widget
                                                    .sendOtpEntity
                                                    .data
                                                    ?.contact ??
                                                '',
                                            otp: pinCode,
                                            sessionId:
                                                widget
                                                    .sendOtpEntity
                                                    .data
                                                    ?.sessionId ??
                                                '',
                                            countryCode: activeCountryCode,
                                            fcmToken: _cachedFcmToken,
                                          ),
                                        );
                                      },
                                      onChanged: (value) {},
                                    ),
                                  ),
                                  SizedBox(height: screenHeight * 0.02),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: isTab
                                            ? referenceWidth * 0.038
                                            : 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Didn't receive the code?",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: isTab
                                              ? referenceWidth * 0.028
                                              : screenWidth * 0.035,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // 6. Resend Engine Handler UI
                                  state is ReSendOtpLoading
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: SizedBox(
                                            height: 40,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator.adaptive(),
                                            ),
                                          ),
                                        )
                                      : isButtonActive
                                      ? TextButton(
                                          onPressed: () {
                                            final String activeCountryCode =
                                                context
                                                    .read<LoginBloc>()
                                                    .currentCountryCode;
                                            context.read<LoginBloc>().add(
                                              OnReSendOtp(
                                                widget
                                                        .sendOtpEntity
                                                        .data
                                                        ?.contact ??
                                                    '',
                                                activeCountryCode,
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Re-send',
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontSize: isTab
                                                  ? referenceWidth * 0.034
                                                  : screenWidth * 0.035,
                                              fontWeight: FontWeight.w600,
                                              color: primaryColor,
                                            ),
                                          ),
                                        )
                                      : Column(
                                          children: [
                                            const SizedBox(height: 10),
                                            Text(
                                              'Resend available in',
                                              style: TextStyle(
                                                fontFamily: appPoppinFont,
                                                fontSize: isTab
                                                    ? referenceWidth * 0.025
                                                    : screenWidth * 0.032,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '00:${displaySeconds.toString().padLeft(2, '0')}',
                                              style: TextStyle(
                                                fontFamily: appPoppinFont,
                                                fontSize: isTab
                                                    ? referenceWidth * 0.028
                                                    : screenWidth * 0.034,
                                                fontWeight: FontWeight.w600,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),

                                  const Spacer(),

                                  state is LoginLoading
                                      ? Padding(
                                          padding: EdgeInsets.only(
                                            bottom: screenHeight * 0.04,
                                          ),
                                          child: SizedBox(
                                            width: displayWidth(context),
                                            height: 50,
                                            child: Center(
                                              child:
                                                  CircularProgressIndicator.adaptive(),
                                            ),
                                          ),
                                        )
                                      : Padding(
                                          padding: EdgeInsets.only(
                                            bottom: isTab
                                                ? screenHeight * 0.04
                                                : 24.0,
                                          ),
                                          child: CustomElevatedButton(
                                            noElevation: true,
                                            height: 50,
                                            width: double.infinity,
                                            text: "Verify & Continue",
                                            onPressed: () {
                                              final String activeCountryCode =
                                                  context
                                                      .read<LoginBloc>()
                                                      .currentCountryCode;
                                              context.read<LoginBloc>().add(
                                                OnTapMobileSignInEvent(
                                                  mobileNumber:
                                                      widget
                                                          .sendOtpEntity
                                                          .data
                                                          ?.contact ??
                                                      '',
                                                  otp: otpController.text,
                                                  sessionId:
                                                      widget
                                                          .sendOtpEntity
                                                          .data
                                                          ?.sessionId ??
                                                      '',
                                                  countryCode:
                                                      activeCountryCode,
                                                  fcmToken: _cachedFcmToken,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
