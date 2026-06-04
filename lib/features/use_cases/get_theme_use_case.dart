import 'package:flutter/material.dart';
import '../domain/repositories/app_theme/theme_repos.dart';

class GetThemeUseCase {
  final ThemeRepository repository;
  GetThemeUseCase(this.repository);

  Future<ThemeMode> call() async {
    return await repository.getThemeMode();
  }
}