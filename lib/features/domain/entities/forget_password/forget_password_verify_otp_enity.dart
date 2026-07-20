class ForgetPasswordVerifyOtpEntity {
  final bool? status;
  final String? message;
  final VerifyOtpDataEntity? data;

  ForgetPasswordVerifyOtpEntity({
    this.status,
    this.message,
    this.data,
  });
}

class VerifyOtpDataEntity {
  final bool? success;
  final String? message;
  final String? contact;
  final String? contactType;
  final String? countryCode;

  VerifyOtpDataEntity({
    this.success,
    this.message,
    this.contact,
    this.contactType,
    this.countryCode,
  });
}