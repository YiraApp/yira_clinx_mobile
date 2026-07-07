
import 'package:equatable/equatable.dart';

class SideMenuEntity extends Equatable {
  final bool status;
  final String message;
  final List<SideMenuItemEntity> data;

  const SideMenuEntity({
    required this.status,
    required this.message,
    required this.data,
  });

  @override
  List<Object?> get props => [status, message, data];
}

class SideMenuItemEntity extends Equatable {
  final String title;
  final String taskCode;
  final int taskId;
  final String imagePath;

  const SideMenuItemEntity({
    required this.title,
    required this.taskCode,
    required this.taskId,
    required this.imagePath,
  });

  @override
  List<Object?> get props => [title, taskCode, taskId, imagePath];
}