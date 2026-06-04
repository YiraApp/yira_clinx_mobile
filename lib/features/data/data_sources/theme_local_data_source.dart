
import '../../../core/local/shared_preferences.dart';

abstract class ThemeLocalDataSource {
  int getThemeIndex();
  Future<bool> cacheThemeIndex(int index);
}

class ThemeLocalDataSourceImpl implements ThemeLocalDataSource {
  final SharedPrefsService sharedPrefsService;
  static const String _themeKey = 'APP_THEME_MODE_INDEX';

  ThemeLocalDataSourceImpl(this.sharedPrefsService);

  @override
  int getThemeIndex() {
    return sharedPrefsService.getValue<int>(_themeKey) ?? 0;
  }

  @override
  Future<bool> cacheThemeIndex(int index) async {
    return await sharedPrefsService.setValue<int>(_themeKey, index);
  }
}