import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:yiraclinics/features/domain/entities/send_otp/send_otp_entity.dart';
import 'package:yiraclinics/features/use_cases/login_email_use_case.dart';
import 'package:yiraclinics/features/use_cases/login_mobile_use_case.dart';

import '../../../../core/constants/clinx_storage_keys.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/local/shared_preferences.dart';
import '../../../domain/entities/login/login_entity.dart';
import '../../../use_cases/send_otp_use_case.dart';
import '../../../use_cases/update_fcm_token_use_case.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LogInEvent, LogInState> {
  final LoginMobileUseCase loginMobileUseCase;
  final LoginEmailUseCase loginEmailUseCase;
  final UpdateFcmTokenUseCase updateFcmTokenUseCase;
  final SharedPrefsService sharedPrefsService;
  final SendOtpUseCase sendOtpUseCase;

  Timer? _timer;
  static const int _countdownDuration = reSendOtpDuration;
  String currentCountryCode = "+91";
  String bloodGroup = '';
  String relationType = '';
  LoginBloc({
    required this.loginMobileUseCase,
    required this.loginEmailUseCase,
    required this.sharedPrefsService,
    required this.sendOtpUseCase, required this.updateFcmTokenUseCase,
  }) : super(SignInInitial()) {
    // Auth & API Events
    on<OnCountryCodeChanged>((event, emit) {
      currentCountryCode = event.countryCode;
    });
    on<OnTapEmailSignInEvent>(_onTapEmailSignIn);
    on<OnTapMobileSignInEvent>(_onTapMobileSignIn);
    on<OnVerifyAndLogin>(_onVerifyAndLogin);
    on<OnReSendOtp>(_onReSendOtp);
    on<OnSendOtp>(_onSendOtp);
    on<NavSelectRole>((event, emit) => emit(NavigateToSelectRole()));
    on<NavSelectRoleVerifyOtp>(
      (event, emit) => emit(NavigateToSelectRoleVerifyOtp()),
    );
    on<NavForgotPasswordEvent>((event, emit) => emit(NavForgotPasswordState()));
    on<NavSelectRoleSignUp>(
      (event, emit) => emit(NavigateToSelectRoleSignUp()),
    );

    on<NavTellAboutYourSelfSignUp>(
      (event, emit) => emit(NavTellAboutYourSelfSignUpState()),
    );
    on<NavSignIn>((event, emit) => emit(NavigateToSignIn()));
    on<NavSignUp>((event, emit) => emit(NavigateToSignup()));

    // Internal Timer Events
    on<_OnTimerTick>(_onTimerTick);
    on<_OnTimerFinished>(_onTimerFinished);
  }

  // --- Event Handlers ---

  Future<void> _onTapEmailSignIn(
    OnTapEmailSignInEvent event,
    Emitter<LogInState> emit,
  ) async {
    emit(const LoginLoading());
    try {
      final LoginEntity? result = await loginEmailUseCase(
        LoginWithEmailParams(
          email: event.email.trim(),
          password: event.password,
        ),
      );

      if (result == null || !(result.status ?? false)) {
        final failureMessage = result?.message ?? "Invalid email or password.";
        emit(LoginFailure(errorMessage: failureMessage));
        return;
      } else {
        await Future.wait([
          GlobalSession.instance.update(result),
          sharedPrefsService.setValue<bool>(
            ClinxStorageKeys.isUserLoggedIn,
            true,
          ),
        ]);
        if (event.fcmToken.isNotEmpty && event.fcmToken != 'no_token_available') {
          try {
            await updateFcmTokenUseCase.call(event.fcmToken);
            debugPrint("Production Login Pipeline - Remote FCM Token synced successfully.");
          } catch (fcmError, fcmStack) {
            debugPrint("CRITICAL (LoginBloc) - FCM Token sync failed background tracking: $fcmError\n$fcmStack");
          }
        }
        emit(LoginSuccess(loginEntity: result));
      }
    } catch (error, stackTrace) {
      debugPrint(
        "CRITICAL (LoginBloc): Unexpected authorization exception: $error",
      );
      debugPrint("Stacktrace: $stackTrace");
      emit(LoginFailure(errorMessage: error.toString()));
    }
  }

  Future<void> _onTapMobileSignIn(
    OnTapMobileSignInEvent event,
    Emitter<LogInState> emit,
  ) async {
    emit(const LoginLoading());
    try {
      final LoginEntity? result = await loginMobileUseCase(
        LoginWithMobileParams(
          mobileNumber: event.mobileNumber,
          otp: event.otp,
          sessionId: event.sessionId,
          countryCode: event.countryCode,
        ),
      );
      {}
      if (result == null || !(result.status ?? false)) {
        final failureMessage =
            result?.message ?? "Invalid OTP or mobile number.";
        emit(LoginFailure(errorMessage: failureMessage));
        return;
      } else {
        await Future.wait([
          GlobalSession.instance.update(result),
          sharedPrefsService.setValue<bool>(
            ClinxStorageKeys.isUserLoggedIn,
            true,
          ),
        ]);
        if (event.fcmToken.isNotEmpty && event.fcmToken != 'no_token_available') {
          try {
            await updateFcmTokenUseCase.call(event.fcmToken);
            debugPrint("Production Login Pipeline - Remote FCM Token synced successfully.");
          } catch (fcmError, fcmStack) {
            debugPrint("CRITICAL (LoginBloc) - FCM Token sync failed background tracking: $fcmError\n$fcmStack");
          }
        }
        emit(LoginSuccess(loginEntity: result));
      }
    } catch (exception) {
      debugPrint(
        "CRITICAL (LoginBloc): Unexpected mobile login exception: $exception",
      );
      emit(LoginFailure(errorMessage: exception.toString()));
    }
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

  Future<void> _onSendOtp(OnSendOtp event, Emitter<LogInState> emit) async {
    emit(SendOtpLoading());
    try {
      final SendOtpEntity? result = await sendOtpUseCase(
        countryCode: event.countryCode.trim(),
        mobileNumber: event.mobileNumber.trim(),
        isReSend: false,
      );

      if (result == null || !(result.status ?? false)) {
        final failureMessage =
            result?.message ?? "Failed to send OTP. Please verify your number.";
        emit(SendOtpFailureState(failureMessage));
        return;
      } else {
        _timer?.cancel();
        _startCountdown();
        emit(NavigateToVerifyOtp(sendOtpEntity: result));
      }
    } catch (error, stackTrace) {
      debugPrint(
        "CRITICAL (LoginBloc): Unexpected error during Send OTP sequence: $error",
      );
      debugPrint("Stacktrace: $stackTrace");

      emit(SendOtpFailureState(error.toString()));
    }
  }

  Future<void> _onReSendOtp(OnReSendOtp event, Emitter<LogInState> emit) async {
    emit(ReSendOtpLoading());
    try {
      final SendOtpEntity? result = await sendOtpUseCase(
        countryCode: event.countryCode.trim(),
        mobileNumber: event.mobileNumber.trim(),
        isReSend: true,
      );

      if (result == null || !(result.status ?? false)) {
        final failureMessage =
            result?.message ?? "Failed to send OTP. Please verify your number.";
        emit(ReSendOtpFailureState(failureMessage));
        return;
      } else {
        _timer?.cancel();
        _startCountdown();
      }
    } catch (error, stackTrace) {
      debugPrint(
        "CRITICAL (LoginBloc): Unexpected error during Send OTP sequence: $error",
      );
      debugPrint("Stacktrace: $stackTrace");

      emit(ReSendOtpFailureState(error.toString()));
    }
  }

  // --- Timer Helper Routines ---

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

      if (currentDuration >= 0) {
        add(_OnTimerTick(currentDuration));
      }
      if (currentDuration <= 0) {
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
