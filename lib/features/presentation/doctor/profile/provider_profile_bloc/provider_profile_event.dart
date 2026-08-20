part of 'provider_profile_bloc.dart';

abstract class ProviderProfileEvent extends Equatable {
  const ProviderProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProviderProfileEvent extends ProviderProfileEvent {
  final String? userId;
  final int? hospitalId;
  final int? orgId;

  const LoadProviderProfileEvent({
    this.userId,
    this.hospitalId,
    this.orgId,
  });

  @override
  List<Object?> get props => [userId, hospitalId, orgId];
}

class RefreshProviderProfileEvent extends ProviderProfileEvent {
  final String? userId;
  final int? hospitalId;
  final int? orgId;

  const RefreshProviderProfileEvent({
    this.userId,
    this.hospitalId,
    this.orgId,
  });

  @override
  List<Object?> get props => [userId, hospitalId, orgId];
}

class UpdateDoctorProfileEvent extends ProviderProfileEvent {
  final ProviderProfileEntity profile;

  const UpdateDoctorProfileEvent({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class UploadDoctorPhotoEvent extends ProviderProfileEvent {
  final String userId;
  final File photoFile;
  final int? hospitalId;
  final int? orgId;

  const UploadDoctorPhotoEvent({
    required this.userId,
    required this.photoFile,
    this.hospitalId,
    this.orgId,
  });

  @override
  List<Object?> get props => [userId, photoFile, hospitalId, orgId];
}
