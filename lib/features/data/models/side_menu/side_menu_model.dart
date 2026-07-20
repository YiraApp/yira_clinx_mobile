// data/models/side_menu_model.dart
import '../../../domain/entities/side_menu/side_menu_entity.dart';

class SideMenuModel extends SideMenuEntity {
  const SideMenuModel({
    required super.status,
    required super.message,
    required super.data,
  });

  factory SideMenuModel.fromJson(Map<String, dynamic> json) {
    return SideMenuModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null
          ? List<SideMenuItemModel>.from(
        json['data'].map((x) => SideMenuItemModel.fromJson(x)),
      )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((x) {
        if (x is SideMenuItemModel) {
          return x.toJson();
        }
        return {
          'title': x.title,
          'taskCode': x.taskCode,
          'taskId': x.taskId,
          'ImagePath': x.imagePath,
        };
      }).toList(),
    };
  }
}

class SideMenuItemModel extends SideMenuItemEntity {
  const SideMenuItemModel({
    required super.title,
    required super.taskCode,
    required super.taskId,
    required super.imagePath,
  });

  factory SideMenuItemModel.fromJson(Map<String, dynamic> json) {
    return SideMenuItemModel(
      title: json['title'] ?? '',
      taskCode: json['taskCode'] ?? '',
      taskId: json['taskId'] ?? 0,
      imagePath: json['ImagePath'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'taskCode': taskCode,
      'taskId': taskId,
      'ImagePath': imagePath,
    };
  }
}