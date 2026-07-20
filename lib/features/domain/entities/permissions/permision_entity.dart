
import 'package:flutter/cupertino.dart';

class PermissionItemEntity {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isGranted;
  final bool isRequired;

  PermissionItemEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isGranted = false,
    this.isRequired = false,
  });

  PermissionItemEntity copyWith({bool? isGranted}) {
    return PermissionItemEntity(
      id: id,
      title: title,
      description: description,
      icon: icon,
      isRequired: isRequired,
      isGranted: isGranted ?? this.isGranted,
    );
  }
}