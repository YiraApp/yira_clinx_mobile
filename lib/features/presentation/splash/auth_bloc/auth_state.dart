part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

class Authenticated extends AuthState {
  final LoginEntity user;
  Authenticated(this.user);
}
class Unauthenticated extends AuthState {}
