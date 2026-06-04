import 'package:flutter/material.dart';
import 'height_scaler.dart';

class VerticalHeightRuler extends StatefulWidget {
  final double currentValue;
  final ValueChanged<double> onChanged;
  final String unit;
  final Color indicatorColor;

  const VerticalHeightRuler({
    super.key,
    required this.currentValue,
    required this.onChanged,
    this.unit = 'cm',
    this.indicatorColor = const Color(0xFF005696),
  });

  @override
  State<VerticalHeightRuler> createState() => _VerticalHeightRulerState();
}

class _VerticalHeightRulerState extends State<VerticalHeightRuler> {
  late FixedExtentScrollController _scrollController;

  double get minValue => widget.unit == 'in' ? 20.0 : 50.0;
  double get maxValue => widget.unit == 'in' ? 100.0 : 250.0;

  double get step => widget.unit == 'in' ? 0.1 : 1.0;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    int initialItem = ((widget.currentValue - minValue) / step).round();
    _scrollController = FixedExtentScrollController(initialItem: initialItem);
  }

  @override
  void didUpdateWidget(VerticalHeightRuler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unit != widget.unit) {
      _scrollController.dispose();
      _initController();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int itemCount = ((maxValue - minValue) / step).round() + 1;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        ListWheelScrollView.useDelegate(
          controller: _scrollController,
          itemExtent: 15,
          perspective: 0.003,
          diameterRatio: 1.5,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            double val = minValue + (index * step);
            widget.onChanged(double.parse(val.toStringAsFixed(1)));
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (context, index) {
              double val = minValue + (index * step);
              bool isMajor;
              if (widget.unit == 'in') {
                isMajor = (val * 10).round() % 10 == 0;
              } else {
                isMajor = val.round() % 10 == 0;
              }

              return CustomPaint(
                size: const Size(100, 20),
                painter: VerticalScalePainter(
                  value: val,
                  isMajor: isMajor,
                  context: context,
                  unit: widget.unit,
                ),
              );
            },
          ),
        ),

        Positioned(
          left: 2,
          child: Container(
            width: 45,
            height: 4,
            decoration: BoxDecoration(
              color: widget.indicatorColor,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}