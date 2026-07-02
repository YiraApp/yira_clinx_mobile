

import '../../../domain/entities/forget_password/forget_password_verify_otp_enity.dart';

class ForgetPasswordVerifyOtpModel extends ForgetPasswordVerifyOtpEntity {
  ForgetPasswordVerifyOtpModel({
    super.status,
    super.message,
    super.data,
  });

  factory ForgetPasswordVerifyOtpModel.fromJson(Map<String, dynamic> json) {
    return ForgetPasswordVerifyOtpModel(
      status: json['status'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? VerifyOtpDataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonMap = {};
    jsonMap['status'] = status;
    jsonMap['message'] = message;
    if (data != null) {
      jsonMap['data'] = (data as VerifyOtpDataModel).toJson();
    }
    return jsonMap;
  }
}

class VerifyOtpDataModel extends VerifyOtpDataEntity {
  VerifyOtpDataModel({
    super.success,
    super.message,
    super.contact,
    super.contactType,
    super.countryCode,
  });

  factory VerifyOtpDataModel.fromJson(Map<String, dynamic> json) {
    return VerifyOtpDataModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      contact: json['contact'] as String?,
      contactType: json['contactType'] as String?,
      countryCode: json['countryCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'contact': contact,
      'contactType': contactType,
      'countryCode': countryCode,
    };
  }
}