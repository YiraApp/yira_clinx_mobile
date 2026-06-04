part of 'change_password_bloc.dart';

@immutable
abstract class ChangePasswordState {
  const ChangePasswordState();
}

class ChangePasswordInitial extends ChangePasswordState {}
class ChangePasswordLoading extends ChangePasswordState {}
class ChangePasswordSuccess extends ChangePasswordState {}
class ChangePasswordError extends ChangePasswordState {
  final String errorMessage;
  const ChangePasswordError(this.errorMessage);
}

class PostChangeLogoutSuccess extends ChangePasswordState {}
