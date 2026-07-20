part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}
class AppStarted extends AuthEvent {}
