import 'package:flutter/material.dart';
import '../domain/repositories/app_theme/theme_repos.dart';

class CacheThemeUseCase {
  final ThemeRepository repository;
  CacheThemeUseCase(this.repository);

  Future<void> call(ThemeMode themeMode) async {
    await repository.cacheThemeMode(themeMode);
  }
}