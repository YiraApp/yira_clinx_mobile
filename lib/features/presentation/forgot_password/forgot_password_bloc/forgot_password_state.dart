part of 'forgot_password_bloc.dart';

@immutable
abstract class ForgotPasswordState {}

class ForgotPasswordInitial extends ForgotPasswordState {}
class ForgotPasswordLoading extends ForgotPasswordState {}
class ReSendOtpLoading extends ForgotPasswordState {}

class ShowOtpField extends ForgotPasswordState {
  final int displaySeconds;
  final bool isButtonActive;
  final String recoveryTarget;

  ShowOtpField({
    this.displaySeconds = 30,
    this.isButtonActive = false,
    required this.recoveryTarget,
  });
}

// UPDATE: Added parameters to track password metric states safely
class ShowPasswordResetFields extends ForgotPasswordState {
  final double passwordStrength;
  final bool isPasswordGood;

  ShowPasswordResetFields({
    this.passwordStrength = 0.0,
    this.isPasswordGood = false,
  });
}

class ForgotPasswordSuccess extends ForgotPasswordState {}

class ForgotPasswordFailure extends ForgotPasswordState {
  final String error;
  ForgotPasswordFailure(this.error);
}

class NavigateToSignIn extends ForgotPasswordState {}