import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'close_account_event.dart';
part 'close_account_state.dart';

class CloseAccountBloc extends Bloc<CloseAccountEvent, CloseAccountState> {

  CloseAccountBloc() : super(const CloseAccountState()) {
    on<InitializeCloseAccountEvent>(_onInitialize);
    on<ConfirmationCodeChangedEvent>(_onCodeChanged);
    on<ToggleTermsCheckboxEvent>(_onToggleCheckbox);
    on<SubmitCloseAccountEvent>(_onSubmit);
  }

  void _onInitialize(InitializeCloseAccountEvent event, Emitter<CloseAccountState> emit) {
    final code = (Random().nextInt(900000) + 100000).toString();
    emit(state.copyWith(
      generatedVerificationCode: code,
      status: CloseAccountStatus.initial,
    ));
  }

  void _onCodeChanged(ConfirmationCodeChangedEvent event, Emitter<CloseAccountState> emit) {
    emit(state.copyWith(inputCode: event.code));
  }

  void _onToggleCheckbox(ToggleTermsCheckboxEvent event, Emitter<CloseAccountState> emit) {
    emit(state.copyWith(isTCOnchecked: event.isChecked));
  }
  Future<void> _onSubmit(SubmitCloseAccountEvent event, Emitter<CloseAccountState> emit) async {
    if (!state.isCodeValid || !state.isTCOnchecked) return;

    emit(state.copyWith(status: CloseAccountStatus.submitting));
    try {
      await Future.delayed(const Duration(seconds: 2)); // Mock processing
      emit(state.copyWith(status: CloseAccountStatus.success));
    } catch (e) {
      emit(state.copyWith(status: CloseAccountStatus.failure, errorMessage: e.toString()));
    }
  }
}