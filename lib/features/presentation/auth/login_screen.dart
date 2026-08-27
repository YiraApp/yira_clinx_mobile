import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/utils/dismiss_key_board.dart';
import 'package:yiraclinics/features/presentation/auth/login_bloc/login_bloc.dart';

import '../../../core/common_input_fields/common_input_field.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_button.dart';
import '../../../core/constants/constants.dart';
import '../../../core/fcm_token/fcm_token_helper.dart';
import '../../../core/models/select_role_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController mobileNumberController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocus = FocusNode();

  final FocusNode mobileFocus = FocusNode();

  final FocusNode passwordFocus = FocusNode();

  final GlobalKey<FormState> mobileFormKey = GlobalKey<FormState>();

  final GlobalKey<FormState> emailFormKey = GlobalKey<FormState>();

  String _cachedFcmToken = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceToken();
  }

  @override
  void dispose() {
    mobileNumberController.dispose();
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    mobileFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
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
    final bool isTabletDevice = isTablet(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double screenHeight = displayHeight(context);
    final double screenWidth = displayWidth(context);

    return GestureDetector(
      onTap: () => context.dismissKeyboard(),
      child: BlocConsumer<LoginBloc, LogInState>(
        buildWhen: (previous, state) =>
            state is! NavigateToVerifyOtp &&
            state is! NavigateToSignup &&
            state is! NavigateToSelectRole,
        listener: (context, state) {
          switch (state) {
            case NavigateToVerifyOtp():
              Navigator.pushNamed(
                context,
                AppRoutes.verifyOtp,
                arguments: state.sendOtpEntity,
              );
              break;
            case NavigateToSignup():
              Navigator.pushNamed(context, AppRoutes.signup);
              break;
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
                /*if (payload.navigationId == '2') {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.docDashboard,
                        (route) => false,
                  );
                }
                else if (payload.navigationId == '1')
                {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.dashboardPatientDetails,
                        (route) => false,
                  );
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.unsupportedRole,
                    (route) => false,
                    arguments: state.loginEntity,
                  );
                }*/
              } else {
                SelectRoleModel data = SelectRoleModel(
                  payload?.roles ?? [],
                  false,
                  profiles: payload?.profiles,
                );
                Navigator.pushNamed(
                  context,
                  AppRoutes.selectRoleScreen,
                  arguments: data,
                );
              }
              break;
            case SendOtpFailureState():
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage,
                    style: const TextStyle(fontFamily: appPoppinFont),
                  ),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
              break;
            case LoginFailure():
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage ?? "Login failed. Please check your credentials.",
                    style: const TextStyle(fontFamily: appPoppinFont),
                  ),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
              break;
            case NavForgotPasswordState():
              Navigator.pushNamed(context, AppRoutes.forgotPassword);
              break;

            default:
              break;
          }
        },
        builder: (context, state) {
          var isLoading = state is LoginLoading;
          var isMobileLoading = state is SendOtpLoading;

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(isTabletDevice ? 40.0 : 20.0),
              child: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            ),
            body: AbsorbPointer(
              absorbing: isLoading || isMobileLoading,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTabletDevice ? 550 : double.infinity,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double referenceWidth = isTabletDevice
                          ? constraints.maxWidth
                          : screenWidth;

                      return SizedBox(
                        width: double.infinity,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: SvgPicture.asset(
                                  'assets/images/svgs/ic_apps_logo.svg',
                                  width: isTabletDevice ? 65 : 60,
                                  height: isTabletDevice ? 65 : 60,
                                ),
                              ),

                              const SizedBox(height: 20),

                              CommonText(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize:
                                  referenceWidth *
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
                                  'Secure access to your professional dashboard.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize:
                                    referenceWidth *
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

                              DefaultTabController(
                                length: 2,
                                initialIndex: 0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
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
                                              ? darkModeCardColor.withValues(
                                            alpha: 0.9,
                                          )
                                              : filedBg,
                                          borderRadius: BorderRadius.circular(
                                            fieldBorderRadius * 5,
                                          ),
                                        ),
                                        child: TabBar(
                                          overlayColor: WidgetStateProperty.all(
                                            Colors.transparent,
                                          ),
                                          indicatorSize:
                                          TabBarIndicatorSize.tab,
                                          dividerColor: Colors.transparent,
                                          indicatorColor: Colors.transparent,
                                          labelColor: isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF005696),
                                          labelStyle: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontFamily: appPoppinFont,
                                            fontSize:
                                            referenceWidth *
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
                                            color: isDarkMode
                                                ? const Color(0xFF005696)
                                                : Colors.white,
                                            horizontalPadding: 4,
                                            verticalPadding: 4,
                                          ),
                                          tabs: const [
                                            Tab(text: "Mobile OTP"),
                                            Tab(text: "Email & Password"),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: isTabletDevice ? 40 : 30,
                                      ),
                                      SizedBox(
                                        height: isTabletDevice
                                            ? screenHeight * 0.28
                                            : screenHeight * 0.45,
                                        child: TabBarView(
                                          physics:
                                          const NeverScrollableScrollPhysics(),
                                          children: [
                                            _buildMobileForm(
                                              context,
                                              isDarkMode,
                                              isTabletDevice,
                                              referenceWidth,
                                              state,
                                            ),
                                            _buildEmailForm(
                                              context,
                                              isTabletDevice,
                                              referenceWidth,
                                              state,
                                            ),
                                          ],
                                        ),
                                      ),

                                      Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          CommonText(
                                            "Don't have an account? ",
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontSize:
                                              referenceWidth *
                                                  (isTabletDevice
                                                      ? 0.026
                                                      : 0.035),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              context.dismissKeyboard();
                                              context.read<LoginBloc>().add(
                                                const NavSignUp(),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                            ),
                                            child: Text(
                                              'Sign Up',
                                              style: TextStyle(
                                                fontFamily: appPoppinFont,
                                                fontSize:
                                                referenceWidth *
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
          );
        },
      ),
    );
  }

  Widget _buildMobileForm(
    BuildContext context,
    bool isDarkMode,
    bool isTab,
    double refWidth,
    LogInState state,
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
                  onChanged: (country) {
                    if (country.dialCode != null) {
                      context.read<LoginBloc>().add(
                        OnCountryCodeChanged(country.dialCode!),
                      );
                    }
                  },
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
            const SizedBox(height: 30),
            state is SendOtpLoading
                ? Center(child: CircularProgressIndicator.adaptive())
                : CustomElevatedButton(
                    noElevation: true,
                    height: 50,
                    width: double.infinity,
                    text: "Send OTP",
                    onPressed: () {
                      if (mobileFormKey.currentState?.validate() ?? false) {
                        context.dismissKeyboard();
                        final String activeCountryCode = context
                            .read<LoginBloc>()
                            .currentCountryCode;
                        context.read<LoginBloc>().add(
                          OnSendOtp(
                            mobileNumberController.text,
                            activeCountryCode,
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

  Widget _buildEmailForm(
    BuildContext context,
    bool isTab,
    double refWidth,
    LogInState state,
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
              requestFocusNode: passwordFocus,
              textInputAction: TextInputAction.next,
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
            const SizedBox(height: fieldSpace),
            CommonText(
              'Password *',
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
              hintText: "Enter Password",
              controller: passwordController,
              focusNode: passwordFocus,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 Characters';
                }
                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                  return 'Password must contain a Capital letter';
                }
                if (!RegExp(r'[0-9]').hasMatch(value)) {
                  return 'Password must contain a Number';
                }
                if (!RegExp(r'[.$?!#&@%*]').hasMatch(value)) {
                  return 'Password must contain a special character (.\$?!#&@%*)';
                }

                return null;
              },
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 30),
            Column(
              crossAxisAlignment: .end,
              children: [
                state is LoginLoading
                    ? Center(child: CircularProgressIndicator.adaptive())
                    : CustomElevatedButton(
                        noElevation: true,
                        height: 50,
                        width: double.infinity,
                        text: "Sign In",
                        onPressed: () {
                          if (emailFormKey.currentState?.validate() ?? false) {
                            context.dismissKeyboard();
                            context.read<LoginBloc>().add(
                              OnTapEmailSignInEvent(
                                email: emailController.text.trim(),
                                password: passwordController.text,
                                fcmToken: _cachedFcmToken,
                              ),
                            );
                          }
                        },
                      ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    context.dismissKeyboard();
                    context.read<LoginBloc>().add(NavForgotPasswordEvent());
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: refWidth * (isTab ? 0.026 : 0.035),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
