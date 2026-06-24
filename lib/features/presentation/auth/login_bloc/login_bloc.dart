import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:yiraclinics/features/use_cases/login_email_use_case.dart';
import 'package:yiraclinics/features/use_cases/login_mobile_use_case.dart';

import '../../../../core/constants/clinx_storage_keys.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/local/shared_preferences.dart';
import '../../../domain/entities/login/login_entity.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LogInEvent, LogInState> {
  final LoginMobileUseCase loginMobileUseCase;
  final LoginEmailUseCase loginEmailUseCase;
  final SharedPrefsService sharedPrefsService;

  Timer? _timer;

  static const int _countdownDuration = 30;

  LoginBloc({required this.loginMobileUseCase, required this.loginEmailUseCase, required this.sharedPrefsService})
    : super(SignInInitial()) {
    on<OnVerifyAndLogin>(_onVerifyAndLogin);
    on<OnReSendOtp>(_onReSendOtp);
    on<NavSendOtp>((event, emit) {
      emit(NavigateToVerifyOtp());
    });
    on<NavSelectRole>((event, emit) {
      emit(NavigateToSelectRole());
    });
    on<NavSelectRoleVerifyOtp>((event, emit) {
      emit(NavigateToSelectRoleVerifyOtp());
    });
    on<NavForgotPasswordEvent>((event, emit) {
      emit(NavForgotPasswordState());
    });
    on<NavSelectRoleSignUp>((event, emit) {
      emit(NavigateToSelectRoleSignUp());
    });
    on<NavSignIn>((event, emit) {
      emit(NavigateToSignIn());
    });
    on<NavSignUp>((event, emit) {
      emit(NavigateToSignup());
    });
    on<OnTapEmailSignInEvent>((event, emit) async {
      emit(const LoginLoading());
      try {
        final LoginEntity? result = await loginEmailUseCase(
          LoginWithEmailParams(
            email: event.email.trim(),
            password: event.password,
          ),
        );
        if (result != null) {
          await GlobalSession.instance.update(result);
          emit(LoginSuccess(loginEntity: result));
          if(result.status ?? false){
            await Future.wait([
              sharedPrefsService.setValue<bool>(ClinxStorageKeys.isUserLoggedIn, true),
            ]);
          }
        } else {
          emit(const LoginFailure());
        }
      } catch (error, stackTrace) {
        debugPrint("CRITICAL (LoginBloc): Unexpected authorization exception: $error");
        debugPrint("Stacktrace: $stackTrace");

        emit(LoginFailure(errorMessage: error.toString()));
      }
    });
    on<OnTapMobileSignInEvent>((event, emit) async {
      emit(LoginLoading());
      final LoginEntity? result = await loginMobileUseCase(
        LoginWithMobileParams(
          mobileNumber: event.mobileNumber,
          otp: event.otp,
          sessionId: event.sessionId,
          countryCode: event.countryCode,
        ),
      );
      if (result != null) {
        emit(LoginSuccess(loginEntity: result));
      } else {
        emit(LoginFailure());
      }
    });
    on<_OnTimerTick>(_onTimerTick);
    on<_OnTimerFinished>(_onTimerFinished);
    _startCountdown();
  }
  Future<void> _onVerifyAndLogin(
    OnVerifyAndLogin event,
    Emitter<LogInState> emit,
  ) async {
    emit(SignInLoading());
    try {
      await Future.delayed(const Duration(seconds: 2));
      _timer?.cancel();
      emit(NavigateToHome());
    } catch (e) {
      emit(SignInError(e.toString()));
    }
  }

  Future<void> _onReSendOtp(OnReSendOtp event, Emitter<LogInState> emit) async {
    emit(ReSendOtpLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      _startCountdown();
    } catch (e) {
      emit(SignInError(e.toString()));
    }
  }

  void _onTimerTick(_OnTimerTick event, Emitter<LogInState> emit) {
    emit(TimerTick(event.secondsRemaining));
  }

  void _onTimerFinished(_OnTimerFinished event, Emitter<LogInState> emit) {
    emit(TimerFinished());
  }

  void _startCountdown() {
    _timer?.cancel();
    int currentDuration = _countdownDuration;
    add(_OnTimerTick(currentDuration));

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      currentDuration--;
      if (currentDuration > 0) {
        add(_OnTimerTick(currentDuration));
      } else {
        timer.cancel();
        add(_OnTimerFinished());
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
