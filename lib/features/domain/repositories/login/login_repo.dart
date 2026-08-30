

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

  Future<LoginEntity?> registerPatient({
    required String firstName,
    required String lastName,
    String? email,
    required String mobileNumber,
    required String countryCode,
    required String password,
    required String otp,
    required String sessionId,
  });
}