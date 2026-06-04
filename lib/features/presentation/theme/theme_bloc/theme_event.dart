part of 'theme_bloc.dart';

@immutable
abstract class ThemeEvent {}

class LoadThemeEvent extends ThemeEvent {}

class SetThemeEvent extends ThemeEvent {
  final ThemeMode themeMode;
  SetThemeEvent(this.themeMode);
}
