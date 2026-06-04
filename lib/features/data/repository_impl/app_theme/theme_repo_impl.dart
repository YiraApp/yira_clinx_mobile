import 'package:flutter/material.dart';

import '../../../domain/repositories/app_theme/theme_repos.dart';
import '../../data_sources/theme_local_data_source.dart';

class ThemeRepositoryImpl implements ThemeRepository {
  final ThemeLocalDataSource localDataSource;

  ThemeRepositoryImpl(this.localDataSource);

  @override
  Future<ThemeMode> getThemeMode() async {
    final index = localDataSource.getThemeIndex();
    return ThemeMode.values[index];
  }

  @override
  Future<void> cacheThemeMode(ThemeMode themeMode) async {
    await localDataSource.cacheThemeIndex(themeMode.index);
  }
}