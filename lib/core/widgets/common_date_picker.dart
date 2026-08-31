import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import '../../core/constants/constants.dart';
import '../common_widgets/common_text.dart';

class CommonDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final double? borderRadius;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const CommonDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.borderRadius,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    // Synchronized border radius fallback logic matching form elements
    final double computedRadius = borderRadius ?? fieldBorderRadius;

    // Adaptive System Colors Matrix
    final Color inactiveBorderColor = isDark ? darkModeBorderColor : lightModeBorderColor;
    final Color activeBorderColor = isDark ? darkModeBorderFocusedColor : lightModeBorderFocusedColor;
    final Color surfaceColor = isDark
        ? darkModeCardColor.withOpacity(0.8)
        : lightModeTextFieldBgColor;

    return InkWell(
      onTap: () async {
        final DateTime now = DateTime.now();
        final int dynamicLastYear = now.year + 5;

        final effectiveFirstDate = firstDate ?? DateTime(1940);
        final effectiveLastDate = lastDate ?? DateTime(dynamicLastYear, 12, 31);
        final effectiveInitialDate = selectedDate.isBefore(effectiveFirstDate)
            ? effectiveFirstDate
            : (selectedDate.isAfter(effectiveLastDate) ? effectiveLastDate : selectedDate);

        final chosen = await showDatePicker(
          initialEntryMode: DatePickerEntryMode.calendarOnly,
          context: context,
          initialDate: effectiveInitialDate,
          firstDate: effectiveFirstDate,
          lastDate: effectiveLastDate,
          builder: (BuildContext context, Widget? child) {
            return Theme(
              data: theme.copyWith(
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: activeBorderColor,
                    textStyle: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.w600,
                      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.036,
                    ),
                  ),
                ),
                datePickerTheme: DatePickerThemeData(
                  backgroundColor: isDark ? darkModeCardColor : Colors.white,
                  headerBackgroundColor: theme.primaryColor,
                  headerForegroundColor: Colors.white,
                  dividerColor: isDark ? darkModeBorderColor : lightModeBorderColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(computedRadius),
                    side: BorderSide(color: inactiveBorderColor, width: 1.0),
                  ),
                  headerHeadlineStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w700,
                    fontSize: isTab ? displayWidth(context) * 0.024 : displayWidth(context) * 0.048,
                    color: Colors.white,
                  ),
                  headerHelpStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w500,
                    fontSize: isTab ? displayWidth(context) * 0.020 : displayWidth(context) * 0.038,
                    color: Colors.white,
                  ),
                  dayStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.032,
                  ),
                  yearStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? displayWidth(context) * 0.016 : displayWidth(context) * 0.032,
                  ),
                  dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return Colors.white;
                    return isDark ? textDarkModePrimaryColor : textLightModeColor;
                  }),
                  dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return theme.primaryColor;
                    return null;
                  }),
                  todayForegroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return Colors.white;
                    return theme.primaryColor;
                  }),
                  todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return theme.primaryColor;
                    return Colors.transparent;
                  }),
                  yearForegroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return Colors.white;
                    return isDark ? textDarkModePrimaryColor : textLightModeColor;
                  }),
                  yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) return theme.primaryColor;
                    return null;
                  }),
                ),
                colorScheme: isDark
                    ? ColorScheme.dark(
                  primary: theme.primaryColor,
                  onPrimary: Colors.white,
                  surface: darkModeCardColor,
                  onSurface: textDarkModePrimaryColor,
                  onSurfaceVariant: Colors.white,
                )
                    : ColorScheme.light(
                  primary: theme.primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: textLightModeColor,
                  onSurfaceVariant: textLightModeColor.withOpacity(0.6),
                ),
              ),
              child: child!,
            );
          },
        );

        if (chosen != null) {
          onDateSelected(chosen);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Synchronized height padding
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(computedRadius),
          border: Border.all(
            color: inactiveBorderColor,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CommonText(
                DateFormat('MMM dd, yyyy').format(selectedDate),
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  decorationThickness: 0,
                  decoration: TextDecoration.none,
                  fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.035,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: isDark ? Colors.white : const Color(0xFF495057),
            ),
          ],
        ),
      ),
    );
  }
}