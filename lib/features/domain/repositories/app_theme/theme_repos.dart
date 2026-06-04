import 'package:flutter/material.dart';

abstract class ThemeRepository {
  Future<ThemeMode> getThemeMode();
  Future<void> cacheThemeMode(ThemeMode themeMode);
}