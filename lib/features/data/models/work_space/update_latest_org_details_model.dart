import '../../../domain/entities/work_space/update_latest_org_details_entity.dart';
class UpdateLatestOrgDetailsModel extends UpdateLatestOrgDetailsEntity {
  const UpdateLatestOrgDetailsModel({
    required super.status,
    required super.message,
    super.data,
  });

  factory UpdateLatestOrgDetailsModel.fromJson(Map<String, dynamic> json) {
    return UpdateLatestOrgDetailsModel(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? LatestOrgDetailsDataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data != null ? (data as LatestOrgDetailsDataModel).toJson() : null,
    };
  }
}



class LatestOrgDetailsDataModel extends LatestOrgDetailsDataEntity {
  const LatestOrgDetailsDataModel({
    required super.userId,
    required super.latestRoleId,
    required super.latestOrgId,
    required super.latestHospitalId,
    required super.navigationId,
  });

  factory LatestOrgDetailsDataModel.fromJson(Map<String, dynamic> json) {
    return LatestOrgDetailsDataModel(
      userId: json['userId'] as String? ?? '',
      latestRoleId: json['latestRoleId'] as String? ?? '',
      latestOrgId: json['latestOrgId'] as int? ?? 0,
      latestHospitalId: json['latestHospitalId'] as int? ?? 0,
      navigationId: json['navigationId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'latestRoleId': latestRoleId,
      'latestOrgId': latestOrgId,
      'latestHospitalId': latestHospitalId,
      'navigationId': navigationId,
    };
  }
}