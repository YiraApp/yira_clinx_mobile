import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'config_event.dart';
part 'config_state.dart';


class ConfigBloc extends Bloc<ConfigEvent, ConfigState> {
  ConfigBloc() : super(ConfigState()) {

    // Handle Toggles
    on<ToggleSettingEvent>((event, emit) async {
      // 1. Update the local toggle UI immediately & show sync pulse
      final updatedSettings = Map<String, bool>.from(state.settings);
      updatedSettings[event.key] = event.value;

      emit(state.copyWith(
          settings: updatedSettings,
          isSyncing: true,
          isUpdated: false
      ));

      // 2. Simulate API/Database delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // 3. Show the "Login Successful" style Success Overlay
      emit(state.copyWith(isSyncing: false, isUpdated: true));

      // 4. Auto-hide the success overlay after 2.5 seconds
      add(ResetUpdateStatusEvent());
    });

    // Handle Overlay Reset
    on<ResetUpdateStatusEvent>((event, emit) async {
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(isUpdated: false));
    });
  }
}
