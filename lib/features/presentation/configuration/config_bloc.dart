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

        final currentProfiles = GlobalSession.instance.userNotifier.value?.data?.profiles ?? [];
        final incomingProfiles = result.data?.profiles ?? [];

        // 1. Resolve or lock the single root primary user ID
        String? rootPrimaryId = GlobalSession.instance.rootPrimaryUserId;
        if (rootPrimaryId == null || rootPrimaryId.isEmpty) {
          ProfileEntity? found;
          for (final p in currentProfiles) {
            final r = (p.relation ?? '').trim().toLowerCase();
            final isFam = r.isNotEmpty && r != 'self' && r != 'primary' && r != 'admin';
            if (p.isPrimary == true && !isFam) {
              found = p;
              break;
            }
          }
          if (found == null) {
            for (final p in incomingProfiles) {
              final r = (p.relation ?? '').trim().toLowerCase();
              final isFam = r.isNotEmpty && r != 'self' && r != 'primary' && r != 'admin';
              if (p.isPrimary == true && !isFam) {
                found = p;
                break;
              }
            }
          }
          if (found != null && found.id != null && found.id!.isNotEmpty) {
            rootPrimaryId = found.id;
            GlobalSession.instance.rootPrimaryUserId = rootPrimaryId;
          }
        }

        // Keyed by lower-case id: a member added on this phone can carry the same
        // id in a different letter case from the server's copy.
        // The server's list is the truth when it sends one; saved copies only fill in
        // when it sends none. Otherwise profiles from another account, or members
        // removed on the server, would stay on this phone.
        // The exception is a family member opened from the main account: the server
        // then lists only that member's own profile, and the main account and the
        // rest of the family must stay on the list so the user can switch back.
        bool lists(List<ProfileEntity> profiles, String? id) {
          final key = (id ?? '').trim().toLowerCase();
          return key.isNotEmpty && profiles.any((p) => (p.id ?? '').trim().toLowerCase() == key);
        }
        final openedFromMainAccount = lists(currentProfiles, rootPrimaryId) &&
            lists(currentProfiles, result.data?.id) &&
            !lists(incomingProfiles, rootPrimaryId);
        final Map<String, ProfileEntity> map = {};
        for (final p in (incomingProfiles.isNotEmpty && !openedFromMainAccount) ? incomingProfiles : currentProfiles) {
          if (p.id != null && p.id!.isNotEmpty) map.putIfAbsent(p.id!.trim().toLowerCase(), () => p);
        }
        // A root profile that is no longer on the list came from an earlier account.
        if (rootPrimaryId != null && !map.containsKey(rootPrimaryId.trim().toLowerCase())) {
          ProfileEntity? root;
          for (final p in map.values) {
            final r = (p.relation ?? '').trim().toLowerCase();
            if (p.isPrimary == true && (r.isEmpty || r == 'self' || r == 'primary' || r == 'admin')) {
              root = p;
              break;
            }
          }
          rootPrimaryId = root?.id;
          GlobalSession.instance.setRootPrimaryUserId(rootPrimaryId);
        }

        // Clean & guarantee that ONLY rootPrimaryId is Primary, all others are their relation or Dependent
        List<ProfileEntity> mergedProfiles = map.values.map((p) {
          final isRealPrimary = (rootPrimaryId != null && (p.id ?? '').toLowerCase() == rootPrimaryId.toLowerCase());
          final rawRel = (p.relation ?? '').trim();
          final bool hasFamilyRel = rawRel.isNotEmpty &&
              rawRel.toLowerCase() != 'self' &&
              rawRel.toLowerCase() != 'admin' &&
              rawRel.toLowerCase() != 'primary';

          final String rel = isRealPrimary ? 'Primary' : (hasFamilyRel ? rawRel : 'Dependent');

          return ProfileEntity(
            id: p.id,
            firstName: p.firstName,
            lastName: p.lastName,
            name: p.name,
            phoneNumber: p.phoneNumber,
            relation: rel,
            isPrimary: isRealPrimary,
            gender: p.gender,
            dob: p.dob,
            accountType: isRealPrimary ? 'Independent' : 'Dependent',
            imagePath: p.imagePath,
          );
        }).toList();

        // Pin the true Primary profile at Index 0
        if (mergedProfiles.isNotEmpty) {
          int pIdx = mergedProfiles.indexWhere((p) => p.isPrimary == true);
          if (pIdx > 0) {
            final primary = mergedProfiles.removeAt(pIdx);
            mergedProfiles.insert(0, primary);
          }
        }

        final currentSessionData = GlobalSession.instance.userNotifier.value?.data;

        final finalData = DataEntity(
          accessToken: (result.data?.accessToken != null &&
                  result.data!.accessToken!.trim().isNotEmpty)
              ? result.data!.accessToken
              : currentSessionData?.accessToken,
          refreshToken: (result.data?.refreshToken != null &&
                  result.data!.refreshToken!.trim().isNotEmpty)
              ? result.data!.refreshToken
              : currentSessionData?.refreshToken,
          accessTokenExpiry: result.data?.accessTokenExpiry ??
              currentSessionData?.accessTokenExpiry,
          refreshTokenExpiry: result.data?.refreshTokenExpiry ??
              currentSessionData?.refreshTokenExpiry,
          id: result.data?.id ?? currentSessionData?.id,
          isMobileVerified: result.data?.isMobileVerified ?? currentSessionData?.isMobileVerified,
          isEmailVerified: result.data?.isEmailVerified ?? currentSessionData?.isEmailVerified,
          roleCount: result.data?.roleCount ?? currentSessionData?.roleCount,
          hospitalCount: result.data?.hospitalCount ?? currentSessionData?.hospitalCount,
          organizationCount: result.data?.organizationCount ?? currentSessionData?.organizationCount,
          latestUserRole: result.data?.latestUserRole ?? currentSessionData?.latestUserRole,
          latestOrgId: result.data?.latestOrgId ?? currentSessionData?.latestOrgId,
          latestHospitalId: result.data?.latestHospitalId ?? currentSessionData?.latestHospitalId,
          latestRoleId: result.data?.latestRoleId ?? currentSessionData?.latestRoleId,
          roles: result.data?.roles ?? currentSessionData?.roles,
          profiles: mergedProfiles.isNotEmpty ? mergedProfiles : (result.data?.profiles ?? currentSessionData?.profiles),
          firstName: result.data?.firstName ?? currentSessionData?.firstName,
          lastName: result.data?.lastName ?? currentSessionData?.lastName,
          email: result.data?.email ?? currentSessionData?.email,
          phoneNumber: result.data?.phoneNumber ?? currentSessionData?.phoneNumber,
          countryCode: result.data?.countryCode ?? currentSessionData?.countryCode,
          gender: result.data?.gender ?? currentSessionData?.gender,
          dob: result.data?.dob ?? currentSessionData?.dob,
          height: result.data?.height ?? currentSessionData?.height,
          weight: result.data?.weight ?? currentSessionData?.weight,
          heightUnit: result.data?.heightUnit ?? currentSessionData?.heightUnit,
          weightUnit: result.data?.weightUnit ?? currentSessionData?.weightUnit,
          navigationId: result.data?.navigationId ?? currentSessionData?.navigationId,
          imagePath: result.data?.imagePath ?? currentSessionData?.imagePath,
        );

        final updatedLoginResult = LoginEntity(
          status: result.status,
          message: result.message,
          data: finalData,
        );

        await GlobalSession.instance.update(updatedLoginResult);
        final userDataPayload = finalData;

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
