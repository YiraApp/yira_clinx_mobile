

import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../common_size_helpers/common_size_helpers.dart';
import 'date_box.dart';
import 'date_time_utils.dart';

class WeekView extends StatelessWidget {
  WeekView({
    super.key,
    required this.dates,
    required this.selectedDate,
    required this.lineHeight,
    this.highlightMonth,
    this.onChanged,
    this.events,
    required this.innerDot,
    required this.keepLineSize,
    this.textStyle, this.dateSize, required this.buttonPrimaryColor,
  });
final double? dateSize;
  final DateTime todayDate = DateTime.now().toZeroTime();
  final List<DateTime> dates;
  final double lineHeight;
  final Color buttonPrimaryColor;
  final int? highlightMonth;
  final DateTime selectedDate;
  final ValueChanged<DateTime>? onChanged;
  final List<DateTime>? events;
  final bool innerDot;
  final bool keepLineSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: lineHeight,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List<Widget>.generate(
          7,
              (dayIndex) {
            final date = dates[dayIndex];
            final isToday = date.isAtSameMomentAs(todayDate);
            final isSelected = date.isAtSameMomentAs(selectedDate);
            final isHighlight = highlightMonth == date.month;

            final hasEvent =
            events!.indexWhere((element) => element.isSameDate(date));

            if (keepLineSize) {
              return InkResponse(
                onTap: onChanged != null ? () => onChanged!(date) : null,
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primaryColor
                        : isToday
                        ? theme.highlightColor
                        : null,
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    shape: BoxShape.rectangle,
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${date.day}',
                        style: textStyle?.copyWith(
                          color: isSelected || isToday
                              ? theme.colorScheme.onPrimary
                              : isHighlight || highlightMonth == null
                              ? null
                              : theme.disabledColor,
                          fontWeight:
                          isSelected && textStyle?.fontWeight != null
                              ? FontWeight
                              .values[textStyle!.fontWeight!.index + 2]
                              : textStyle?.fontWeight,
                          fontSize:isTablet(context)?displayWidth(context) * 0.015: displayWidth(context)*0.035,
                        ),
                      ),
                      if (!hasEvent.isNegative)
                        Container(
                          height: 4,
                          width: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.secondary,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DateBox(
                  buttonPrimaryColor: buttonPrimaryColor,
                  width: innerDot ? 32 : 24,
                  height: innerDot ? 32 : 24,
                  showDot: innerDot,
                  onPressed: onChanged != null ? () => onChanged!(date) : null,
                  isSelected: isSelected,
                  isToday: isToday,
                  hasEvent: !hasEvent.isNegative,
                  child: Text(
                    '${date.day}',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      color: isSelected || isToday
                          ? Colors.white
                          : isHighlight || highlightMonth == null
                          ? null
                          : theme.disabledColor,
                        fontSize:isTablet(context)?displayWidth(context) * 0.012: displayWidth(context)*0.028,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ),
              ],
            );
          },
          growable: false,
        ),
      ),
    );
  }
}
