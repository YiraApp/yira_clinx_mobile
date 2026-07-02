import 'package:country_code_picker/country_code_picker.dart';
import 'package:fancy_password_field/fancy_password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/features/use_cases/forget_password_send_otp_use_case.dart';
import '../../../core/common_appbar/common_app_bar.dart';
import '../../../core/common_input_fields/common_input_field.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_button.dart';
import '../../../core/constants/constants.dart';
import '../../../core/custom_stepper/custom_stepper.dart';
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
  final TextEditingController confirmPasswordController =
      TextEditingController();

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

          return PopScope(
            canPop: !isOtpStep && !isPasswordStep,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              _handleBackNavigation(context);
            },
            child: AbsorbPointer(
              absorbing: isLoading,
              child: Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                appBar: CommonAppBar(
                  actions: const [],
                  onBackPressed: () => _handleBackNavigation(context),
                ),
                body: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTabletDevice ? 550 : double.infinity,
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
                            child: Column(
                              children: [
                                /*if (isLoading)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 16.0),
                                    child: LinearProgressIndicator(),
                                  ),*/
                                Icon(
                                  isPasswordStep
                                      ? Icons.lock_open
                                      : (isOtpStep
                                            ? Icons.domain_verification
                                            : Icons.lock_reset),
                                  color: primaryColor,
                                  size: isTabletDevice ? 75 : 65,
                                ),
                                const SizedBox(height: 10),
                                CommonText(
                                  isPasswordStep
                                      ? 'Update Password'
                                      : (isOtpStep
                                            ? 'Verification'
                                            : 'Reset Password'),
                                  style: TextStyle(
                                    fontSize:
                                        refWidth *
                                        (isTabletDevice ? 0.055 : 0.065),
                                    fontWeight: FontWeight.w600,
                                    fontFamily: appPoppinFont,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: CommonText(
                                    isPasswordStep
                                        ? 'Set a secure password for account accessibility.'
                                        : (isOtpStep
                                              ? 'Enter the verification code sent to your device.'
                                              : 'Choose a recovery method to regain access to your account.'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize:
                                          refWidth *
                                          (isTabletDevice ? 0.026 : 0.03),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: appPoppinFont,
                                      color: isDarkMode
                                          ? Colors.white60
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                SizedBox(height: isTabletDevice ? 40 : 30),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      if (!isOtpStep && !isPasswordStep) ...[
                                        Container(
                                          margin: EdgeInsets.symmetric(
                                            horizontal: isTabletDevice
                                                ? screenHorizontalSpacePadding
                                                : (screenHorizontalSpacePadding /
                                                      2),
                                          ),
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? darkModeCardColor.withOpacity(
                                                    0.9,
                                                  )
                                                : filedBg,
                                            borderRadius: BorderRadius.circular(
                                              fieldBorderRadius * 5,
                                            ),
                                          ),
                                          child: TabBar(
                                            controller: _tabController,
                                            overlayColor:
                                                WidgetStateProperty.all(
                                                  Colors.transparent,
                                                ),
                                            indicatorSize:
                                                TabBarIndicatorSize.tab,
                                            dividerColor: Colors.transparent,
                                            indicatorColor: Colors.transparent,
                                            labelColor: isDarkMode
                                                ? Colors.black
                                                : primaryColor,
                                            labelStyle: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontFamily: appPoppinFont,
                                              fontSize:
                                                  refWidth *
                                                  (isTabletDevice
                                                      ? 0.028
                                                      : 0.035),
                                            ),
                                            unselectedLabelColor: isDarkMode
                                                ? Colors.white60
                                                : Colors.grey.shade600,
                                            indicator: RectangularIndicator(
                                              bottomLeftRadius:
                                                  fieldBorderRadius * 5,
                                              bottomRightRadius:
                                                  fieldBorderRadius * 5,
                                              topLeftRadius:
                                                  fieldBorderRadius * 5,
                                              topRightRadius:
                                                  fieldBorderRadius * 5,
                                              color: Colors.white,
                                              horizontalPadding: 4,
                                              verticalPadding: 4,
                                            ),
                                            tabs: const [
                                              Tab(text: "Mobile Recovery"),
                                              Tab(text: "Email Recovery"),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height: isTabletDevice ? 40 : 30,
                                        ),
                                      ],

                                      if (isOtpStep || isPasswordStep)
                                        const SizedBox(height: 10),

                                      _buildFormContent(
                                        context,
                                        state,
                                        isDarkMode,
                                        isTabletDevice,
                                        refWidth,
                                        screenHeight,
                                        isOtpStep,
                                        isPasswordStep,
                                      ),

                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CommonText(
                                            "Remembered your credentials? ",
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontSize:
                                                  refWidth *
                                                  (isTabletDevice
                                                      ? 0.026
                                                      : 0.035),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              context
                                                  .read<ForgotPasswordBloc>()
                                                  .add(NavSignInClicked());
                                            },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            child: Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontFamily: appPoppinFont,
                                                fontSize:
                                                    refWidth *
                                                    (isTabletDevice
                                                        ? 0.026
                                                        : 0.035),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
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

  Widget _buildFormContent(
    BuildContext context,
    ForgotPasswordState state,
    bool isDarkMode,
    bool isTab,
    double refWidth,
    double screenHeight,
    bool isOtpStep,
    bool isPasswordStep,
  ) {
    if (isPasswordStep) {
      return _buildNewPasswordForm(context, isTab, refWidth, isDarkMode, state);
    } else if (isOtpStep) {
      return _buildOtpVerificationForm(
        context,
        state,
        isTab,
        refWidth,
        screenHeight,
      );
    }

    return _activeTabIndex == 0
        ? _buildMobileForm(context, isDarkMode, isTab, refWidth, state)
        : _buildEmailForm(context, isTab, refWidth, state);
  }

  Widget _buildMobileForm(
    BuildContext context,
    bool isDarkMode,
    bool isTab,
    double refWidth,
    ForgotPasswordState state,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTab
            ? screenHorizontalSpacePadding
            : (screenHorizontalSpacePadding / 2),
      ),
      child: Form(
        key: mobileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CommonText(
              'Mobile number *',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: refWidth * (isTab ? 0.026 : 0.032),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: titleSpace),
            CommonInputAddRecordTextField(
              focusNode: mobileFocus,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              prefixIcon: Theme(
                data: ThemeData(
                  dialogTheme: DialogThemeData(
                    barrierColor: isDarkMode ? Colors.black12 : Colors.black54,
                  ),
                ),
                child: CountryCodePicker(
                  onChanged: (country) {
                    if (country.dialCode != null) {
                      context.read<ForgotPasswordBloc>().add(
                        OnCountryCodeChangedEvent(country.dialCode!),
                      );
                    }
                  },
                  showFlag: false,
                  showFlagDialog: true,
                  initialSelection: 'IN',
                  favorite: const ['IN', 'US'],
                  textStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: refWidth * (isTab ? 0.026 : 0.035),
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  dialogBackgroundColor: isDarkMode
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  dialogTextStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  barrierColor: Colors.black12,
                  searchStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  searchDecoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.white70 : Colors.grey,
                    ),
                    hintText: "Search Country",
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.white24 : Colors.black12,
                      ),
                    ),
                  ),
                ),
              ),
              borderRadius: fieldBorderRadius,
              hintText: "Mobile number",
              controller: mobileNumberController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                } else if (value.length != 10) {
                  return 'Please enter a valid 10-digit phone number';
                }
                return null;
              },
              inputFormatter: [
                LengthLimitingTextInputFormatter(10),
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: 25),
            state is ForgotPasswordLoading
                ? SizedBox(
                    height: 50,
                    width: displayWidth(context),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : CustomElevatedButton(
                    noElevation: true,
                    height: 50,
                    width: double.infinity,
                    text: "Send OTP",
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
      ),
    );
  }

  Widget _buildEmailForm(
    BuildContext context,
    bool isTab,
    double refWidth,
    ForgotPasswordState state,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTab
            ? screenHorizontalSpacePadding
            : (screenHorizontalSpacePadding / 2),
      ),
      child: Form(
        key: emailFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CommonText(
              'Email *',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: refWidth * (isTab ? 0.026 : 0.032),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: titleSpace),
            CommonInputAddRecordTextField(
              suffixIcon: null,
              borderRadius: fieldBorderRadius,
              hintText: "Enter Email",
              controller: emailController,
              focusNode: emailFocus,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email or username';
                }
                final String trimmedValue = value.trim();
                if (trimmedValue.contains('@')) {
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(trimmedValue)) {
                    return 'Please enter a valid email address';
                  }
                } else {
                  if (trimmedValue.length < 4) {
                    return 'Username must be at least 4 characters';
                  }
                  final usernameRegex = RegExp(r'^[a-zA-Z0-9_.]+$');
                  if (!usernameRegex.hasMatch(trimmedValue)) {
                    return 'Username can only include letters, numbers, underscores, or periods';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 25),
            state is ForgotPasswordLoading
                ? SizedBox(
                    height: 50,
                    width: displayWidth(context),
                    child: Center(child: CircularProgressIndicator()),
                  )
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
                          ForgotPasswordSendOtp(
                              forgetPasswordParams
                          ),
                        );
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpVerificationForm(
    BuildContext context,
    ForgotPasswordState state,
    bool isTab,
    double refWidth,
    double screenHeight,
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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTab
            ? screenHorizontalSpacePadding
            : (screenHorizontalSpacePadding / 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CommonText(
            'OTP Code *',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: refWidth * (isTab ? 0.026 : 0.032),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: titleSpace),

          Center(
            child: SizedBox(
              width: isTab ? refWidth * 0.55 : displayWidth(context) * 0.82,
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
                obscureText: false,
                animationType: AnimationType.fade,
                pinTheme: PinTheme(
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                  inactiveColor: notificationSwitchColor,
                  activeColor: primaryColor,
                  selectedColor: primaryColor,
                  shape: PinCodeFieldShape.box,
                  borderWidth: 1.0,
                  fieldHeight: isTab
                      ? refWidth * 0.09
                      : displayWidth(context) * 0.11,
                  fieldWidth: isTab
                      ? refWidth * 0.09
                      : displayWidth(context) * 0.11,
                  inactiveFillColor: Theme.of(context).cardColor,
                  activeFillColor: Theme.of(context).cardColor,
                  selectedFillColor: Theme.of(context).cardColor,
                ),
                cursorColor: Colors.grey,
                animationDuration: const Duration(milliseconds: 300),
                textStyle: TextStyle(fontSize: isTab ? refWidth * 0.03 : 16),
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
          SizedBox(height: screenHeight * 0.02),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: isTab ? refWidth * 0.038 : 16,
              ),
              const SizedBox(width: 6),
              Text(
                "Didn't receive the code?",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab
                      ? refWidth * 0.028
                      : displayWidth(context) * 0.035,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Center(
            child:
                state is ReSendOtpLoading ||
                    (state is ForgotPasswordLoading &&
                        otpController.text.length < 6)
                ?  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: SizedBox(
                      height: 32,
                      width: 32,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                : isButtonActive
                ? TextButton(
                    onPressed: () {
                      context.read<ForgotPasswordBloc>().add(
                        ResendOtpRequested(target: recoveryTarget),
                      );
                    },
                    child: Text(
                      'Re-send',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab
                            ? refWidth * 0.034
                            : displayWidth(context) * 0.035,
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
                              ? refWidth * 0.025
                              : displayWidth(context) * 0.032,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '00:${displaySeconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab
                              ? refWidth * 0.028
                              : displayWidth(context) * 0.034,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 25),

          state is ForgotPasswordLoading
              ? SizedBox(
                  height: 50,
                  width: displayWidth(context),
                  child: Center(child: CircularProgressIndicator()),
                )
              : CustomElevatedButton(
                  noElevation: true,
                  height: 50,
                  width: double.infinity,
                  text: "Verify OTP",
                  onPressed: () {
                    context.dismissKeyboard();
                    context.read<ForgotPasswordBloc>().add(
                      VerifyOtpClicked(otp: otpController.text),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordForm(
    BuildContext context,
    bool isTab,
    double refWidth,
    bool isDark,
    ForgotPasswordState state,
  ) {
    final bloc = context.read<ForgotPasswordBloc>();

    // PRODUCTION RELEASE FIX: Read from the BLoC cache to retain strength values during loading states
    final double strengthValue = state is ShowPasswordResetFields
        ? state.passwordStrength
        : bloc.cachedStrength;

    final bool canSubmitForm = state is ShowPasswordResetFields
        ? state.isPasswordGood
        : bloc.cachedIsPasswordGood;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTab
            ? screenHorizontalSpacePadding
            : (screenHorizontalSpacePadding / 2),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CommonText(
              'New Password *',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: refWidth * (isTab ? 0.026 : 0.032),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: titleSpace),
            FancyPasswordField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              passwordController: _passwordController,
              controller: newPasswordController,
              textInputAction: TextInputAction.next,
              cursorColor: isDark
                  ? darkModeBorderFocusedColor
                  : lightModeBorderFocusedColor,
              style: TextStyle(
                decorationThickness: 0,
                decoration: TextDecoration.none,
                fontFamily: appPoppinFont,
                fontSize: isTab
                    ? displayWidth(context) * 0.018
                    : displayWidth(context) * 0.035,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter Password';
                }
                return null;
              },
              showPasswordWidget: Icon(
                Icons.visibility,
                color: isDark ? textDarkModeSecondaryColor : Colors.grey[600],
                size: isTab
                    ? displayWidth(context) * 0.022
                    : displayWidth(context) * 0.045,
              ),
              hidePasswordWidget: Icon(
                Icons.visibility_off,
                color: isDark ? textDarkModeSecondaryColor : Colors.grey[600],
                size: isTab
                    ? displayWidth(context) * 0.022
                    : displayWidth(context) * 0.045,
              ),
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Password',
                floatingLabelBehavior: FloatingLabelBehavior.never,
                labelStyle: TextStyle(
                  fontFamily: appPoppinFont,
                  color: isDark
                      ? textDarkModeSecondaryColor
                      : textLightModeColor.withOpacity(0.5),
                  fontSize: isTab
                      ? displayWidth(context) * 0.018
                      : displayWidth(context) * 0.032,
                ),
                hintStyle: TextStyle(
                  decoration: TextDecoration.none,
                  fontFamily: appPoppinFont,
                  color: isDark
                      ? textDarkModeHintColor
                      : textLightModeColor.withOpacity(0.4),
                  fontSize: isTab
                      ? displayWidth(context) * 0.018
                      : displayWidth(context) * 0.032,
                ),
                errorStyle: TextStyle(
                  fontFamily: appPoppinFont,
                  color: errorTextStyleColor,
                  fontSize: isTab
                      ? displayWidth(context) * 0.018
                      : displayWidth(context) * 0.025,
                ),
                filled: true,
                fillColor: isDark
                    ? darkModeCardColor.withOpacity(0.9)
                    : lightModeTextFieldBgColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(fieldBorderRadius ?? 8.0),
                  borderSide: BorderSide(
                    color: isDark ? darkModeBorderColor : lightModeBorderColor,
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(fieldBorderRadius ?? 8.0),
                  borderSide: BorderSide(
                    color: isDark ? darkModeBorderColor : lightModeBorderColor,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(fieldBorderRadius ?? 8.0),
                  borderSide: BorderSide(
                    color: isDark
                        ? darkModeBorderFocusedColor
                        : lightModeBorderFocusedColor,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(fieldBorderRadius ?? 8.0),
                  borderSide: const BorderSide(
                    color: errorTextStyleColor,
                    width: 1.0,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(fieldBorderRadius ?? 8.0),
                  borderSide: const BorderSide(
                    color: errorTextStyleColor,
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
                UppercaseValidationRule(customText: 'Capital letter'),
                DigitValidationRule(customText: 'Number', showName: true),
                SpecialCharacterValidationRule(customText: '\$?!#&@%*'),
                MinCharactersValidationRule(8, customText: '8 Characters'),
              },
              strengthIndicatorBuilder: (strength) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: CustomStepIndicator(
                    size: isTab
                        ? displayWidth(context) * 0.012
                        : displayWidth(context) * 0.022,
                    totalSteps: 3,
                    currentStep: _getStep(strengthValue),
                    selectedColor: _getColor(strengthValue),
                    unselectedColor: isDark
                        ? const Color(0xFF334155)
                        : Colors.grey[300]!,
                  ),
                );
              },
              validationRuleBuilder: (rules, value) {
                if (value.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rules.map((rule) {
                    bool isValid = rule.validate(value);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            isValid
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: isValid
                                ? lightGreenColor
                                : errorTextStyleColor,
                            size: isTab
                                ? displayWidth(context) * 0.02
                                : displayWidth(context) * 0.045,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rule.name,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab
                                  ? displayWidth(context) * 0.018
                                  : displayWidth(context) * 0.032,
                              color: isDark
                                  ? textDarkModeSecondaryColor
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: fieldSpace),
            CommonText(
              'Confirm Password *',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: refWidth * (isTab ? 0.026 : 0.032),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: titleSpace),
            CommonInputAddRecordTextField(
              borderRadius: fieldBorderRadius,
              hintText: "Confirm New Password",
              controller: confirmPasswordController,
              focusNode: confirmPasswordFocus,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm New Password';
                } else if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  return "Password does not match";
                }
                return null;
              },
            ),
            const SizedBox(height: 25),
            state is ForgotPasswordLoading
                ? SizedBox(
              height: 50,
              width: displayWidth(context),
              child: Center(child: CircularProgressIndicator()),
            )
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
                      newPassword: newPasswordController.text,
                      confirmPassword: confirmPasswordController.text,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  int _getStep(double strength) {
    if (strength < 0.4) return 1;
    if (strength < 0.8) return 2;
    return 3;
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

  Color _getColor(double strength) {
    if (strength < 0.4) return Colors.red;
    if (strength < 0.8) return Colors.orange;
    return Colors.green;
  }
}
