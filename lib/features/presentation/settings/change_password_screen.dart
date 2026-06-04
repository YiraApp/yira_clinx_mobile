
import 'package:fancy_password_field/fancy_password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../core/colors/colors.dart';
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
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),

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
                    horizontal: screenWidth * 0.05,
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
                                SizedBox(height: screenHeight * 0.02),
                                Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: isTablet ? screenWidth * 0.045 : screenWidth * 0.065,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.035),

                                // New Password Header Label
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: isTablet ? screenWidth * 0.021 : screenWidth * 0.032,
                                    fontWeight: FontWeight.w400,
                                    color: textColor.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 6),

                                FancyPasswordField(
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  passwordController: _passwordController,
                                  controller: passwordController,
                                  textInputAction: TextInputAction.next,
                                  cursorColor: isDark ? Colors.white : Colors.black,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: isTablet ? screenWidth * 0.018 : screenWidth * 0.038,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter Password';
                                    }
                                    return null;
                                  },
                                  showPasswordWidget: Icon(
                                    Icons.visibility,
                                    color: Colors.grey,
                                    size: screenHeight * 0.025,
                                  ),
                                  hidePasswordWidget: Icon(
                                    Icons.visibility_off,
                                    color: Colors.grey,
                                    size: screenHeight * 0.025,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelText: 'Password',
                                    floatingLabelBehavior: FloatingLabelBehavior.never,
                                    labelStyle: TextStyle(fontFamily: appPoppinFont,color: Colors.grey, fontSize: isTablet ? screenWidth * 0.018 : screenWidth * 0.034),
                                    hintStyle: TextStyle(fontFamily: appPoppinFont,color: hintColor, fontSize: isTablet ? screenWidth * 0.018 : screenWidth * 0.038),
                                    errorStyle: TextStyle(
                                        fontFamily: appPoppinFont,
                                        color: errorTextStyleColor,
                                        fontSize: displayWidth(context) * 0.025),
                                    filled: true,
                                    fillColor: Theme.of(context).brightness == Brightness.dark
                                        ? filedBg.withOpacity(0.2)
                                        : lightModeTextFieldBgColor,
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(width: 1, color: Colors.redAccent),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(width: 1, color: Colors.redAccent),
                                      borderRadius: BorderRadius.circular(12),
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

                                        size: screenHeight * 0.01,
                                        totalSteps: 3,
                                        currentStep: _getStep(_passwordStrength),
                                        selectedColor: _getColor(_passwordStrength),
                                        unselectedColor: Colors.grey[300]!,
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
                                                isValid ? Icons.check : Icons.close,
                                                color: isValid ? Colors.green : Colors.red,
                                                size: screenHeight * 0.02,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                rule.name,
                                                style: TextStyle(fontFamily: appPoppinFont,
                                                  fontSize: isTablet ? screenWidth * 0.018 : screenWidth * 0.034,
                                                  color: isDark ? Colors.white70 : Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                                SizedBox(height: screenHeight * 0.025),

                                Text(
                                  'Confirm Password',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: isTablet ? screenWidth * 0.021 : screenWidth * 0.032,
                                    fontWeight: FontWeight.w400,
                                    color: textColor.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 6),

                                CommonInputAddRecordTextField(
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
                                      size: screenHeight * 0.025,
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