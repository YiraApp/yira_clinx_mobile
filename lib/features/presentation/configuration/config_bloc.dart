import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:yiraclinics/features/use_cases/config_use_case.dart';

import '../../../core/local/global_session.dart';
import '../../domain/entities/login/login_entity.dart';

part 'config_event.dart';
part 'config_state.dart';

class ConfigBloc extends Bloc<ConfigEvent, ConfigState> {
  final ConfigUseCase configUseCase;

  ConfigBloc({required this.configUseCase}) : super(ConfigInitial()) {

    // 1. Toggle Setting Handler
    on<ToggleSettingEvent>((event, emit) async {

      emit(LoadDataStatus());

      await Future.delayed(const Duration(milliseconds: 1500));

      add(ResetUpdateStatusEvent());
    });
    on<ResetUpdateStatusEvent>((event, emit) async {
      await Future.delayed(const Duration(seconds: 2));
      emit(ConfigInitial());
    });

    on<LoadUserConfigurationScreen>((event, emit) async {
      emit(LoadDataStatus());

      try {
        final LoginEntity? result = await configUseCase(null);

        if (result == null || !(result.status ?? false)) {
          final failureMessage = result?.message ?? "Invalid email or password.";

          emit(GetDataFailureState(failureMessage));
          return;
        } else {
          await Future.wait([GlobalSession.instance.update(result)]);

          emit(GetDataSuccessState(result));
        }
      } catch (e, s) {
        debugPrint("CRITICAL (ConfigBloc): Unexpected authorization exception: $e");
        debugPrint("Stacktrace: $s");

        emit(GetDataFailureState(e.toString()));
      }
    });
  }
}