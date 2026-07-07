import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:yiraclinics/features/domain/entities/token/get_version_and_token_status_entity.dart';
import 'package:yiraclinics/features/use_cases/config_use_case.dart';
import 'package:yiraclinics/features/use_cases/side_menu_use_case.dart';

import '../../../core/global_session/global_menu_session.dart';
import '../../../core/local/global_session.dart';
import '../../domain/entities/login/login_entity.dart';
import '../../use_cases/get_version_and_token_status_use_case.dart';

part 'config_event.dart';
part 'config_state.dart';

class ConfigBloc extends Bloc<ConfigEvent, ConfigState> {
  final ConfigUseCase configUseCase;
  final GetVersionAndTokenStatusUseCase getVersionAndTokenStatusUseCase;
  final SideMenuUseCase sideMenuUseCase;

  ConfigBloc({
    required this.configUseCase,
    required this.getVersionAndTokenStatusUseCase,
    required this.sideMenuUseCase,
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
        final LoginEntity? result = await configUseCase.call(null);

        if (result == null || !(result.status ?? false)) {
          final failureMessage =
              result?.message ?? "Invalid email or password.";
          emit(GetDataFailureState(failureMessage));
          return;
        }

        await GlobalSession.instance.update(result);
        final userDataPayload = result.data;

        if (userDataPayload == null) {
          emit(
            GetDataFailureState(
              "User metadata payload resolving returned empty context.",
            ),
          );
          return;
        }

        await Future.microtask(() {});

        try {
          final sideMenuEntity = await sideMenuUseCase.call(
            SideMenuRequestParams(
              userId: userDataPayload.id ?? '',
              latestRoleId: userDataPayload.latestRoleId ?? '',
              latestOrgId: userDataPayload.latestOrgId ?? 0,
              latestHospitalId: userDataPayload.latestHospitalId ?? 0,
            ),
          );

          if (sideMenuEntity != null) {
            GlobalMenuSession.instance.updateMenu(sideMenuEntity);
          }
        } catch (sideMenuError, stackTrace) {
          developer.log(
            "NON-FATAL EXCEPTION: Side menu optimization step bypassed safely.",
            error: sideMenuError,
            stackTrace: stackTrace,
            name: "ConfigBloc",
          );
        }

        try {
          final versionStatusEntity = await getVersionAndTokenStatusUseCase
              .call(null);

          if (versionStatusEntity == null || !(versionStatusEntity.status)) {
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
