import 'package:flutter/material.dart';

enum RoleType { frontDesk, provider }

class RoleEntity {
  final RoleType type;
  final String title;
  final String subtitle;
  final IconData icon;

  const RoleEntity({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}