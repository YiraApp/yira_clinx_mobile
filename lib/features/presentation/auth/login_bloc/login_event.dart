part of 'login_bloc.dart';

@immutable

abstract class LogInEvent {
  const LogInEvent();
}

class OnVerifyAndLogin extends LogInEvent {
  final String mobileNumber;
  final String otp;

  const OnVerifyAndLogin(this.mobileNumber, this.otp);
}

class OnReSendOtp extends LogInEvent {
  final String mobileNumber;

  const OnReSendOtp(this.mobileNumber);
}
class NavSendOtp extends LogInEvent {
  const NavSendOtp();
}
class NavSignIn extends LogInEvent {
  const NavSignIn();
}
class NavSignUp extends LogInEvent {
  const NavSignUp();
}
class NavForgotPasswordEvent extends LogInEvent {
  const NavForgotPasswordEvent();
}
class NavSelectRole extends LogInEvent {
  const NavSelectRole();
}
class NavSelectRoleVerifyOtp extends LogInEvent {
  const NavSelectRoleVerifyOtp();
}
class NavSelectRoleSignUp extends LogInEvent {
  const NavSelectRoleSignUp();
}
/// Triggered internally every second by our countdown timer loop
class _OnTimerTick extends LogInEvent {
  final int secondsRemaining;

  const _OnTimerTick(this.secondsRemaining);
}

/// Triggered internally when the countdown hits zero
class _OnTimerFinished extends LogInEvent {}
class OnTapEmailSignInEvent extends LogInEvent{
  final String email;
  final String password;

  const OnTapEmailSignInEvent({required this.email, required this.password});
}
class OnTapMobileSignInEvent extends LogInEvent{
  final  String mobileNumber;
  final String otp;
  final String sessionId;
  final String countryCode;

  const OnTapMobileSignInEvent({ required this.mobileNumber, required this.otp, required this.sessionId, required this.countryCode});
}