
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/widgets/calendar/view_range.dart';
import 'package:yiraclinics/core/widgets/calendar/week_view.dart';

import 'date_time_utils.dart';

class MonthView extends StatelessWidget {
  const MonthView({
    super.key,
    required this.monthView,
    required this.todayDate,
    required this.selectedDate,
    required this.weekLineHeight,
    required this.weeksAmount,
    required this.innerDot,
    this.onChanged,
    this.events,
    required this.keepLineSize,
    this.textStyle, required this.numberOfweeks, required this.buttonPrimaryColor,
  });
final int numberOfweeks;

final Color buttonPrimaryColor;
  final ViewRange monthView;
  final DateTime? todayDate;
  final DateTime selectedDate;
  final double weekLineHeight;
  final int weeksAmount;
  final ValueChanged<DateTime>? onChanged;
  final List<DateTime>? events;
  final bool innerDot;
  final bool keepLineSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final index = selectedDate.findWeekIndex(monthView.dates);
    final offset = index / (weeksAmount - 1) * 2 - 1.0;

    return OverflowBox(
      alignment: Alignment(0, offset),
      minHeight: weekLineHeight,
      maxHeight: weekLineHeight * weeksAmount,
      child: Column(
        children: List<Widget>.generate(
          numberOfweeks,
              (weekIndex) {
            final weekStart = weekIndex * 7;
            return WeekView(
              innerDot: innerDot,
              dates: monthView.dates.sublist(weekStart, weekStart + 7),
              selectedDate: selectedDate,
              highlightMonth: monthView.firstDay.month,
              lineHeight: weekLineHeight,
              onChanged: onChanged,
              events: events,
              keepLineSize: keepLineSize,
              textStyle: textStyle, buttonPrimaryColor: buttonPrimaryColor,
            );
          },
          growable: false,
        ),
      ),
    );
  }
}
