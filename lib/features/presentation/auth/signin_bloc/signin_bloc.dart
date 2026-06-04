import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'signin_event.dart';
part 'signin_state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  Timer? _timer;
  static const int _countdownDuration = 30; // Resend window in seconds

  SignInBloc() : super(SignInInitial()) {
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
    on<NavSelectRoleSignUp>((event, emit) {
      emit(NavigateToSelectRoleSignUp());
    });
    on<NavSignIn>((event, emit) {
      emit(NavigateToSignIn());
    });
    on<NavSignUp>((event, emit) {
      emit(NavigateToSignup());
    });

    on<_OnTimerTick>(_onTimerTick);
    on<_OnTimerFinished>(_onTimerFinished);
    _startCountdown();
  }

  Future<void> _onVerifyAndLogin(
    OnVerifyAndLogin event,
    Emitter<SignInState> emit,
  ) async {
    emit(SignInLoading());
    try {

      await Future.delayed(
        const Duration(seconds: 2),
      );

      _timer?.cancel();
      emit(NavigateToHome());
    } catch (e) {
      emit(SignInError(e.toString()));
    }
  }

  Future<void> _onReSendOtp(
    OnReSendOtp event,
    Emitter<SignInState> emit,
  ) async {
    emit(ReSendOtpLoading());
    try {

      await Future.delayed(
        const Duration(seconds: 1),
      );

      _startCountdown();
    } catch (e) {
      emit(SignInError(e.toString()));
    }
  }

  void _onTimerTick(_OnTimerTick event, Emitter<SignInState> emit) {
    emit(TimerTick(event.secondsRemaining));
  }

  void _onTimerFinished(_OnTimerFinished event, Emitter<SignInState> emit) {
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
