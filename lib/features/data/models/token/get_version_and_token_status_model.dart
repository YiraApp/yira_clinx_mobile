
import '../../../domain/entities/token/get_version_and_token_status_entity.dart';
class GetVersionAndTokenStatusModel extends VersionTokenStatusEntity {
  const GetVersionAndTokenStatusModel({
    required super.status,
    required super.message,
    super.data,
  });

  factory GetVersionAndTokenStatusModel.fromJson(Map<String, dynamic> json) {
    return GetVersionAndTokenStatusModel(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null
          ? VersionTokenStatusDataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data != null ? (data as VersionTokenStatusDataModel).toJson() : null,
    };
  }
}


class VersionTokenStatusDataModel extends GetVersionTokenStatusEntity {
  const VersionTokenStatusDataModel({
    required super.versionStatus,
    required super.updateType,
    required super.tokenStatus,
  });

  factory VersionTokenStatusDataModel.fromJson(Map<String, dynamic> json) {
    return VersionTokenStatusDataModel(
      versionStatus: json['versionStatus'] as bool? ?? false,
      updateType: json['updateType'] as String? ?? '',
      tokenStatus: json['tokenStatus'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'versionStatus': versionStatus,
      'updateType': updateType,
      'tokenStatus': tokenStatus,
    };
  }
}