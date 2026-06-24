import 'package:flutter/material.dart';

enum RoleType { frontDesk, provider }

class RoleLoginEntity {
  final RoleType type;
  final String title;
  final String subtitle;
  final IconData icon;

  const RoleLoginEntity({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}