import 'package:flutter/material.dart';

enum TourCardPosition { top, bottom, auto }

class ProviderTourStep {
  final String id;
  final String title;
  final String description;
  final GlobalKey? targetKey;
  final IconData icon;
  final String? route;
  final int? navIndex;
  final int? tabIndex;
  final TourCardPosition position;
  final double borderRadius;
  final EdgeInsets targetPadding;

  const ProviderTourStep({
    required this.id,
    required this.title,
    required this.description,
    this.targetKey,
    required this.icon,
    this.route,
    this.navIndex,
    this.tabIndex,
    this.position = TourCardPosition.auto,
    this.borderRadius = 16.0,
    this.targetPadding = const EdgeInsets.all(6.0),
  });
}
