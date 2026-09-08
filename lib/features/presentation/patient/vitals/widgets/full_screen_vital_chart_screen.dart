import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../../core/constants/constants.dart';
import '../patient_vitals_tracking_screen.dart';

enum FullScreenTimeRange { oneDay, sevenDays, oneMonth, threeMonths, oneYear, all }

enum FullScreenChartStyle { splineArea, splineLine, columnBar }

class FullScreenVitalChartScreen extends StatefulWidget {
  final VitalMetricType metricType;
  final String metricTitle;
  final String metricUnit;
  final IconData metricIcon;
  final Color metricColor;
  final String normalRangeText;
  final List<Map<String, dynamic>> vitalsHistory;
  final Map<String, String> currentVitals;
  final FullScreenTimeRange initialRange;

  const FullScreenVitalChartScreen({
    super.key,
    required this.metricType,
    required this.metricTitle,
    required this.metricUnit,
    required this.metricIcon,
    required this.metricColor,
    required this.normalRangeText,
    required this.vitalsHistory,
    required this.currentVitals,
    this.initialRange = FullScreenTimeRange.all,
  });

  @override
  State<FullScreenVitalChartScreen> createState() => _FullScreenVitalChartScreenState();
}

class _FullScreenVitalChartScreenState extends State<FullScreenVitalChartScreen> {
  late FullScreenTimeRange _selectedRange;
  FullScreenChartStyle _chartStyle = FullScreenChartStyle.splineArea;
  late TrackballBehavior _trackballBehavior;
  late ZoomPanBehavior _zoomPanBehavior;

  bool _isInspectMode = false;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialRange;

    // Allow both orientations during fullscreen trading view
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initChartBehaviors();
  }

  void _initChartBehaviors() {
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: _isInspectMode ? ActivationMode.singleTap : ActivationMode.longPress,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      lineType: TrackballLineType.vertical,
      lineColor: widget.metricColor.withValues(alpha: 0.6),
      lineWidth: 1.5,
      lineDashArray: const [4, 4],
      tooltipSettings: InteractiveTooltip(
        enable: true,
        color: const Color(0xFF0F172A),
        borderColor: widget.metricColor.withValues(alpha: 0.6),
        borderWidth: 1.2,
        borderRadius: 8,
        arrowLength: 6,
        arrowWidth: 6,
        textStyle: const TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );

    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      enableDoubleTapZooming: true,
      zoomMode: ZoomMode.x,
      maximumZoomLevel: 0.02,
    );
  }

  void _toggleInspectMode() {
    setState(() {
      _isInspectMode = !_isInspectMode;
      _initChartBehaviors();
    });
  }

  void _handleZoomIn() {
    _zoomPanBehavior.zoomIn();
  }

  void _handleZoomOut() {
    _zoomPanBehavior.zoomOut();
  }

  void _handleResetZoom() {
    _zoomPanBehavior.reset();
  }

  @override
  void dispose() {
    // Reset back to portrait orientation when leaving full-screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _toggleOrientation(bool isCurrentlyLandscape) {
    if (isCurrentlyLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  DateTimeRange _getDateRange(FullScreenTimeRange range) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (range) {
      case FullScreenTimeRange.oneDay:
        return DateTimeRange(start: todayStart, end: todayEnd);
      case FullScreenTimeRange.sevenDays:
        return DateTimeRange(
          start: todayStart.subtract(const Duration(days: 7)),
          end: todayEnd,
        );
      case FullScreenTimeRange.oneMonth:
        return DateTimeRange(
          start: todayStart.subtract(const Duration(days: 30)),
          end: todayEnd,
        );
      case FullScreenTimeRange.threeMonths:
        return DateTimeRange(
          start: todayStart.subtract(const Duration(days: 90)),
          end: todayEnd,
        );
      case FullScreenTimeRange.oneYear:
        return DateTimeRange(
          start: todayStart.subtract(const Duration(days: 365)),
          end: todayEnd,
        );
      case FullScreenTimeRange.all:
        return DateTimeRange(
          start: DateTime(2000, 1, 1),
          end: todayEnd.add(const Duration(days: 365)),
        );
    }
  }

  List<VitalsDataPoint> _getFilteredPoints() {
    final range = _getDateRange(_selectedRange);
    final List<VitalsDataPoint> points = [];

    for (final entry in widget.vitalsHistory) {
      final tsStr = entry['timestamp']?.toString();
      DateTime dt = DateTime.now();
      if (tsStr != null) {
        dt = DateTime.tryParse(tsStr) ?? DateTime.now();
      }

      if (dt.isBefore(range.start) || dt.isAfter(range.end)) {
        continue;
      }

      final label = DateFormat('d MMM, hh:mm a').format(dt);

      switch (widget.metricType) {
        case VitalMetricType.all:
        case VitalMetricType.bloodPressure:
          final bpVal = (entry['bp'] ?? '').toString();
          if (bpVal.contains('/')) {
            final parts = bpVal.split('/');
            final sys = double.tryParse(parts[0].replaceAll(RegExp(r'[^\d.]'), '').trim());
            final dia = parts.length > 1
                ? double.tryParse(parts[1].replaceAll(RegExp(r'[^\d.]'), '').trim())
                : null;
            if (sys != null && sys > 0) {
              points.add(VitalsDataPoint(
                date: dt,
                primaryValue: sys,
                secondaryValue: (dia != null && dia > 0) ? dia : null,
                label: label,
              ));
            }
          }
          break;

        case VitalMetricType.heartRate:
          final pulseVal = (entry['pulse'] ?? '').toString();
          final pNum = double.tryParse(pulseVal.replaceAll(RegExp(r'[^\d.]'), '').trim());
          if (pNum != null && pNum > 0) {
            points.add(VitalsDataPoint(date: dt, primaryValue: pNum, label: label));
          }
          break;

        case VitalMetricType.spO2:
          final spVal = (entry['spO2'] ?? '').toString();
          final spNum = double.tryParse(spVal.replaceAll(RegExp(r'[^\d.]'), '').trim());
          if (spNum != null && spNum > 0) {
            points.add(VitalsDataPoint(date: dt, primaryValue: spNum, label: label));
          }
          break;

        case VitalMetricType.temperature:
          final tempVal = (entry['temp'] ?? '').toString();
          final tNum = double.tryParse(tempVal.replaceAll(RegExp(r'[^\d.]'), '').trim());
          if (tNum != null && tNum > 0) {
            points.add(VitalsDataPoint(date: dt, primaryValue: tNum, label: label));
          }
          break;

        case VitalMetricType.weight:
          final weightVal = (entry['weight'] ?? '').toString();
          final wNum = double.tryParse(weightVal.replaceAll(RegExp(r'[^\d.]'), '').trim());
          if (wNum != null && wNum > 0) {
            points.add(VitalsDataPoint(date: dt, primaryValue: wNum, label: label));
          }
          break;
      }
    }

    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  String _getCurrentValueDisplay() {
    switch (widget.metricType) {
      case VitalMetricType.all:
      case VitalMetricType.bloodPressure:
        return widget.currentVitals['bp'] ?? '--';
      case VitalMetricType.heartRate:
        return widget.currentVitals['pulse'] ?? '--';
      case VitalMetricType.spO2:
        return widget.currentVitals['spO2'] ?? '--';
      case VitalMetricType.temperature:
        return widget.currentVitals['temp'] ?? '--';
      case VitalMetricType.weight:
        return widget.currentVitals['weight'] ?? '--';
    }
  }

  String _getLatestTimestampString() {
    if (widget.vitalsHistory.isNotEmpty) {
      for (int i = widget.vitalsHistory.length - 1; i >= 0; i--) {
        final tsStr = widget.vitalsHistory[i]['timestamp']?.toString();
        if (tsStr != null) {
          final dt = DateTime.tryParse(tsStr);
          if (dt != null) {
            final now = DateTime.now();
            final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
            final timeStr = DateFormat('hh:mm a').format(dt);
            if (isToday) return 'Today at $timeStr';
            return DateFormat('d MMM, hh:mm a').format(dt);
          }
        }
      }
    }
    return 'Recent';
  }

  String _getStatusTag(String value) {
    if (value == '--') return 'PENDING';
    switch (widget.metricType) {
      case VitalMetricType.all:
      case VitalMetricType.bloodPressure:
        if (value.contains('/')) {
          final parts = value.split('/');
          final sys = double.tryParse(parts[0].trim()) ?? 0;
          if (sys < 120) return 'OPTIMAL';
          if (sys < 130) return 'NORMAL';
          if (sys < 140) return 'ELEVATED';
          return 'HIGH';
        }
        return 'NORMAL';
      case VitalMetricType.heartRate:
        final num = double.tryParse(value) ?? 72;
        if (num >= 60 && num <= 100) return 'NORMAL';
        if (num < 60) return 'LOW';
        return 'ELEVATED';
      case VitalMetricType.spO2:
        final num = double.tryParse(value) ?? 98;
        if (num >= 95) return 'OPTIMAL';
        if (num >= 90) return 'NORMAL';
        return 'LOW';
      case VitalMetricType.temperature:
        final num = double.tryParse(value) ?? 98.4;
        if (num >= 97.0 && num <= 99.0) return 'NORMAL';
        if (num > 99.0) return 'FEVER';
        return 'LOW';
      case VitalMetricType.weight:
        return 'TRACKED';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPTIMAL':
      case 'NORMAL':
      case 'TRACKED':
        return const Color(0xFF10B981); // Emerald Green
      case 'ELEVATED':
      case 'FEVER':
        return const Color(0xFFF59E0B); // Amber
      case 'HIGH':
      case 'LOW':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF94A3B8);
    }
  }

  PlotBand? _getClinicalNormalBand() {
    switch (widget.metricType) {
      case VitalMetricType.all:
      case VitalMetricType.bloodPressure:
        return PlotBand(
          start: 90,
          end: 120,
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderColor: const Color(0xFF10B981).withValues(alpha: 0.25),
          borderWidth: 1,
          dashArray: const [4, 4],
          text: 'Normal Systolic (90 - 120 mmHg)',
          textStyle: const TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 9.5,
            color: Color(0xFF10B981),
            fontWeight: FontWeight.w600,
          ),
          verticalTextAlignment: TextAnchor.end,
          horizontalTextAlignment: TextAnchor.start,
        );
      case VitalMetricType.heartRate:
        return PlotBand(
          start: 60,
          end: 100,
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderColor: const Color(0xFF10B981).withValues(alpha: 0.25),
          borderWidth: 1,
          dashArray: const [4, 4],
          text: 'Normal Pulse (60 - 100 BPM)',
          textStyle: const TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 9.5,
            color: Color(0xFF10B981),
            fontWeight: FontWeight.w600,
          ),
          verticalTextAlignment: TextAnchor.end,
          horizontalTextAlignment: TextAnchor.start,
        );
      case VitalMetricType.spO2:
        return PlotBand(
          start: 95,
          end: 100,
          color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
          borderColor: const Color(0xFF06B6D4).withValues(alpha: 0.25),
          borderWidth: 1,
          dashArray: const [4, 4],
          text: 'Healthy Oxygen (95 - 100%)',
          textStyle: const TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 9.5,
            color: Color(0xFF06B6D4),
            fontWeight: FontWeight.w600,
          ),
          verticalTextAlignment: TextAnchor.end,
          horizontalTextAlignment: TextAnchor.start,
        );
      case VitalMetricType.temperature:
        return PlotBand(
          start: 97.0,
          end: 99.0,
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderColor: const Color(0xFF10B981).withValues(alpha: 0.25),
          borderWidth: 1,
          dashArray: const [4, 4],
          text: 'Normal Temp (97 - 99°F)',
          textStyle: const TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 9.5,
            color: Color(0xFF10B981),
            fontWeight: FontWeight.w600,
          ),
          verticalTextAlignment: TextAnchor.end,
          horizontalTextAlignment: TextAnchor.start,
        );
      case VitalMetricType.weight:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // True physical widescreen detection
    final isLandscape = media.size.width > media.size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final points = _getFilteredPoints();
    final currentValue = _getCurrentValueDisplay();
    final status = _getStatusTag(currentValue);
    final statusColor = _getStatusColor(status);
    final latestTs = _getLatestTimestampString();

    // Calculate High, Low, Average
    double highVal = 0;
    double lowVal = 0;
    double avgVal = 0;

    if (points.isNotEmpty) {
      final primaries = points.map((p) => p.primaryValue).toList();
      highVal = primaries.reduce(math.max);
      lowVal = primaries.reduce(math.min);
      avgVal = primaries.reduce((a, b) => a + b) / primaries.length;
    }

    const bgDark = Color(0xFF0B0F19);
    const bgLight = Color(0xFFF8FAFC);
    const surfaceDark = Color(0xFF131B2E);
    const surfaceLight = Colors.white;
    final borderColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      },
      child: Scaffold(
        backgroundColor: isDark ? bgDark : bgLight,
        body: SafeArea(
        child: Column(
          children: [
            // ─── UPSTOX TRADING-STYLE HEADER ────────────────────────────────
            if (isLandscape)
              _buildLandscapeTopAppBar(
                isDark: isDark,
                currentValue: currentValue,
                status: status,
                statusColor: statusColor,
                high: highVal,
                low: lowVal,
                avg: avgVal,
              )
            else ...[
              _buildPortraitTopAppBar(
                isDark: isDark,
                currentValue: currentValue,
                status: status,
                statusColor: statusColor,
                latestTs: latestTs,
              ),
              _buildTimeframeBar(isDark: isDark),
            ],

            // ─── MAIN EXPANDED FULL SCREEN CHART ───────────────────────────
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 8 : 12,
                  vertical: isLandscape ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: isDark ? surfaceDark : surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.35) : const Color(0xFF64748B).withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: points.isEmpty
                            ? _buildEmptyState(isDark)
                            : _buildTradingChart(points, isDark, isLandscape),
                      ),

                      // ─── STATS HUD OVERLAY (Portrait only, in landscape it's in top bar)
                      if (!isLandscape && points.isNotEmpty)
                        Positioned(
                          top: 10,
                          left: 12,
                          child: _buildChartStatsOverlay(
                            high: highVal,
                            low: lowVal,
                            avg: avgVal,
                            isDark: isDark,
                          ),
                        ),

                      // ─── FLOATING ZOOM & INSPECT CONTROLS ─────────────────
                      Positioned(
                        right: 12,
                        top: 10,
                        child: _buildFloatingZoomControls(isDark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  /// Landscape: Single slim 42px header with all controls and scrollable pills
  Widget _buildLandscapeTopAppBar({
    required bool isDark,
    required String currentValue,
    required String status,
    required Color statusColor,
    required double high,
    required double low,
    required double avg,
  }) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          // Close button
          InkWell(
            onTap: () {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
                DeviceOrientation.portraitDown,
              ]);
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Metric Icon & Title
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: widget.metricColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Icon(widget.metricIcon, size: 13, color: widget.metricColor),
          ),
          const SizedBox(width: 6),
          Text(
            widget.metricTitle,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 8),

          // Live Value
          Text(
            currentValue,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          if (widget.metricUnit.isNotEmpty) ...[
            const SizedBox(width: 2),
            Text(
              widget.metricUnit,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: widget.metricColor,
              ),
            ),
          ],
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),

          const SizedBox(width: 10),
          Container(
            height: 18,
            width: 1,
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 8),

          // Timeframe Pills & Stats (Horizontal scrollable to prevent ANY overflow)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTimePill('1D', FullScreenTimeRange.oneDay, isDark),
                  const SizedBox(width: 4),
                  _buildTimePill('7D', FullScreenTimeRange.sevenDays, isDark),
                  const SizedBox(width: 4),
                  _buildTimePill('1M', FullScreenTimeRange.oneMonth, isDark),
                  const SizedBox(width: 4),
                  _buildTimePill('3M', FullScreenTimeRange.threeMonths, isDark),
                  const SizedBox(width: 4),
                  _buildTimePill('1Y', FullScreenTimeRange.oneYear, isDark),
                  const SizedBox(width: 4),
                  _buildTimePill('ALL', FullScreenTimeRange.all, isDark),
                  if (high > 0) ...[
                    const SizedBox(width: 10),
                    _buildOverlayStat('H', high.toStringAsFixed(1), const Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    _buildOverlayStat('L', low.toStringAsFixed(1), const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    _buildOverlayStat('AVG', avg.toStringAsFixed(1), widget.metricColor),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),
          _buildChartStyleButton(isDark),
          IconButton(
            tooltip: 'Portrait View',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.screen_rotation_rounded, size: 18, color: widget.metricColor),
            onPressed: () => _toggleOrientation(true),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// Portrait: Clean 2-row layout with flexible columns
  Widget _buildPortraitTopAppBar({
    required bool isDark,
    required String currentValue,
    required String status,
    required Color statusColor,
    required String latestTs,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Back, Title, and Actions
          Row(
            children: [
              InkWell(
                onTap: () {
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                    DeviceOrientation.portraitDown,
                  ]);
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: widget.metricColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(widget.metricIcon, size: 14, color: widget.metricColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.metricTitle,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              _buildChartStyleButton(isDark),
              IconButton(
                tooltip: 'Rotate Screen',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.screen_rotation_rounded, size: 18, color: widget.metricColor),
                onPressed: () => _toggleOrientation(false),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: Live Value, Unit, Status Badge, and Timestamp
          Row(
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      currentValue,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (widget.metricUnit.isNotEmpty) ...[
                      const SizedBox(width: 3),
                      Text(
                        widget.metricUnit,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.metricColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  latestTs,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 10,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartStyleButton(bool isDark) {
    return IconButton(
      tooltip: 'Chart Style',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: Icon(
          _chartStyle == FullScreenChartStyle.splineArea
              ? Icons.area_chart_rounded
              : _chartStyle == FullScreenChartStyle.splineLine
                  ? Icons.show_chart_rounded
                  : Icons.bar_chart_rounded,
          size: 18,
          color: isDark ? Colors.white70 : const Color(0xFF475569),
        ),
      ),
      onPressed: () {
        setState(() {
          if (_chartStyle == FullScreenChartStyle.splineArea) {
            _chartStyle = FullScreenChartStyle.splineLine;
          } else if (_chartStyle == FullScreenChartStyle.splineLine) {
            _chartStyle = FullScreenChartStyle.columnBar;
          } else {
            _chartStyle = FullScreenChartStyle.splineArea;
          }
        });
      },
    );
  }

  Widget _buildChartStatsOverlay({
    required double high,
    required double low,
    required double avg,
    required bool isDark,
  }) {
    String formatVal(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOverlayStat('H', high > 0 ? formatVal(high) : '--', const Color(0xFFEF4444)),
          const SizedBox(width: 7),
          _buildOverlayStat('L', low > 0 ? formatVal(low) : '--', const Color(0xFF10B981)),
          const SizedBox(width: 7),
          _buildOverlayStat('AVG', avg > 0 ? formatVal(avg) : '--', widget.metricColor),
        ],
      ),
    );
  }

  Widget _buildOverlayStat(String label, String val, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          val,
          style: const TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingZoomControls(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.90)
            : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Inspect / Crosshair Mode Toggle
          InkWell(
            onTap: _toggleInspectMode,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: _isInspectMode ? widget.metricColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isInspectMode ? Icons.pin_drop_rounded : Icons.pan_tool_rounded,
                size: 14,
                color: _isInspectMode
                    ? Colors.white
                    : isDark
                        ? Colors.white70
                        : const Color(0xFF475569),
              ),
            ),
          ),
          Container(
            height: 12,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
          ),
          // Zoom In Button (+)
          InkWell(
            onTap: _handleZoomIn,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Icon(
                Icons.add_rounded,
                size: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          // Zoom Out Button (-)
          InkWell(
            onTap: _handleZoomOut,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Icon(
                Icons.remove_rounded,
                size: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          // Reset Zoom Button (↺)
          InkWell(
            onTap: _handleResetZoom,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Icon(
                Icons.restart_alt_rounded,
                size: 16,
                color: widget.metricColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeBar({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTimePill('1D', FullScreenTimeRange.oneDay, isDark),
                  const SizedBox(width: 5),
                  _buildTimePill('7D', FullScreenTimeRange.sevenDays, isDark),
                  const SizedBox(width: 5),
                  _buildTimePill('1M', FullScreenTimeRange.oneMonth, isDark),
                  const SizedBox(width: 5),
                  _buildTimePill('3M', FullScreenTimeRange.threeMonths, isDark),
                  const SizedBox(width: 5),
                  _buildTimePill('1Y', FullScreenTimeRange.oneYear, isDark),
                  const SizedBox(width: 5),
                  _buildTimePill('ALL', FullScreenTimeRange.all, isDark),
                ],
              ),
            ),
          ),
          if (widget.normalRangeText.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.normalRangeText,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 9.5,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePill(String label, FullScreenTimeRange range, bool isDark) {
    final isSelected = _selectedRange == range;

    return InkWell(
      onTap: () {
        if (_selectedRange != range) {
          setState(() => _selectedRange = range);
        }
      },
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.metricColor
              : isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isSelected
                ? widget.metricColor
                : isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : isDark
                    ? Colors.white70
                    : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  NumericAxis _getYAxisForMetric(
    VitalMetricType metric,
    List<VitalsDataPoint> points,
    bool isDark,
    PlotBand? normalBand,
  ) {
    double? minVal;
    double? maxVal;
    double? interval;

    if (points.isNotEmpty) {
      double lowest = points.map((p) => math.min(p.primaryValue, p.secondaryValue ?? p.primaryValue)).reduce(math.min);
      double highest = points.map((p) => math.max(p.primaryValue, p.secondaryValue ?? p.primaryValue)).reduce(math.max);

      switch (metric) {
        case VitalMetricType.all:
        case VitalMetricType.bloodPressure:
          minVal = math.max(30.0, ((math.min(50.0, lowest - 15)) / 10).floor() * 10.0);
          maxVal = math.min(240.0, ((math.max(150.0, highest + 15)) / 10).ceil() * 10.0);
          interval = 20;
          break;
        case VitalMetricType.heartRate:
          minVal = math.max(30.0, ((math.min(50.0, lowest - 10)) / 10).floor() * 10.0);
          maxVal = math.min(220.0, ((math.max(120.0, highest + 10)) / 10).ceil() * 10.0);
          interval = 20;
          break;
        case VitalMetricType.spO2:
          minVal = math.max(75.0, ((math.min(90.0, lowest - 2)) / 5).floor() * 5.0);
          maxVal = 102;
          interval = 5;
          break;
        case VitalMetricType.temperature:
          minVal = math.max(90.0, (lowest - 1.0).floorToDouble());
          maxVal = math.min(106.0, (highest + 1.0).ceilToDouble());
          interval = 1.0;
          break;
        case VitalMetricType.weight:
          minVal = math.max(0.0, (lowest - 5.0).floorToDouble());
          maxVal = (highest + 5.0).ceilToDouble();
          interval = ((maxVal - minVal) / 5).ceilToDouble().clamp(1.0, 20.0);
          break;
      }
    }

    return NumericAxis(
      minimum: minVal,
      maximum: maxVal,
      interval: interval,
      axisLine: const AxisLine(width: 0),
      majorTickLines: const MajorTickLines(size: 0),
      majorGridLines: MajorGridLines(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
        dashArray: const [4, 4],
      ),
      labelStyle: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: 9.5,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
      ),
      plotBands: normalBand != null ? [normalBand] : const [],
    );
  }

  Widget _buildTradingChart(List<VitalsDataPoint> points, bool isDark, bool isLandscape) {
    final normalBand = _getClinicalNormalBand();

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.fromLTRB(
        isLandscape ? 6 : 8,
        isLandscape ? 6 : 34,
        isLandscape ? 6 : 8,
        isLandscape ? 6 : 8,
      ),
      trackballBehavior: _trackballBehavior,
      zoomPanBehavior: _zoomPanBehavior,
      legend: widget.metricType == VitalMetricType.bloodPressure
          ? Legend(
              isVisible: true,
              position: LegendPosition.bottom,
              alignment: ChartAlignment.center,
              textStyle: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 10,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            )
          : const Legend(isVisible: false),
      primaryXAxis: DateTimeAxis(
        majorGridLines: MajorGridLines(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF1F5F9),
          dashArray: const [4, 4],
        ),
        axisLine: AxisLine(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        labelStyle: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 9.5,
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        ),
        dateFormat: DateFormat('d MMM'),
        edgeLabelPlacement: EdgeLabelPlacement.shift,
      ),
      primaryYAxis: _getYAxisForMetric(widget.metricType, points, isDark, normalBand),
      series: _buildSeriesList(points, isDark),
    );
  }

  List<CartesianSeries> _buildSeriesList(List<VitalsDataPoint> points, bool isDark) {
    final color = widget.metricColor;

    if (widget.metricType == VitalMetricType.bloodPressure) {
      if (_chartStyle == FullScreenChartStyle.columnBar) {
        return <CartesianSeries>[
          ColumnSeries<VitalsDataPoint, DateTime>(
            name: 'Systolic',
            dataSource: points,
            xValueMapper: (d, _) => d.date,
            yValueMapper: (d, _) => d.primaryValue,
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          ColumnSeries<VitalsDataPoint, DateTime>(
            name: 'Diastolic',
            dataSource: points,
            xValueMapper: (d, _) => d.date,
            yValueMapper: (d, _) => d.secondaryValue ?? 0,
            color: const Color(0xFF06B6D4),
            borderRadius: BorderRadius.circular(4),
          ),
        ];
      }

      return <CartesianSeries>[
        SplineAreaSeries<VitalsDataPoint, DateTime>(
          splineType: SplineType.monotonic,
          name: 'Systolic (mmHg)',
          dataSource: points,
          xValueMapper: (d, _) => d.date,
          yValueMapper: (d, _) => d.primaryValue,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.30),
              color.withValues(alpha: 0.01),
            ],
          ),
          borderColor: color,
          borderWidth: 2.5,
          markerSettings: MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            color: color,
            borderColor: Colors.white,
            borderWidth: 2,
            width: 6,
            height: 6,
          ),
        ),
        SplineSeries<VitalsDataPoint, DateTime>(
          splineType: SplineType.monotonic,
          name: 'Diastolic (mmHg)',
          dataSource: points,
          xValueMapper: (d, _) => d.date,
          yValueMapper: (d, _) => d.secondaryValue,
          color: const Color(0xFF06B6D4),
          width: 2.2,
          dashArray: const [5, 5],
          markerSettings: const MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            color: Color(0xFF06B6D4),
            borderColor: Colors.white,
            borderWidth: 1.5,
            width: 5,
            height: 5,
          ),
        ),
      ];
    }

    if (_chartStyle == FullScreenChartStyle.columnBar) {
      return <CartesianSeries>[
        ColumnSeries<VitalsDataPoint, DateTime>(
          name: widget.metricTitle,
          dataSource: points,
          xValueMapper: (d, _) => d.date,
          yValueMapper: (d, _) => d.primaryValue,
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ];
    }

    if (_chartStyle == FullScreenChartStyle.splineLine) {
      return <CartesianSeries>[
        SplineSeries<VitalsDataPoint, DateTime>(
          splineType: SplineType.monotonic,
          name: widget.metricTitle,
          dataSource: points,
          xValueMapper: (d, _) => d.date,
          yValueMapper: (d, _) => d.primaryValue,
          color: color,
          width: 2.8,
          markerSettings: MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            color: color,
            borderColor: Colors.white,
            borderWidth: 2,
            width: 6,
            height: 6,
          ),
        ),
      ];
    }

    return <CartesianSeries>[
      SplineAreaSeries<VitalsDataPoint, DateTime>(
        splineType: SplineType.monotonic,
        name: widget.metricTitle,
        dataSource: points,
        xValueMapper: (d, _) => d.date,
        yValueMapper: (d, _) => d.primaryValue,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.0),
          ],
        ),
        borderColor: color,
        borderWidth: 2.6,
        markerSettings: MarkerSettings(
          isVisible: true,
          shape: DataMarkerType.circle,
          color: color,
          borderColor: Colors.white,
          borderWidth: 2,
          width: 6,
          height: 6,
        ),
      ),
    ];
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.query_builder_rounded, size: 36, color: widget.metricColor.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          Text(
            'No readings in this timeframe',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select "ALL" or record a new reading.',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 11,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
