import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/features/presentation/auth/login_bloc/login_bloc.dart';

import '../../../../core/common_input_fields/common_input_field.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/common_widgets/custom_button.dart';
import '../../../../core/constants/constants.dart';
import '../../../core/common_drop_down/common_drop_down.dart';
import '../../../core/utils/dismiss_key_board.dart';

class SignupScreen extends StatelessWidget {
  SignupScreen({super.key});

  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final FocusNode firstNameFocus = FocusNode();
  final FocusNode lastNameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode mobileFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    final bool isTab = isTablet(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = displayWidth(context);
    final String? profileImagePath = null;
    return GestureDetector(
      onTap: () => context.dismissKeyboard(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
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

                return SizedBox(
                  width: double.infinity,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: BlocConsumer<LoginBloc, LogInState>(
                      buildWhen: (previous, state) =>
                          state is! NavigateToSignIn &&
                          state is! NavigateToSelectRoleSignUp,
                      listener: (context, state) => {
                        if (state is NavigateToSignIn)
                          {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.signIn,
                              (route) => false,
                            ),
                          }
                        else if (state is NavTellAboutYourSelfSignUpState)
                          {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.genderSelection,
                            ),
                          },
                      },
                      builder: (context, state) {
                        return Column(
                          children: [
                            /*ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: SvgPicture.asset(
                                'assets/images/svgs/ic_apps_logo.svg',
                                width: isTab ? 65 : 60,
                                height: isTab ? 65 : 60,
                              ),
                            ),
                            const SizedBox(height: 10),*/
                            CommonText(
                              'Create Account',
                              style: TextStyle(
                                fontSize:
                                    referenceWidth * (isTab ? 0.055 : 0.065),
                                fontWeight: FontWeight.w600,
                                fontFamily: appPoppinFont,
                              ),
                            ),
                            CommonText(
                              'Start your health journey today',
                              style: TextStyle(
                                fontSize:
                                    referenceWidth * (isTab ? 0.026 : 0.03),
                                fontWeight: FontWeight.w500,
                                fontFamily: appPoppinFont,
                                color: isDarkMode
                                    ? Colors.white60
                                    : Colors.grey.shade600,
                              ),
                            ),

                            const SizedBox(height: 30),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: screenHorizontalSpacePadding,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Theme.of(
                                                context,
                                              ).primaryColor.withOpacity(0.2),
                                              width: 3,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: isTab ? 55 : 48,
                                            backgroundColor: isDarkMode
                                                ? Colors.white.withOpacity(0.05)
                                                : Colors.grey.shade100,
                                            backgroundImage:
                                                profileImagePath != null
                                                ? FileImage(
                                                    File(profileImagePath),
                                                  )
                                                : null,
                                            child: profileImagePath == null
                                                ? Icon(
                                                    Icons
                                                        .person_outline_rounded,
                                                    size: isTab ? 48 : 42,
                                                    color: isDarkMode
                                                        ? Colors.white54
                                                        : Colors.grey.shade400,
                                                  )
                                                : null,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              // TODO: Fire picker event to your LoginBloc / Image Service
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.15),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                profileImagePath == null
                                                    ? Icons.camera_alt_rounded
                                                    : Icons.edit_rounded,
                                                size: isTab ? 20 : 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 15),
                                  CommonText(
                                    'First Name *',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize:
                                          referenceWidth *
                                          (isTab ? 0.026 : 0.032),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: titleSpace),
                                  CommonInputAddRecordTextField(
                                    suffixIcon: null,
                                    borderRadius: fieldBorderRadius,
                                    hintText: "Enter First Name",
                                    controller: firstNameController,
                                    focusNode: firstNameFocus,
                                    requestFocusNode: lastNameFocus,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: fieldSpace),

                                  CommonText(
                                    'Last Name *',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize:
                                          referenceWidth *
                                          (isTab ? 0.026 : 0.032),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: titleSpace),
                                  CommonInputAddRecordTextField(
                                    suffixIcon: null,
                                    borderRadius: fieldBorderRadius,
                                    hintText: "Enter Last Name",
                                    controller: lastNameController,
                                    focusNode: lastNameFocus,
                                    requestFocusNode: emailFocus,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: fieldSpace),

                                  CommonText(
                                    'Email *',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize:
                                          referenceWidth *
                                          (isTab ? 0.026 : 0.032),
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
                                    requestFocusNode: mobileFocus,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: fieldSpace),

                                  CommonText(
                                    'Mobile number *',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize:
                                          referenceWidth *
                                          (isTab ? 0.026 : 0.032),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: titleSpace),
                                  CommonInputAddRecordTextField(
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: Theme(
                                      data: ThemeData(
                                        dialogTheme: DialogThemeData(
                                          barrierColor: isDarkMode
                                              ? Colors.black12
                                              : Colors.black54,
                                        ),
                                      ),
                                      child: CountryCodePicker(
                                        showFlag: false,
                                        showFlagDialog: true,
                                        initialSelection: 'IN',
                                        favorite: const ['IN', 'US'],
                                        textStyle: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize:
                                              referenceWidth *
                                              (isTab ? 0.026 : 0.035),
                                          fontWeight: FontWeight.w500,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        dialogBackgroundColor: isDarkMode
                                            ? const Color(0xFF1E1E1E)
                                            : Colors.white,
                                        dialogTextStyle: TextStyle(
                                          fontFamily: appPoppinFont,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        barrierColor: Colors.black12,
                                        searchStyle: TextStyle(
                                          fontFamily: appPoppinFont,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                        searchDecoration: InputDecoration(
                                          prefixIcon: Icon(
                                            Icons.search,
                                            color: isDarkMode
                                                ? Colors.white70
                                                : Colors.grey,
                                          ),
                                          hintText: "Search Country",
                                          hintStyle: TextStyle(
                                            color: isDarkMode
                                                ? Colors.white54
                                                : Colors.black54,
                                          ),
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: isDarkMode
                                                  ? Colors.white24
                                                  : Colors.black12,
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
                                    focusNode: mobileFocus,
                                    requestFocusNode: passwordFocus,
                                    textInputAction: TextInputAction.next,
                                    inputFormatter: [
                                      LengthLimitingTextInputFormatter(10),
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                  const SizedBox(height: fieldSpace),

                                  CommonText(
                                    'Password *',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize:
                                          referenceWidth *
                                          (isTab ? 0.026 : 0.032),
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
                                    requestFocusNode: confirmPasswordFocus,
                                    textInputAction: TextInputAction.next,
                                  ),

                                  const SizedBox(height: 40),

                                  CustomElevatedButton(
                                    noElevation: true,
                                    height: 50,
                                    width: double.infinity,
                                    text: "Sign Up",
                                    onPressed: () {
                                      context.dismissKeyboard();
                                      context.read<LoginBloc>().add(
                                        NavTellAboutYourSelfSignUp(),
                                      );
                                    },
                                  ),

                                  SizedBox(height: isTab ? 30 : 10),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CommonText(
                                        'Already have account? ',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize:
                                              referenceWidth *
                                              (isTab ? 0.026 : 0.035),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          context.read<LoginBloc>().add(
                                            NavSignIn(),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize:
                                                referenceWidth *
                                                (isTab ? 0.026 : 0.035),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
