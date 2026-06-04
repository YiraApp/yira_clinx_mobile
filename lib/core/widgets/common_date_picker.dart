import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';

import '../../core/constants/constants.dart';
import '../common_widgets/common_text.dart';

class CommonDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const CommonDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () async {
        final DateTime now = DateTime.now();
        final int dynamicLastYear = now.year + 5;

        final chosen = await showDatePicker(
          initialEntryMode: DatePickerEntryMode.calendarOnly,
          context: context,
          initialDate: selectedDate.isBefore(DateTime(1940))
              ? DateTime.now()
              : selectedDate,
          firstDate: DateTime(1940),
          lastDate: DateTime(dynamicLastYear, 12, 31),
          builder: (BuildContext context, Widget? child) {
            final currentTheme = Theme.of(context);
            final isDarkTheme =
                currentTheme.brightness == Brightness.dark;

            return Theme(
              data: currentTheme.copyWith(
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: currentTheme.primaryColor,
                    textStyle: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.w600,
                      fontSize: displayWidth(context) * 0.036,
                    ),
                  ),
                ),
                datePickerTheme: DatePickerThemeData(
                  backgroundColor:
                  isDarkTheme ? cardPopUpMenuColor : Colors.white,

                  headerBackgroundColor:
                  currentTheme.primaryColor,

                  headerForegroundColor: Colors.white,

                  dividerColor: isDarkTheme
                      ? Colors.white12
                      : Colors.grey.shade200,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),

                  headerHeadlineStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w700,
                    fontSize:
                    displayWidth(context) * 0.048,
                    color: Colors.white,
                  ),

                  headerHelpStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w500,
                    fontSize:
                    displayWidth(context) * 0.038,
                    color: Colors.white,
                  ),

                  dayStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize:
                    displayWidth(context) * 0.032,
                  ),

                  yearStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize:
                    displayWidth(context) * 0.032,
                  ),

                  dayForegroundColor:
                  WidgetStateProperty.resolveWith(
                        (states) {
                      if (states.contains(
                          WidgetState.selected)) {
                        return Colors.white;
                      }

                      return isDarkTheme
                          ? Colors.white
                          : Colors.black87;
                    },
                  ),

                  dayBackgroundColor:
                  WidgetStateProperty.resolveWith(
                        (states) {
                      if (states.contains(
                          WidgetState.selected)) {
                        return currentTheme.primaryColor;
                      }
                      return null;
                    },
                  ),

                  todayForegroundColor:
                  WidgetStateProperty.resolveWith(
                        (states) {
                      return Colors.white;
                    },
                  ),

                  todayBackgroundColor:
                  WidgetStateProperty.resolveWith(
                        (states) {
                      return currentTheme.primaryColor;
                    },
                  ),

                  yearForegroundColor:
                  WidgetStateProperty.resolveWith(
                        (states) {
                      if (states.contains(
                          WidgetState.selected)) {
                        return Colors.white;
                      }

                      return isDarkTheme
                          ? Colors.white
                          : Colors.black87;
                    },
                  ),

                  yearBackgroundColor:
                  WidgetStateProperty.resolveWith(
                        (states) {
                      if (states.contains(
                          WidgetState.selected)) {
                        return currentTheme.primaryColor;
                      }
                      return null;
                    },
                  ),
                ),
                colorScheme: isDarkTheme
                    ? ColorScheme.dark(
                  primary:
                  currentTheme.primaryColor,
                  onPrimary: Colors.white,
                  surface: cardPopUpMenuColor,
                  onSurface: Colors.white,
                  onSurfaceVariant:
                  Colors.white,
                )
                    : ColorScheme.light(
                  primary:
                  currentTheme.primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                  onSurfaceVariant:
                  Colors.white,
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
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.transparent
                : const Color(0xFFCED4DA),
          ),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CommonText(
                DateFormat('MMM dd, yyyy')
                    .format(selectedDate),
                style: textTheme.bodyMedium?.copyWith(
                  fontFamily: appPoppinFont,
                  fontSize:
                  displayWidth(context) * 0.034,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: isDark
                  ? Colors.white60
                  : const Color(0xFF495057),
            ),
          ],
        ),
      ),
    );
  }
}