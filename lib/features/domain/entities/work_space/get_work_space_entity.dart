
class GetWorkSpaceDetailsEntity {
  final bool? status;
  final String? message;
  final List<DataEntity>? data;

  GetWorkSpaceDetailsEntity({this.status, this.message, this.data});
}

class DataEntity {
  final int? organizationId;
  final String? organizationName;
  final String? organizationCode;
  final bool? isExpanded;
  final List<HospitalsEntity>? hospitals;

  DataEntity({
    this.organizationId,
    this.organizationName,
    this.organizationCode,
    this.hospitals, this.isExpanded,
  });
}

class HospitalsEntity {
  final int? hospitalId;
  final String? hospitalCode;
  final String? hospitalName;
  final String? email;
  final String? mobileNumber;
  final String? countryCode;
  final String? address;
  final String? helplineNumber;
  final String? website;
  final String? city;
  final String? state;
  final String? country;
  final String? pincode;
  final bool? status;
  final bool? is24Hours;

  HospitalsEntity({
    this.hospitalId,
    this.hospitalCode,
    this.hospitalName,
    this.email,
    this.mobileNumber,
    this.countryCode,
    this.address,
    this.helplineNumber,
    this.website,
    this.city,
    this.state,
    this.country,
    this.pincode,
    this.status,
    this.is24Hours,
  });
}