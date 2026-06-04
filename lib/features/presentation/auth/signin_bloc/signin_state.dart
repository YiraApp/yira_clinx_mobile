part of 'signin_bloc.dart';

@immutable

abstract class SignInState {
  const SignInState();
}

class SignInInitial extends SignInState {}

class SignInLoading extends SignInState {}

class ReSendOtpLoading extends SignInState {}

class NavigateToHome extends SignInState {}
class NavigateToSignup extends SignInState {}
class NavigateToSignIn extends SignInState {}
class NavigateToVerifyOtp extends SignInState {}
class NavigateToSelectRole extends SignInState {}
class NavigateToSelectRoleSignUp extends SignInState {}
class NavigateToSelectRoleVerifyOtp extends SignInState {}
class NavigateToSelectWorkSpace extends SignInState {}

class SignInError extends SignInState {
  final String errorMessage;

  const SignInError(this.errorMessage);
}

class TimerTick extends SignInState {
  final int secondsRemaining;

  const TimerTick(this.secondsRemaining);
}

class TimerFinished extends SignInState {}
