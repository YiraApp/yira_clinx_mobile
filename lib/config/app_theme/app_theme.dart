import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../core/colors/colors.dart';

class AppTheme {
  static const Color primaryTeal = primaryColor;
  static const Color darkBg = darkBackGroundColor;
  static const Color darkSurface = darkSurfaceColor;
  static TextTheme _buildTextTheme(Color color) {
    return TextTheme(
      displayLarge: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: color.withOpacity(0.9), fontSize: 16),
      bodyMedium: TextStyle(color: color.withOpacity(0.8), fontSize: 14),
      labelSmall: TextStyle(color: color.withOpacity(0.6), fontSize: 12),
    );
  }
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryTeal,
    scaffoldBackgroundColor: lightModeBgColor,
    colorScheme: const ColorScheme.light(
      primary: primaryTeal,
      surface: lightBackGroundColor,
    ),
    textTheme: _buildTextTheme(Colors.black),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackGroundColor,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryTeal,
      thumbColor: primaryTeal,
      overlayColor: primaryTeal.withOpacity(0.2),
      inactiveTrackColor: Colors.grey.shade200,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
      states.contains(WidgetState.selected) ? primaryTeal : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    elevatedButtonTheme: _buttonTheme(),
    chipTheme: _chipTheme(Colors.grey.shade300),
    inputDecorationTheme: _inputTheme(lightBackGroundColor, Colors.grey.shade200),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryTeal,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: primaryTeal,
      surface: darkBg,
      onSurface: textDarkModePrimaryColor,
    ),
    textTheme: _buildTextTheme(textDarkModePrimaryColor),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color:textDarkModePrimaryColor),
      titleTextStyle: TextStyle(
        color: textDarkModePrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: primaryTeal,
      thumbColor: primaryTeal,
      inactiveTrackColor: inactiveTrackColor,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) =>
      states.contains(WidgetState.selected) ? primaryTeal : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    elevatedButtonTheme: _buttonTheme(),
    chipTheme: _chipTheme(Colors.white10),
    inputDecorationTheme: _inputTheme(darkSurface, Colors.transparent),
  );

  static ElevatedButtonThemeData _buttonTheme() => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryTeal,
      foregroundColor: lightBackGroundColor,
      minimumSize: const Size(double.infinity, 54),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 0,
    ),
  );

  static ChipThemeData _chipTheme(Color borderColor) => ChipThemeData(
    selectedColor: primaryTeal.withOpacity(0.1),
    secondarySelectedColor: primaryTeal,
    shape: StadiumBorder(side: BorderSide(color: borderColor)),
  );

  static InputDecorationTheme _inputTheme(Color fill, Color border) =>
      InputDecorationTheme(
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          borderSide: BorderSide(color: border),
        ),
      );
}