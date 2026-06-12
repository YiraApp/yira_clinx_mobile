import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

enum RecoveryStep { initialForm, otpPhase, passwordPhase }

class ForgotPasswordBloc extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  StreamSubscription<int>? _timerSubscription;
  static const int _countdownDuration = 30;

  RecoveryStep currentStep = RecoveryStep.initialForm;

  int cachedSeconds = _countdownDuration;
  bool cachedBtnActive = false;
  String cachedTarget = '';
  double cachedStrength = 0.0;
  bool cachedIsPasswordGood = false;

  ForgotPasswordBloc() : super(ForgotPasswordInitial()) {

    on<ForgotPasswordSendOtp>((event, emit) async {
      emit(ForgotPasswordLoading());
      await Future.delayed(const Duration(milliseconds: 500));

      currentStep = RecoveryStep.otpPhase;
      cachedTarget = event.mobileNumber;
      cachedSeconds = _countdownDuration;
      cachedBtnActive = false;

      _startNewCountdown();
      emit(ShowOtpField(
        displaySeconds: _countdownDuration,
        isButtonActive: false,
        recoveryTarget: event.mobileNumber,
      ));
    });

    on<ForgotPasswordSendEmailLink>((event, emit) async {
      emit(ForgotPasswordLoading());
      await Future.delayed(const Duration(milliseconds: 500));

      currentStep = RecoveryStep.otpPhase;
      cachedTarget = event.email;
      cachedSeconds = _countdownDuration;
      cachedBtnActive = false;

      _startNewCountdown();
      emit(ShowOtpField(
        displaySeconds: _countdownDuration,
        isButtonActive: false,
        recoveryTarget: event.email,
      ));
    });

    on<TimerTicked>((event, emit) {
      cachedSeconds = event.durationRemaining;
      cachedBtnActive = event.durationRemaining <= 0;

      if (state is ShowOtpField) {
        emit(ShowOtpField(
          displaySeconds: cachedSeconds,
          isButtonActive: cachedBtnActive,
          recoveryTarget: cachedTarget,
        ));
      }
    });

    on<ResendOtpRequested>((event, emit) async {
      emit(ReSendOtpLoading());
      await Future.delayed(const Duration(milliseconds: 600));

      cachedSeconds = _countdownDuration;
      cachedBtnActive = false;

      _startNewCountdown();
      emit(ShowOtpField(
        displaySeconds: _countdownDuration,
        isButtonActive: false,
        recoveryTarget: cachedTarget,
      ));
    });

    on<VerifyOtpClicked>((event, emit) async {
      emit(ForgotPasswordLoading());
      await Future.delayed(const Duration(milliseconds: 500));

      if (event.otp.isNotEmpty && event.otp.length == 4) {
        _timerSubscription?.cancel();
        currentStep = RecoveryStep.passwordPhase;
        emit(ShowPasswordResetFields(
          passwordStrength: cachedStrength,
          isPasswordGood: cachedIsPasswordGood,
        ));
      } else {
        emit(ForgotPasswordFailure("Please enter a valid 4-digit OTP"));
        emit(ShowOtpField(
          displaySeconds: cachedSeconds,
          isButtonActive: cachedBtnActive,
          recoveryTarget: cachedTarget,
        ));
      }
    });

    on<OnBackProgressClicked>((event, emit) {
      if (currentStep == RecoveryStep.passwordPhase) {
        currentStep = RecoveryStep.otpPhase;
        emit(ShowOtpField(
          displaySeconds: cachedSeconds,
          isButtonActive: cachedBtnActive,
          recoveryTarget: cachedTarget,
        ));
      } else if (currentStep == RecoveryStep.otpPhase) {
        _timerSubscription?.cancel();
        currentStep = RecoveryStep.initialForm;
        emit(ForgotPasswordInitial()); // Re-emits Initial to display Mobile/Email fields cleanly
      }
    });

    on<PasswordInputChanged>((event, emit) {
      final password = event.password;

      bool hasMinLength = password.length >= 8;
      bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
      bool hasNumber = password.contains(RegExp(r'[0-9]'));
      bool hasSpecialCharacter = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      int validCount = 0;
      if (hasMinLength) validCount++;
      if (hasUppercase) validCount++;
      if (hasNumber) validCount++;
      if (hasSpecialCharacter) validCount++;

      cachedStrength = validCount / 4;
      cachedIsPasswordGood = validCount == 4;

      emit(ShowPasswordResetFields(
        passwordStrength: cachedStrength,
        isPasswordGood: cachedIsPasswordGood,
      ));
    });

    on<UpdatePasswordFields>((event, emit) async {
      if (!cachedIsPasswordGood) {
        emit(ForgotPasswordFailure("Password parameters have not satisfied validation rules."));
        emit(ShowPasswordResetFields(passwordStrength: cachedStrength, isPasswordGood: cachedIsPasswordGood));
        return;
      }

      emit(ForgotPasswordLoading());
      await Future.delayed(const Duration(milliseconds: 500));

      if (event.newPassword.isEmpty || event.confirmPassword.isEmpty) {
        emit(ForgotPasswordFailure("Password entries cannot be blank."));
        emit(ShowPasswordResetFields(passwordStrength: cachedStrength, isPasswordGood: cachedIsPasswordGood));
      } else if (event.newPassword == event.confirmPassword) {
        emit(ForgotPasswordSuccess());
        currentStep = RecoveryStep.initialForm;
        emit(NavigateToSignIn());
      } else {
        emit(ForgotPasswordFailure("Passwords do not match."));
        emit(ShowPasswordResetFields(passwordStrength: cachedStrength, isPasswordGood: cachedIsPasswordGood));
      }
    });

    on<NavSignInClicked>((event, emit) {
      _timerSubscription?.cancel();
      currentStep = RecoveryStep.initialForm;
      emit(NavigateToSignIn());
    });
  }

  void _startNewCountdown() {
    _timerSubscription?.cancel();
    _timerSubscription = Stream<int>.periodic(
      const Duration(seconds: 1),
          (computationCount) => _countdownDuration - computationCount - 1,
    ).take(_countdownDuration).listen((secondsLeft) {
      add(TimerTicked(durationRemaining: secondsLeft));
    });
  }

  @override
  Future<void> close() {
    _timerSubscription?.cancel();
    return super.close();
  }
}