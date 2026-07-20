import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/features/use_cases/forget_password_send_otp_use_case.dart';
import 'package:yiraclinics/features/use_cases/save_reset_password_use_case.dart';
import '../../../../core/constants/constants.dart';
import '../../../domain/entities/common/common_entity.dart';
import '../../../domain/entities/forget_password/forget_password_send_otp_entity.dart';
import '../../../domain/entities/forget_password/forget_password_verify_otp_enity.dart';
import '../../../use_cases/forget_password_verify_otp_use_case.dart';

part 'forgot_password_event.dart';
part 'forgot_password_state.dart';

enum RecoveryStep { initialForm, otpPhase, passwordPhase }

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  final ForgetPasswordSendOtpUseCase forgetPasswordSendOtpUseCase;
  final ForgetPasswordVerifyOtpUseCase forgetPasswordVerifyOtpUseCase;
  final SaveResetPasswordUseCase saveResetPasswordUseCase;

  StreamSubscription<int>? _timerSubscription;
  static const int _countdownDuration = reSendOtpDuration;

  String currentCountryCode = "91";
  RecoveryStep currentStep = RecoveryStep.initialForm;

  int cachedSeconds = _countdownDuration;
  bool cachedBtnActive = false;
  String cachedTarget = '';
  String _cachedContactType = "mobile";
  String _cachedCountryCode = "";
  String _cachedSessionId = "";
  double cachedStrength = 0.0;
  bool cachedIsPasswordGood = false;

  ForgotPasswordBloc({
    required this.forgetPasswordSendOtpUseCase,
    required this.forgetPasswordVerifyOtpUseCase,
    required this.saveResetPasswordUseCase,
  }) : super(ForgotPasswordInitial()) {
    on<OnCountryCodeChangedEvent>((event, emit) {
      currentCountryCode = event.countryCode.replaceAll('+', '');
    });

    on<ForgotPasswordSendOtp>(_onForgotPasswordSendOtp);

    on<ForgotPasswordSendEmailLink>((event, emit) {
      emit(ForgotPasswordLoading());

      currentStep = RecoveryStep.otpPhase;
      cachedTarget = event.email;
      _cachedContactType = "email";
      _cachedCountryCode = "";
      _cachedSessionId = "";
      cachedSeconds = _countdownDuration;
      cachedBtnActive = false;

      _startNewCountdown();
      emit(
        ShowOtpField(
          displaySeconds: _countdownDuration,
          isButtonActive: false,
          recoveryTarget: event.email,
        ),
      );
    });

    on<TimerTicked>((event, emit) {
      cachedSeconds = event.durationRemaining;
      cachedBtnActive = event.durationRemaining <= 0;

      if (currentStep == RecoveryStep.otpPhase) {
        emit(
          ShowOtpField(
            displaySeconds: cachedSeconds,
            isButtonActive: cachedBtnActive,
            recoveryTarget: cachedTarget,
          ),
        );
      }
    });

    on<ResendOtpRequested>(_onResendOtpRequested);

    on<VerifyOtpClicked>(_onVerifyOtpClicked);

    on<OnBackProgressClicked>((event, emit) {
      if (currentStep == RecoveryStep.passwordPhase) {
        currentStep = RecoveryStep.otpPhase;
        emit(
          ShowOtpField(
            displaySeconds: cachedSeconds,
            isButtonActive: cachedBtnActive,
            recoveryTarget: cachedTarget,
          ),
        );
      } else if (currentStep == RecoveryStep.otpPhase) {
        _timerSubscription?.cancel();
        currentStep = RecoveryStep.initialForm;
        emit(ForgotPasswordInitial());
      }
    });

    on<PasswordInputChanged>((event, emit) {
      final password = event.password;

      final bool hasMinLength = password.length >= 8;
      final bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
      final bool hasNumber = password.contains(RegExp(r'[0-9]'));
      final bool hasSpecialCharacter = password.contains(
        RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
      );

      int validCount = 0;
      if (hasMinLength) validCount++;
      if (hasUppercase) validCount++;
      if (hasNumber) validCount++;
      if (hasSpecialCharacter) validCount++;

      cachedStrength = validCount / 4;
      cachedIsPasswordGood = validCount == 4;

      emit(
        ShowPasswordResetFields(
          passwordStrength: cachedStrength,
          isPasswordGood: cachedIsPasswordGood,
        ),
      );
    });

    on<UpdatePasswordFields>(_onUpdatePasswordFields);

    on<NavSignInClicked>((event, emit) {
      _timerSubscription?.cancel();
      currentStep = RecoveryStep.initialForm;
      emit(NavigateToSignIn());
    });
  }

  Future<void> _onForgotPasswordSendOtp(
    ForgotPasswordSendOtp event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(ForgotPasswordLoading());

    try {
      final params = event.forgetPasswordSendOtpParams;
      final sanitizedCountryCode =
          params.countryCode?.replaceAll('+', '') ?? '';

      final ForgetPasswordSendOtpEntity? result =
          await forgetPasswordSendOtpUseCase(
            ForgetPasswordSendOtpParams(
              identity: params.identity,
              contactType: params.contactType ?? "mobile",
              countryCode: sanitizedCountryCode,
              isResend: params.isResend ?? false,
            ),
          );

      if (result != null && result.status == true) {
        currentStep = RecoveryStep.otpPhase;
        cachedTarget = params.identity ?? '';
        cachedSeconds = _countdownDuration;
        cachedBtnActive = false;

        _cachedSessionId = result.data?.sessionId ?? '';
        _cachedContactType =
            result.data?.contactType ?? params.contactType ?? 'mobile';
        _cachedCountryCode = result.data?.countryCode ?? sanitizedCountryCode;

        _startNewCountdown();
        emit(
          ShowOtpField(
            displaySeconds: _countdownDuration,
            isButtonActive: false,
            recoveryTarget: params.identity ?? '',
          ),
        );
      } else {
        currentStep = RecoveryStep.initialForm;
        emit(
          ForgotPasswordFailure(
            result?.message ?? "Failed to send OTP. Please try again.",
          ),
        );
        emit(ForgotPasswordInitial());
      }
    } catch (error) {
      currentStep = RecoveryStep.initialForm;
      emit(ForgotPasswordFailure(error.toString()));
      emit(ForgotPasswordInitial());
    }
  }

  Future<void> _onResendOtpRequested(
    ResendOtpRequested event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(ReSendOtpLoading());
    try {
      final ForgetPasswordSendOtpEntity? result =
          await forgetPasswordSendOtpUseCase(
            ForgetPasswordSendOtpParams(
              identity: cachedTarget,
              contactType: _cachedContactType,
              countryCode: _cachedCountryCode,
              isResend: true,
            ),
          );

      if (result != null && result.status == true) {
        _cachedSessionId = result.data?.sessionId ?? _cachedSessionId;
        cachedSeconds = _countdownDuration;
        cachedBtnActive = false;

        _startNewCountdown();
        emit(
          ShowOtpField(
            displaySeconds: _countdownDuration,
            isButtonActive: false,
            recoveryTarget: cachedTarget,
          ),
        );
      } else {
        emit(
          ForgotPasswordFailure(result?.message ?? "Failed to resend token."),
        );
        emit(
          ShowOtpField(
            displaySeconds: cachedSeconds,
            isButtonActive: cachedBtnActive,
            recoveryTarget: cachedTarget,
          ),
        );
      }
    } catch (error) {
      emit(ForgotPasswordFailure(error.toString()));
      emit(
        ShowOtpField(
          displaySeconds: cachedSeconds,
          isButtonActive: cachedBtnActive,
          recoveryTarget: cachedTarget,
        ),
      );
    }
  }

  Future<void> _onVerifyOtpClicked(
    VerifyOtpClicked event,
    Emitter<ForgotPasswordState> emit,
  ) async {

    emit(ForgotPasswordLoading());
    try {
      final ForgetPasswordVerifyOtpEntity? result =
          await forgetPasswordVerifyOtpUseCase(
            ForgetPasswordVerifyOtpParams(
              identity: cachedTarget,
              countryCode: _cachedCountryCode,
              contactType: _cachedContactType.toLowerCase(),
              otp: event.otp,
              sessionId: _cachedSessionId,
            ),
          );

      if (result != null &&
          result.status == true &&
          result.data?.success == true) {
        _timerSubscription?.cancel();
        currentStep = RecoveryStep.passwordPhase;

        emit(
          ShowPasswordResetFields(
            passwordStrength: cachedStrength,
            isPasswordGood: cachedIsPasswordGood,
          ),
        );
      } else {
        currentStep = RecoveryStep.otpPhase;
        emit(
          ForgotPasswordFailure(
            result?.data?.message ??
                result?.message ??
                "Invalid OTP code entered.",
          ),
        );
        emit(
          ShowOtpField(
            displaySeconds: cachedSeconds,
            isButtonActive: cachedBtnActive,
            recoveryTarget: cachedTarget,
          ),
        );
      }
    } catch (exception) {
      currentStep = RecoveryStep.otpPhase;
      emit(ForgotPasswordFailure(exception.toString()));
      emit(
        ShowOtpField(
          displaySeconds: cachedSeconds,
          isButtonActive: cachedBtnActive,
          recoveryTarget: cachedTarget,
        ),
      );
    }
  }

  Future<void> _onUpdatePasswordFields(
    UpdatePasswordFields event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    if (!cachedIsPasswordGood) {
      emit(
        ForgotPasswordFailure(
          "Password parameters have not satisfied validation rules.",
        ),
      );
      emit(
        ShowPasswordResetFields(
          passwordStrength: cachedStrength,
          isPasswordGood: cachedIsPasswordGood,
        ),
      );
      return;
    }

    if (event.newPassword.isEmpty || event.confirmPassword.isEmpty) {
      emit(ForgotPasswordFailure("Password entries cannot be blank."));
      emit(
        ShowPasswordResetFields(
          passwordStrength: cachedStrength,
          isPasswordGood: cachedIsPasswordGood,
        ),
      );
      return;
    }

    if (event.newPassword != event.confirmPassword) {
      emit(ForgotPasswordFailure("Passwords do not match."));
      emit(
        ShowPasswordResetFields(
          passwordStrength: cachedStrength,
          isPasswordGood: cachedIsPasswordGood,
        ),
      );
      return;
    }
    currentStep = RecoveryStep.passwordPhase;
    emit(ForgotPasswordLoading());

    try {
      final CommonEntity? result = await saveResetPasswordUseCase(
        SaveResetPasswordParams(
          identity: cachedTarget,
          contactType: _cachedContactType,
          countryCode: _cachedCountryCode,
          newPassword: event.newPassword.trim(),
          confirmPassword: event.confirmPassword.trim(),
        ),
      );

      if (result != null && result.status == true) {
        emit(ForgotPasswordSuccess());
        currentStep = RecoveryStep.initialForm;
        emit(NavigateToSignIn());
      } else {
        currentStep = RecoveryStep.passwordPhase;
        emit(
          ForgotPasswordFailure(
            result?.message ??
                "Failed to update your password. Please try again.",
          ),
        );
        emit(
          ShowPasswordResetFields(
            passwordStrength: cachedStrength,
            isPasswordGood: cachedIsPasswordGood,
          ),
        );
      }
    } catch (exception) {
      currentStep = RecoveryStep.passwordPhase;
      emit(ForgotPasswordFailure(exception.toString()));
      emit(
        ShowPasswordResetFields(
          passwordStrength: cachedStrength,
          isPasswordGood: cachedIsPasswordGood,
        ),
      );
    }
  }

  void _startNewCountdown() {
    _timerSubscription?.cancel();
    _timerSubscription =
        Stream<int>.periodic(
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
