import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_route/app_routes.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/services/fitness/fitness_sync_service.dart';
import '../../../data/models/fitness/patient_fitness_model.dart';
import '../../../../core/shimmer_widgets/patient_fitness_shimmer.dart';

enum FitnessMetricType {
  steps,
  heartRate,
  calories,
  sleep,
  distance,
  bloodOxygen,
  weight,
}

enum FitnessPeriod {
  day,
  week,
  month,
}

class PatientFitnessDashboardScreen extends StatefulWidget {
  const PatientFitnessDashboardScreen({super.key});

  @override
  State<PatientFitnessDashboardScreen> createState() => _PatientFitnessDashboardScreenState();
}

class _PatientFitnessDashboardScreenState extends State<PatientFitnessDashboardScreen> {
  FitnessMetricType _selectedMetric = FitnessMetricType.steps;
  FitnessPeriod _selectedPeriod = FitnessPeriod.week;

  bool _isLoading = true;
  bool _isManualSyncing = false;
  PatientFitnessSummaryResponse? _summary;

  @override
  void initState() {
    super.initState();
    FitnessSyncService.instance.todayFitnessNotifier.addListener(_onTodayNotifierChanged);
    _initialLoadAndAutoSync();
  }

  @override
  void dispose() {
    FitnessSyncService.instance.todayFitnessNotifier.removeListener(_onTodayNotifierChanged);
    super.dispose();
  }

  void _onTodayNotifierChanged() {
    if (mounted) setState(() {});
  }

  /// Initial load from cache/backend first, then automatically trigger native sensor sync
  Future<void> _initialLoadAndAutoSync() async {
    await _loadSummary(showSpinner: true);

    // Auto-sync silently with Health Connect / Apple Health in background
    if (mounted) {
      await FitnessSyncService.instance.syncNow(silent: true);
      if (mounted) {
        await _loadSummary(showSpinner: false);
      }
    }
  }

  Future<void> _loadSummary({bool showSpinner = false}) async {
    if (showSpinner && mounted) {
      setState(() => _isLoading = true);
    }
    final periodStr = _selectedPeriod == FitnessPeriod.day
        ? 'day'
        : _selectedPeriod == FitnessPeriod.week
            ? 'week'
            : 'month';

    final res = await FitnessSyncService.instance.fetchSummaryFromBackend(period: periodStr);
    if (mounted) {
      setState(() {
        _summary = res;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleManualSync() async {
    setState(() => _isManualSyncing = true);
    try {
      final syncResult = await FitnessSyncService.instance.syncNow(silent: false);
      await _loadSummary(showSpinner: false);

      if (!mounted) return;
      if (syncResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(syncResult.message)),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(syncResult.message)),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Fix',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.patientConnectFitness);
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isManualSyncing = false);
      }
    }
  }

  void _handleDisconnect() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Fitness?'),
        content: Text(
          Platform.isIOS
              ? 'Are you sure you want to unlink Apple Health? You can reconnect anytime.'
              : 'Are you sure you want to unlink Health Connect? You can reconnect anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FitnessSyncService.instance.disconnectFitness();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.patientConnectFitness);
              }
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    final platformName = Platform.isIOS ? 'Apple Health' : 'Health Connect';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'My Fitness Insights',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Connected with $platformName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sync with device',
            icon: (_isManualSyncing || FitnessSyncService.instance.isSyncingNotifier.value)
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.sync_rounded, color: primaryColor),
            onPressed: (_isManualSyncing || FitnessSyncService.instance.isSyncingNotifier.value)
                ? null
                : _handleManualSync,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white70 : Colors.black87),
            onSelected: (val) {
              if (val == 'disconnect') _handleDisconnect();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'disconnect',
                child: Row(
                  children: [
                    Icon(Icons.link_off_rounded, color: Color(0xFFEF4444), size: 18),
                    SizedBox(width: 8),
                    Text('Disconnect Fitness', style: TextStyle(color: Color(0xFFEF4444))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleManualSync,
        child: _isLoading && _summary == null
            ? const PatientFitnessDashboardShimmer()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Today's Activity Overview Hero Card
                    _buildTodayHeroSummaryCard(isDark: isDark, isTab: isTab, primaryColor: primaryColor),

                    // 2. Time Range Segmented Control
                    _buildPeriodSegmentedControl(isDark: isDark, primaryColor: primaryColor),
                    const SizedBox(height: 16),

                    // 3. Horizontal Metric Selector Chips
                    _buildMetricSelectorChips(isDark: isDark),
                    const SizedBox(height: 18),

                    // 4. Main Interactive Graph Card (New Age Design)
                    _isLoading && _summary == null
                        ? FitnessGraphCardShimmer(isDark: isDark, isTab: isTab)
                        : _buildInteractiveGraphCard(isDark: isDark, isTab: isTab),
                    const SizedBox(height: 18),

                    // 5. Analytics Summary Highlights (2x2 Grid)
                    _isLoading && _summary == null
                        ? FitnessAnalyticsGridShimmer(isDark: isDark, isTab: isTab)
                        : _buildAnalyticsSummaryGrid(isDark: isDark, isTab: isTab),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  /// Segmented pill selector: Today | 7 Days | 30 Days
  Widget _buildPeriodSegmentedControl({required bool isDark, required Color primaryColor}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Today', FitnessPeriod.day, isDark, primaryColor),
          _buildPeriodButton('7 Days', FitnessPeriod.week, isDark, primaryColor),
          _buildPeriodButton('30 Days', FitnessPeriod.month, isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String title, FitnessPeriod period, bool isDark, Color primaryColor) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedPeriod != period) {
            setState(() => _selectedPeriod = period);
            _loadSummary();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Horizontal scrollable chips for selecting metrics
  Widget _buildMetricSelectorChips({required bool isDark}) {
    final metrics = [
      (FitnessMetricType.steps, 'Steps', Icons.directions_walk_rounded, const Color(0xFF3B82F6)),
      (FitnessMetricType.heartRate, 'Heart Rate', Icons.favorite_rounded, const Color(0xFFEF4444)),
      (FitnessMetricType.calories, 'Calories', Icons.local_fire_department_rounded, const Color(0xFFF97316)),
      (FitnessMetricType.sleep, 'Sleep', Icons.bedtime_rounded, const Color(0xFF8B5CF6)),
      (FitnessMetricType.distance, 'Distance', Icons.social_distance_rounded, const Color(0xFF10B981)),
      (FitnessMetricType.bloodOxygen, 'SpO2', Icons.water_drop_rounded, const Color(0xFF06B6D4)),
      (FitnessMetricType.weight, 'Weight', Icons.monitor_weight_rounded, const Color(0xFFEC4899)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: metrics.map((m) {
          final isSelected = _selectedMetric == m.$1;
          final color = m.$4;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(
                m.$3,
                size: 16,
                color: isSelected ? Colors.white : color,
              ),
              label: Text(m.$2),
              selected: isSelected,
              selectedColor: color,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              labelStyle: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  width: 1,
                ),
              ),
              onSelected: (sel) {
                if (sel) setState(() => _selectedMetric = m.$1);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Interactive Spline Chart Card with glowing gradient area fills
  Widget _buildInteractiveGraphCard({required bool isDark, required bool isTab}) {
    final points = _getNormalizedPoints();
    final metricConfig = _getMetricConfig(_selectedMetric);
    final themeColor = metricConfig.color;

    // Build fl_chart FlSpot data points
    final List<FlSpot> spots = [];
    double maxValue = 0.0;
    double latestValue = 0.0;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final val = _extractMetricValue(p, _selectedMetric);
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxValue) maxValue = val;
      if (i == points.length - 1) latestValue = val;
    }

    if (spots.isEmpty) {
      // Fallback empty point
      spots.add(const FlSpot(0, 0));
    }

    final maxY = maxValue > 0 ? (maxValue * 1.25) : 10.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Hero Stat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${metricConfig.name} Trend',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _formatMetricValue(latestValue, _selectedMetric),
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        metricConfig.unit,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: themeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(metricConfig.icon, color: themeColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Live Sensor',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: themeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // fl_chart Line Chart with smooth curve & touch tooltip
          SizedBox(
            height: isTab ? 280 : 210,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble().clamp(0.0, 30.0),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? (maxY / 4) : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                    strokeWidth: 0.8,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: spots.length > 7 ? (spots.length / 4).ceilToDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                        final rawDate = points[idx].date;
                        String label = '';
                        try {
                          final parsed = DateTime.parse(rawDate);
                          label = _selectedPeriod == FitnessPeriod.month
                              ? DateFormat('d/M').format(parsed)
                              : DateFormat.E().format(parsed);
                        } catch (_) {
                          label = rawDate;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.spotIndex;
                        final dateStr = idx < points.length ? points[idx].date : '';
                        return LineTooltipItem(
                          '$dateStr\n${_formatMetricValue(spot.y, _selectedMetric)} ${metricConfig.unit}',
                          const TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    curveSmoothness: 0.35,
                    color: themeColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 14,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3.5,
                          color: Colors.white,
                          strokeWidth: 2.2,
                          strokeColor: themeColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          themeColor.withValues(alpha: 0.38),
                          themeColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generates a continuous, padded list of points matching the exact selected period:
  /// - 1 day for 'Today'
  /// - 7 consecutive days for '7 Days'
  /// - 30 consecutive days for '30 Days'
  List<ChartFitnessPoint> _getNormalizedPoints() {
    final rawPoints = _summary?.chartPoints ?? [];
    if (_selectedPeriod == FitnessPeriod.day) {
      if (rawPoints.isNotEmpty) return rawPoints;
      final today = _summary?.today ?? FitnessSyncService.instance.todayFitnessNotifier.value;
      if (today != null) {
        final rawSpo2 = today.bloodOxygen;
        final normalizedSpo2 = (rawSpo2 > 0 && rawSpo2 <= 1.0) ? rawSpo2 * 100.0 : rawSpo2;
        return [
          ChartFitnessPoint(
            date: today.date,
            steps: today.steps,
            calories: today.calories,
            distanceMeters: today.distanceMeters,
            heartRateAvg: today.heartRateAvg,
            heartRateMin: today.heartRateMin,
            heartRateMax: today.heartRateMax,
            bloodOxygen: normalizedSpo2,
            sleepMinutes: today.sleepMinutes,
            weightKg: today.weightKg,
          ),
        ];
      }
      return [ChartFitnessPoint(date: DateTime.now().toIso8601String().split('T')[0])];
    }

    final int targetDays = _selectedPeriod == FitnessPeriod.week ? 7 : 30;
    final now = DateTime.now();

    // Map existing points by date "YYYY-MM-DD"
    final Map<String, ChartFitnessPoint> pointMap = {};
    for (final p in rawPoints) {
      final key = p.date.split('T')[0];
      final rawSpo2 = p.bloodOxygen;
      final normalizedSpo2 = (rawSpo2 > 0 && rawSpo2 <= 1.0) ? rawSpo2 * 100.0 : rawSpo2;
      pointMap[key] = ChartFitnessPoint(
        date: p.date,
        steps: p.steps,
        calories: p.calories,
        distanceMeters: p.distanceMeters,
        heartRateAvg: p.heartRateAvg,
        heartRateMin: p.heartRateMin,
        heartRateMax: p.heartRateMax,
        bloodOxygen: normalizedSpo2,
        sleepMinutes: p.sleepMinutes,
        weightKg: p.weightKg,
        hourly: p.hourly,
      );
    }

    // Ensure today's live metrics from sensor are blended if backend record has 0 steps
    final todayLive = FitnessSyncService.instance.todayFitnessNotifier.value;
    final todayStr =
        "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    if (todayLive != null &&
        (!pointMap.containsKey(todayStr) || (pointMap[todayStr]?.steps ?? 0) == 0)) {
      final rawSpo2 = todayLive.bloodOxygen;
      final normalizedSpo2 = (rawSpo2 > 0 && rawSpo2 <= 1.0) ? rawSpo2 * 100.0 : rawSpo2;
      pointMap[todayStr] = ChartFitnessPoint(
        date: todayStr,
        steps: todayLive.steps,
        calories: todayLive.calories,
        distanceMeters: todayLive.distanceMeters,
        heartRateAvg: todayLive.heartRateAvg,
        heartRateMin: todayLive.heartRateMin,
        heartRateMax: todayLive.heartRateMax,
        bloodOxygen: normalizedSpo2,
        sleepMinutes: todayLive.sleepMinutes,
        weightKg: todayLive.weightKg,
      );
    }

    final List<ChartFitnessPoint> normalized = [];
    for (int i = targetDays - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final dateStr =
          "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
      if (pointMap.containsKey(dateStr)) {
        normalized.add(pointMap[dateStr]!);
      } else {
        normalized.add(ChartFitnessPoint(date: dateStr));
      }
    }

    return normalized;
  }

  /// 4 Statistics Highlights below the chart
  Widget _buildAnalyticsSummaryGrid({required bool isDark, required bool isTab}) {
    final points = _getNormalizedPoints();

    final metricConfig = _getMetricConfig(_selectedMetric);
    final themeColor = metricConfig.color;

    // Calculate dynamic stats for selected metric
    final values = points.map((p) => _extractMetricValue(p, _selectedMetric)).toList();
    final nonZeroValues = values.where((v) => v > 0).toList();
    final total = values.isNotEmpty ? values.reduce((a, b) => a + b) : 0.0;
    final avg = nonZeroValues.isNotEmpty ? (total / nonZeroValues.length) : 0.0;
    final peak = nonZeroValues.isNotEmpty ? nonZeroValues.reduce((a, b) => a > b ? a : b) : 0.0;
    final lowest = nonZeroValues.isNotEmpty ? nonZeroValues.reduce((a, b) => a < b ? a : b) : 0.0;

    return GridView.count(
      crossAxisCount: isTab ? 4 : 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(
          title: 'Daily Average',
          value: _formatMetricValue(avg, _selectedMetric),
          unit: metricConfig.unit,
          icon: Icons.trending_up_rounded,
          color: themeColor,
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'Peak High',
          value: _formatMetricValue(peak, _selectedMetric),
          unit: metricConfig.unit,
          icon: Icons.vertical_align_top_rounded,
          color: const Color(0xFF10B981),
          isDark: isDark,
        ),
        _buildStatCard(
          title: 'Period Lowest',
          value: _formatMetricValue(lowest, _selectedMetric),
          unit: metricConfig.unit,
          icon: Icons.vertical_align_bottom_rounded,
          color: const Color(0xFF64748B),
          isDark: isDark,
        ),
        _buildStatCard(
          title: _selectedMetric == FitnessMetricType.heartRate || _selectedMetric == FitnessMetricType.bloodOxygen
              ? 'Readings'
              : 'Total Logged',
          value: _selectedMetric == FitnessMetricType.heartRate || _selectedMetric == FitnessMetricType.bloodOxygen
              ? '${values.length} days'
              : _formatMetricValue(total, _selectedMetric),
          unit: _selectedMetric == FitnessMetricType.heartRate || _selectedMetric == FitnessMetricType.bloodOxygen
              ? ''
              : metricConfig.unit,
          icon: Icons.analytics_rounded,
          color: const Color(0xFF8B5CF6),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }


  // --- Helper Methods ---

  _MetricConfig _getMetricConfig(FitnessMetricType type) {
    switch (type) {
      case FitnessMetricType.steps:
        return _MetricConfig('Steps', 'steps', Icons.directions_walk_rounded, const Color(0xFF3B82F6));
      case FitnessMetricType.heartRate:
        return _MetricConfig('Heart Rate', 'bpm', Icons.favorite_rounded, const Color(0xFFEF4444));
      case FitnessMetricType.calories:
        return _MetricConfig('Calories', 'kcal', Icons.local_fire_department_rounded, const Color(0xFFF97316));
      case FitnessMetricType.sleep:
        return _MetricConfig('Sleep', 'hours', Icons.bedtime_rounded, const Color(0xFF8B5CF6));
      case FitnessMetricType.distance:
        return _MetricConfig('Distance', 'km', Icons.social_distance_rounded, const Color(0xFF10B981));
      case FitnessMetricType.bloodOxygen:
        return _MetricConfig('Blood Oxygen', '%', Icons.water_drop_rounded, const Color(0xFF06B6D4));
      case FitnessMetricType.weight:
        return _MetricConfig('Weight', 'kg', Icons.monitor_weight_rounded, const Color(0xFFEC4899));
    }
  }

  double _extractMetricValue(ChartFitnessPoint point, FitnessMetricType type) {
    switch (type) {
      case FitnessMetricType.steps:
        return point.steps.toDouble();
      case FitnessMetricType.heartRate:
        return point.heartRateAvg;
      case FitnessMetricType.calories:
        return point.calories;
      case FitnessMetricType.sleep:
        return double.parse((point.sleepMinutes / 60.0).toStringAsFixed(1));
      case FitnessMetricType.distance:
        return double.parse((point.distanceMeters / 1000.0).toStringAsFixed(2));
      case FitnessMetricType.bloodOxygen:
        final raw = point.bloodOxygen;
        return (raw > 0 && raw <= 1.0) ? raw * 100.0 : raw;
      case FitnessMetricType.weight:
        return point.weightKg;
    }
  }

  String _formatMetricValue(double value, FitnessMetricType type) {
    if (value == 0) return '0';
    if (type == FitnessMetricType.steps) return value.toInt().toString();
    if (type == FitnessMetricType.calories) return value.toInt().toString();
    if (type == FitnessMetricType.heartRate) return value.toInt().toString();
    if (type == FitnessMetricType.bloodOxygen) {
      final v = (value > 0 && value <= 1.0) ? value * 100.0 : value;
      return '${v.toStringAsFixed(1)}%';
    }
    return value.toStringAsFixed(1);
  }

  /// Today's Activity Overview Hero Card showing key metrics at a glance
  Widget _buildTodayHeroSummaryCard({
    required bool isDark,
    required bool isTab,
    required Color primaryColor,
  }) {
    final todayBackend = _summary?.today;
    final todayLive = FitnessSyncService.instance.todayFitnessNotifier.value;
    final today = (todayLive != null && (todayLive.steps > 0 || todayLive.heartRateAvg > 0 || todayBackend == null))
        ? todayLive
        : (todayBackend ?? todayLive);

    final steps = today?.steps ?? 0;
    final calories = today?.calories ?? 0.0;
    final heartRate = today?.heartRateAvg ?? 0.0;
    final sleepStr = (today?.sleepFormatted != null && today!.sleepFormatted.isNotEmpty)
        ? today.sleepFormatted
        : '0h 0m';
    final distanceKm = ((today?.distanceMeters ?? 0.0) / 1000).toStringAsFixed(2);
    final rawSpo2 = today?.bloodOxygen ?? 0.0;
    final spo2 = (rawSpo2 > 0 && rawSpo2 <= 1.0) ? rawSpo2 * 100.0 : rawSpo2;

    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Activity",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEEE, MMM d').format(DateTime.now()),
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.20 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 15),
                    SizedBox(width: 4),
                    Text(
                      'Live Metrics',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 Main Activity Tiles (Steps, Calories, Heart, Sleep)
          GridView.count(
            crossAxisCount: isTab ? 4 : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.45,
            children: [
              // 1. Steps
              _buildTodayMetricTile(
                title: 'Steps',
                value: NumberFormat('#,###').format(steps),
                unit: 'steps',
                icon: Icons.directions_walk_rounded,
                color: const Color(0xFF3B82F6),
                isDark: isDark,
                isSelected: _selectedMetric == FitnessMetricType.steps,
                onTap: () => setState(() => _selectedMetric = FitnessMetricType.steps),
              ),
              // 2. Active Calories
              _buildTodayMetricTile(
                title: 'Active Burn',
                value: calories > 0 ? calories.toInt().toString() : '0',
                unit: 'kcal',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFF97316),
                isDark: isDark,
                isSelected: _selectedMetric == FitnessMetricType.calories,
                onTap: () => setState(() => _selectedMetric = FitnessMetricType.calories),
              ),
              // 3. Heart Rate
              _buildTodayMetricTile(
                title: 'Heart Rate',
                value: heartRate > 0 ? heartRate.toInt().toString() : '--',
                unit: 'bpm',
                icon: Icons.favorite_rounded,
                color: const Color(0xFFEF4444),
                isDark: isDark,
                isSelected: _selectedMetric == FitnessMetricType.heartRate,
                onTap: () => setState(() => _selectedMetric = FitnessMetricType.heartRate),
              ),
              // 4. Sleep
              _buildTodayMetricTile(
                title: 'Sleep',
                value: sleepStr,
                unit: '',
                icon: Icons.bedtime_rounded,
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
                isSelected: _selectedMetric == FitnessMetricType.sleep,
                onTap: () => setState(() => _selectedMetric = FitnessMetricType.sleep),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Secondary row: Distance & SpO2
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSecondaryMetricItem(
                  icon: Icons.social_distance_rounded,
                  color: const Color(0xFF10B981),
                  label: 'Distance',
                  value: '$distanceKm km',
                  isDark: isDark,
                  onTap: () => setState(() => _selectedMetric = FitnessMetricType.distance),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                _buildSecondaryMetricItem(
                  icon: Icons.water_drop_rounded,
                  color: const Color(0xFF06B6D4),
                  label: 'Blood Oxygen',
                  value: spo2 > 0 ? '${spo2.toStringAsFixed(0)}%' : '--',
                  isDark: isDark,
                  onTap: () => setState(() => _selectedMetric = FitnessMetricType.bloodOxygen),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMetricTile({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required bool isDark,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.22 : 0.10)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 18),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 3),
                      Text(
                        unit,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryMetricItem({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 10,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricConfig {
  final String name;
  final String unit;
  final IconData icon;
  final Color color;

  _MetricConfig(this.name, this.unit, this.icon, this.color);
}
