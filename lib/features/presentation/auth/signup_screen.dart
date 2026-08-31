import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/features/domain/entities/send_otp/send_otp_entity.dart';
import 'package:yiraclinics/features/presentation/auth/login_bloc/login_bloc.dart';

import '../../../../core/colors/colors.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/common_widgets/custom_button.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/fcm_token/fcm_token_helper.dart';
import '../../../core/utils/dismiss_key_board.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _mobileFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  String _selectedCountryCode = "+91";
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _cachedFcmToken = '';

  // Password criteria states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  int _passwordStrength = 0; // 0 to 4

  @override
  void initState() {
    super.initState();
    _loadDeviceToken();
    _passwordController.addListener(_validatePasswordStrength);
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  Future<void> _loadDeviceToken() async {
    final String token = await FcmTokenHelper.getProductionFcmToken();
    if (mounted && token.isNotEmpty) {
      setState(() {
        _cachedFcmToken = token;
      });
    }
  }

  void _validatePasswordStrength() {
    final pass = _passwordController.text;
    final minLen = pass.length >= 8;
    final upper = pass.contains(RegExp(r'[A-Z]'));
    final num = pass.contains(RegExp(r'[0-9]'));
    final spec = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+]'));

    int score = 0;
    if (minLen) score++;
    if (upper) score++;
    if (num) score++;
    if (spec) score++;

    setState(() {
      _hasMinLength = minLen;
      _hasUppercase = upper;
      _hasNumber = num;
      _hasSpecialChar = spec;
      _passwordStrength = pass.isEmpty ? 0 : score;
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength && _hasUppercase && _hasNumber && _hasSpecialChar;

  bool get _doPasswordsMatch =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text == _confirmPasswordController.text;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _mobileFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onSignUpPressed() {
    context.dismissKeyboard();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isPasswordValid) {
      _showSnackBar(
        "Please choose a strong password matching all criteria below.",
        isError: true,
      );
      _passwordFocus.requestFocus();
      return;
    }

    if (!_doPasswordsMatch) {
      _showSnackBar(
        "Passwords do not match. Please verify your confirm password.",
        isError: true,
      );
      _confirmPasswordFocus.requestFocus();
      return;
    }

    // Dispatch Send Signup OTP event to backend
    context.read<LoginBloc>().add(
          OnSendSignupOtpEvent(
            mobileNumber: _mobileNumberController.text.trim(),
            countryCode: _selectedCountryCode,
            email: _emailController.text.trim().isNotEmpty
                ? _emailController.text.trim()
                : null,
          ),
        );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAlreadyRegisteredDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Account Exists",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<LoginBloc>().add(const NavSignIn());
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.signIn,
                  (route) => false,
                );
              },
              child: const Text(
                "Sign In",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showOtpVerificationSheet(SendOtpEntity sendOtpEntity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _SignupOtpVerificationSheet(
        sendOtpEntity: sendOtpEntity,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        mobileNumber: _mobileNumberController.text.trim(),
        countryCode: _selectedCountryCode,
        password: _passwordController.text,
        fcmToken: _cachedFcmToken,
        loginBloc: context.read<LoginBloc>(),
        onSuccess: (loginEntity) {
          Navigator.of(sheetContext).pop();
          _showSnackBar("Account created successfully! Welcome to Yira Clinx.");
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.genderSelection,
            (route) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTab = isTablet(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => context.dismissKeyboard(),
      child: Scaffold(
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : const Color(0xFFF7F9FC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTab ? 560 : 440,
            ),
            child: BlocConsumer<LoginBloc, LogInState>(
              listener: (context, state) {
                if (state is SignupOtpSentState) {
                  _showOtpVerificationSheet(state.sendOtpEntity);
                } else if (state is SignupOtpFailureState) {
                  if (state.errorMessage.toLowerCase().contains("already registered") ||
                      state.errorMessage.toLowerCase().contains("already exists")) {
                    _showAlreadyRegisteredDialog(state.errorMessage);
                  } else {
                    _showSnackBar(state.errorMessage, isError: true);
                  }
                } else if (state is SignupSuccessState) {
                  _showSnackBar("Account created successfully!");
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.genderSelection,
                    (route) => false,
                  );
                } else if (state is SignupFailureState) {
                  _showSnackBar(state.errorMessage, isError: true);
                }
              },
              builder: (context, state) {
                final bool isSubmitting =
                    state is SignupOtpLoadingState || state is SignupLoadingState;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isTab ? 24 : 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      // Top Brand Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor.withValues(alpha: 0.15),
                                    primaryColor.withValues(alpha: 0.04),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SvgPicture.asset(
                                  'assets/images/svgs/ic_apps_logo.svg',
                                  width: isTab ? 48 : 42,
                                  height: isTab ? 48 : 42,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            CommonText(
                              'Create Account',
                              style: TextStyle(
                                fontSize: isTab ? 25 : 23,
                                fontWeight: FontWeight.w700,
                                fontFamily: appPoppinFont,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            CommonText(
                              'Join Yira Clinx and start your health journey',
                              style: TextStyle(
                                fontSize: isTab ? 13.5 : 12.5,
                                fontWeight: FontWeight.w400,
                                fontFamily: appPoppinFont,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── MAIN SIGNUP CARD ──
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.35)
                                  : Colors.black.withValues(alpha: 0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 22,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section 1: Personal Information
                              _buildSectionHeader('Personal Details', Icons.person_outline_rounded, isDark),
                              const SizedBox(height: 12),

                              // First Name
                              _buildFieldLabel('First Name', isRequired: true, isDark: isDark),
                              const SizedBox(height: 6),
                              _buildCustomTextField(
                                controller: _firstNameController,
                                focusNode: _firstNameFocus,
                                nextFocusNode: _lastNameFocus,
                                hintText: 'Enter your first name',
                                prefixIcon: Icons.badge_outlined,
                                isDark: isDark,
                                textCapitalization: TextCapitalization.words,
                                autocorrect: false,
                                enableSuggestions: false,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your first name';
                                  }
                                  if (val.trim().length < 2) {
                                    return 'Minimum 2 characters required';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),

                              // Last Name
                              _buildFieldLabel('Last Name', isRequired: true, isDark: isDark),
                              const SizedBox(height: 6),
                              _buildCustomTextField(
                                controller: _lastNameController,
                                focusNode: _lastNameFocus,
                                nextFocusNode: _mobileFocus,
                                hintText: 'Enter your last name',
                                prefixIcon: Icons.person_outline,
                                isDark: isDark,
                                textCapitalization: TextCapitalization.words,
                                autocorrect: false,
                                enableSuggestions: false,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your last name';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 14),

                              // Mobile Number Field
                              _buildFieldLabel('Mobile Number', isRequired: true, isDark: isDark),
                              const SizedBox(height: 6),
                              _buildPhoneField(isDark),

                              const SizedBox(height: 14),

                              // Email Field (OPTIONAL)
                              Row(
                                children: [
                                  _buildFieldLabel('Email Address', isRequired: false, isDark: isDark),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Optional',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildCustomTextField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                nextFocusNode: _passwordFocus,
                                hintText: 'e.g. name@example.com',
                                prefixIcon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                isDark: isDark,
                                validator: (val) {
                                  if (val != null && val.trim().isNotEmpty) {
                                    final emailRegex = RegExp(r'^[\w\.-]+@[\w-]+\.\w{2,4}$');
                                    if (!emailRegex.hasMatch(val.trim())) {
                                      return 'Please enter a valid email address';
                                    }
                                  }
                                  return null; // Empty is valid
                                },
                              ),

                              const SizedBox(height: 20),

                              // Section 2: Security Details
                              _buildSectionHeader('Security', Icons.lock_outline_rounded, isDark),
                              const SizedBox(height: 12),

                              // Password Field
                              _buildFieldLabel('Password', isRequired: true, isDark: isDark),
                              const SizedBox(height: 6),
                              _buildPasswordField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                nextFocusNode: _confirmPasswordFocus,
                                hintText: 'Create a strong password',
                                obscureText: _obscurePassword,
                                isDark: isDark,
                                onToggleVisibility: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),

                              const SizedBox(height: 8),

                              // Password Strength Bar & Checklist
                              if (_passwordController.text.isNotEmpty) ...[
                                _buildPasswordStrengthBar(isDark),
                                const SizedBox(height: 10),
                                _buildPasswordCriteriaChecklist(isDark),
                                const SizedBox(height: 14),
                              ],

                              // Confirm Password Field
                              _buildFieldLabel('Confirm Password', isRequired: true, isDark: isDark),
                              const SizedBox(height: 6),
                              _buildPasswordField(
                                controller: _confirmPasswordController,
                                focusNode: _confirmPasswordFocus,
                                hintText: 'Re-enter your password',
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                isDark: isDark,
                                onToggleVisibility: () =>
                                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),

                              // Confirm Password Match Indicator
                              if (_confirmPasswordController.text.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _buildPasswordMatchIndicator(isDark),
                              ],

                              const SizedBox(height: 24),

                              // Sign Up Action Button
                              isSubmitting
                                  ? const Center(
                                      child: SizedBox(
                                        height: 50,
                                        width: 50,
                                        child: CircularProgressIndicator.adaptive(),
                                      ),
                                    )
                                  : CustomElevatedButton(
                                      noElevation: true,
                                      height: 50,
                                      width: double.infinity,
                                      text: "Create Account",
                                      onPressed: _onSignUpPressed,
                                    ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Already have account? Sign In
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CommonText(
                              'Already have an account? ',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? 13.5 : 12.5,
                                fontWeight: FontWeight.w400,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                context.read<LoginBloc>().add(const NavSignIn());
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  AppRoutes.signIn,
                                  (route) => false,
                                );
                              },
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 13.5 : 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper Widgets ──

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, {required bool isRequired, required bool isDark}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.grey.shade800,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool autocorrect = false,
    bool enableSuggestions = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      onFieldSubmitted: (_) {
        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        }
      },
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: 13,
        color: isDark ? Colors.white : Colors.black87,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 12.5,
          color: isDark ? Colors.white30 : Colors.grey.shade400,
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: 17,
          color: isDark ? Colors.white54 : Colors.grey.shade600,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPhoneField(bool isDark) {
    return TextFormField(
      controller: _mobileNumberController,
      focusNode: _mobileFocus,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      onFieldSubmitted: (_) => _emailFocus.requestFocus(),
      inputFormatters: [
        LengthLimitingTextInputFormatter(10),
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: 13,
        color: isDark ? Colors.white : Colors.black87,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your mobile number';
        }
        if (value.trim().length != 10) {
          return 'Please enter a valid 10-digit mobile number';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: '10-digit phone number',
        hintStyle: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 12.5,
          color: isDark ? Colors.white30 : Colors.grey.shade400,
        ),
        prefixIcon: CountryCodePicker(
          showFlag: false,
          showFlagDialog: true,
          initialSelection: 'IN',
          favorite: const ['IN', 'US', 'AE', 'GB'],
          textStyle: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
          dialogBackgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          dialogTextStyle: TextStyle(
            fontFamily: appPoppinFont,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onChanged: (country) {
            setState(() {
              _selectedCountryCode = country.dialCode ?? '+91';
            });
            context.read<LoginBloc>().add(OnCountryCodeChanged(_selectedCountryCode));
          },
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required bool isDark,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      textInputAction: textInputAction,
      autocorrect: false,
      enableSuggestions: false,
      onFieldSubmitted: (_) {
        if (nextFocusNode != null) {
          nextFocusNode.requestFocus();
        }
      },
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: 13,
        color: isDark ? Colors.white : Colors.black87,
      ),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Password is required';
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 12.5,
          color: isDark ? Colors.white30 : Colors.grey.shade400,
        ),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          size: 17,
          color: isDark ? Colors.white54 : Colors.grey.shade600,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 17,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthBar(bool isDark) {
    Color getStrengthColor() {
      switch (_passwordStrength) {
        case 1:
          return Colors.red;
        case 2:
          return Colors.orange;
        case 3:
          return Colors.amber.shade700;
        case 4:
          return Colors.green;
        default:
          return Colors.grey.shade300;
      }
    }

    String getStrengthText() {
      switch (_passwordStrength) {
        case 1:
          return "Weak";
        case 2:
          return "Fair";
        case 3:
          return "Good";
        case 4:
          return "Strong";
        default:
          return "";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Strength",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            Text(
              getStrengthText(),
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: getStrengthColor(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(4, (index) {
            final bool isActive = index < _passwordStrength;
            return Expanded(
              child: Container(
                height: 3.5,
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isActive
                      ? getStrengthColor()
                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPasswordCriteriaChecklist(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          _buildChecklistItem("At least 8 characters", _hasMinLength, isDark),
          const SizedBox(height: 3),
          _buildChecklistItem("At least 1 uppercase letter (A-Z)", _hasUppercase, isDark),
          const SizedBox(height: 3),
          _buildChecklistItem("At least 1 number (0-9)", _hasNumber, isDark),
          const SizedBox(height: 3),
          _buildChecklistItem("At least 1 special character (!@#\$%...)", _hasSpecialChar, isDark),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isMet, bool isDark) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 13,
          color: isMet
              ? Colors.green
              : (isDark ? Colors.white30 : Colors.grey.shade400),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 11,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              color: isMet
                  ? (isDark ? Colors.white : Colors.black87)
                  : (isDark ? Colors.white38 : Colors.grey.shade500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordMatchIndicator(bool isDark) {
    final bool isMatch = _doPasswordsMatch;
    return Row(
      children: [
        Icon(
          isMatch ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 13,
          color: isMatch ? Colors.green : Colors.redAccent,
        ),
        const SizedBox(width: 5),
        Text(
          isMatch ? "Passwords match" : "Passwords do not match",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isMatch ? Colors.green : Colors.redAccent,
          ),
        ),
      ],
    );
  }
}

// ── Smooth OTP Verification Bottom Sheet ──

class _SignupOtpVerificationSheet extends StatefulWidget {
  final SendOtpEntity sendOtpEntity;
  final String firstName;
  final String lastName;
  final String? email;
  final String mobileNumber;
  final String countryCode;
  final String password;
  final String fcmToken;
  final LoginBloc loginBloc;
  final Function(dynamic) onSuccess;

  const _SignupOtpVerificationSheet({
    required this.sendOtpEntity,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.mobileNumber,
    required this.countryCode,
    required this.password,
    required this.fcmToken,
    required this.loginBloc,
    required this.onSuccess,
  });

  @override
  State<_SignupOtpVerificationSheet> createState() =>
      _SignupOtpVerificationSheetState();
}

class _SignupOtpVerificationSheetState
    extends State<_SignupOtpVerificationSheet> {
  final TextEditingController _otpController = TextEditingController();
  late String _currentSessionId;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentSessionId = widget.sendOtpEntity.data?.sessionId ?? '';
  }

  @override
  void dispose() {
    // PinCodeTextField might still be finalizing during modal pop animation;
    // Disposing via microtask prevents assertion errors while unmounting.
    final controllerToDispose = _otpController;
    Future.microtask(() => controllerToDispose.dispose());
    super.dispose();
  }

  void _onVerifyPressed() {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      if (mounted) {
        setState(() {
          _errorMessage = "Please enter complete 6-digit OTP";
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isVerifying = true;
        _errorMessage = null;
      });
    }

    widget.loginBloc.add(
      OnRegisterPatientEvent(
        firstName: widget.firstName,
        lastName: widget.lastName,
        email: widget.email,
        mobileNumber: widget.mobileNumber,
        countryCode: widget.countryCode,
        password: widget.password,
        otp: otp,
        sessionId: _currentSessionId,
        fcmToken: widget.fcmToken,
      ),
    );
  }

  void _onResendOtp() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
    widget.loginBloc.add(
      OnSendSignupOtpEvent(
        mobileNumber: widget.mobileNumber,
        countryCode: widget.countryCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = displayWidth(context);

    return BlocListener<LoginBloc, LogInState>(
      bloc: widget.loginBloc,
      listener: (context, state) {
        if (state is SignupSuccessState) {
          if (mounted) {
            setState(() => _isVerifying = false);
          }
          widget.onSuccess(state.loginEntity);
        } else if (state is SignupFailureState) {
          if (mounted) {
            setState(() {
              _isVerifying = false;
              _errorMessage = state.errorMessage;
            });
          }
        } else if (state is SignupOtpSentState) {
          if (mounted) {
            setState(() {
              _currentSessionId = state.sendOtpEntity.data?.sessionId ?? _currentSessionId;
              _errorMessage = null;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP resent successfully!'),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 28,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              "Verify Mobile Number",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle
            Text(
              "Enter the 6-digit verification code sent to\n${widget.countryCode} ${widget.mobileNumber}",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Pin Code Input
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _otpController,
              autoFocus: true,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 48,
                fieldWidth: (screenWidth - 80) / 6,
                activeFillColor: isDark ? Colors.white10 : Colors.grey.shade50,
                inactiveFillColor: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50,
                selectedFillColor: isDark ? Colors.white12 : Colors.white,
                activeColor: primaryColor,
                inactiveColor: isDark ? Colors.white12 : Colors.grey.shade300,
                selectedColor: primaryColor,
                borderWidth: 1.5,
              ),
              textStyle: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
              enableActiveFill: true,
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
              onCompleted: (_) => _onVerifyPressed(),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Resend OTP Countdown
            BlocBuilder<LoginBloc, LogInState>(
              bloc: widget.loginBloc,
              builder: (context, state) {
                if (state is TimerTick && state.secondsRemaining > 0) {
                  return Text(
                    "Resend code in ${state.secondsRemaining}s",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  );
                }
                return GestureDetector(
                  onTap: state is SignupOtpLoadingState ? null : _onResendOtp,
                  child: Text(
                    "Didn't receive code? Resend Code",
                    style: const TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Submit Button
            _isVerifying
                ? const SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator.adaptive(),
                  )
                : CustomElevatedButton(
                    noElevation: true,
                    height: 50,
                    width: double.infinity,
                    text: "Verify & Create Account",
                    onPressed: _onVerifyPressed,
                  ),
          ],
        ),
      ),
    );
  }
}
