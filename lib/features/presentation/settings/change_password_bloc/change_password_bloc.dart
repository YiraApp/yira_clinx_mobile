import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'change_password_event.dart';
part 'change_password_state.dart';



class ChangePasswordBloc extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  ChangePasswordBloc() : super(ChangePasswordInitial()) {
    on<OnSubmitChangePassword>(_onSubmitChangePassword);
    on<OnProcessPostChangeLogout>(_onProcessPostChangeLogout);
  }

  Future<void> _onSubmitChangePassword(
      OnSubmitChangePassword event,
      Emitter<ChangePasswordState> emit,
      ) async {
    emit(ChangePasswordLoading());
    try {
      // await changePasswordUseCase(event.newPassword);
      await Future.delayed(const Duration(seconds: 2));
      emit(ChangePasswordSuccess());
    } catch (e) {
      emit(ChangePasswordError(e.toString()));
    }
  }

  Future<void> _onProcessPostChangeLogout(
      OnProcessPostChangeLogout event,
      Emitter<ChangePasswordState> emit,
      ) async {
    try {
      // TODO: Connect to your Clean data repository layers
      // final deviceId = await getDeviceIdUseCase();
      // await logoutUseCase(deviceId);

      await Future.delayed(const Duration(seconds: 1)); // Mock session cache clearance
      emit(PostChangeLogoutSuccess());
    } catch (e) {
      // Fallback gracefully to let them redirect to sign-in even if remote session invalidation hits a snag
      emit(PostChangeLogoutSuccess());
    }
  }
}
