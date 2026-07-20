import 'package:flutter/widgets.dart';

import 'date_time_utils.dart';


/// Advanced Calendar controller that manage selection date state.
class AdvancedCalendarController extends ValueNotifier<DateTime> {
  /// Generates controller with custom date selected.
  AdvancedCalendarController(super.value);

  /// Generates controller with today date selected.
  AdvancedCalendarController.today() : this(DateTime.now().toZeroTime());

  @override
  set value(DateTime newValue) => super.value = newValue.toZeroTime();
}
