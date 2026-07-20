
class SendOtpEntity {
  final bool? status;
  final String? message;
  final SendOtpDataEntity? data;

  const SendOtpEntity({
    this.status,
    this.message,
    this.data,
  });
}

class SendOtpDataEntity {
  final bool? otpSent;
  final String? sessionId;
  final String? contact;
  final String? contactType;
  final String? message;

  const SendOtpDataEntity({
    this.otpSent,
    this.sessionId,
    this.contact,
    this.contactType,
    this.message,
  });
}