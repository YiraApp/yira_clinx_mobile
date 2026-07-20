


import '../../../domain/entities/forget_password/forget_password_send_otp_entity.dart';

class ForgetPasswordSendOtpModel extends ForgetPasswordSendOtpEntity {
  ForgetPasswordSendOtpModel({
    super.status,
    super.message,
    super.data,
  });

  factory ForgetPasswordSendOtpModel.fromJson(Map<String, dynamic> json) {
    return ForgetPasswordSendOtpModel(
      status: json['status'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? DataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> jsonMap = {};
    jsonMap['status'] = status;
    jsonMap['message'] = message;
    if (data != null) {
      // Safely cast to DataModel to call its toJson()
      jsonMap['data'] = (data as DataModel).toJson();
    }
    return jsonMap;
  }
}

class DataModel extends DataEntity {
  DataModel({
    super.sessionId,
    super.contact,
    super.contactType,
    super.countryCode,
    super.message,
  });

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      sessionId: json['sessionId'] as String?,
      contact: json['contact'] as String?,
      contactType: json['contactType'] as String?,
      countryCode: json['countryCode'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'contact': contact,
      'contactType': contactType,
      'countryCode': countryCode,
      'message': message,
    };
  }
}