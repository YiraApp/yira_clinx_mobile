import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/login/login_entity.dart';
import '../../../use_cases/auth_use_case.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthUseCase authUseCase;
  AuthBloc(this.authUseCase) : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      final bool isLoggedIn = authUseCase.execute();
      if (isLoggedIn) {
        var user = await authUseCase.localData();
        if (user != null) {
          emit(Authenticated( user));
        } else {
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
    });
  }
}
