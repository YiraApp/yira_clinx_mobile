import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';
import '../widgets/update_vitals_sheet.dart';

enum VitalsTimeRange { all, today, sevenDays, dateRange }

enum VitalMetricType { all, bloodPressure, heartRate, spO2, temperature, weight }

class VitalsDataPoint {
  final DateTime date;
  final double primaryValue;
  final double? secondaryValue; // Diastolic for BP
  final String label;

  const VitalsDataPoint({
    required this.date,
    required this.primaryValue,
    this.secondaryValue,
    required this.label,
  });
}

class PatientVitalsTrackingScreen extends StatefulWidget {
  final VitalMetricType initialMetric;

  const PatientVitalsTrackingScreen({
    super.key,
    this.initialMetric = VitalMetricType.all,
  });

  @override
  State<PatientVitalsTrackingScreen> createState() => _PatientVitalsTrackingScreenState();
}

class _PatientVitalsTrackingScreenState extends State<PatientVitalsTrackingScreen> {
  late VitalMetricType _selectedMetric;
  VitalsTimeRange _timeRange = VitalsTimeRange.all;
  DateTimeRange? _customDateRange;

  bool _isLoading = false;

  Map<String, String> _currentVitals = {};
  List<Map<String, dynamic>> _vitalsHistory = [];

  static const Color _primaryBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _selectedMetric = widget.initialMetric;
    _loadStoredVitals();
  }

  Future<void> _loadStoredVitals() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';
      if (userId.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final savedStr = prefs.getString('patient_vitals_$userId');
        if (savedStr != null) {
          final Map<String, dynamic> decoded = jsonDecode(savedStr);
          final Map<String, String> loaded = {};
          decoded.forEach((key, value) {
            if (value != null && value.toString().trim().isNotEmpty && value.toString().trim() != '--') {
              loaded[key] = value.toString();
            }
          });
          _currentVitals = loaded;
        }

        final historyStr = prefs.getString('patient_vitals_history_$userId');
        if (historyStr != null) {
          final List<dynamic> decodedList = jsonDecode(historyStr);
          _vitalsHistory = decodedList.map((e) => Map<String, dynamic>.from(e)).toList();
        } else if (_currentVitals.isNotEmpty) {
          final entry = Map<String, dynamic>.from(_currentVitals);
          entry['timestamp'] = DateTime.now().toIso8601String();
          _vitalsHistory = [entry];
          await prefs.setString('patient_vitals_history_$userId', jsonEncode(_vitalsHistory));
        }
      }
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 120));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _switchMetric(VitalMetricType metric) {
    if (_selectedMetric == metric) return;
    setState(() {
      _selectedMetric = metric;
      _isLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _switchTimeRange(VitalsTimeRange range) {
    if (_timeRange == range && range != VitalsTimeRange.dateRange) return;
    if (range == VitalsTimeRange.dateRange) {
      _pickCustomDateRange();
      return;
    }
    setState(() {
      _timeRange = range;
      _isLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 14)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: _primaryBlue,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: _primaryBlue,
                    onPrimary: Colors.white,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _timeRange = VitalsTimeRange.dateRange;
        _isLoading = true;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    }
  }

  void _openUpdateVitals() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UpdateVitalsSheet(
        currentVitals: _currentVitals,
        onSave: (updated) {
          setState(() {
            _currentVitals = updated;
          });
        },
      ),
    );

    if (result != null) {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';

      final now = DateTime.now();
      final newEntry = Map<String, dynamic>.from(result);
      newEntry['timestamp'] = now.toIso8601String();

      setState(() {
        _currentVitals = result;
        _vitalsHistory.add(newEntry);
      });

      if (userId.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('patient_vitals_$userId', jsonEncode(result));
        await prefs.setString('patient_vitals_history_$userId', jsonEncode(_vitalsHistory));
      }
    }
  }

  DateTimeRange _getActiveDateRange() {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final todayStart = DateTime(now.year, now.month, now.day);
    switch (_timeRange) {
      case VitalsTimeRange.all:
        return DateTimeRange(
          start: DateTime(2000, 1, 1),
          end: todayEnd.add(const Duration(days: 365)),
        );
      case VitalsTimeRange.today:
        return DateTimeRange(
          start: todayStart,
          end: todayEnd,
        );
      case VitalsTimeRange.sevenDays:
        return DateTimeRange(
          start: todayStart.subtract(const Duration(days: 6)),
          end: todayEnd,
        );
      case VitalsTimeRange.dateRange:
        return _customDateRange != null
            ? DateTimeRange(
                start: DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day),
                end: DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59),
              )
            : DateTimeRange(
                start: todayStart.subtract(const Duration(days: 14)),
                end: todayEnd,
              );
    }
  }

  List<VitalsDataPoint> _getRealDataPoints(VitalMetricType metric, DateTimeRange range) {
    final List<VitalsDataPoint> points = [];

    for (final entry in _vitalsHistory) {
      final tsStr = entry['timestamp']?.toString();
      DateTime dt = DateTime.now();
      if (tsStr != null) {
        dt = DateTime.tryParse(tsStr) ?? DateTime.now();
      }

      if (dt.isBefore(range.start) || dt.isAfter(range.end)) {
        continue;
      }

      final label = DateFormat('MMM d, hh:mm a').format(dt);

      switch (metric) {
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
            points.add(VitalsDataPoint(
              date: dt,
              primaryValue: pNum,
              label: label,
            ));
          }
          break;

        case VitalMetricType.spO2:
          final spVal = (entry['spO2'] ?? '').toString();
          final spNum = double.tryParse(spVal.replaceAll(RegExp(r'[^\d.]'), '').trim());
          if (spNum != null && spNum > 0) {
            points.add(VitalsDataPoint(
              date: dt,
              primaryValue: spNum,
              label: label,
            ));
          }
          break;

        case VitalMetricType.temperature:
          final tempVal = (entry['temp'] ?? '').toString();
          final tNum = double.tryParse(tempVal.replaceAll(RegExp(r'[^\d.]'), '').trim());
          if (tNum != null && tNum > 0) {
            points.add(VitalsDataPoint(
              date: dt,
              primaryValue: tNum,
              label: label,
            ));
          }
          break;

        case VitalMetricType.weight:
          final weightVal = (entry['weight'] ?? '').toString();
          final wNum = double.tryParse(weightVal.replaceAll(RegExp(r'[^\d.]'), '').trim());
          if (wNum != null && wNum > 0) {
            points.add(VitalsDataPoint(
              date: dt,
              primaryValue: wNum,
              label: label,
            ));
          }
          break;
      }
    }

    points.sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  String _getMetricTitle(VitalMetricType metric) {
    switch (metric) {
      case VitalMetricType.all:
        return 'All Vitals';
      case VitalMetricType.bloodPressure:
        return 'Blood Pressure';
      case VitalMetricType.heartRate:
        return 'Heart Rate';
      case VitalMetricType.spO2:
        return 'Oxygen (SpO2)';
      case VitalMetricType.temperature:
        return 'Temperature';
      case VitalMetricType.weight:
        return 'Body Weight';
    }
  }

  String _getMetricUnit(VitalMetricType metric) {
    switch (metric) {
      case VitalMetricType.all:
        return '';
      case VitalMetricType.bloodPressure:
        return 'mmHg';
      case VitalMetricType.heartRate:
        return 'BPM';
      case VitalMetricType.spO2:
        return '%';
      case VitalMetricType.temperature:
        return '°F';
      case VitalMetricType.weight:
        return 'kg';
    }
  }

  IconData _getMetricIcon(VitalMetricType metric) {
    switch (metric) {
      case VitalMetricType.all:
        return Icons.dashboard_customize_outlined;
      case VitalMetricType.bloodPressure:
        return Icons.favorite_outline_rounded;
      case VitalMetricType.heartRate:
        return Icons.monitor_heart_outlined;
      case VitalMetricType.spO2:
        return Icons.air_rounded;
      case VitalMetricType.temperature:
        return Icons.thermostat_outlined;
      case VitalMetricType.weight:
        return Icons.scale_outlined;
    }
  }

  String _getMetricNormalRange(VitalMetricType metric) {
    switch (metric) {
      case VitalMetricType.all:
        return 'Clinical Overview';
      case VitalMetricType.bloodPressure:
        return 'Normal: 90/60 - 120/80 mmHg';
      case VitalMetricType.heartRate:
        return 'Normal: 60 - 100 BPM';
      case VitalMetricType.spO2:
        return 'Normal: 95% - 100%';
      case VitalMetricType.temperature:
        return 'Normal: 97.0°F - 99.0°F';
      case VitalMetricType.weight:
        return 'Target BMI: 18.5 - 24.9';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);

    final activeRange = _getActiveDateRange();
    final dataPoints = _getRealDataPoints(_selectedMetric, activeRange);
    final metricUnit = _getMetricUnit(_selectedMetric);
    final metricTitle = _getMetricTitle(_selectedMetric);
    final metricIcon = _getMetricIcon(_selectedMetric);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vitals Tracking',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Record Reading',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_note_rounded, size: 18, color: _primaryBlue),
            ),
            onPressed: _openUpdateVitals,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openUpdateVitals,
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          _selectedMetric == VitalMetricType.all ? 'Record Vitals' : 'Record $metricTitle',
          style: const TextStyle(
            fontFamily: appPoppinFont,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: screenHorizontalSpacePadding,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Metric Selection Horizontal Chips (with ALL option first)
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildMetricChip(
                      type: VitalMetricType.all,
                      label: 'All Vitals',
                      icon: Icons.dashboard_customize_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricChip(
                      type: VitalMetricType.bloodPressure,
                      label: 'Blood Pressure',
                      icon: Icons.favorite_outline_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricChip(
                      type: VitalMetricType.heartRate,
                      label: 'Heart Rate',
                      icon: Icons.monitor_heart_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricChip(
                      type: VitalMetricType.spO2,
                      label: 'SpO2',
                      icon: Icons.air_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricChip(
                      type: VitalMetricType.temperature,
                      label: 'Temperature',
                      icon: Icons.thermostat_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricChip(
                      type: VitalMetricType.weight,
                      label: 'Weight',
                      icon: Icons.scale_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Time Range Selector: All / Today / 7 Days / Custom Date Range
              Row(
                children: [
                  _buildTimeRangePill(
                    label: 'All',
                    range: VitalsTimeRange.all,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildTimeRangePill(
                    label: 'Today',
                    range: VitalsTimeRange.today,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildTimeRangePill(
                    label: '7 Days',
                    range: VitalsTimeRange.sevenDays,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildTimeRangePill(
                    label: _timeRange == VitalsTimeRange.dateRange && _customDateRange != null
                        ? '${DateFormat('d MMM').format(_customDateRange!.start)} - ${DateFormat('d MMM').format(_customDateRange!.end)}'
                        : 'Custom',
                    range: VitalsTimeRange.dateRange,
                    isDark: isDark,
                    icon: Icons.date_range_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_isLoading) ...[
                _buildShimmerCard(isDark, height: 220),
                const SizedBox(height: 14),
                _buildShimmerCard(isDark, height: 90),
              ] else if (_vitalsHistory.isEmpty && _currentVitals.isEmpty) ...[
                // Empty State
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF64748B).withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(metricIcon, color: _primaryBlue, size: 30),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No $metricTitle Recorded',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 17 : 15.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Record your $metricTitle reading to view clinical trends and statistics.',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 13 : 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: _openUpdateVitals,
                        icon: const Icon(Icons.add_chart_rounded, size: 16),
                        label: const Text(
                          'Record Vitals',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else if (_selectedMetric == VitalMetricType.all) ...[
                // ─── ALL VITALS DASHBOARD OVERVIEW ──────────────────────────
                _buildAllVitalsOverviewCards(isDark, isTab),
                const SizedBox(height: 14),
                _buildHistoryLogs(isDark, isTab),
              ] else ...[
                // ─── INDIVIDUAL METRIC FOCUSED VIEW ──────────────────────────
                if (dataPoints.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(metricIcon, color: _primaryBlue, size: 28),
                        const SizedBox(height: 10),
                        Text(
                          'No $metricTitle readings in this time range',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try selecting "All" or recording a new reading.',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  _buildMetricSummaryCard(
                    dataPoints: dataPoints,
                    metric: _selectedMetric,
                    unit: metricUnit,
                    isDark: isDark,
                    isTab: isTab,
                  ),
                  const SizedBox(height: 12),

                  // Chart Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF64748B).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(metricIcon, color: _primaryBlue, size: 17),
                                const SizedBox(width: 8),
                                Text(
                                  '$metricTitle Trend',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: isTab ? 15.5 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${dataPoints.length} reading${dataPoints.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: isTab ? 240 : 200,
                          child: _buildSyncfusionChart(dataPoints, isDark, metricUnit),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _buildHistoryLogs(isDark, isTab),
              ],
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllVitalsOverviewCards(bool isDark, bool isTab) {
    final bp = _currentVitals['bp'] ?? '--';
    final pulse = _currentVitals['pulse'] ?? '--';
    final spO2 = _currentVitals['spO2'] ?? '--';
    final temp = _currentVitals['temp'] ?? '--';
    final weight = _currentVitals['weight'] ?? '--';
    final height = _currentVitals['height'] ?? '--';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildOverviewTile(
                title: 'Blood Pressure',
                value: bp,
                unit: bp != '--' ? 'mmHg' : '',
                icon: Icons.favorite_outline_rounded,
                targetMetric: VitalMetricType.bloodPressure,
                status: bp != '--' ? 'Normal' : 'Pending',
                isDark: isDark,
                isTab: isTab,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOverviewTile(
                title: 'Heart Rate',
                value: pulse,
                unit: pulse != '--' ? 'BPM' : '',
                icon: Icons.monitor_heart_outlined,
                targetMetric: VitalMetricType.heartRate,
                status: pulse != '--' ? 'Normal' : 'Pending',
                isDark: isDark,
                isTab: isTab,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOverviewTile(
                title: 'Oxygen (SpO2)',
                value: spO2,
                unit: spO2 != '--' ? '%' : '',
                icon: Icons.air_rounded,
                targetMetric: VitalMetricType.spO2,
                status: spO2 != '--' ? 'Optimal' : 'Pending',
                isDark: isDark,
                isTab: isTab,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOverviewTile(
                title: 'Temperature',
                value: temp,
                unit: temp != '--' ? '°F' : '',
                icon: Icons.thermostat_outlined,
                targetMetric: VitalMetricType.temperature,
                status: temp != '--' ? 'Normal' : 'Pending',
                isDark: isDark,
                isTab: isTab,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildOverviewTile(
                title: 'Weight',
                value: weight,
                unit: weight != '--' ? 'kg' : '',
                icon: Icons.scale_outlined,
                targetMetric: VitalMetricType.weight,
                status: weight != '--' ? 'Tracked' : 'Pending',
                isDark: isDark,
                isTab: isTab,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildOverviewTile(
                title: 'Height',
                value: height,
                unit: height != '--' ? 'cm' : '',
                icon: Icons.height_rounded,
                targetMetric: VitalMetricType.weight,
                status: height != '--' ? 'Tracked' : 'Pending',
                isDark: isDark,
                isTab: isTab,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewTile({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required VitalMetricType targetMetric,
    required String status,
    required bool isDark,
    required bool isTab,
  }) {
    final hasVal = value != '--';

    return InkWell(
      onTap: () => _switchMetric(targetMetric),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isTab ? 16 : 13),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF64748B).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 15, color: _primaryBlue),
                    const SizedBox(width: 5),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
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
                    fontSize: isTab ? 20 : 17,
                    fontWeight: FontWeight.bold,
                    color: hasVal ? (isDark ? Colors.white : const Color(0xFF0F172A)) : (isDark ? Colors.white38 : Colors.grey[400]),
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 3),
                  Text(
                    unit,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required VitalMetricType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedMetric == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _switchMetric(type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryBlue
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? _primaryBlue
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangePill({
    required String label,
    required VitalsTimeRange range,
    required bool isDark,
    IconData? icon,
  }) {
    final isSelected = _timeRange == range;

    return Expanded(
      child: InkWell(
        onTap: () => _switchTimeRange(range),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? _primaryBlue
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? _primaryBlue
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: 0.8,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 12,
                  color: isSelected ? Colors.white : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 3),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricSummaryCard({
    required List<VitalsDataPoint> dataPoints,
    required VitalMetricType metric,
    required String unit,
    required bool isDark,
    required bool isTab,
  }) {
    final latest = dataPoints.last;
    final latestStr = latest.secondaryValue != null
        ? '${latest.primaryValue.toInt()}/${latest.secondaryValue!.toInt()}'
        : (metric == VitalMetricType.temperature
            ? latest.primaryValue.toStringAsFixed(1)
            : latest.primaryValue.toInt().toString());

    double sumPri = 0;
    double minPri = double.infinity;
    double maxPri = -double.infinity;
    for (final p in dataPoints) {
      sumPri += p.primaryValue;
      if (p.primaryValue < minPri) minPri = p.primaryValue;
      if (p.primaryValue > maxPri) maxPri = p.primaryValue;
    }
    final avgPri = sumPri / dataPoints.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF64748B).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                    'Latest Reading',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        latestStr,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 26 : 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getMetricNormalRange(metric),
                  style: const TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatCol('Average', metric == VitalMetricType.temperature ? avgPri.toStringAsFixed(1) : avgPri.toInt().toString(), unit, isDark),
              _buildStatCol('Minimum', metric == VitalMetricType.temperature ? minPri.toStringAsFixed(1) : minPri.toInt().toString(), unit, isDark),
              _buildStatCol('Maximum', metric == VitalMetricType.temperature ? maxPri.toStringAsFixed(1) : maxPri.toInt().toString(), unit, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String val, String unit, bool isDark) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 10.5,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$val $unit',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncfusionChart(List<VitalsDataPoint> points, bool isDark, String unit) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      primaryXAxis: DateTimeAxis(
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: AxisLine(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        labelStyle: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 10,
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        ),
        dateFormat: DateFormat('d MMM'),
      ),
      primaryYAxis: NumericAxis(
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
          dashArray: const [4, 4],
        ),
        labelStyle: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 10,
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        ),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: '',
        canShowMarker: true,
        format: 'point.x : point.y $unit',
      ),
      series: <CartesianSeries>[
        SplineAreaSeries<VitalsDataPoint, DateTime>(
          dataSource: points,
          xValueMapper: (VitalsDataPoint d, _) => d.date,
          yValueMapper: (VitalsDataPoint d, _) => d.primaryValue,
          color: _primaryBlue.withValues(alpha: 0.15),
          borderColor: _primaryBlue,
          borderWidth: 2.5,
          markerSettings: const MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            color: _primaryBlue,
            borderColor: Colors.white,
            borderWidth: 2,
            width: 7,
            height: 7,
          ),
        ),
        if (points.isNotEmpty && points.first.secondaryValue != null)
          SplineSeries<VitalsDataPoint, DateTime>(
            dataSource: points,
            xValueMapper: (VitalsDataPoint d, _) => d.date,
            yValueMapper: (VitalsDataPoint d, _) => d.secondaryValue,
            color: const Color(0xFF64748B),
            width: 2,
            dashArray: const [4, 4],
            markerSettings: const MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              color: Color(0xFF64748B),
              borderColor: Colors.white,
              borderWidth: 1.5,
              width: 5,
              height: 5,
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryLogs(bool isDark, bool isTab) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF64748B).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recorded History',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? 16 : 14.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _vitalsHistory.length > 5 ? 5 : _vitalsHistory.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
            ),
            itemBuilder: (context, idx) {
              final item = _vitalsHistory[_vitalsHistory.length - 1 - idx];
              final tsStr = item['timestamp']?.toString();
              DateTime dt = DateTime.now();
              if (tsStr != null) dt = DateTime.tryParse(tsStr) ?? DateTime.now();
              final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);

              final bp = item['bp'] ?? '--';
              final pulse = item['pulse'] ?? '--';
              final spO2 = item['spO2'] ?? '--';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'BP: $bp • Pulse: $pulse • SpO2: $spO2%',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.check_circle_outline_rounded, size: 16, color: _primaryBlue),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerCard(bool isDark, {required double height}) {
    return BaseShimmer(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
