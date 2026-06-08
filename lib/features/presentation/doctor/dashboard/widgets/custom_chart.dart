import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
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
    this.monthly = false, required this.isTab,
  }) : assert(values.length == labels.length, 'Values and labels must have the same length');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final fallbackDividerColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final effectiveDividerColor = xAxisDividerColor ?? fallbackDividerColor;

    final tooltipBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A);
    final tooltipTextStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: isTab?displayWidth(context) * 0.014 :displayWidth(context) * 0.024,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
    final sideTitles = SideTitles(
      showTitles: true,
      reservedSize: 24,
      interval: 1,
      getTitlesWidget: (double value, TitleMeta meta) {
        final int index = value.round();

        if (value == index.toDouble() && index >= 0 && index < labels.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              labels[index],
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: isTab? displayWidth(context)*0.014:displayWidth(context) * 0.024,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );

    return SizedBox(
      height: chartHeight,
      child: monthly
          ? LineChart(_buildLineChartData(primaryColor, isDark, tooltipBgColor, tooltipTextStyle, sideTitles, effectiveDividerColor))
          : BarChart(_buildBarChartData(primaryColor, isDark, tooltipBgColor, tooltipTextStyle, sideTitles, effectiveDividerColor)),
    );
  }

  LineChartData _buildLineChartData(
      Color primaryColor,
      bool isDark,
      Color tooltipBgColor,
      TextStyle tooltipTextStyle,
      SideTitles sideTitles,
      Color dividerColor,
      ) {
    final double extraBounds = values.length > 1 ? 0.5 : 0.0;
    final gridLineColor = isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[300]!.withOpacity(0.6);

    return LineChartData(
      maxY: maxY,
      minY: 0,
      minX: -extraBounds,
      maxX: (values.length - 1) + extraBounds,

      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        drawHorizontalLine: true,
        horizontalInterval: maxY / 4,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: gridLineColor,
            strokeWidth: 1,
            dashArray: [4, 4],
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: gridLineColor,
            strokeWidth: 1,
            dashArray: [4, 4],
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(sideTitles: sideTitles), // Using our fixed interval side titles
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(
        show: showXAxisDivider,
        border: Border(bottom: BorderSide(color: dividerColor, width: 1.0)),
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => tooltipBgColor,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          tooltipMargin: 8,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((barSpot) {
              return LineTooltipItem(
                '${barSpot.y.toInt()} $tooltipSuffix',
                tooltipTextStyle,
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(values.length, (index) => FlSpot(index.toDouble(), values[index])),
          isCurved: true,
          curveSmoothness: 0.35,
          color: barColors?.first ?? primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: barColors?.first ?? primaryColor,
              strokeWidth: 0,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: (barColors?.first ?? primaryColor).withOpacity(0.12),
          ),
        ),
      ],
    );
  }

  BarChartData _buildBarChartData(
      Color primaryColor,
      bool isDark,
      Color tooltipBgColor,
      TextStyle tooltipTextStyle,
      SideTitles sideTitles,
      Color dividerColor,
      ) {
    final effectiveRadius = borderRadius ?? const BorderRadius.vertical(top: Radius.circular(8.0));

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(
        enabled: true,
        handleBuiltInTouches: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => tooltipBgColor,
          tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          tooltipMargin: 4,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem('${rod.toY.toInt()} $tooltipSuffix', tooltipTextStyle);
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(sideTitles: sideTitles),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(
        show: showXAxisDivider,
        border: Border(bottom: BorderSide(color: dividerColor, width: 1.0)),
      ),
      barGroups: List.generate(
        values.length,
            (index) {
          Color specificBarColor;
          if (barColors != null && index < barColors!.length) {
            specificBarColor = barColors![index];
          } else {
            final double opacity = (index % 2 == 0) ? 1.0 : (isDark ? 0.5 : 0.6);
            specificBarColor = primaryColor.withOpacity(opacity);
          }
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: values[index],
                color: specificBarColor,
                width: barWidth,
                borderRadius: effectiveRadius,
              ),
            ],
          );
        },
      ),
    );
  }
}