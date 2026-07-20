
import '../../entities/fcm_token/update_fcm_token_entity.dart';

abstract class UpdateFcmRepository {
  Future< FcmTokenEntity?> updateFcmToken({
    required String fcmToken
  });
}