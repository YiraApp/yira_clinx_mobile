import 'package:flutter/material.dart';

class AppPopupItemModel {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final bool isDestructive;

  const AppPopupItemModel({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.isDestructive = false,
  });
}