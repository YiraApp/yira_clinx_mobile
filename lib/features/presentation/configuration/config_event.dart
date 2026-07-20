part of 'config_bloc.dart';

@immutable
abstract class ConfigEvent {}

class ToggleSettingEvent extends ConfigEvent {
  final String key;
  final bool value;
  ToggleSettingEvent(this.key, this.value);
}

// Resets the success overlay so the user can see the settings again
class ResetUpdateStatusEvent extends ConfigEvent {}
class LoadUserConfigurationScreen extends ConfigEvent {}
