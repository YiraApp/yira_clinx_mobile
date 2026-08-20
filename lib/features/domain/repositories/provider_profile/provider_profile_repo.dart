import 'dart:io';
import 'package:yiraclinics/features/domain/entities/provider_profile/provider_profile_entity.dart';

abstract class ProviderProfileRepo {
  Future<ProviderProfileEntity> getProviderProfile({
    required String userId,
    int? hospitalId,
    int? orgId,
  });

  Future<ProviderProfileEntity> updateProviderProfile({
    required ProviderProfileEntity profile,
  });

  Future<String> uploadProfilePhoto({
    required String userId,
    required File photoFile,
    int? hospitalId,
    int? orgId,
  });
}
