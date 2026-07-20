

import '../../entities/login/login_entity.dart';

abstract class LoginRepository {
  Future<LoginEntity?> loginWithEmail({
    required String email,
    required String password,
  });

  Future<LoginEntity?> loginWithMobile({
    required String mobileNumber,
    required String otp,
    required String sessionId,
    String? countryCode,
  });
}