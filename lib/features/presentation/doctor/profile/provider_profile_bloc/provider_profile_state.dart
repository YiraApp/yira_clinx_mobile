part of 'provider_profile_bloc.dart';

abstract class ProviderProfileState extends Equatable {
  const ProviderProfileState();

  @override
  List<Object?> get props => [];
}

class ProviderProfileInitialState extends ProviderProfileState {}

class ProviderProfileLoadingState extends ProviderProfileState {}

class ProviderProfileLoadedState extends ProviderProfileState {
  final ProviderProfileEntity profile;
  final bool isUpdating;
  final bool isPhotoUploading;

  const ProviderProfileLoadedState({
    required this.profile,
    this.isUpdating = false,
    this.isPhotoUploading = false,
  });

  ProviderProfileLoadedState copyWith({
    ProviderProfileEntity? profile,
    bool? isUpdating,
    bool? isPhotoUploading,
  }) {
    return ProviderProfileLoadedState(
      profile: profile ?? this.profile,
      isUpdating: isUpdating ?? this.isUpdating,
      isPhotoUploading: isPhotoUploading ?? this.isPhotoUploading,
    );
  }

  @override
  List<Object?> get props => [profile, isUpdating, isPhotoUploading];
}

class ProviderProfileErrorState extends ProviderProfileState {
  final String message;

  const ProviderProfileErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}
