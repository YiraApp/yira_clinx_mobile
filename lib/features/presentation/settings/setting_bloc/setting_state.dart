part of 'setting_bloc.dart';
enum SettingsStatus { initial, loading, success, failure }



@immutable
class SettingsState extends Equatable {
  final String selectedLanguageCode;
  final ThemeMode themeMode;
  final bool soundEnabled;
  final SettingsStatus status;
  final String? errorMessage;

  final bool emailEnabled;
  final bool smsEnabled;
  final bool pushEnabled;

  final bool appointmentReminders;
  final bool labResultsNotif;
  final bool prescriptionReminders;

  const SettingsState({
    this.selectedLanguageCode = 'en',
    this.themeMode = ThemeMode.system,
    this.soundEnabled = true,
    this.status = SettingsStatus.initial,
    this.errorMessage,
    // Default values matching your UI toggles
    this.emailEnabled = true,
    this.smsEnabled = true,
    this.pushEnabled = true,
    this.appointmentReminders = true,
    this.labResultsNotif = true,
    this.prescriptionReminders = true,
  });

  bool get isSaving => status == SettingsStatus.loading;
  bool get isSuccess => status == SettingsStatus.success;

  SettingsState copyWith({
    String? selectedLanguageCode,
    ThemeMode? themeMode,
    bool? soundEnabled,
    SettingsStatus? status,
    String? errorMessage,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? pushEnabled,
    bool? appointmentReminders,
    bool? labResultsNotif,
    bool? prescriptionReminders,
  }) {
    return SettingsState(
      selectedLanguageCode: selectedLanguageCode ?? this.selectedLanguageCode,
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      appointmentReminders: appointmentReminders ?? this.appointmentReminders,
      labResultsNotif: labResultsNotif ?? this.labResultsNotif,
      prescriptionReminders: prescriptionReminders ?? this.prescriptionReminders,
    );
  }

  @override
  List<Object?> get props => [
    selectedLanguageCode,
    themeMode,
    soundEnabled,
    status,
    errorMessage,
    emailEnabled,
    smsEnabled,
    pushEnabled,
    appointmentReminders,
    labResultsNotif,
    prescriptionReminders,
  ];
}
