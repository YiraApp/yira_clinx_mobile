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

class OnSendOtp extends LogInEvent {
  final String mobileNumber;
  final String countryCode;

  const OnSendOtp(this.mobileNumber, this.countryCode);
}

class OnReSendOtp extends LogInEvent {
  final String mobileNumber;
  final String countryCode;

  const OnReSendOtp(this.mobileNumber, this.countryCode);
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

class NavTellAboutYourSelfSignUp extends LogInEvent {
  const NavTellAboutYourSelfSignUp();
}

class _OnTimerTick extends LogInEvent {
  final int secondsRemaining;

  const _OnTimerTick(this.secondsRemaining);
}

class _OnTimerFinished extends LogInEvent {}

class OnCountryCodeChanged extends LogInEvent {
  final String countryCode;
  const OnCountryCodeChanged(this.countryCode);
}

class OnTapEmailSignInEvent extends LogInEvent {
  final String email;
  final String password;
  final String fcmToken;

  const OnTapEmailSignInEvent({
    required this.email,
    required this.password,
    required this.fcmToken,
  });
}

class OnTapMobileSignInEvent extends LogInEvent {
  final String mobileNumber;
  final String otp;
  final String sessionId;
  final String countryCode;
  final String fcmToken;

  const OnTapMobileSignInEvent({
    required this.mobileNumber,
    required this.otp,
    required this.sessionId,
    required this.countryCode,
    required this.fcmToken,
  });
}

class OnInitiateSignup extends LogInEvent {
  final String mobileNumber;
  final String countryCode;
  final String firstName;
  final String lastName;
  final String? email;
  final String password;
  final String? profileImagePath;

  const OnInitiateSignup({
    required this.mobileNumber,
    required this.countryCode,
    required this.firstName,
    required this.lastName,
    this.email,
    required this.password,
    this.profileImagePath,
  });
}

class OnVerifyAndRegisterPatient extends LogInEvent {
  final String otp;
  final String fcmToken;
  final String? sessionId;

  const OnVerifyAndRegisterPatient({
    required this.otp,
    required this.fcmToken,
    this.sessionId,
  });
}