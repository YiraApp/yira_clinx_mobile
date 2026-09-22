import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/features/domain/entities/provider_profile/provider_profile_entity.dart';
import 'package:yiraclinics/features/domain/use_cases/provider_profile/get_provider_profile_use_case.dart';
import 'package:yiraclinics/features/domain/use_cases/provider_profile/update_provider_profile_use_case.dart';
import 'package:yiraclinics/features/domain/use_cases/provider_profile/upload_provider_photo_use_case.dart';

import 'package:yiraclinics/features/data/models/login/login_model.dart';

part 'provider_profile_event.dart';
part 'provider_profile_state.dart';

class ProviderProfileBloc extends Bloc<ProviderProfileEvent, ProviderProfileState> {
  final GetProviderProfileUseCase getProviderProfileUseCase;
  final UpdateProviderProfileUseCase updateProviderProfileUseCase;
  final UploadProviderPhotoUseCase uploadProviderPhotoUseCase;

  ProviderProfileBloc({
    required this.getProviderProfileUseCase,
    required this.updateProviderProfileUseCase,
    required this.uploadProviderPhotoUseCase,
  }) : super(ProviderProfileInitialState()) {
    on<LoadProviderProfileEvent>(_onLoadProviderProfile);
    on<RefreshProviderProfileEvent>(_onRefreshProviderProfile);
    on<UpdateDoctorProfileEvent>(_onUpdateDoctorProfile);
    on<UploadDoctorPhotoEvent>(_onUploadDoctorPhoto);
  }

  Future<void> _syncDoctorToGlobalSession({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? gender,
    String? dob,
    String? imagePath,
    int? hospitalId,
    int? orgId,
  }) async {
    try {
      final currentSession = GlobalSession.instance.userNotifier.value;
      if (currentSession?.data != null) {
        final currentData = currentSession!.data!;
        final effectiveImage = imagePath ?? currentData.imagePath;

        final updatedProfiles = (currentData.profiles ?? []).map((p) {
          if (p.isPrimary == true || p.id == currentData.id) {
            return ProfileModel(
              id: p.id,
              firstName: firstName ?? p.firstName,
              lastName: lastName ?? p.lastName,
              name: '${firstName ?? p.firstName ?? ''} ${lastName ?? p.lastName ?? ''}'.trim(),
              phoneNumber: phoneNumber ?? p.phoneNumber,
              relation: p.relation,
              isPrimary: p.isPrimary,
              gender: gender ?? p.gender,
              dob: dob ?? p.dob,
              accountType: p.accountType,
              imagePath: effectiveImage,
            );
          }
          return p is ProfileModel ? p : ProfileModel.fromEntity(p);
        }).toList();

        final updatedData = DataModel(
          accessToken: currentData.accessToken,
          refreshToken: currentData.refreshToken,
          accessTokenExpiry: currentData.accessTokenExpiry,
          refreshTokenExpiry: currentData.refreshTokenExpiry,
          id: currentData.id,
          isMobileVerified: currentData.isMobileVerified,
          isEmailVerified: currentData.isEmailVerified,
          roleCount: currentData.roleCount,
          hospitalCount: currentData.hospitalCount,
          organizationCount: currentData.organizationCount,
          roles: (currentData.roles ?? []).map((r) => r is RoleModel ? r : RoleModel.fromEntity(r)).toList(),
          profiles: updatedProfiles,
          firstName: firstName ?? currentData.firstName,
          lastName: lastName ?? currentData.lastName,
          email: email ?? currentData.email,
          phoneNumber: phoneNumber ?? currentData.phoneNumber,
          countryCode: currentData.countryCode,
          gender: gender ?? currentData.gender,
          dob: dob ?? currentData.dob,
          height: currentData.height,
          weight: currentData.weight,
          heightUnit: currentData.heightUnit,
          weightUnit: currentData.weightUnit,
          latestUserRole: currentData.latestUserRole,
          latestHospitalId: hospitalId ?? currentData.latestHospitalId,
          latestOrgId: orgId ?? currentData.latestOrgId,
          latestRoleId: currentData.latestRoleId,
          navigationId: currentData.navigationId,
          imagePath: effectiveImage,
        );

        final newModel = LoginModel(
          status: currentSession.status,
          message: currentSession.message,
          data: updatedData,
        );
        await GlobalSession.instance.update(newModel);
      }
    } catch (_) {}
  }

  Future<void> _onLoadProviderProfile(
    LoadProviderProfileEvent event,
    Emitter<ProviderProfileState> emit,
  ) async {
    emit(ProviderProfileLoadingState());
    await _fetchProfile(
      userId: event.userId,
      hospitalId: event.hospitalId,
      orgId: event.orgId,
      emit: emit,
    );
  }

  Future<void> _onRefreshProviderProfile(
    RefreshProviderProfileEvent event,
    Emitter<ProviderProfileState> emit,
  ) async {
    await _fetchProfile(
      userId: event.userId,
      hospitalId: event.hospitalId,
      orgId: event.orgId,
      emit: emit,
    );
  }

  Future<void> _onUpdateDoctorProfile(
    UpdateDoctorProfileEvent event,
    Emitter<ProviderProfileState> emit,
  ) async {
    if (state is ProviderProfileLoadedState) {
      final currentLoaded = state as ProviderProfileLoadedState;
      emit(currentLoaded.copyWith(isUpdating: true));
      try {
        final updatedProfile = await updateProviderProfileUseCase(profile: event.profile);
        await _syncDoctorToGlobalSession(
          firstName: updatedProfile.firstName,
          lastName: updatedProfile.lastName,
          email: updatedProfile.email,
          phoneNumber: updatedProfile.phoneNumber,
          gender: updatedProfile.gender,
          dob: updatedProfile.dob,
          imagePath: updatedProfile.imagePath ?? updatedProfile.profileImageUrl,
          hospitalId: updatedProfile.hospitalId,
          orgId: updatedProfile.orgId,
        );
        emit(ProviderProfileLoadedState(profile: updatedProfile, isUpdating: false));
      } catch (e) {
        emit(currentLoaded.copyWith(isUpdating: false));
      }
    } else {
      try {
        final updatedProfile = await updateProviderProfileUseCase(profile: event.profile);
        await _syncDoctorToGlobalSession(
          firstName: updatedProfile.firstName,
          lastName: updatedProfile.lastName,
          email: updatedProfile.email,
          phoneNumber: updatedProfile.phoneNumber,
          gender: updatedProfile.gender,
          dob: updatedProfile.dob,
          imagePath: updatedProfile.imagePath ?? updatedProfile.profileImageUrl,
          hospitalId: updatedProfile.hospitalId,
          orgId: updatedProfile.orgId,
        );
        emit(ProviderProfileLoadedState(profile: updatedProfile));
      } catch (e) {
        emit(ProviderProfileErrorState(message: e.toString()));
      }
    }
  }

  Future<void> _onUploadDoctorPhoto(
    UploadDoctorPhotoEvent event,
    Emitter<ProviderProfileState> emit,
  ) async {
    if (state is ProviderProfileLoadedState) {
      final currentLoaded = state as ProviderProfileLoadedState;
      emit(currentLoaded.copyWith(isPhotoUploading: true));
      try {
        final photoUrl = await uploadProviderPhotoUseCase(
          userId: event.userId,
          photoFile: event.photoFile,
          hospitalId: event.hospitalId,
          orgId: event.orgId,
        );

        await _syncDoctorToGlobalSession(
          imagePath: photoUrl,
          hospitalId: event.hospitalId,
          orgId: event.orgId,
        );

        final updatedProfile = currentLoaded.profile.copyWith(
          imagePath: photoUrl,
          profileImageUrl: photoUrl,
        );
        emit(ProviderProfileLoadedState(profile: updatedProfile, isPhotoUploading: false));
      } catch (e) {
        emit(currentLoaded.copyWith(isPhotoUploading: false));
      }
    }
  }

  Future<void> _fetchProfile({
    String? userId,
    int? hospitalId,
    int? orgId,
    required Emitter<ProviderProfileState> emit,
  }) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final targetUserId = userId ?? currentUser?.data?.id ?? '';
      final targetHospitalId = hospitalId ?? currentUser?.data?.latestHospitalId;
      final targetOrgId = orgId ?? currentUser?.data?.latestOrgId;

      final profile = await getProviderProfileUseCase(
        userId: targetUserId,
        hospitalId: targetHospitalId,
        orgId: targetOrgId,
      );

      emit(ProviderProfileLoadedState(profile: profile));
    } catch (e) {
      emit(ProviderProfileErrorState(message: e.toString()));
    }
  }
}
