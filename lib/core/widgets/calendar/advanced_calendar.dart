import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/widgets/calendar/view_range.dart';
import 'package:yiraclinics/core/widgets/calendar/week_days.dart';
import 'package:yiraclinics/core/widgets/calendar/week_view.dart';

import '../../common_size_helpers/common_size_helpers.dart';
import 'advanced_calendar_controller.dart';
import 'date_time_utils.dart';
import 'handle_bar.dart';
import 'headers.dart';
import 'month_view.dart';

/// Advanced Calendar widget.
class AdvancedCalendar extends StatefulWidget {
  const AdvancedCalendar({
    Key? key,
    this.controller,
    this.startWeekDay,
    this.events,
    this.weekLineHeight = 40.0,
    this.preloadMonthViewAmount = 13,
    this.preloadWeekViewAmount = 21,
    this.weeksInMonthViewAmount = 6,
    this.todayStyle,
    this.headerStyle,
    this.onHorizontalDrag,
    this.innerDot = false,
    this.keepLineSize = false,
    this.calendarTextStyle,
    this.showNavigationArrows = false,
    this.weekFontSize,
    required this.buttonPrimaryColor, required this.handlerColor, required this.weekColor, this.onDateChanged,
  })  : assert(
          keepLineSize && innerDot ||
              innerDot && !keepLineSize ||
              !innerDot && !keepLineSize,
          'keepLineSize should be used only when innerDot is true',
        ),
        super(key: key);

  /// Calendar selection date controller.
  final AdvancedCalendarController? controller;
  final Color buttonPrimaryColor;

  /// Executes on horizontal calendar swipe. Allows to load additional dates.
  final Function(DateTime)? onHorizontalDrag;
  final Function(DateTime)? onDateChanged;

  /// Height of week line.
  final double weekLineHeight;
final Color weekColor;
  /// Amount of months in month view to preload.
  final int preloadMonthViewAmount;
final Color handlerColor;
  /// Amount of weeks in week view to preload.
  final int preloadWeekViewAmount;

  /// Weeks lines amount in month view.
  final int weeksInMonthViewAmount;

  /// List of points for the week and month
  final List<DateTime>? events;

  /// The first day of the week starts[0-6]
  final int? startWeekDay;

  /// Style of headers date
  final TextStyle? headerStyle;

  /// Style of Today button
  final TextStyle? todayStyle;

  /// Show DateBox event in container.
  final bool innerDot;

  /// Keeps consistent line size for dates
  /// Can't be used without innerDot
  final bool keepLineSize;
  final double? weekFontSize;

  /// Text style for dates in calendar
  final TextStyle? calendarTextStyle;

  /// Show navigation arrows.
  final bool showNavigationArrows;

  @override
  _AdvancedCalendarState createState() => _AdvancedCalendarState();
}

class _AdvancedCalendarState extends State<AdvancedCalendar>
    with SingleTickerProviderStateMixin {
  late ValueNotifier<int> _monthViewCurrentPage;
  late AnimationController _animationController;
  late AdvancedCalendarController _controller;
  late double _animationValue;
  late List<ViewRange> _monthRangeList;
  late List<List<DateTime>> _weekRangeList;

  PageController? _monthPageController;
  PageController? _weekPageController;
  Offset? _captureOffset;
  DateTime? _todayDate;
  List<String>? _weekNames;

  @override
  void initState() {
    super.initState();

    final monthPageIndex = widget.preloadMonthViewAmount ~/ 2;

    _monthViewCurrentPage = ValueNotifier(monthPageIndex);

    _monthPageController = PageController(
      initialPage: monthPageIndex,
    );

    final weekPageIndex = widget.preloadWeekViewAmount ~/ 2;

    _weekPageController = PageController(
      initialPage: weekPageIndex,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 0,
    );

    _animationValue = _animationController.value;

    _controller = widget.controller ?? AdvancedCalendarController.today();
    _todayDate = _controller.value;

    _monthRangeList = List.generate(
      widget.preloadMonthViewAmount,
      (index) => ViewRange.generateDates(
        _todayDate!,
        _todayDate!.month + (index - _monthPageController!.initialPage),
        widget.weeksInMonthViewAmount,
        startWeekDay: widget.startWeekDay,
      ),
    );

    _weekRangeList = _controller.value.generateWeeks(
      widget.preloadWeekViewAmount,
      startWeekDay: widget.startWeekDay,
    );
    _controller.addListener(() {
      _weekRangeList = _controller.value.generateWeeks(
        widget.preloadWeekViewAmount,
        startWeekDay: widget.startWeekDay,
      );
      _weekPageController!.jumpToPage(widget.preloadWeekViewAmount ~/ 2);
    });
    if (widget.startWeekDay != null && widget.startWeekDay! < 7) {
      final time = _controller.value.subtract(
        Duration(days: _controller.value.weekday - widget.startWeekDay!),
      );
      final list = List<DateTime>.generate(
        8,
        (index) => time.add(Duration(days: index * 1)),
      ).toList();
      _weekNames = List<String>.generate(7, (index) {
        return DateFormat('EEE').format(list[index]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: DefaultTextStyle.merge(
        style: theme.textTheme.bodyMedium,
        child: GestureDetector(
          onVerticalDragStart: (details) {
            _captureOffset = details.globalPosition;
          },
          onVerticalDragUpdate: (details) {
            final moveOffset = details.globalPosition;
            final diffY = moveOffset.dy - _captureOffset!.dy;
            _animationController.value =
                _animationValue + diffY / (widget.weekLineHeight * 5);
          },
          onVerticalDragEnd: (details) => _handleFinishDrag(),
          onVerticalDragCancel: _handleFinishDrag,
          child: Container(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: _monthViewCurrentPage,
                  builder: (_, value, __) {
                    return Header(
                      monthDate:
                          _monthRangeList[_monthViewCurrentPage.value].firstDay,
                      onPressed: _handleTodayPressed,
                      dateStyle: widget.headerStyle,
                      todayStyle: widget.todayStyle,
                      child: widget.showNavigationArrows
                          ? Row(
                              children: [
                                IconButton(
                                  iconSize: 16,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.arrow_back_ios),
                                  onPressed: _handlePrevPressed,
                                ),
                                IconButton(
                                  iconSize: 16,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.arrow_forward_ios),
                                  onPressed: _handleNextPressed,
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
                SizedBox(
                  height: 10,
                ),
                WeekDays(
                  buttonPrimaryColor: widget.buttonPrimaryColor,
                  style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white, fontSize: widget.weekFontSize),
                  keepLineSize: widget.keepLineSize,
                  weekNames: _weekNames != null
                      ? _weekNames!
                      : const <String>[
                          'Sun',
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat'
                        ], weekColor: widget.weekColor,
                ),
                SizedBox(
                  height: 6,
                ),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (_, __) {
                    final height = Tween<double>(
                      begin: widget.weekLineHeight,
                      end:
                          widget.weekLineHeight * widget.weeksInMonthViewAmount,
                    ).transform(_animationController.value);
                    return SizedBox(
                      height: height,
                      child: ValueListenableBuilder<DateTime>(
                        valueListenable: _controller,
                        builder: (_, selectedDate, __) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              IgnorePointer(
                                ignoring: _animationController.value == 0.0,
                                child: Opacity(
                                  opacity: Tween<double>(
                                    begin: 0.0,
                                    end: 1.0,
                                  ).evaluate(_animationController),
                                  child: PageView.builder(
                                    onPageChanged: (pageIndex) {
                                      if (widget.onHorizontalDrag != null) {
                                        widget.onHorizontalDrag!(
                                          _monthRangeList[pageIndex].firstDay,
                                        );
                                      }
                                      _monthViewCurrentPage.value = pageIndex;
                                    },
                                    controller: _monthPageController,
                                    physics: _animationController.value == 1.0
                                        ? const AlwaysScrollableScrollPhysics()
                                        : const NeverScrollableScrollPhysics(),
                                    itemCount: _monthRangeList.length,
                                    itemBuilder: (_, pageIndex) {
                                      return MonthView(
                                        buttonPrimaryColor:
                                            widget.buttonPrimaryColor,
                                        numberOfweeks: 5,
                                        innerDot: widget.innerDot,
                                        monthView: _monthRangeList[pageIndex],
                                        todayDate: _todayDate,
                                        selectedDate: selectedDate,
                                        weekLineHeight: widget.weekLineHeight,
                                        weeksAmount:
                                            widget.weeksInMonthViewAmount,
                                        onChanged: _handleDateChanged,
                                        events: widget.events,
                                        keepLineSize: widget.keepLineSize,
                                        textStyle: widget.calendarTextStyle,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              ValueListenableBuilder<int>(
                                valueListenable: _monthViewCurrentPage,
                                builder: (_, pageIndex, __) {
                                  final index = selectedDate.findWeekIndex(
                                    _monthRangeList[_monthViewCurrentPage.value]
                                        .dates,
                                  );
                                  final offset = index /
                                          (widget.weeksInMonthViewAmount - 1) *
                                          2 -
                                      1.0;
                                  return Align(
                                    alignment: Alignment(0.0, offset),
                                    child: IgnorePointer(
                                      ignoring:
                                          _animationController.value == 1.0,
                                      child: Opacity(
                                        opacity: Tween<double>(
                                          begin: 1.0,
                                          end: 0.0,
                                        ).evaluate(_animationController),
                                        child: SizedBox(
                                          height: widget.weekLineHeight,
                                          child: PageView.builder(
                                            onPageChanged: (indexPage) {
                                              final pageIndex =
                                                  _monthRangeList.indexWhere(
                                                (index) =>
                                                    index.firstDay.month ==
                                                    _weekRangeList[indexPage]
                                                        .first
                                                        .month,
                                              );

                                              if (widget.onHorizontalDrag !=
                                                  null) {
                                                widget.onHorizontalDrag!(
                                                  _monthRangeList[pageIndex]
                                                      .firstDay,
                                                );
                                              }
                                              _monthViewCurrentPage.value =
                                                  pageIndex;
                                            },
                                            controller: _weekPageController,
                                            itemCount: _weekRangeList.length,
                                            physics: _closeMonthScroll(),
                                            itemBuilder: (context, index) {
                                              return WeekView(
                                                buttonPrimaryColor:
                                                    widget.buttonPrimaryColor,
                                                dateSize:
                                                isTablet(context)?displayWidth(context) * 0.015:displayWidth(context) *
                                                        0.026,
                                                innerDot: widget.innerDot,
                                                dates: _weekRangeList[index],
                                                selectedDate: selectedDate,
                                                lineHeight:
                                                    widget.weekLineHeight,
                                                onChanged:
                                                    _handleWeekDateChanged,
                                                events: widget.events,
                                                keepLineSize:
                                                    widget.keepLineSize,
                                                textStyle:
                                                    widget.calendarTextStyle,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
                HandleBar(
                  margin: EdgeInsetsGeometry.only(top:isTablet(context)? 5:0,bottom: isTablet(context)? 5:0),
                  onPressed: () async {
                    await _animationController.forward();
                    _animationValue = 1.0;
                  }, handlerColor: widget.handlerColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _monthPageController!.dispose();
    _monthViewCurrentPage.dispose();

    if (widget.controller == null) {
      _controller.dispose();
    }

    super.dispose();
  }

  void _handleWeekDateChanged(DateTime date) {
    _handleDateChanged(date);

    _monthViewCurrentPage.value = _monthRangeList
        .lastIndexWhere((monthRange) => monthRange!.dates.contains(date));
  }

  void _handleDateChanged(DateTime date) {
    _controller.value = date;
    widget.onDateChanged!(date);
  }

  void _handleFinishDrag() async {
    _captureOffset = null;

    if (_animationController.value > 0.5) {
      await _animationController.forward();
      _animationValue = 1.0;
    } else {
      await _animationController.reverse();
      _animationValue = 0.0;
    }
  }

  void _handleTodayPressed() {
    _controller.value = DateTime.now().toZeroTime();

    _monthPageController!.jumpToPage(widget.preloadMonthViewAmount ~/ 2);
    _weekPageController!.jumpToPage(widget.preloadWeekViewAmount ~/ 2);
  }

  void _handlePrevPressed() {
    final isMonthView = _animationController.value >= 0.5;

    if (isMonthView) {
      _monthPageController?.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _weekPageController?.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleNextPressed() {
    final isMonthView = _animationController.value >= 0.5;

    if (isMonthView) {
      _monthPageController!.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _weekPageController!.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  ScrollPhysics _closeMonthScroll() {
    if ((_monthViewCurrentPage.value ==
            (widget.preloadMonthViewAmount ~/ 2) + 3 ||
        _monthViewCurrentPage.value ==
            (widget.preloadMonthViewAmount ~/ 2) - 3)) {
      return const NeverScrollableScrollPhysics();
    } else {
      return const AlwaysScrollableScrollPhysics();
    }
  }
}
