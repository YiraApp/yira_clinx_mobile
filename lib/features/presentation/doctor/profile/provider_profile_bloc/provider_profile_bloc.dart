import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/features/domain/entities/provider_profile/provider_profile_entity.dart';
import 'package:yiraclinics/features/domain/use_cases/provider_profile/get_provider_profile_use_case.dart';
import 'package:yiraclinics/features/domain/use_cases/provider_profile/update_provider_profile_use_case.dart';
import 'package:yiraclinics/features/domain/use_cases/provider_profile/upload_provider_photo_use_case.dart';

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
        emit(ProviderProfileLoadedState(profile: updatedProfile, isUpdating: false));
      } catch (e) {
        emit(currentLoaded.copyWith(isUpdating: false));
      }
    } else {
      try {
        final updatedProfile = await updateProviderProfileUseCase(profile: event.profile);
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
