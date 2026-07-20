import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'setting_event.dart';
part 'setting_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<LanguageChanged>((event, emit) {
      emit(
        state.copyWith(
          selectedLanguageCode: event.languageCode,
          status: SettingsStatus.initial,
        ),
      );
    });
    on<NotificationToggleChanged>((event, emit) {
      switch (event.type) {
        case 'email':
          emit(state.copyWith(emailEnabled: event.isEnabled));
          break;
        case 'sms':
          emit(state.copyWith(smsEnabled: event.isEnabled));
          break;
        case 'push':
          emit(state.copyWith(pushEnabled: event.isEnabled));
          break;
        case 'appointment':
          emit(state.copyWith(appointmentReminders: event.isEnabled));
          break;
        case 'lab':
          emit(state.copyWith(labResultsNotif: event.isEnabled));
          break;
        case 'user_prescription':
          emit(state.copyWith(prescriptionReminders: event.isEnabled));
          break;
      }
    });
    on<ThemeChanged>((event, emit) {
      emit(
        state.copyWith(
          themeMode: event.themeMode,
          status: SettingsStatus.initial,
        ),
      );
    });

    on<SoundToggleChanged>((event, emit) {
      emit(
        state.copyWith(
          soundEnabled: event.isEnabled,
          status: SettingsStatus.initial,
        ),
      );
    });

    on<SaveSettingsPressed>((event, emit) async {
      if (state.status == SettingsStatus.loading) return;

      emit(state.copyWith(status: SettingsStatus.loading));

      try {
        await Future.delayed(const Duration(seconds: 1));

        emit(state.copyWith(status: SettingsStatus.success));
      } catch (e) {
        emit(
          state.copyWith(
            status: SettingsStatus.failure,
            errorMessage: "Failed to update settings.",
          ),
        );
      }
    });

    on<PasswordAndSecurityNavEvent>((event, emit) {
      emit(PasswordAndSecurityNavState());
    });
    on<NotificationNavEvent>((event, emit) {
      emit(NotificationNavState());
    });
    on<LanguageNavEvent>((event, emit) {
      emit(LanguageNavState());
    });
    on<ThemeNavEvent>((event, emit) {
      emit(ThemeNavState());
    });
    on<DeleteAccountNavEvent>((event, emit) {
      emit(DeleteAccountNavState());
    });
  }
}
