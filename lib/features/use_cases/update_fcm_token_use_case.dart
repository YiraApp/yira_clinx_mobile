

import 'package:equatable/equatable.dart';
import 'package:yiraclinics/features/domain/repositories/fcm_token/update_fcm_token_repo.dart';

import '../../core/use_case/use_case.dart';
import '../domain/entities/fcm_token/update_fcm_token_entity.dart';
import '../domain/entities/login/login_entity.dart';
import '../domain/repositories/login/login_repo.dart';

class UpdateFcmTokenUseCase implements UseCase<FcmTokenEntity?,String> {
  final UpdateFcmRepository _repository;

  const UpdateFcmTokenUseCase({required UpdateFcmRepository repository}) : _repository = repository;

  @override
  Future<FcmTokenEntity?> call(String fcmToken) {

    return _repository.updateFcmToken(fcmToken: fcmToken);
  }
}
