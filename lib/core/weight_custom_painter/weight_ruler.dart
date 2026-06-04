import 'package:flutter/material.dart';
import 'package:yiraclinics/core/weight_custom_painter/weight_custom_painter.dart';
import '../common_size_helpers/common_size_helpers.dart';

class WeightScaleRuler extends StatefulWidget {
  final double currentValue;
  final String unit;
  final Color indicatorColor;
  final ValueChanged<double> onChanged;

  const WeightScaleRuler({
    super.key,
    required this.currentValue,
    required this.unit,
    required this.indicatorColor,
    required this.onChanged,
  });

  @override
  State<WeightScaleRuler> createState() => _WeightScaleRulerState();
}

class _WeightScaleRulerState extends State<WeightScaleRuler> {
  late ScrollController _scrollController;
  final double _step = 0.1;
  final double _minWeight = 0.0;
  final double _maxWeight = 500.0;

  @override
  void initState() {
    super.initState();
    double tickWidth = 12.0;
    _scrollController = ScrollController(
      initialScrollOffset: (widget.currentValue / _step) * tickWidth,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double tickWidth = isTablet(context) ? 14.0 : 12.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 100,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                double offset = _scrollController.offset;
                double weight = (offset / tickWidth) * _step;

                widget.onChanged(weight.clamp(_minWeight, _maxWeight));
              }
              return true;
            },
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width / 2.16 - (tickWidth / 2),
              ),
              itemCount: ((_maxWeight - _minWeight) / _step).toInt() + 1,
              itemBuilder: (context, index) {
                double value = index * _step;
                return SizedBox(
                  width: tickWidth,
                  child: CustomPaint(
                    painter: ScaleTickPainter(
                      value: value,
                      isMajor: (index % 10 == 0),
                      context: context,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // The Central Needle Indicator
        Container(
          width: 3,
          height: 70,
          decoration: BoxDecoration(
            color: widget.indicatorColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}