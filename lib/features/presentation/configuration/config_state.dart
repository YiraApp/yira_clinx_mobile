part of 'config_bloc.dart';

@immutable
class ConfigState {
  final Map<String, bool> settings;
  final bool isSyncing; // For the small AppBar pulse
  final bool isUpdated; // For the full-screen Success Overlay

  const ConfigState({
    this.settings = const {
      "notif": true,
      "dark": false,
      "bio": true
    },
    this.isSyncing = false,
    this.isUpdated = false,
  });

  ConfigState copyWith({
    Map<String, bool>? settings,
    bool? isSyncing,
    bool? isUpdated,
  }) {
    return ConfigState(
      settings: settings ?? this.settings,
      isSyncing: isSyncing ?? this.isSyncing,
      isUpdated: isUpdated ?? this.isUpdated,
    );
  }
}
