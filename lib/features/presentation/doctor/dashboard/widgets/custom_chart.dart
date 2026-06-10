import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';

class CustomBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double maxY;
  final double chartHeight;
  final List<Color>? barColors;
  final double barWidth;
  final BorderRadius? borderRadius;
  final String tooltipSuffix;
  final String? fontFamily;
  final bool showXAxisDivider;
  final Color? xAxisDividerColor;
  final bool monthly;
  final bool isTab;

  const CustomBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.maxY = 75,
    this.chartHeight = 100,
    this.barColors,
    this.barWidth = 10,
    this.borderRadius,
    this.tooltipSuffix = 'Patients',
    this.fontFamily,
    this.showXAxisDivider = true,
    this.xAxisDividerColor,
    this.monthly = false,
    required this.isTab,
  }) : assert(values.length == labels.length, 'Values and labels must have the same length');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    final effectiveDividerColor = xAxisDividerColor ?? theme.dividerColor;

    final tooltipBgColor = isDark ? theme.cardColor : Colors.grey[900]!;
    final tooltipTextColor = isDark ? theme.textTheme.bodyLarge?.color : Colors.white;

    final tooltipTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: isTab ? displayWidth(context) * 0.014 : displayWidth(context) * 0.024,
      fontWeight: FontWeight.w600,
      color: tooltipTextColor,
    );

    final xAxisTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: isTab ? displayWidth(context) * 0.012 : displayWidth(context) * 0.020,
      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
    );

    // Dynamic style for the values displayed on top of the graph peaks
    final dataLabelTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: isTab ? displayWidth(context) * 0.011 : displayWidth(context) * 0.025,
      fontWeight: FontWeight.bold,
      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
    );

    final List<_ChartDataPoint> chartData = List.generate(
      values.length,
          (index) => _ChartDataPoint(xLabel: labels[index], yValue: values[index], index: index),
    );

    final tooltipBehavior = TooltipBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      canShowMarker: false,
      color: tooltipBgColor,
      textStyle: tooltipTextStyle,
      header: '',
      format: 'point.y $tooltipSuffix',
    );

    return SizedBox(
      height: chartHeight,
      child: SfCartesianChart(
        margin: EdgeInsets.only(
          left: isTab ? 12.0 : 8.0,
          right: isTab ? 12.0 : 8.0,
          bottom: 4.0,
          top: 16.0,
        ),
        plotAreaBorderWidth: 0,
        tooltipBehavior: tooltipBehavior,

        primaryXAxis: CategoryAxis(
          labelStyle: xAxisTextStyle,
          interval: 1,
          edgeLabelPlacement: EdgeLabelPlacement.shift,
          axisLine: AxisLine(
            width: showXAxisDivider ? 1.0 : 0.0,
            color: effectiveDividerColor,
          ),
          majorTickLines: const MajorTickLines(size: 0),
          majorGridLines: MajorGridLines(
            width: monthly ? 1.0 : 0.0,
            color: theme.dividerColor.withOpacity(isDark ? 0.15 : 0.4),
            dashArray: const [4, 4],
          ),
        ),

        primaryYAxis: NumericAxis(
          maximum: maxY,
          minimum: 0,
          isVisible: false,
          majorGridLines: MajorGridLines(
            width: monthly ? 1.0 : 0.0,
            color: theme.dividerColor.withOpacity(isDark ? 0.15 : 0.4),
            dashArray: const [4, 4],
          ),
        ),

        series: monthly
            ? _buildSplineSeries(chartData, primaryColor, dataLabelTextStyle)
            : _buildColumnSeries(chartData, primaryColor, isDark, dataLabelTextStyle),
      ),
    );
  }

  List<CartesianSeries<_ChartDataPoint, String>> _buildSplineSeries(
      List<_ChartDataPoint> data,
      Color primaryColor,
      TextStyle dataLabelTextStyle,
      ) {
    final lineColor = barColors?.first ?? primaryColor;

    return [
      SplineAreaSeries<_ChartDataPoint, String>(
        dataSource: data,
        xValueMapper: (_ChartDataPoint point, _) => point.xLabel,
        yValueMapper: (_ChartDataPoint point, _) => point.yValue,
        color: lineColor.withOpacity(0.12),
        animationDuration: 400,
        enableTooltip: false,
      ),
      SplineSeries<_ChartDataPoint, String>(
        dataSource: data,
        xValueMapper: (_ChartDataPoint point, _) => point.xLabel,
        yValueMapper: (_ChartDataPoint point, _) => point.yValue,
        color: lineColor,
        width: 3,
        enableTooltip: true,
        dataLabelSettings: DataLabelSettings(
          isVisible: true,
          textStyle: dataLabelTextStyle,
          labelAlignment: ChartDataLabelAlignment.top,
          useSeriesColor: false,
        ),
        markerSettings: MarkerSettings(
          isVisible: true,
          height: isTab ? 7 : 5,
          width: isTab ? 7 : 5,
          shape: DataMarkerType.circle,
          color: lineColor,
          borderWidth: 0,
        ),
        animationDuration: 400,
      ),
    ];
  }

  List<CartesianSeries<_ChartDataPoint, String>> _buildColumnSeries(
      List<_ChartDataPoint> data,
      Color primaryColor,
      bool isDark,
      TextStyle dataLabelTextStyle,
      ) {
    final effectiveRadius = borderRadius ?? const BorderRadius.vertical(top: Radius.circular(8.0));

    return [
      ColumnSeries<_ChartDataPoint, String>(
        dataSource: data,
        xValueMapper: (_ChartDataPoint point, _) => point.xLabel,
        yValueMapper: (_ChartDataPoint point, _) => point.yValue,
        width: barWidth > 1 ? (barWidth / 50).clamp(0.1, 1.0) : barWidth,
        borderRadius: effectiveRadius,
        animationDuration: 400,
        enableTooltip: true,
        dataLabelSettings: const DataLabelSettings(
          isVisible: false,
        ),
        pointColorMapper: (_ChartDataPoint point, _) {
          if (barColors != null && point.index < barColors!.length) {
            return barColors![point.index];
          } else {
            final double opacity = (point.index % 2 == 0) ? 1.0 : (isDark ? 0.45 : 0.6);
            return primaryColor.withOpacity(opacity);
          }
        },
      ),
    ];
  }
}

class _ChartDataPoint {
  final String xLabel;
  final double yValue;
  final int index;

  _ChartDataPoint({required this.xLabel, required this.yValue, required this.index});
}