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
    textButtonTheme: _textButtonTheme(),
    chipTheme: _chipTheme(Colors.grey.shade300),
    inputDecorationTheme: _inputTheme(lightBackGroundColor, Colors.grey.shade200),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryTeal,
      unselectedItemColor: Colors.grey,
    ),
    dialogTheme: _dialogTheme(
      background: Colors.white,
      title: const Color(0xFF0F172A),
      body: const Color(0xFF475569),
    ),
    bottomSheetTheme: _bottomSheetTheme(Colors.white, const Color(0xFFCBD5E1)),
    popupMenuTheme: _popupMenuTheme(Colors.white, const Color(0xFF0F172A)),
    datePickerTheme: _datePickerTheme(Colors.white),
    timePickerTheme: _timePickerTheme(Colors.white),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade200,
      thickness: 0.8,
    ),
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
    textButtonTheme: _textButtonTheme(),
    chipTheme: _chipTheme(Colors.white10),
    inputDecorationTheme: _inputTheme(darkSurface, Colors.transparent),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkModeCardColor,
      selectedItemColor: primaryTeal,
      unselectedItemColor: Colors.white54,
    ),
    dialogTheme: _dialogTheme(
      background: darkModeCardColor,
      title: Colors.white,
      body: const Color(0xFFCBD5E1),
    ),
    bottomSheetTheme: _bottomSheetTheme(darkModeCardColor, const Color(0xFF475569)),
    datePickerTheme: _datePickerTheme(darkModeCardColor),
    timePickerTheme: _timePickerTheme(darkModeCardColor),
    cardTheme: CardThemeData(
      color: darkModeCardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.white10,
      thickness: 0.8,
    ),
    popupMenuTheme: _popupMenuTheme(darkModeCardColor, Colors.white),
  );

  // --- Popups: dialogs, bottom sheets, menus and pickers share one look ---

  static const double _popupRadius = 24;

  static DialogThemeData _dialogTheme({
    required Color background,
    required Color title,
    required Color body,
  }) =>
      DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_popupRadius)),
        titleTextStyle: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: title,
        ),
        contentTextStyle: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: body,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      );

  static BottomSheetThemeData _bottomSheetTheme(Color background, Color handle) => BottomSheetThemeData(
        backgroundColor: background,
        modalBackgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: handle,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_popupRadius)),
        ),
      );

  static PopupMenuThemeData _popupMenuTheme(Color background, Color text) => PopupMenuThemeData(
        color: background,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(fontFamily: appPoppinFont, fontSize: 14, color: text),
      );

  static DatePickerThemeData _datePickerTheme(Color background) => DatePickerThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_popupRadius)),
      );

  static TimePickerThemeData _timePickerTheme(Color background) => TimePickerThemeData(
        backgroundColor: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_popupRadius)),
      );

  /// Dialog actions are mostly plain TextButtons; give them the app font.
  static TextButtonThemeData _textButtonTheme() => TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w600),
        ),
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