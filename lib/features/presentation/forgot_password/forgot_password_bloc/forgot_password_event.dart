part of 'forgot_password_bloc.dart';

@immutable
abstract class ForgotPasswordEvent {}


class ForgotPasswordSendOtp extends ForgotPasswordEvent {
  final String mobileNumber;
  ForgotPasswordSendOtp(this.mobileNumber);
}


class ForgotPasswordSendEmailLink extends ForgotPasswordEvent {
  final String email;
  ForgotPasswordSendEmailLink(this.email);
}


class VerifyOtpClicked extends ForgotPasswordEvent {
  final String otp;
  VerifyOtpClicked({required this.otp});
}


class PasswordInputChanged extends ForgotPasswordEvent {
  final String password;
  PasswordInputChanged({required this.password});
}


class UpdatePasswordFields extends ForgotPasswordEvent {
  final String newPassword;
  final String confirmPassword;

  UpdatePasswordFields({
    required this.newPassword,
    required this.confirmPassword,
  });
}


class ResendOtpRequested extends ForgotPasswordEvent {
  final String target;
  ResendOtpRequested({required this.target});
}


class TimerTicked extends ForgotPasswordEvent {
  final int durationRemaining;
  TimerTicked({required this.durationRemaining});
}


class OnBackProgressClicked extends ForgotPasswordEvent {}


class NavSignInClicked extends ForgotPasswordEvent {}