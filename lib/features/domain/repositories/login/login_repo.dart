import '../../entities/login/login_entity.dart';
import '../../entities/send_otp/send_otp_entity.dart';

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

  Future<SendOtpEntity?> sendSignupOtp({
    required String mobileNumber,
    String? countryCode,
  });

  Future<LoginEntity?> registerPatient({
    required String mobileNumber,
    required String firstName,
    required String lastName,
    String? email,
    required String password,
    required String otp,
    required String sessionId,
    String? countryCode,
    String? profileImagePath,
  });
}