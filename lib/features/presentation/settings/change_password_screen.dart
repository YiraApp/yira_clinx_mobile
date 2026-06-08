
import 'package:fancy_password_field/fancy_password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../core/colors/colors.dart';
import '../../../core/common_appbar/common_app_bar.dart';
import '../../../core/common_input_fields/common_input_field.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/custom_button.dart';
import '../../../core/custom_stepper/custom_stepper.dart';
import 'change_password_bloc/change_password_bloc.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final FancyPasswordController _passwordController = FancyPasswordController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  double _passwordStrength = 0.0;
  bool isPasswordGood = false;

  bool  _isConfirmPasswordObscured = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isTablet = screenWidth > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : const Color(0xFF333138);
    final hintColor = isDark ? Colors.white54 : Colors.black45;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CommonAppBar(


        ),
        body: BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
          listener: (context, state) {

          },
          builder: (context, state) {
            return SafeArea(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenHorizontalSpacePadding,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: screenTopPadding),
                                Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: isTablet ? screenWidth * 0.035 : screenWidth * 0.065,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.035),
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: isTablet ? screenWidth * 0.021 : screenWidth * 0.032,
                                    fontWeight: FontWeight.w400,
                                    color: textColor.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: titleSpace),

                                FancyPasswordField(
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  passwordController: _passwordController,
                                  controller: passwordController,
                                  textInputAction: TextInputAction.next,
                                  cursorColor: isDark ? darkModeBorderFocusedColor : lightModeBorderFocusedColor,
                                  style: TextStyle(
                                    decorationThickness: 0,
                                    decoration: TextDecoration.none,
                                    fontFamily: appPoppinFont,
                                    fontSize: isTablet ? displayWidth(context) * 0.018 : displayWidth(context) * 0.035,
                                    color: theme.colorScheme.onSurface,
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
                                    size: isTablet ? displayWidth(context) * 0.022 : displayWidth(context) * 0.045, // Screen independent sizing scaling
                                  ),
                                  hidePasswordWidget: Icon(
                                    Icons.visibility_off,
                                    color: isDark ? textDarkModeSecondaryColor : Colors.grey[600],
                                    size: isTablet ? displayWidth(context) * 0.022 : displayWidth(context) * 0.045,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelText: 'Password',
                                    floatingLabelBehavior: FloatingLabelBehavior.never,
                                    labelStyle: TextStyle(
                                      fontFamily: appPoppinFont,
                                      color: isDark ? textDarkModeSecondaryColor : textLightModeColor.withOpacity(0.5),
                                      fontSize: isTablet ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
                                    ),
                                    hintStyle: TextStyle(
                                      decoration: TextDecoration.none,
                                      fontFamily: appPoppinFont,
                                      color: isDark ? textDarkModeHintColor : textLightModeColor.withOpacity(0.4),
                                      fontSize: isTablet ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
                                    ),
                                    errorStyle: TextStyle(
                                      fontFamily: appPoppinFont,
                                      color: errorTextStyleColor,
                                      fontSize: isTablet ? displayWidth(context) * 0.018 : displayWidth(context) * 0.025,
                                    ),
                                    filled: true,
                                    fillColor: isDark ? darkModeCardColor.withOpacity(0.9) : lightModeTextFieldBgColor,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(fieldBorderRadius ?? 8.0),
                                      borderSide: BorderSide(color: isDark ? darkModeBorderColor : lightModeBorderColor, width: 1.0),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(fieldBorderRadius ?? 8.0),
                                      borderSide: BorderSide(color: isDark ? darkModeBorderColor : lightModeBorderColor, width: 1.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(fieldBorderRadius ?? 8.0),
                                      borderSide: BorderSide(color: isDark ? darkModeBorderFocusedColor : lightModeBorderFocusedColor, width: 1.5),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(fieldBorderRadius ?? 8.0),
                                      borderSide: const BorderSide(color: errorTextStyleColor, width: 1.0),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(fieldBorderRadius ?? 8.0),
                                      borderSide: const BorderSide(color: errorTextStyleColor, width: 1.5),
                                    ),
                                  ),
                                  onChanged: _validatePassword,
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
                                        size: isTablet ? displayWidth(context) * 0.012 : displayWidth(context) * 0.022,
                                        totalSteps: 3,
                                        currentStep: _getStep(_passwordStrength),
                                        selectedColor: _getColor(_passwordStrength),
                                        unselectedColor: isDark ? const Color(0xFF334155) : Colors.grey[300]!, // Custom dark step track background
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
                                                isValid ? Icons.check_circle_rounded : Icons.cancel_rounded, // Styled to look cleaner for a clinic application
                                                color: isValid ? const Color(0xFF10B981) : const Color(0xFFEF4444), // Emerald green / Ruby red
                                                size: isTablet ? displayWidth(context) * 0.02 : displayWidth(context) * 0.045,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                rule.name,
                                                style: TextStyle(
                                                  fontFamily: appPoppinFont,
                                                  fontSize: isTablet ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
                                                  color: isDark ? textDarkModeSecondaryColor : Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                                SizedBox(height: fieldSpace),

                                Text(
                                  'Confirm Password',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: isTablet ? screenWidth * 0.021 : screenWidth * 0.032,
                                    fontWeight: FontWeight.w400,
                                    color: textColor.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: titleSpace),

                                CommonInputAddRecordTextField(
                                  borderRadius:  fieldBorderRadius,
                                  controller: confirmPasswordController,
                                  hintText: 'Re-enter your new password',
                                  textInputAction: TextInputAction.done,
                                  keyboardType: TextInputType.visiblePassword,
                                  obscureText: _isConfirmPasswordObscured,
                                  inputFormatter: [
                                    LengthLimitingTextInputFormatter(18),
                                  ],
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPasswordObscured ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey,
                                      size:isTablet? 18: screenHeight * 0.025,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter Confirm Password';
                                    }
                                    if (passwordController.text != confirmPasswordController.text) {
                                      return "Passwords do not match";
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: state is ChangePasswordLoading
                              ? const SizedBox(
                            height: 50,
                            child: Center(child: CircularProgressIndicator()),
                          )
                              : CustomElevatedButton(
                            noElevation: true,
                            height: 50,
                            width: double.infinity,
                            text: 'Submit',
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              if (_formKey.currentState!.validate()) {

                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int _getStep(double strength) {
    if (strength < 0.4) return 1;
    if (strength < 0.8) return 2;
    return 3;
  }

  Color _getColor(double strength) {
    if (strength < 0.4) return Colors.red;
    if (strength < 0.8) return Colors.orange;
    return Colors.green;
  }

  void _validatePassword(String password) {
    bool hasMinLength = password.length >= 8;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacter = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int validCount = 0;
    if (hasMinLength) validCount++;
    if (hasUppercase) validCount++;
    if (hasNumber) validCount++;
    if (hasSpecialCharacter) validCount++;

    setState(() {
      _passwordStrength = validCount / 4;
      isPasswordGood = validCount == 4;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}