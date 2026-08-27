import 'dart:io';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/utils/dismiss_key_board.dart';
import 'package:yiraclinics/features/presentation/auth/login_bloc/login_bloc.dart';

class PasswordStrength {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  const PasswordStrength({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
  });

  static PasswordStrength calculate(String password) {
    return PasswordStrength(
      hasMinLength: password.length >= 8,
      hasUppercase: password.contains(RegExp(r'[A-Z]')),
      hasLowercase: password.contains(RegExp(r'[a-z]')),
      hasDigit: password.contains(RegExp(r'[0-9]')),
      hasSpecialChar: password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]')),
    );
  }

  int get score {
    int s = 0;
    if (hasMinLength) s++;
    if (hasUppercase && hasLowercase) s++;
    if (hasDigit) s++;
    if (hasSpecialChar) s++;
    return s;
  }

  bool get isStrong => score >= 4;
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final FocusNode firstNameFocus = FocusNode();
  final FocusNode lastNameFocus = FocusNode();
  final FocusNode mobileFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  String _selectedCountryCode = "+91";
  String? _profileImagePath;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  PasswordStrength _passwordStrength = const PasswordStrength(
    hasMinLength: false,
    hasUppercase: false,
    hasLowercase: false,
    hasDigit: false,
    hasSpecialChar: false,
  );

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_onPasswordChanged);
    confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    passwordController.removeListener(_onPasswordChanged);
    firstNameController.dispose();
    lastNameController.dispose();
    mobileNumberController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    firstNameFocus.dispose();
    lastNameFocus.dispose();
    mobileFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordStrength = PasswordStrength.calculate(passwordController.text);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _profileImagePath = image.path;
        });
      }
    } catch (e) {
      debugPrint("Image picker exception: $e");
    }
  }

  void _showImagePickerModal(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select Profile Photo',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: primaryColor),
                  ),
                  title: Text(
                    'Take a Photo',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Colors.purple),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_profileImagePath != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    ),
                    title: const Text(
                      'Remove Photo',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _profileImagePath = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitSignup(BuildContext context) {
    context.dismissKeyboard();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!_passwordStrength.isStrong) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please create a strong password meeting all security requirements.',
            style: TextStyle(fontFamily: appPoppinFont),
          ),
          backgroundColor: Colors.amber.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Passwords do not match.',
            style: TextStyle(fontFamily: appPoppinFont),
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    context.read<LoginBloc>().add(
          OnInitiateSignup(
            mobileNumber: mobileNumberController.text.trim(),
            countryCode: _selectedCountryCode,
            firstName: firstNameController.text.trim(),
            lastName: lastNameController.text.trim(),
            email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
            password: passwordController.text,
            profileImagePath: _profileImagePath,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTab = isTablet(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = displayWidth(context);

    return GestureDetector(
      onTap: () => context.dismissKeyboard(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Create Patient Account',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTab ? 580 : double.infinity,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double refWidth = isTab ? constraints.maxWidth : screenWidth;

                return BlocConsumer<LoginBloc, LogInState>(
                  buildWhen: (previous, current) =>
                      current is SendSignupOtpLoading ||
                      current is SendSignupOtpFailureState ||
                      current is NavigateToVerifyOtpForSignup ||
                      current is NavigateToSignIn,
                  listener: (context, state) {
                    if (state is NavigateToVerifyOtpForSignup) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.verifyOtp,
                        arguments: {
                          'sendOtpEntity': state.sendOtpEntity,
                          'isSignup': true,
                        },
                      );
                    } else if (state is SendSignupOtpFailureState) {
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
                    } else if (state is NavigateToSignIn) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.signIn,
                        (route) => false,
                      );
                    }
                  },
                  builder: (context, state) {
                    final bool isLoading = state is SendSignupOtpLoading;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isTab
                            ? screenHorizontalSpacePadding
                            : (screenHorizontalSpacePadding / 1.5),
                        vertical: 12,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Profile Picture & Org Badge
                            Center(
                              child: Column(
                                children: [
                                  _buildAvatarPicker(context, isDarkMode),
                                  const SizedBox(height: 12),
                                  _buildOrganizationBadge(isDarkMode, refWidth, isTab),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // First & Last Name
                            _buildNameFields(isDarkMode, refWidth, isTab),

                            const SizedBox(height: 16),

                            // Mobile Number Field
                            _buildMobileField(isDarkMode, refWidth, isTab),

                            const SizedBox(height: 16),

                            // Optional Email Field
                            _buildEmailField(isDarkMode, refWidth, isTab),

                            const SizedBox(height: 16),

                            // Password Field
                            _buildPasswordField(isDarkMode, refWidth, isTab),

                            const SizedBox(height: 10),

                            // Strong Password Meter
                            _buildPasswordStrengthMeter(isDarkMode, refWidth, isTab),

                            const SizedBox(height: 16),

                            // Confirm Password Field
                            _buildConfirmPasswordField(isDarkMode, refWidth, isTab),

                            const SizedBox(height: 28),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : () => _submitSignup(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF005696),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.verified_user_rounded, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Verify Phone & Sign Up',
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontSize: isTab ? refWidth * 0.028 : 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Footer: Sign In Link
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.signIn,
                                    (route) => false,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: RichText(
                                    text: TextSpan(
                                      text: "Already have an account? ",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: isTab ? refWidth * 0.024 : 14,
                                        color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "Sign In",
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: isTab ? refWidth * 0.024 : 14,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF005696),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
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

  // --- WIDGET BUILDERS ---

  Widget _buildAvatarPicker(BuildContext context, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _showImagePickerModal(context, isDarkMode),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF005696), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF005696).withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: ClipOval(
                child: Container(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  child: _profileImagePath != null
                      ? Image.file(
                          File(_profileImagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 52,
                            color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
                          ),
                        ),
                ),
              ),
            ),
          ),
          PositionContainer(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF005696),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationBadge(bool isDarkMode, double refWidth, bool isTab) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF005696).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF005696).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_hospital_rounded,
            size: 15,
            color: Color(0xFF005696),
          ),
          const SizedBox(width: 6),
          Text(
            'Patient Account  •  Yira Hospitals',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? refWidth * 0.022 : 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF005696),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameFields(bool isDarkMode, double refWidth, bool isTab) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('First Name *', isDarkMode, refWidth, isTab),
              const SizedBox(height: 6),
              TextFormField(
                controller: firstNameController,
                focusNode: firstNameFocus,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: _inputTextStyle(isDarkMode, refWidth, isTab),
                decoration: _inputDecoration(
                  hint: 'First name',
                  isDarkMode: isDarkMode,
                  prefixIcon: Icons.badge_outlined,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Required';
                  }
                  if (val.trim().length < 2) {
                    return 'Min 2 chars';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Last Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Last Name *', isDarkMode, refWidth, isTab),
              const SizedBox(height: 6),
              TextFormField(
                controller: lastNameController,
                focusNode: lastNameFocus,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: _inputTextStyle(isDarkMode, refWidth, isTab),
                decoration: _inputDecoration(
                  hint: 'Last name',
                  isDarkMode: isDarkMode,
                  prefixIcon: Icons.person_outline_rounded,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileField(bool isDarkMode, double refWidth, bool isTab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Mobile Number *', isDarkMode, refWidth, isTab),
        const SizedBox(height: 6),
        TextFormField(
          controller: mobileNumberController,
          focusNode: mobileFocus,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: _inputTextStyle(isDarkMode, refWidth, isTab),
          decoration: _inputDecoration(
            hint: '10-digit mobile number',
            isDarkMode: isDarkMode,
            prefix: Theme(
              data: ThemeData(
                dialogTheme: DialogThemeData(
                  barrierColor: isDarkMode ? Colors.black26 : Colors.black54,
                ),
              ),
              child: CountryCodePicker(
                showFlag: true,
                showFlagDialog: true,
                initialSelection: 'IN',
                favorite: const ['+91', 'IN'],
                textStyle: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? refWidth * 0.026 : 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                onChanged: (countryCode) {
                  setState(() {
                    _selectedCountryCode = countryCode.dialCode ?? '+91';
                  });
                  context.read<LoginBloc>().add(
                        OnCountryCodeChanged(_selectedCountryCode),
                      );
                },
                dialogBackgroundColor:
                    isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                dialogTextStyle: TextStyle(
                  fontFamily: appPoppinFont,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                searchStyle: TextStyle(
                  fontFamily: appPoppinFont,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                searchDecoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Search Country",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter your mobile number';
            }
            if (val.trim().length != 10) {
              return 'Enter a valid 10-digit mobile number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField(bool isDarkMode, double refWidth, bool isTab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildFieldLabel('Email Address', isDarkMode, refWidth, isTab),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Optional',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: emailController,
          focusNode: emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: _inputTextStyle(isDarkMode, refWidth, isTab),
          decoration: _inputDecoration(
            hint: 'name@example.com (Optional)',
            isDarkMode: isDarkMode,
            prefixIcon: Icons.email_outlined,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return null; // Optional!
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(val.trim())) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField(bool isDarkMode, double refWidth, bool isTab) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Password *', isDarkMode, refWidth, isTab),
        const SizedBox(height: 6),
        TextFormField(
          controller: passwordController,
          focusNode: passwordFocus,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          style: _inputTextStyle(isDarkMode, refWidth, isTab),
          decoration: _inputDecoration(
            hint: 'Create a strong password',
            isDarkMode: isDarkMode,
            prefixIcon: Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'Please enter a password';
            }
            if (val.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthMeter(bool isDarkMode, double refWidth, bool isTab) {
    final score = _passwordStrength.score;
    Color strengthColor;
    String strengthLabel;

    switch (score) {
      case 1:
        strengthColor = Colors.red;
        strengthLabel = 'Weak';
        break;
      case 2:
        strengthColor = Colors.orange;
        strengthLabel = 'Fair';
        break;
      case 3:
        strengthColor = Colors.amber.shade700;
        strengthLabel = 'Good';
        break;
      case 4:
        strengthColor = const Color(0xFF10B981);
        strengthLabel = 'Strong';
        break;
      default:
        strengthColor = isDarkMode ? Colors.white24 : Colors.grey.shade300;
        strengthLabel = 'Too short';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1F26) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password Strength',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              if (passwordController.text.isNotEmpty)
                Text(
                  strengthLabel,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: strengthColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // 4 Segment Bars
          Row(
            children: List.generate(4, (index) {
              final isFilled = index < score && passwordController.text.isNotEmpty;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isFilled
                        ? strengthColor
                        : (isDarkMode ? Colors.white12 : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          // Checklist
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildRequirementItem('8+ Chars', _passwordStrength.hasMinLength, isDarkMode),
              _buildRequirementItem('Uppercase', _passwordStrength.hasUppercase, isDarkMode),
              _buildRequirementItem('Lowercase', _passwordStrength.hasLowercase, isDarkMode),
              _buildRequirementItem('Number', _passwordStrength.hasDigit, isDarkMode),
              _buildRequirementItem('Symbol (!@#\$)', _passwordStrength.hasSpecialChar, isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String title, bool isMet, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 13,
          color: isMet ? const Color(0xFF10B981) : (isDarkMode ? Colors.white38 : Colors.grey),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 11,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
            color: isMet
                ? (isDarkMode ? Colors.white : Colors.black87)
                : (isDarkMode ? Colors.white38 : Colors.grey.shade600),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField(bool isDarkMode, double refWidth, bool isTab) {
    final bool hasText = confirmPasswordController.text.isNotEmpty;
    final bool isMatching = hasText && confirmPasswordController.text == passwordController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Confirm Password *', isDarkMode, refWidth, isTab),
        const SizedBox(height: 6),
        TextFormField(
          controller: confirmPasswordController,
          focusNode: confirmPasswordFocus,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submitSignup(context),
          style: _inputTextStyle(isDarkMode, refWidth, isTab),
          decoration: _inputDecoration(
            hint: 'Re-enter your password',
            isDarkMode: isDarkMode,
            prefixIcon: Icons.lock_reset_rounded,
            suffix: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasText)
                  Icon(
                    isMatching ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 18,
                    color: isMatching ? const Color(0xFF10B981) : Colors.red,
                  ),
                IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: isDarkMode ? Colors.white60 : Colors.grey.shade600,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ],
            ),
          ),
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'Please confirm your password';
            }
            if (val != passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, bool isDarkMode, double refWidth, bool isTab) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: isTab ? refWidth * 0.025 : 13,
        fontWeight: FontWeight.w500,
        color: isDarkMode ? Colors.white70 : const Color(0xFF1E293B),
      ),
    );
  }

  TextStyle _inputTextStyle(bool isDarkMode, double refWidth, bool isTab) {
    return TextStyle(
      fontFamily: appPoppinFont,
      fontSize: isTab ? refWidth * 0.026 : 14,
      fontWeight: FontWeight.w500,
      color: isDarkMode ? Colors.white : Colors.black87,
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required bool isDarkMode,
    IconData? prefixIcon,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: 13,
        color: isDarkMode ? Colors.white38 : Colors.grey.shade400,
      ),
      filled: true,
      fillColor: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefixIcon: prefixIcon != null
          ? Icon(
              prefixIcon,
              size: 20,
              color: isDarkMode ? Colors.white54 : Colors.grey.shade500,
            )
          : prefix,
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF005696),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}

class PositionContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Decoration decoration;

  const PositionContainer({
    super.key,
    required this.child,
    required this.padding,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}
