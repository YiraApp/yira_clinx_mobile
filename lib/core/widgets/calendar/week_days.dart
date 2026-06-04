

import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../common_size_helpers/common_size_helpers.dart';
import 'date_box.dart';

/// Week day names line.
class WeekDays extends StatelessWidget {
  const WeekDays({
    Key? key,
    this.weekNames = const <String>['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    this.style,
    required this.keepLineSize, required this.buttonPrimaryColor, required this.weekColor,
  })  : assert(weekNames.length == 7, '`weekNames` must have length 7'),
        super(key: key);

  /// Week day names.
  final List<String> weekNames;
  final Color weekColor;
  final Color buttonPrimaryColor;

  /// Text style.
  final TextStyle? style;

  final bool keepLineSize;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: style!,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(weekNames.length, (index) {
          return DateBox(
            buttonPrimaryColor: buttonPrimaryColor,
            isWeek: true,
            child: Text(weekNames[index],style: TextStyle(color: weekColor,fontSize:isTablet(context)?displayWidth(context) * 0.011: displayWidth(context)*0.022,fontFamily: appPoppinFont,fontWeight: FontWeight.w500),),
          );
        }),
      ),
    );
  }
}
