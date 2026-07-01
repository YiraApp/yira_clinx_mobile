import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:yiraclinics/features/domain/entities/token/get_version_and_token_status_entity.dart';
import 'package:yiraclinics/features/use_cases/config_use_case.dart';

import '../../../core/local/global_session.dart';
import '../../domain/entities/login/login_entity.dart';
import '../../use_cases/get_version_and_token_status_use_case.dart';

part 'config_event.dart';
part 'config_state.dart';

class ConfigBloc extends Bloc<ConfigEvent, ConfigState> {
  final ConfigUseCase configUseCase;
  final GetVersionAndTokenStatusUseCase getVersionAndTokenStatusUseCase;

  ConfigBloc({
    required this.configUseCase,
    required this.getVersionAndTokenStatusUseCase,
  }) : super(ConfigInitial()) {
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
          final failureMessage =
              result?.message ?? "Invalid email or password.";
          emit(GetDataFailureState(failureMessage));
          return;
        }

        await Future.wait([GlobalSession.instance.update(result)]);

        try {
          final versionStatusEntity = await getVersionAndTokenStatusUseCase
              .call(null);

          if (versionStatusEntity == null ||
              !(versionStatusEntity.status ?? false)) {
            final failureMessage =
                versionStatusEntity?.message ??
                "Failed to verify version status details.";
            emit(GetDataFailureState(failureMessage));
            return;
          }

          emit(
            GetDataSuccessState(
              coreData: result,
              versionData: versionStatusEntity,
            ),
          );
        } catch (versionError, stackTrace) {
          debugPrint(
            "CRITICAL: Telemetry evaluation failed: $versionError\n$stackTrace",
          );
          emit(GetDataSuccessState(coreData: result, versionData: null));
        }
      } catch (e, s) {
        debugPrint(
          "CRITICAL (ConfigBloc): Unexpected authorization exception: $e\nStacktrace: $s",
        );
        emit(GetDataFailureState(e.toString()));
      }
    });
  }
}
