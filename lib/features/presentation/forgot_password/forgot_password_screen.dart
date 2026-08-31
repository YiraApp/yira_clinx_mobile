import 'package:country_code_picker/country_code_picker.dart';
import 'package:fancy_password_field/fancy_password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/features/use_cases/forget_password_send_otp_use_case.dart';
import '../../../core/common_appbar/common_app_bar.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/custom_button.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/dismiss_key_board.dart';
import 'forgot_password_bloc/forgot_password_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FancyPasswordController _passwordController = FancyPasswordController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode mobileFocus = FocusNode();
  final FocusNode otpFocus = FocusNode();
  final FocusNode newPasswordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  final GlobalKey<FormState> mobileFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> emailFormKey = GlobalKey<FormState>();

  late TabController _tabController;
  int _activeTabIndex = 0;
  bool _obscureConfirmPassword = true;

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _successEmerald = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _activeTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    mobileNumberController.dispose();
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    emailFocus.dispose();
    mobileFocus.dispose();
    otpFocus.dispose();
    newPasswordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTabletDevice = isTablet(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double screenHeight = displayHeight(context);
    final double referenceWidth = displayWidth(context);

    return GestureDetector(
      onTap: () => context.dismissKeyboard(),
      child: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
        buildWhen: (previous, state) => state is! NavigateToSignIn,
        listener: (context, state) {
          if (state is NavigateToSignIn) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.signIn,
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          final bool isLoading = state is ForgotPasswordLoading;
          final bloc = context.read<ForgotPasswordBloc>();

          final bool isPasswordStep =
              state is ShowPasswordResetFields ||
              bloc.currentStep == RecoveryStep.passwordPhase;
          final bool isOtpStep =
              !isPasswordStep &&
              (state is ShowOtpField ||
                  state is ReSendOtpLoading ||
                  bloc.currentStep == RecoveryStep.otpPhase);

          final int currentStageNumber = isPasswordStep ? 3 : (isOtpStep ? 2 : 1);

          return PopScope(
            canPop: !isOtpStep && !isPasswordStep,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              _handleBackNavigation(context);
            },
            child: AbsorbPointer(
              absorbing: isLoading,
              child: Scaffold(
                backgroundColor: isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                appBar: CommonAppBar(
                  actions: const [],
                  onBackPressed: () => _handleBackNavigation(context),
                ),
                body: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTabletDevice ? 560 : double.infinity,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double refWidth = isTabletDevice
                            ? constraints.maxWidth
                            : referenceWidth;

                        return SizedBox(
                          width: double.infinity,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: isTabletDevice ? 32 : 20,
                              vertical: 12,
                            ),
                            child: Column(
                              children: [
                                // 1. Top Step Progress Tracker
                                _buildStepProgressTracker(
                                  currentStage: currentStageNumber,
                                  isDarkMode: isDarkMode,
                                ),
                                const SizedBox(height: 24),

                                // 2. Header Icon Badge & Title
                                _buildHeaderBadge(
                                  isPasswordStep: isPasswordStep,
                                  isOtpStep: isOtpStep,
                                  isDarkMode: isDarkMode,
                                  refWidth: refWidth,
                                  isTabletDevice: isTabletDevice,
                                ),
                                const SizedBox(height: 24),

                                // 3. Main Form Card with Animated Transition
                                Container(
                                  padding: EdgeInsets.all(isTabletDevice ? 28 : 20),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDarkMode
                                            ? Colors.black.withValues(alpha: 0.3)
                                            : const Color(0xFF64748B).withValues(alpha: 0.06),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 350),
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0, 0.05),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _buildStepContent(
                                      context: context,
                                      state: state,
                                      isDarkMode: isDarkMode,
                                      isTab: isTabletDevice,
                                      refWidth: refWidth,
                                      screenHeight: screenHeight,
                                      isOtpStep: isOtpStep,
                                      isPasswordStep: isPasswordStep,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // 4. Bottom "Sign In" helper row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Remembered your password? ",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: isTabletDevice ? 14 : 13,
                                        color: isDarkMode
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context
                                            .read<ForgotPasswordBloc>()
                                            .add(NavSignInClicked());
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 2),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: _primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP PROGRESS TRACKER (3 STAGES)
  // -------------------------------------------------------------
  Widget _buildStepProgressTracker({
    required int currentStage,
    required bool isDarkMode,
  }) {
    final steps = [
      {"num": 1, "label": "Identify"},
      {"num": 2, "label": "Verify"},
      {"num": 3, "label": "Reset"},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepBeforeIndex = index ~/ 2;
            final isPassed = currentStage > (stepBeforeIndex + 1);
            return Expanded(
              child: Container(
                height: 2.5,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isPassed
                      ? _successEmerald
                      : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final stepNum = steps[stepIndex]["num"] as int;
          final stepLabel = steps[stepIndex]["label"] as String;
          final bool isCurrent = currentStage == stepNum;
          final bool isDone = currentStage > stepNum;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? _successEmerald
                      : (isCurrent ? _primaryBlue : Colors.transparent),
                  border: Border.all(
                    color: isDone
                        ? _successEmerald
                        : (isCurrent
                            ? _primaryBlue
                            : (isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1))),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                      : Text(
                          '$stepNum',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? Colors.white
                                : (isDarkMode ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                stepLabel,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent
                      ? (isDarkMode ? Colors.white : const Color(0xFF0F172A))
                      : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // -------------------------------------------------------------
  // HEADER BADGE & TITLE
  // -------------------------------------------------------------
  Widget _buildHeaderBadge({
    required bool isPasswordStep,
    required bool isOtpStep,
    required bool isDarkMode,
    required double refWidth,
    required bool isTabletDevice,
  }) {
    IconData headerIcon;
    List<Color> gradientColors;
    String titleText;
    String subtitleText;

    if (isPasswordStep) {
      headerIcon = Icons.lock_open_rounded;
      gradientColors = const [Color(0xFF10B981), Color(0xFF059669)];
      titleText = 'Create New Password';
      subtitleText = 'Your identity is verified. Enter a secure new password for your account.';
    } else if (isOtpStep) {
      headerIcon = Icons.shield_outlined;
      gradientColors = const [Color(0xFF2563EB), Color(0xFF06B6D4)];
      titleText = 'Verify Security Code';
      subtitleText = 'Enter the 6-digit OTP sent to your registered contact to continue.';
    } else {
      headerIcon = Icons.lock_reset_rounded;
      gradientColors = const [Color(0xFF2563EB), Color(0xFF1D4ED8)];
      titleText = 'Forgot Password?';
      subtitleText = 'No worries! Select a recovery method below to receive a secure verification code.';
    }

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              headerIcon,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          titleText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: isTabletDevice ? 24 : 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            subtitleText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTabletDevice ? 13.5 : 12.5,
              height: 1.5,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP CONTENT ROUTER
  // -------------------------------------------------------------
  Widget _buildStepContent({
    required BuildContext context,
    required ForgotPasswordState state,
    required bool isDarkMode,
    required bool isTab,
    required double refWidth,
    required double screenHeight,
    required bool isOtpStep,
    required bool isPasswordStep,
  }) {
    if (isPasswordStep) {
      return KeyedSubtree(
        key: const ValueKey('step_password'),
        child: _buildNewPasswordForm(context, isTab, refWidth, isDarkMode, state),
      );
    } else if (isOtpStep) {
      return KeyedSubtree(
        key: const ValueKey('step_otp'),
        child: _buildOtpVerificationForm(
          context,
          state,
          isTab,
          refWidth,
          screenHeight,
          isDarkMode,
        ),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('step_initial'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Segmented Tab Selector
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: _primaryBlue,
              unselectedLabelColor: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              indicator: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_iphone_rounded, size: 16),
                      SizedBox(width: 6),
                      Text("Mobile OTP"),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.alternate_email_rounded, size: 16),
                      SizedBox(width: 6),
                      Text("Email OTP"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _activeTabIndex == 0
              ? _buildMobileForm(context, isDarkMode, isTab, refWidth, state)
              : _buildEmailForm(context, isDarkMode, isTab, refWidth, state),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // FORM: MOBILE IDENTIFIER
  // -------------------------------------------------------------
  Widget _buildMobileForm(
    BuildContext context,
    bool isDarkMode,
    bool isTab,
    double refWidth,
    ForgotPasswordState state,
  ) {
    return Form(
      key: mobileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_android_rounded, size: 16, color: _primaryBlue),
              const SizedBox(width: 6),
              Text(
                'Registered Mobile Number *',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: [
                CountryCodePicker(
                  onChanged: (country) {
                    if (country.dialCode != null) {
                      context.read<ForgotPasswordBloc>().add(
                            OnCountryCodeChangedEvent(country.dialCode!),
                          );
                    }
                  },
                  showFlag: true,
                  showFlagDialog: true,
                  initialSelection: 'IN',
                  favorite: const ['IN', 'US'],
                  textStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                  dialogBackgroundColor:
                      isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                  dialogTextStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                  searchDecoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: _primaryBlue),
                    hintText: "Search Country",
                    hintStyle: TextStyle(
                      fontFamily: appPoppinFont,
                      color: isDarkMode ? Colors.white54 : Colors.black45,
                    ),
                    filled: true,
                    fillColor: isDarkMode
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
                Expanded(
                  child: TextFormField(
                    controller: mobileNumberController,
                    focusNode: mobileFocus,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: "10-digit mobile number",
                      hintStyle: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 13.5,
                        color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a phone number';
                      } else if (value.trim().length != 10) {
                        return 'Please enter a valid 10-digit phone number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          state is ForgotPasswordLoading
              ? _buildLoadingButton()
              : CustomElevatedButton(
                  noElevation: true,
                  height: 50,
                  width: double.infinity,
                  text: "Send Verification Code",
                  onPressed: () {
                    context.dismissKeyboard();
                    if (mobileFormKey.currentState!.validate()) {
                      final String activeCountryCode = context
                          .read<ForgotPasswordBloc>()
                          .currentCountryCode;
                      var forgetPasswordParams = ForgetPasswordSendOtpParams(
                        contactType: "mobile",
                        countryCode: activeCountryCode,
                        identity: mobileNumberController.text.trim(),
                        isResend: false,
                      );
                      context.read<ForgotPasswordBloc>().add(
                            ForgotPasswordSendOtp(forgetPasswordParams),
                          );
                    }
                  },
                ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // FORM: EMAIL IDENTIFIER
  // -------------------------------------------------------------
  Widget _buildEmailForm(
    BuildContext context,
    bool isDarkMode,
    bool isTab,
    double refWidth,
    ForgotPasswordState state,
  ) {
    return Form(
      key: emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded, size: 16, color: _primaryBlue),
              const SizedBox(width: 6),
              Text(
                'Registered Email Address *',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            child: TextFormField(
              controller: emailController,
              focusNode: emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined, size: 20, color: _primaryBlue),
                hintText: "e.g. yourname@gmail.com",
                hintStyle: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13.5,
                  color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your registered email';
                }
                final String trimmedValue = value.trim();
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(trimmedValue)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),

          state is ForgotPasswordLoading
              ? _buildLoadingButton()
              : CustomElevatedButton(
                  noElevation: true,
                  height: 50,
                  width: double.infinity,
                  text: "Send Verification Code",
                  onPressed: () {
                    context.dismissKeyboard();
                    if (emailFormKey.currentState!.validate()) {
                      var forgetPasswordParams = ForgetPasswordSendOtpParams(
                        contactType: "email",
                        countryCode: '',
                        identity: emailController.text.trim(),
                        isResend: false,
                      );
                      context.read<ForgotPasswordBloc>().add(
                            ForgotPasswordSendOtp(forgetPasswordParams),
                          );
                    }
                  },
                ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // FORM: OTP VERIFICATION (STEP 2)
  // -------------------------------------------------------------
  Widget _buildOtpVerificationForm(
    BuildContext context,
    ForgotPasswordState state,
    bool isTab,
    double refWidth,
    double screenHeight,
    bool isDarkMode,
  ) {
    final blocCache = context.read<ForgotPasswordBloc>();
    final int displaySeconds = state is ShowOtpField
        ? state.displaySeconds
        : blocCache.cachedSeconds;
    final bool isButtonActive = state is ShowOtpField
        ? state.isButtonActive
        : blocCache.cachedBtnActive;
    final String recoveryTarget = state is ShowOtpField
        ? state.recoveryTarget
        : blocCache.cachedTarget;

    final bool isEmailTarget = recoveryTarget.contains('@');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Target Recipient Pill Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _primaryBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _primaryBlue.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isEmailTarget ? Icons.email_rounded : Icons.phone_android_rounded,
                color: _primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recoveryTarget.isNotEmpty
                      ? recoveryTarget
                      : "Registered Contact",
                  style: const TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _primaryBlue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => _handleBackNavigation(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "Change",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _primaryBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.edit_rounded, size: 13, color: _primaryBlue),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Center(
          child: Text(
            'Enter 6-Digit OTP Code',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // PIN Code Input Field
        Center(
          child: SizedBox(
            width: isTab ? refWidth * 0.75 : double.infinity,
            child: PinCodeTextField(
              backgroundColor: Colors.transparent,
              autoDisposeControllers: false,
              controller: otpController,
              focusNode: otpFocus,
              appContext: context,
              pastedTextStyle: const TextStyle(
                fontFamily: appPoppinFont,
                color: _successEmerald,
                fontWeight: FontWeight.bold,
              ),
              length: 6,
              obscureText: false,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                borderRadius: BorderRadius.circular(12),
                shape: PinCodeFieldShape.box,
                fieldHeight: isTab ? 54 : 48,
                fieldWidth: isTab ? 50 : 44,
                borderWidth: 1.5,
                inactiveColor: isDarkMode
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
                activeColor: _primaryBlue,
                selectedColor: _primaryBlue,
                inactiveFillColor: isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                activeFillColor: isDarkMode
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                selectedFillColor: isDarkMode
                    ? const Color(0xFF1E293B)
                    : Colors.white,
              ),
              enableActiveFill: true,
              cursorColor: _primaryBlue,
              animationDuration: const Duration(milliseconds: 250),
              textStyle: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onCompleted: (pinCode) {
                context.dismissKeyboard();
                context.read<ForgotPasswordBloc>().add(
                      VerifyOtpClicked(otp: pinCode),
                    );
              },
              onChanged: (value) {},
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Resend Timer Row
        Center(
          child: isButtonActive
              ? OutlinedButton.icon(
                  onPressed: () {
                    context.read<ForgotPasswordBloc>().add(
                          ResendOtpRequested(target: recoveryTarget),
                        );
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: _primaryBlue),
                  label: const Text(
                    "Resend Verification Code",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _primaryBlue,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 15, color: _primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        "Resend available in ",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12.5,
                          color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '00:${displaySeconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
        ),

        const SizedBox(height: 24),

        // Verify Button
        state is ForgotPasswordLoading
            ? _buildLoadingButton()
            : CustomElevatedButton(
                noElevation: true,
                height: 50,
                width: double.infinity,
                text: "Verify & Continue",
                onPressed: () {
                  context.dismissKeyboard();
                  context.read<ForgotPasswordBloc>().add(
                        VerifyOtpClicked(otp: otpController.text.trim()),
                      );
                },
              ),
      ],
    );
  }

  // -------------------------------------------------------------
  // FORM: NEW PASSWORD RESET (STEP 3)
  // -------------------------------------------------------------
  Widget _buildNewPasswordForm(
    BuildContext context,
    bool isTab,
    double refWidth,
    bool isDark,
    ForgotPasswordState state,
  ) {
    final bloc = context.read<ForgotPasswordBloc>();

    final double strengthValue = state is ShowPasswordResetFields
        ? state.passwordStrength
        : bloc.cachedStrength;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 16, color: _primaryBlue),
              const SizedBox(width: 6),
              Text(
                'New Password *',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          FancyPasswordField(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            passwordController: _passwordController,
            controller: newPasswordController,
            focusNode: newPasswordFocus,
            textInputAction: TextInputAction.next,
            cursorColor: _primaryBlue,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a new password';
              }
              return null;
            },
            showPasswordWidget: Icon(
              Icons.visibility_rounded,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              size: 20,
            ),
            hidePasswordWidget: Icon(
              Icons.visibility_off_rounded,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              size: 20,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Enter strong password',
              hintStyle: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13.5,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: _primaryBlue,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (value) {
              context.read<ForgotPasswordBloc>().add(
                    PasswordInputChanged(password: value),
                  );
            },
            validationRules: {
              MinCharactersValidationRule(8, customText: '8+ Characters'),
              UppercaseValidationRule(customText: 'Uppercase Letter'),
              DigitValidationRule(customText: 'At least 1 Number', showName: true),
              SpecialCharacterValidationRule(customText: 'Special Symbol (\$?!#&@%*)'),
            },
            strengthIndicatorBuilder: (strength) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: _buildPasswordStrengthBar(strengthValue, isDark),
              );
            },
            validationRuleBuilder: (rules, value) {
              if (value.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rules.map((rule) {
                    bool isValid = rule.validate(value);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.0),
                      child: Row(
                        children: [
                          Icon(
                            isValid
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isValid ? _successEmerald : (isDark ? Colors.white38 : Colors.black26),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rule.name,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12,
                              fontWeight: isValid ? FontWeight.w600 : FontWeight.w400,
                              color: isValid
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              const Icon(Icons.lock_reset_rounded, size: 16, color: _primaryBlue),
              const SizedBox(width: 6),
              Text(
                'Confirm New Password *',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            child: TextFormField(
              controller: confirmPasswordController,
              focusNode: confirmPasswordFocus,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: "Re-enter new password",
                hintStyle: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13.5,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your new password';
                } else if (newPasswordController.text != confirmPasswordController.text) {
                  return "Passwords do not match";
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),

          state is ForgotPasswordLoading
              ? _buildLoadingButton()
              : CustomElevatedButton(
                  noElevation: true,
                  height: 50,
                  width: double.infinity,
                  text: "Reset Password",
                  onPressed: () {
                    context.dismissKeyboard();
                    if (_formKey.currentState!.validate()) {
                      context.read<ForgotPasswordBloc>().add(
                            UpdatePasswordFields(
                              newPassword: newPasswordController.text.trim(),
                              confirmPassword: confirmPasswordController.text.trim(),
                            ),
                          );
                    }
                  },
                ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PASSWORD STRENGTH BAR
  // -------------------------------------------------------------
  Widget _buildPasswordStrengthBar(double strength, bool isDark) {
    String label = "Too Weak";
    Color barColor = const Color(0xFFEF4444);
    int activeBars = 1;

    if (strength >= 0.8) {
      label = "Strong Password";
      barColor = _successEmerald;
      activeBars = 3;
    } else if (strength >= 0.4) {
      label = "Moderate";
      barColor = const Color(0xFFF59E0B);
      activeBars = 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Strength:",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(3, (index) {
            final isFilled = index < activeBars;
            return Expanded(
              child: Container(
                height: 4.5,
                margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  color: isFilled
                      ? barColor
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _primaryBlue.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
  }

  void _handleBackNavigation(BuildContext context) {
    final bloc = context.read<ForgotPasswordBloc>();
    if (bloc.currentStep == RecoveryStep.passwordPhase ||
        bloc.currentStep == RecoveryStep.otpPhase) {
      bloc.add(OnBackProgressClicked());
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.signIn,
        (route) => false,
      );
    }
  }
}
