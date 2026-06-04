part of 'change_password_bloc.dart';

@immutable
abstract class ChangePasswordEvent {
  const ChangePasswordEvent();
}

class OnSubmitChangePassword extends ChangePasswordEvent {
  final String newPassword;
  final String confirmPassword;

  const OnSubmitChangePassword({
    required this.newPassword,
    required this.confirmPassword,
  });
}

class OnProcessPostChangeLogout extends ChangePasswordEvent {}