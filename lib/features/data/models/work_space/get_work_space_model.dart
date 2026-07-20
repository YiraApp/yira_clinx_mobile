
import '../../../domain/entities/work_space/get_work_space_entity.dart';

class GetWorkSpaceDetailsModel extends GetWorkSpaceDetailsEntity {
  GetWorkSpaceDetailsModel({
    super.status,
    super.message,
    List<DataModel>? super.data,
  });

  factory GetWorkSpaceDetailsModel.fromJson(Map<String, dynamic> json) {
    return GetWorkSpaceDetailsModel(
      status: json['status'],
      message: json['message'],
      data: json['data'] != null
          ? (json['data'] as List).map((v) => DataModel.fromJson(v)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.map((v) => (v as DataModel).toJson()).toList(),
    };
  }
}

class DataModel extends DataEntity {
  DataModel({
    super.organizationId,
    super.organizationName,
    super.organizationCode,
    super.isExpanded,
    List<HospitalsModel>? super.hospitals,
  });

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      organizationId: json['organizationId'],
      organizationName: json['organizationName'],
      organizationCode: json['organizationCode'],
      isExpanded: json['isExpanded']?? false,
      hospitals: json['hospitals'] != null
          ? (json['hospitals'] as List)
          .map((v) => HospitalsModel.fromJson(v))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'organizationId': organizationId,
      'organizationName': organizationName,
      'organizationCode': organizationCode,
      'isExpanded': isExpanded,
      'hospitals': hospitals?.map((v) => (v as HospitalsModel).toJson()).toList(),
    };
  }
}

class HospitalsModel extends HospitalsEntity {
  HospitalsModel({
    super.hospitalId,
    super.hospitalCode,
    super.hospitalName,
    super.email,
    super.mobileNumber,
    super.countryCode,
    super.address,
    super.helplineNumber,
    super.website,
    super.city,
    super.state,
    super.country,
    super.pincode,
    super.status,
    super.is24Hours,
  });

  factory HospitalsModel.fromJson(Map<String, dynamic> json) {
    return HospitalsModel(
      hospitalId: json['hospitalId'],
      hospitalCode: json['hospitalCode'],
      hospitalName: json['hospitalName'],
      email: json['email'],
      mobileNumber: json['mobileNumber'],
      countryCode: json['countryCode'],
      address: json['address'],
      helplineNumber: json['helplineNumber'],
      website: json['website'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      pincode: json['pincode'],
      status: json['status'],
      is24Hours: json['is24Hours'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hospitalId': hospitalId,
      'hospitalCode': hospitalCode,
      'hospitalName': hospitalName,
      'email': email,
      'mobileNumber': mobileNumber,
      'countryCode': countryCode,
      'address': address,
      'helplineNumber': helplineNumber,
      'website': website,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      'status': status,
      'is24Hours': is24Hours,
    };
  }
}