part of 'login_bloc.dart';

@immutable

abstract class LogInState {
  const LogInState();
}

class SignInInitial extends LogInState {}

class SignInLoading extends LogInState {}

class ReSendOtpLoading extends LogInState {}

class NavigateToHome extends LogInState {}
class NavigateToSignup extends LogInState {}
class NavigateToSignIn extends LogInState {}
class NavigateToVerifyOtp extends LogInState {}
class NavigateToSelectRole extends LogInState {}
class NavigateToSelectRoleSignUp extends LogInState {}
class NavigateToSelectRoleVerifyOtp extends LogInState {}
class NavigateToSelectWorkSpace extends LogInState {}
class NavForgotPasswordState extends LogInState {
  const NavForgotPasswordState();
}
class SignInError extends LogInState {
  final String errorMessage;

  const SignInError(this.errorMessage);
}

class TimerTick extends LogInState {
  final int secondsRemaining;

  const TimerTick(this.secondsRemaining);
}

class TimerFinished extends LogInState {}
class OnTapEmailSignInState extends LogInState{
  final String email;
  final String password;

  const OnTapEmailSignInState({required this.email, required this.password});
}
class OnTapMobileSignInState extends LogInState{
  final  String mobileNumber;
  final String otp;
  final String sessionId;
  final String countryCode;

  const OnTapMobileSignInState({ required this.mobileNumber, required this.otp, required this.sessionId, required this.countryCode});
}
class LoginLoading extends LogInState {
  const LoginLoading();
}

class LoginSuccess extends LogInState {
  final LoginEntity loginEntity;

  const LoginSuccess({required this.loginEntity});

  @override
  List<Object?> get props => [loginEntity];
}

class LoginFailure extends LogInState {
  final String? errorMessage;

  const LoginFailure({this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}