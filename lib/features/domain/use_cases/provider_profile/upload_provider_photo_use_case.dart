import 'dart:io';
import 'package:yiraclinics/features/domain/repositories/provider_profile/provider_profile_repo.dart';

class UploadProviderPhotoUseCase {
  final ProviderProfileRepo repository;

  UploadProviderPhotoUseCase({required this.repository});

  Future<String> call({
    required String userId,
    required File photoFile,
    int? hospitalId,
    int? orgId,
  }) async {
    return await repository.uploadProfilePhoto(
      userId: userId,
      photoFile: photoFile,
      hospitalId: hospitalId,
      orgId: orgId,
    );
  }
}
