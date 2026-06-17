import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/features/presentation/auth/signin_bloc/signin_bloc.dart';

import '../../../core/common_input_fields/common_input_field.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_button.dart';
import '../../../core/constants/constants.dart';
import '../../../core/widgets/internet_guard.dart';

class SignInScreen extends StatelessWidget {
  SignInScreen({super.key});

  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode emailFocus = FocusNode();
  final FocusNode mobileFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    final bool isTabletDevice = isTablet(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double screenHeight = displayHeight(context);
    final double screenWidth = displayWidth(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: BlocConsumer<SignInBloc, SignInState>(
        buildWhen: (previous, state) =>
            state is! NavigateToVerifyOtp &&
            state is! NavigateToSignup &&
            state is! NavigateToSelectRole,
        listener: (context, state) {
          switch (state) {
            case NavigateToVerifyOtp():
              Navigator.pushNamed(context, AppRoutes.verifyOtp);
              break;

            case NavigateToSignup():
              Navigator.pushNamed(context, AppRoutes.signup);
              break;

            case NavigateToSelectRole():
              Navigator.pushNamed(context, AppRoutes.selectRoleScreen);

              break;
            case NavForgotPasswordState():
              Navigator.pushNamed(context, AppRoutes.forgotPassword);
              break;

            default:
              break;
          }
        },
        builder: (context, state) {
          return InternetGuard(
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(isTabletDevice ? 40.0 : 20.0),
                child: AppBar(backgroundColor: Colors.transparent, elevation: 0),
              ),
              body: Center(
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
                              /*Icon(
                                Icons.health_and_safety,
                                color: primaryColor,
                                size: isTabletDevice ? 75 : 65,
                              ),*/
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
                                              ? darkModeCardColor.withOpacity(0.9)
                                              : filedBg,
                                          borderRadius: BorderRadius.circular(
                                            fieldBorderRadius * 5,
                                          ),
                                        ),
                                        child: TabBar(
                                          overlayColor: WidgetStateProperty.all(
                                            Colors.transparent,
                                          ),
                                          indicatorSize: TabBarIndicatorSize.tab,
                                          dividerColor: Colors.transparent,
                                          indicatorColor: Colors.transparent,
                                          labelColor: isDarkMode
                                              ? Colors.black
                                              : primaryColor,
                                          labelStyle: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontFamily: appPoppinFont,
                                            fontSize:
                                                referenceWidth *
                                                (isTabletDevice ? 0.028 : 0.035),
                                          ),
                                          unselectedLabelColor: isDarkMode
                                              ? Colors.white60
                                              : Colors.grey.shade600,
                                          indicator: RectangularIndicator(
                                            bottomLeftRadius:
                                                fieldBorderRadius * 5,
                                            bottomRightRadius:
                                                fieldBorderRadius * 5,
                                            topLeftRadius: fieldBorderRadius * 5,
                                            topRightRadius: fieldBorderRadius * 5,
                                            color: Colors.white,
                                            horizontalPadding: 4,
                                            verticalPadding: 4,
                                          ),
                                          tabs: const [
                                            Tab(text: "Mobile Login"),
                                            Tab(text: "Email Login"),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: isTabletDevice ? 40 : 30),
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
                                            ),
                                            _buildEmailForm(
                                              context,
                                              isTabletDevice,
                                              referenceWidth,
                                            ),
                                          ],
                                        ),
                                      ),
            
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CommonText(
                                            "Don't you have account? ",
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
                                              context.read<SignInBloc>().add(
                                                NavSignUp(),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize
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
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTab
            ? screenHorizontalSpacePadding
            : (screenHorizontalSpacePadding / 2),
      ),
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
                onChanged: (country) {},
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
          CustomElevatedButton(
            noElevation: true,
            height: 50,
            width: double.infinity,
            text: "Send OTP",
            onPressed: () {
              context.read<SignInBloc>().add(NavSendOtp());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm(BuildContext context, bool isTab, double refWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTab
            ? screenHorizontalSpacePadding
            : (screenHorizontalSpacePadding / 2),
      ),
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
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 30),
          Column(
            crossAxisAlignment: .end,
            children: [
              CustomElevatedButton(
                noElevation: true,
                height: 50,
                width: double.infinity,
                text: "Sign In",
                onPressed: () {
                  context.read<SignInBloc>().add(NavSelectRole());
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  context.read<SignInBloc>().add(NavForgotPasswordEvent());
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
    );
  }
}
