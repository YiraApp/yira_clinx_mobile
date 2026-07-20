import '../../../domain/entities/send_otp/send_otp_entity.dart';
class SendOtpModel extends SendOtpEntity {
  const SendOtpModel({
    super.status,
    super.message,
    SendOtpDataModel? super.data,
  });

  factory SendOtpModel.fromJson(Map<String, dynamic> json) {
    return SendOtpModel(
      status: json['status'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? SendOtpDataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data != null ? (data as SendOtpDataModel).toJson() : null,
    };
  }
}

class SendOtpDataModel extends SendOtpDataEntity {
  const SendOtpDataModel({
    super.otpSent,
    super.sessionId,
    super.contact,
    super.contactType,
    super.message,
  });

  factory SendOtpDataModel.fromJson(Map<String, dynamic> json) {
    return SendOtpDataModel(
      otpSent: json['otpSent'] as bool?,
      sessionId: json['sessionId'] as String?,
      contact: json['contact'] as String?,
      contactType: json['contactType'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'otpSent': otpSent,
      'sessionId': sessionId,
      'contact': contact,
      'contactType': contactType,
      'message': message,
    };
  }
}