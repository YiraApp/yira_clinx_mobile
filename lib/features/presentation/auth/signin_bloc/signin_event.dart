part of 'signin_bloc.dart';

@immutable

abstract class SignInEvent {
  const SignInEvent();
}

class OnVerifyAndLogin extends SignInEvent {
  final String mobileNumber;
  final String otp;

  const OnVerifyAndLogin(this.mobileNumber, this.otp);
}

class OnReSendOtp extends SignInEvent {
  final String mobileNumber;

  const OnReSendOtp(this.mobileNumber);
}
class NavSendOtp extends SignInEvent {
  const NavSendOtp();
}
class NavSignIn extends SignInEvent {
  const NavSignIn();
}
class NavSignUp extends SignInEvent {
  const NavSignUp();
}
class NavSelectRole extends SignInEvent {
  const NavSelectRole();
}
class NavSelectRoleVerifyOtp extends SignInEvent {
  const NavSelectRoleVerifyOtp();
}
class NavSelectRoleSignUp extends SignInEvent {
  const NavSelectRoleSignUp();
}
/// Triggered internally every second by our countdown timer loop
class _OnTimerTick extends SignInEvent {
  final int secondsRemaining;

  const _OnTimerTick(this.secondsRemaining);
}

/// Triggered internally when the countdown hits zero
class _OnTimerFinished extends SignInEvent {}
