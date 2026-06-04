import 'package:flutter/material.dart';

class SettingTileEntity {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingTileEntity({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}