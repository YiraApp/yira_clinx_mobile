import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';
import '../../../../core/urls/urls.dart';
import '../widgets/update_vitals_sheet.dart';
import 'widgets/full_screen_vital_chart_screen.dart';
import 'widgets/human_body_vitals_widget.dart';

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
    _loadVitalsFromApi();
  }

  Future<void> _loadVitalsFromApi({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }

    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final token = currentUser?.data?.accessToken ?? '';

    // First instant pass: populate from local cache if available to prevent flash
    if (userId.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedStr = prefs.getString('patient_vitals_$userId');
        if (savedStr != null) {
          final Map<String, dynamic> decoded = jsonDecode(savedStr);
          final Map<String, String> loaded = {};
          decoded.forEach((key, value) {
            if (value != null && value.toString().trim().isNotEmpty && value.toString().trim() != '--' && value.toString().trim() != 'null') {
              loaded[key] = value.toString().trim();
            }
          });
          _currentVitals = loaded;
        }

        final historyStr = prefs.getString('patient_vitals_history_$userId');
        if (historyStr != null) {
          final List<dynamic> decodedList = jsonDecode(historyStr);
          _vitalsHistory = decodedList.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      } catch (_) {}
    }

    // Dynamic Server Fetch via REST API
    try {
      final client = ApiClient();
      final response = await client.account(showSuccessSnack: false).get(
        URLs.patientVitalsUrl,
        queryParameters: {
          if (userId.isNotEmpty) 'patientId': userId,
        },
        options: Options(
          headers: {
            if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic rawBody = response.data is Map<String, dynamic>
            ? response.data
            : (response.data is String ? jsonDecode(response.data) : null);

        if (rawBody != null && rawBody['status'] == true) {
          final data = rawBody['data'] as Map<String, dynamic>?;
          await _processVitalsPayload(data, userId);
        }
      }
    } catch (e) {
      debugPrint("Vitals API fetch error (using cache): $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _processVitalsPayload(Map<String, dynamic>? data, String userId) async {
    if (data == null) return;

    final currentMap = data['current'] as Map<String, dynamic>?;
    final historyList = data['history'] as List<dynamic>?;

    final Map<String, String> parsedCurrent = {};
    currentMap?.forEach((key, val) {
      if (val != null &&
          val.toString().trim().isNotEmpty &&
          val.toString().trim() != '--' &&
          val.toString().trim() != 'null') {
        parsedCurrent[key] = val.toString().trim();
      }
    });

    final List<Map<String, dynamic>> parsedHistory = [];
    if (historyList != null) {
      for (final item in historyList) {
        if (item is Map) {
          parsedHistory.add(Map<String, dynamic>.from(item));
        }
      }
    }

    if (mounted) {
      setState(() {
        _currentVitals = parsedCurrent;
        _vitalsHistory = parsedHistory;
      });
    }

    if (userId.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('patient_vitals_$userId', jsonEncode(parsedCurrent));
        await prefs.setString('patient_vitals_history_$userId', jsonEncode(parsedHistory));
      } catch (_) {}
    }
  }

  Future<void> _recordVitalsToApi(Map<String, String> result) async {
    setState(() => _isLoading = true);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final token = currentUser?.data?.accessToken ?? '';

    try {
      final client = ApiClient();
      final response = await client.account(showSuccessSnack: false).post(
        URLs.patientVitalsUrl,
        data: {
          'patientId': userId,
          'bp': result['bp'],
          'bpSystolic': result['bpSystolic'],
          'bpDiastolic': result['bpDiastolic'],
          'pulse': result['pulse'],
          'temp': result['temp'],
          'spO2': result['spO2'],
          'weight': result['weight'],
          'height': result['height'],
        },
        options: Options(
          headers: {
            if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dynamic rawBody = response.data is Map<String, dynamic>
            ? response.data
            : (response.data is String ? jsonDecode(response.data) : null);

        if (rawBody != null && rawBody['status'] == true) {
          final data = rawBody['data'] as Map<String, dynamic>?;
          await _processVitalsPayload(data, userId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vitals recorded and synced with server successfully!'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Vitals record API error (falling back to local cache): $e");
      // Fallback to local save if offline
      final now = DateTime.now();
      final newEntry = Map<String, dynamic>.from(result);
      newEntry['timestamp'] = now.toIso8601String();

      setState(() {
        _currentVitals = result;
        _vitalsHistory.insert(0, newEntry);
      });

      if (userId.isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('patient_vitals_$userId', jsonEncode(result));
          await prefs.setString('patient_vitals_history_$userId', jsonEncode(_vitalsHistory));
        } catch (_) {}
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
        onSave: (updated) {},
      ),
    );

    if (result != null) {
      await _recordVitalsToApi(result);
    }
  }

  void _openFullScreenChart() {
    _openFullScreenChartFor(_selectedMetric);
  }

  void _openFullScreenChartFor(VitalMetricType metric) {
    if (metric == VitalMetricType.all) return;

    final metricTitle = _getMetricTitle(metric);
    final metricUnit = _getMetricUnit(metric);
    final metricIcon = _getMetricIcon(metric);
    final normalRangeText = _getMetricNormalRange(metric);

    Color metricColor = _primaryBlue;
    switch (metric) {
      case VitalMetricType.all:
        break;
      case VitalMetricType.bloodPressure:
        metricColor = const Color(0xFF8B5CF6);
        break;
      case VitalMetricType.heartRate:
        metricColor = const Color(0xFFE11D48);
        break;
      case VitalMetricType.spO2:
        metricColor = const Color(0xFF06B6D4);
        break;
      case VitalMetricType.temperature:
        metricColor = const Color(0xFFF59E0B);
        break;
      case VitalMetricType.weight:
        metricColor = const Color(0xFF10B981);
        break;
    }

    FullScreenTimeRange initialRange = FullScreenTimeRange.all;
    switch (_timeRange) {
      case VitalsTimeRange.all:
        initialRange = FullScreenTimeRange.all;
        break;
      case VitalsTimeRange.today:
        initialRange = FullScreenTimeRange.oneDay;
        break;
      case VitalsTimeRange.sevenDays:
        initialRange = FullScreenTimeRange.sevenDays;
        break;
      case VitalsTimeRange.dateRange:
        initialRange = FullScreenTimeRange.custom;
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenVitalChartScreen(
          metricType: metric,
          metricTitle: metricTitle,
          metricUnit: metricUnit,
          metricIcon: metricIcon,
          metricColor: metricColor,
          normalRangeText: normalRangeText,
          vitalsHistory: _vitalsHistory,
          currentVitals: _currentVitals,
          initialRange: initialRange,
          initialCustomRange: _customDateRange,
        ),
      ),
    );
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
      if (tsStr == null || tsStr.trim().isEmpty) continue;
      final parsed = DateTime.tryParse(tsStr.trim());
      if (parsed == null) continue;
      final dt = parsed.toLocal();

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

    return PopScope(
      canPop: _selectedMetric == VitalMetricType.all,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedMetric != VitalMetricType.all) {
          _switchMetric(VitalMetricType.all);
        }
      },
      child: Scaffold(
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
            onPressed: () {
              if (_selectedMetric != VitalMetricType.all) {
                _switchMetric(VitalMetricType.all);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          centerTitle: false,
          title: Text(
            _selectedMetric == VitalMetricType.all ? 'Vitals Tracking' : metricTitle,
            style: const TextStyle(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (_selectedMetric != VitalMetricType.all) ...[
              IconButton(
                tooltip: 'Full Screen Graph',
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.open_in_full_rounded, size: 17, color: _primaryBlue),
                ),
                onPressed: _openFullScreenChart,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openUpdateVitals,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add_rounded, size: 15, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'Record',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 4),
          ],
        ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _primaryBlue,
          onRefresh: () => _loadVitalsFromApi(showLoading: false),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(
              horizontal: screenHorizontalSpacePadding,
              vertical: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Time Range Selector (shown only for individual metrics, hidden for All Vitals)
              if (_selectedMetric != VitalMetricType.all) ...[
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
              ],

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
                // ─── ALL VITALS DASHBOARD ────────────────────────────────────
                _buildLastRecordedHeader(isDark, isTab),
                const SizedBox(height: 6),
                HumanBodyVitalsWidget(
                  currentVitals: _currentVitals,
                  onVitalTapped: (metricKey) {
                    switch (metricKey) {
                      case 'bp':
                        _switchMetric(VitalMetricType.bloodPressure);
                        break;
                      case 'pulse':
                        _switchMetric(VitalMetricType.heartRate);
                        break;
                      case 'spO2':
                        _switchMetric(VitalMetricType.spO2);
                        break;
                      case 'temp':
                        _switchMetric(VitalMetricType.temperature);
                        break;
                      case 'weight':
                      case 'height':
                        _switchMetric(VitalMetricType.weight);
                        break;
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildAllVitalsOverviewCards(isDark, isTab),
                const SizedBox(height: 16),
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
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(metricIcon, color: _primaryBlue, size: 17),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _selectedMetric == VitalMetricType.bloodPressure
                                          ? 'BP Trend'
                                          : '$metricTitle Trend',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: isTab ? 15.5 : 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${dataPoints.length} reading${dataPoints.length > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: _openFullScreenChart,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _primaryBlue.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.open_in_full_rounded, size: 11, color: _primaryBlue),
                                        SizedBox(width: 3),
                                        Text(
                                          'Full Screen',
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _primaryBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: isTab ? 280 : 230,
                          child: _buildSyncfusionChart(dataPoints, isDark, metricUnit),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _buildHistoryLogs(isDark, isTab),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  String? _getLastRecordedVitalsDate() {
    DateTime? latestDt;
    if (_vitalsHistory.isNotEmpty) {
      for (final entry in _vitalsHistory) {
        final tsStr = entry['timestamp']?.toString();
        if (tsStr != null && tsStr.trim().isNotEmpty) {
          final dt = DateTime.tryParse(tsStr.trim())?.toLocal();
          if (dt != null) {
            if (latestDt == null || dt.isAfter(latestDt)) {
              latestDt = dt;
            }
          }
        }
      }
    }
    if (latestDt != null) {
      return _formatLastRecorded(latestDt);
    }
    return null;
  }

  String _formatLastRecorded(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
    final timeStr = DateFormat('hh:mm a').format(dt);

    if (isToday) {
      return 'Today, $timeStr';
    } else if (isYesterday) {
      return 'Yesterday, $timeStr';
    } else {
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    }
  }

  Widget _buildLastRecordedHeader(bool isDark, bool isTab) {
    final lastRecorded = _getLastRecordedVitalsDate() ?? 'Recently recorded';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.symmetric(
        horizontal: isTab ? 16 : 12,
        vertical: isTab ? 14 : 11,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: _primaryBlue,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Last Vitals Recorded',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  lastRecorded,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 13 : 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openUpdateVitals,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTab ? 14 : 11,
                  vertical: isTab ? 9 : 7,
                ),
                decoration: BoxDecoration(
                  color: _primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryBlue.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 15, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      'Record Vitals',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 12 : 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0, left: 2, right: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Vitals',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 16 : 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Tap card for trends',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildOverviewTile(
                title: 'Blood Pressure',
                value: bp,
                unit: bp != '--' ? 'mmHg' : '',
                icon: Icons.favorite_rounded,
                color: const Color(0xFF8B5CF6),
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
                icon: Icons.monitor_heart_rounded,
                color: const Color(0xFFE11D48),
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
                color: const Color(0xFF06B6D4),
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
                unit: temp != '--' && !temp.endsWith('°F') && !temp.endsWith('°') ? '°F' : '',
                icon: Icons.thermostat_rounded,
                color: const Color(0xFFF59E0B),
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
                icon: Icons.scale_rounded,
                color: const Color(0xFF10B981),
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
                color: const Color(0xFF3B82F6),
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
    required Color color,
    required VitalMetricType targetMetric,
    required String status,
    required bool isDark,
    required bool isTab,
  }) {
    final hasVal = value != '--';
    final isGood = status == 'Normal' || status == 'Optimal' || status == 'Tracked';

    return InkWell(
      onTap: () => _switchMetric(targetMetric),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(isTab ? 16 : 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? color.withValues(alpha: 0.25)
                : color.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : color.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => _openFullScreenChartFor(targetMetric),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      size: 11,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 20 : 17,
                            fontWeight: FontWeight.bold,
                            color: hasVal
                                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                : (isDark ? Colors.white38 : Colors.grey[400]),
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
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isGood ? const Color(0xFF10B981) : const Color(0xFF94A3B8))
                        .withValues(alpha: isDark ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: isGood ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
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
              Expanded(
                child: Column(
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
                        Flexible(
                          child: Text(
                            latestStr,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 26 : 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
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
              ),
              const SizedBox(width: 8),
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

  NumericAxis _getYAxisForMetric(VitalMetricType metric, List<VitalsDataPoint> points, bool isDark) {
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

    if (minVal != null && maxVal != null && minVal >= maxVal) {
      minVal = math.max(0.0, minVal - 10.0);
      maxVal = minVal + 20.0;
    }

    return NumericAxis(
      minimum: minVal,
      maximum: maxVal,
      interval: interval,
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
    );
  }

  Widget _buildSyncfusionChart(List<VitalsDataPoint> points, bool isDark, String unit) {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enablePanning: true,
        enableDoubleTapZooming: true,
        zoomMode: ZoomMode.x,
      ),
      primaryXAxis: DateTimeAxis(
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: AxisLine(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        labelStyle: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 10,
          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        ),
        dateFormat: _timeRange == VitalsTimeRange.today ? DateFormat('h:mm a') : DateFormat('d MMM'),
        edgeLabelPlacement: EdgeLabelPlacement.shift,
      ),
      primaryYAxis: _getYAxisForMetric(_selectedMetric, points, isDark),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        header: '',
        canShowMarker: true,
        format: 'point.x : point.y $unit',
      ),
      series: <CartesianSeries>[
        SplineAreaSeries<VitalsDataPoint, DateTime>(
          splineType: SplineType.monotonic,
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
            splineType: SplineType.monotonic,
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
    final isAllScreen = _selectedMetric == VitalMetricType.all;
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // For All Vitals screen, filter only past 7 days
    final filteredHistory = isAllScreen
        ? _vitalsHistory.where((item) {
            final tsStr = item['timestamp']?.toString();
            if (tsStr == null) return false;
            final dt = DateTime.tryParse(tsStr);
            return dt != null && dt.isAfter(sevenDaysAgo);
          }).toList()
        : _vitalsHistory;

    final displayLogs = List<Map<String, dynamic>>.from(filteredHistory);
    displayLogs.sort((a, b) {
      final dtA = DateTime.tryParse(a['timestamp']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dtB = DateTime.tryParse(b['timestamp']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dtB.compareTo(dtA);
    });

    final logsCount = isAllScreen
        ? displayLogs.length
        : (displayLogs.length > 5 ? 5 : displayLogs.length);

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
              Text(
                'Recorded History',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 16 : 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              if (isAllScreen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Past 7 Days',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (logsCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 28,
                      color: isDark ? Colors.white24 : Colors.grey[400],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isAllScreen
                          ? 'No vitals recorded in the past 7 days'
                          : 'No recorded history available',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logsCount,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, idx) {
                final item = displayLogs[idx];
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
