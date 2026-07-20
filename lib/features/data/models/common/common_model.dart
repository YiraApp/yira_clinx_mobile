
import '../../../domain/entities/common/common_entity.dart';

class CommonModel extends CommonEntity {
  const CommonModel({
    required super.status,
    required super.message,
    super.data,
  });

  factory CommonModel.fromJson(Map<String, dynamic> json) {
    return CommonModel(
      status: json['status'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data,
    };
  }
  factory CommonModel.fromEntity(CommonEntity entity) {
    return CommonModel(
      status: entity.status,
      message: entity.message,
      data: entity.data,
    );
  }
}