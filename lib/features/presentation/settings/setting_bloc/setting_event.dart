part of 'setting_bloc.dart';

@immutable
abstract class SettingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LanguageChanged extends SettingsEvent {
  final String languageCode;
  LanguageChanged(this.languageCode);

  @override
  List<Object?> get props => [languageCode];
}

// Added for 11.png: Theme selection
class ThemeChanged extends SettingsEvent {
  final ThemeMode themeMode;
  ThemeChanged(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}
class SoundToggleChanged extends SettingsEvent {
  final bool isEnabled;
  SoundToggleChanged(this.isEnabled);

  @override
  List<Object?> get props => [isEnabled];
}

class SaveSettingsPressed extends SettingsEvent {}
class NotificationToggleChanged extends SettingsEvent {
  final String type; // e.g., 'email', 'sms', 'appointment'
  final bool isEnabled;
  NotificationToggleChanged(this.type, this.isEnabled);

  @override
  List<Object?> get props => [type, isEnabled];
}

