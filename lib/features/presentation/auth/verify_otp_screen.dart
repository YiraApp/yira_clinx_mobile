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
  final bool isSignup;
  const VerifyOtpScreen({
    super.key,
    required this.sendOtpEntity,
    this.isSignup = false,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _cachedFcmToken = '';
  bool _showError = false;
  String _errorText = '';
  bool _isSubmitting = false;
  bool _isVerified = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _loadDeviceToken();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  Future<void> _loadDeviceToken() async {
    final String token = await FcmTokenHelper.getProductionFcmToken();
    if (mounted && token.isNotEmpty) {
      setState(() {
        _cachedFcmToken = token;
      });
      debugPrint(
          "Auth Configuration - Device token initialized successfully.");
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_showError) {
      setState(() {
        _showError = false;
        _errorText = '';
      });
    }
  }

  void _showErrorMessage(String msg) {
    setState(() {
      _showError = true;
      _errorText = msg;
    });
    _shakeController.forward(from: 0);
  }

  void _submitOtp() {
    if (_isSubmitting) return; // Prevent double submission
    _clearError();
    if (otpController.text.length < 6) {
      _showErrorMessage('Please enter a valid 6-digit OTP');
      return;
    }
    setState(() {
      _isSubmitting = true;
    });

    if (widget.isSignup) {
      context.read<LoginBloc>().add(
            OnVerifyAndRegisterPatient(
              otp: otpController.text.trim(),
              sessionId: widget.sendOtpEntity.data?.sessionId,
              fcmToken: _cachedFcmToken,
            ),
          );
    } else {
      final String activeCountryCode =
          context.read<LoginBloc>().currentCountryCode;
      context.read<LoginBloc>().add(
            OnTapMobileSignInEvent(
              mobileNumber: widget.sendOtpEntity.data?.contact ?? '',
              otp: otpController.text.trim(),
              sessionId: widget.sendOtpEntity.data?.sessionId ?? '',
              countryCode: activeCountryCode,
              fcmToken: _cachedFcmToken,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTab = isTablet(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = displayHeight(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                final double referenceWidth =
                    isTab ? constraints.maxWidth : screenWidth;

                return BlocConsumer<LoginBloc, LogInState>(
                  buildWhen: (previous, current) =>
                      current is TimerTick ||
                      current is TimerFinished ||
                      current is SendOtpLoading ||
                      current is ReSendOtpLoading ||
                      current is ReSendOtpSuccessState ||
                      current is ReSendOtpFailureState ||
                      current is SignInLoading ||
                      current is LoginLoading ||
                      current is LoginSuccess ||
                      current is LoginFailure ||
                      current is SignInError ||
                      current is RegisterPatientLoading ||
                      current is RegisterPatientFailureState ||
                      current is SendSignupOtpLoading ||
                      current is SendSignupOtpFailureState,
                  listener: (context, state) {
                    if (state is LoginSuccess) {
                      _clearError();
                      setState(() {
                        _isVerified = true;
                        _isSubmitting = false;
                      });
                      final payload = state.loginEntity.data;
                      final profiles = payload?.profiles ?? [];
                      final hasMultipleProfiles = profiles.length > 1;
                      final hasMultipleRolesOrHospitals =
                          (payload?.roleCount ?? 0) > 1 ||
                              (payload?.hospitalCount ?? 0) > 1;

                      if (!hasMultipleProfiles &&
                          !hasMultipleRolesOrHospitals &&
                          (payload?.roleCount == 1 &&
                              payload?.hospitalCount == 1)) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.userConfiguration,
                          (route) => false,
                        );
                      } else {
                        SelectRoleModel data = SelectRoleModel(
                          state.loginEntity.data?.roles ?? [],
                          false,
                          profiles: payload?.profiles,
                        );
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.selectRoleScreen,
                          (route) => false,
                          arguments: data,
                        );
                      }
                    } else if (state is SignInError) {
                      _isSubmitting = false;
                      _isVerified = false;
                      _showErrorMessage(
                          _parseErrorMessage(state.errorMessage));
                    } else if (state is LoginFailure) {
                      _isSubmitting = false;
                      _isVerified = false;
                      _showErrorMessage(
                          _parseErrorMessage(state.errorMessage ?? 'Verification failed'));
                    } else if (state is RegisterPatientFailureState) {
                      _isSubmitting = false;
                      _isVerified = false;
                      _showErrorMessage(
                          _parseErrorMessage(state.errorMessage));
                    } else if (state is SendSignupOtpFailureState) {
                      _showErrorMessage(
                          _parseErrorMessage(state.errorMessage));
                    } else if (state is ReSendOtpSuccessState) {
                      _clearError();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'OTP resent successfully!',
                              style: TextStyle(fontFamily: appPoppinFont),
                            ),
                            backgroundColor: Colors.green.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } else if (state is ReSendOtpFailureState) {
                      _showErrorMessage(
                          _parseErrorMessage(state.errorMessage));
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

                    final bool isVerifying =
                        (_isSubmitting || state is LoginLoading || state is SignInLoading) && !_isVerified;
                    final bool isResending = state is ReSendOtpLoading;

                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
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
                                crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: screenHeight * 0.02),

                                  // ── App Logo ──
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: primaryColor
                                          .withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(12.0),
                                      child: SvgPicture.asset(
                                        'assets/images/svgs/ic_apps_logo.svg',
                                        width: isTab ? 55 : 48,
                                        height: isTab ? 55 : 48,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: screenHeight * 0.025),

                                  // ── Title ──
                                  Text(
                                    'Verification Code',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: isTab
                                          ? referenceWidth * 0.035
                                          : displayWidth(context) * 0.06,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // ── Subtitle with phone ──
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white
                                              .withValues(alpha: 0.05)
                                          : Colors.grey.shade50,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.sms_outlined,
                                          size: isTab ? 18 : 16,
                                          color: primaryColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: RichText(
                                            textAlign: TextAlign.center,
                                            text: TextSpan(
                                              style: TextStyle(
                                                fontFamily: appPoppinFont,
                                                fontSize: isTab
                                                    ? referenceWidth *
                                                        0.022
                                                    : screenWidth * 0.032,
                                                color: isDark
                                                    ? Colors.white70
                                                    : Colors.black54,
                                              ),
                                              children: [
                                                const TextSpan(
                                                    text:
                                                        'Code sent to '),
                                                TextSpan(
                                                  text:
                                                      '${context.read<LoginBloc>().currentCountryCode}-${widget.sendOtpEntity.data?.contact}',
                                                  style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  SizedBox(
                                    height: screenHeight *
                                        (isTab ? 0.045 : 0.04),
                                  ),

                                  // ── OTP Pin Fields ──
                                  AnimatedBuilder(
                                    animation: _shakeController,
                                    builder: (context, child) {
                                      final shakeOffset =
                                          _shakeController.isAnimating
                                              ? 10 *
                                                  (0.5 -
                                                      _shakeController
                                                          .value) *
                                                  (_shakeController
                                                              .value <
                                                          0.5
                                                      ? 1
                                                      : -1)
                                              : 0.0;
                                      return Transform.translate(
                                        offset: Offset(shakeOffset, 0),
                                        child: child,
                                      );
                                    },
                                    child: SizedBox(
                                      width: isTab
                                          ? referenceWidth * 0.7
                                          : screenWidth * 0.82,
                                      child: PinCodeTextField(
                                        backgroundColor:
                                            Colors.transparent,
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
                                        obscuringCharacter: '●',
                                        hintCharacter: '•',
                                        hintStyle: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: isTab
                                              ? referenceWidth * 0.022
                                              : screenWidth * 0.03,
                                          color: Colors.grey.shade300,
                                        ),
                                        animationType: AnimationType.scale,
                                        pinTheme: PinTheme(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          inactiveColor: _showError
                                              ? Colors.red.shade300
                                              : (isDark
                                                  ? Colors.white24
                                                  : Colors.grey.shade300),
                                          activeColor: _showError
                                              ? Colors.red
                                              : primaryColor,
                                          selectedColor: primaryColor,
                                          errorBorderColor: Colors.red,
                                          shape: PinCodeFieldShape.box,
                                          borderWidth: 1.5,
                                          fieldHeight: isTab
                                              ? referenceWidth * 0.09
                                              : screenWidth * 0.12,
                                          fieldWidth: isTab
                                              ? referenceWidth * 0.09
                                              : screenWidth * 0.12,
                                          inactiveFillColor:
                                              Theme.of(context).cardColor,
                                          activeFillColor:
                                              Theme.of(context).cardColor,
                                          selectedFillColor:
                                              Theme.of(context).cardColor,
                                        ),
                                        cursorColor: primaryColor,
                                        cursorHeight: 18,
                                        enableActiveFill: true,
                                        animationDuration:
                                            const Duration(
                                                milliseconds: 200),
                                        textStyle: TextStyle(
                                          fontSize: isTab
                                              ? referenceWidth * 0.032
                                              : 18,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: appPoppinFont,
                                        ),
                                        keyboardType:
                                            TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        onCompleted: (pinCode) {
                                          _submitOtp();
                                        },
                                        onChanged: (value) {
                                          _clearError();
                                        },
                                      ),
                                    ),
                                  ),

                                  // ── Error Message ──
                                  AnimatedSize(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                    child: _showError
                                        ? Padding(
                                            padding:
                                                const EdgeInsets.only(
                                                    top: 4, bottom: 8),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.red
                                                    .withValues(
                                                        alpha: 0.08),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        10),
                                                border: Border.all(
                                                    color: Colors.red
                                                        .withValues(
                                                            alpha: 0.2)),
                                              ),
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                      Icons
                                                          .error_outline_rounded,
                                                      size: 16,
                                                      color: Colors
                                                          .red.shade600),
                                                  const SizedBox(
                                                      width: 8),
                                                  Flexible(
                                                    child: Text(
                                                      _errorText,
                                                      style: TextStyle(
                                                        fontFamily:
                                                            appPoppinFont,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight
                                                                .w500,
                                                        color: Colors.red
                                                            .shade700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),

                                  SizedBox(
                                      height: screenHeight * 0.012),

                                  // ── Resend Section ──
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white
                                              .withValues(alpha: 0.03)
                                          : Colors.grey.shade50,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: isResending
                                        ? Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation(
                                                          primaryColor),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Sending new code...',
                                                style: TextStyle(
                                                  fontFamily:
                                                      appPoppinFont,
                                                  fontSize: 13,
                                                  color: isDark
                                                      ? Colors.white60
                                                      : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          )
                                        : isButtonActive
                                            ? Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    "Didn't receive the code?",
                                                    style: TextStyle(
                                                      fontFamily:
                                                          appPoppinFont,
                                                      fontSize: isTab
                                                          ? referenceWidth *
                                                              0.024
                                                          : 13,
                                                      color: isDark
                                                          ? Colors
                                                              .white60
                                                          : Colors
                                                              .black54,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width: 6),
                                                  GestureDetector(
                                                    onTap: () {
                                                      _clearError();
                                                      final String
                                                          activeCountryCode =
                                                          context
                                                              .read<
                                                                  LoginBloc>()
                                                              .currentCountryCode;
                                                      if (widget.isSignup) {
                                                        final draft = context
                                                            .read<LoginBloc>()
                                                            .currentSignupDraft;
                                                        if (draft != null) {
                                                          context
                                                              .read<LoginBloc>()
                                                              .add(
                                                                OnInitiateSignup(
                                                                  mobileNumber:
                                                                      draft.phoneNumber,
                                                                  countryCode:
                                                                      draft.countryCode,
                                                                  firstName:
                                                                      draft.firstName,
                                                                  lastName:
                                                                      draft.lastName,
                                                                  email: draft.email,
                                                                  password:
                                                                      draft.password,
                                                                  profileImagePath:
                                                                      draft.profileImagePath,
                                                                ),
                                                              );
                                                        }
                                                      } else {
                                                        context
                                                            .read<LoginBloc>()
                                                            .add(
                                                              OnReSendOtp(
                                                                widget
                                                                        .sendOtpEntity
                                                                        .data
                                                                        ?.contact ??
                                                                    '',
                                                                activeCountryCode,
                                                              ),
                                                            );
                                                      }
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal:
                                                                  12,
                                                              vertical:
                                                                  4),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: primaryColor
                                                            .withValues(
                                                                alpha:
                                                                    0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    8),
                                                      ),
                                                      child: Text(
                                                        'Resend',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              appPoppinFont,
                                                          fontSize: isTab
                                                              ? referenceWidth *
                                                                  0.026
                                                              : 13,
                                                          fontWeight:
                                                              FontWeight
                                                                  .w600,
                                                          color:
                                                              primaryColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.timer_outlined,
                                                    size: 16,
                                                    color: isDark
                                                        ? Colors.white38
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(
                                                      width: 6),
                                                  Text(
                                                    'Resend in ',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          appPoppinFont,
                                                      fontSize: 13,
                                                      color: isDark
                                                          ? Colors
                                                              .white38
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 8,
                                                            vertical: 2),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: primaryColor
                                                          .withValues(
                                                              alpha:
                                                                  0.08),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                                  6),
                                                    ),
                                                    child: Text(
                                                      '00:${displaySeconds.toString().padLeft(2, '0')}',
                                                      style: TextStyle(
                                                        fontFamily:
                                                            appPoppinFont,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight
                                                                .w700,
                                                        color:
                                                            primaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                  ),

                                  const Spacer(),

                                  // ── Verify Button ──
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: isTab
                                          ? screenHeight * 0.04
                                          : 24.0,
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                          milliseconds: 250),
                                      child: (_isVerified || state is LoginSuccess)
                                          ? SizedBox(
                                              key: const ValueKey('verified'),
                                              width: displayWidth(context),
                                              height: 52,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.green
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: Colors.green
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .check_circle_rounded,
                                                        color: Colors
                                                            .green.shade600,
                                                        size: 22,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        'Verified!',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              appPoppinFont,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors
                                                              .green.shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                          : isVerifying
                                              ? SizedBox(
                                                  key: const ValueKey(
                                                      'loading'),
                                                  width:
                                                      displayWidth(context),
                                                  height: 52,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: primaryColor
                                                          .withValues(
                                                              alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(14),
                                                    ),
                                                    child: Center(
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth:
                                                                  2.5,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation(
                                                                      primaryColor),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 12),
                                                          Text(
                                                            'Verifying...',
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  appPoppinFont,
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  primaryColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : CustomElevatedButton(
                                                  key: const ValueKey(
                                                      'button'),
                                                  noElevation: true,
                                                  height: 52,
                                                  width: double.infinity,
                                                  text: "Verify & Continue",
                                                  onPressed: _submitOtp,
                                                ),
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

  /// Parse backend error messages into user-friendly text
  String _parseErrorMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid otp') || lower.contains('invalid code')) {
      return 'Invalid OTP. Please check and try again.';
    }
    if (lower.contains('expired')) {
      return 'OTP has expired. Please request a new one.';
    }
    if (lower.contains('too many') || lower.contains('rate limit')) {
      return 'Too many attempts. Please wait and try again.';
    }
    if (lower.contains('network') ||
        lower.contains('timeout') ||
        lower.contains('connection')) {
      return 'Network error. Please check your connection.';
    }
    if (lower.contains('exception') ||
        lower.contains('error') && raw.length > 80) {
      return 'Verification failed. Please try again.';
    }
    // Truncate very long messages
    if (raw.length > 60) {
      return '${raw.substring(0, 57)}...';
    }
    return raw;
  }
}
