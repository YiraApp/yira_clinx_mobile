


import 'package:yiraclinics/features/domain/entities/common/common_entity.dart';

abstract class SaveResetPasswordRepo {
  Future<CommonEntity?> savePassword({
    required String identity,
    required String contactType,
    required String countryCode,
    required String newPassword,
    required String confirmPassword,
  });
}
