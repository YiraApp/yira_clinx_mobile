class ForgetPasswordSendOtpEntity {
  final bool? status;
  final String? message;
  final DataEntity? data;

  ForgetPasswordSendOtpEntity({
    this.status,
    this.message,
    this.data,
  });
}

class DataEntity {
  final String? sessionId;
  final String? contact;
  final String? contactType;
  final String? countryCode;
  final String? message;

  DataEntity({
    this.sessionId,
    this.contact,
    this.contactType,
    this.countryCode,
    this.message,
  });
}