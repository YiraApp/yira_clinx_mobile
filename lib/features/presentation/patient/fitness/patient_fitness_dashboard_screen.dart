import 'dart:io';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/custom_dialogue/app_dialog.dart';
import '../../../../config/app_route/app_routes.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/services/fitness/fitness_service.dart';
import '../../../../core/services/fitness/fitness_sync_service.dart';
import '../../../../core/shimmer_widgets/patient_fitness_shimmer.dart';
import '../../../../core/widgets/phosphor_icons.dart';
import '../../../data/models/fitness/patient_fitness_model.dart';

enum FitnessMetricType { steps, calories, distance, sleep, restingHeartRate, heartRate, bloodOxygen, weight }

enum FitnessPeriod { week, month }

class _Metric {
  const _Metric(this.label, this.unit, this.color, this.icon, {this.bars = true});
  final String label;
  final String unit;
  final Color color;
  final IconData icon;
  final bool bars;
}

const Map<FitnessMetricType, _Metric> _metrics = {
  FitnessMetricType.steps: _Metric('Steps', 'steps', Color(0xFF16A34A), PhosphorIconsFill.footprints),
  FitnessMetricType.calories: _Metric('Active energy', 'kcal', Color(0xFFF97316), PhosphorIconsFill.flame),
  FitnessMetricType.distance: _Metric('Distance', 'km', Color(0xFF0EA5E9), PhosphorIconsFill.path),
  FitnessMetricType.sleep: _Metric('Sleep', 'h', Color(0xFF6366F1), PhosphorIconsFill.moonStars),
  FitnessMetricType.restingHeartRate:
      _Metric('Resting heart rate', 'bpm', Color(0xFFE11D48), PhosphorIconsFill.heartbeat, bars: false),
  FitnessMetricType.heartRate: _Metric('Heart rate', 'bpm', Color(0xFFF43F5E), PhosphorIconsFill.heart, bars: false),
  FitnessMetricType.bloodOxygen: _Metric('Blood oxygen', '%', Color(0xFF06B6D4), PhosphorIconsFill.drop, bars: false),
  FitnessMetricType.weight: _Metric('Weight', 'kg', Color(0xFF8B5CF6), PhosphorIconsFill.scales, bars: false),
};

class PatientFitnessDashboardScreen extends StatefulWidget {
  const PatientFitnessDashboardScreen({super.key, this.previewSummary, this.previewToday});

  /// Fixed data for screenshots and widget tests; the screen then neither reads the phone nor syncs.
  @visibleForTesting
  final PatientFitnessSummaryResponse? previewSummary;
  @visibleForTesting
  final TodayFitnessData? previewToday;

  @override
  State<PatientFitnessDashboardScreen> createState() => _PatientFitnessDashboardScreenState();
}

class _PatientFitnessDashboardScreenState extends State<PatientFitnessDashboardScreen> {
  final _sync = FitnessSyncService.instance;
  FitnessMetricType _metric = FitnessMetricType.steps;
  FitnessPeriod _period = FitnessPeriod.week;
  PatientFitnessSummaryResponse? _summary;
  bool _isLoading = true;
  int _stepGoal = 8000;
  late final String _profileId;
  final Map<FitnessMetricType, GlobalKey> _chipKeys = {for (final t in FitnessMetricType.values) t: GlobalKey()};

  @override
  void initState() {
    super.initState();
    _profileId = GlobalSession.instance.userNotifier.value?.data?.id ?? '';
    GlobalSession.instance.userNotifier.addListener(_onProfileChanged);
    _sync.todayFitnessNotifier.addListener(_refresh);
    _sync.lastSyncedAtNotifier.addListener(_refresh);
    _sync.sourcesNotifier.addListener(_refresh);
    _sync.isSyncingNotifier.addListener(_refresh);
    _start();
  }

  @override
  void dispose() {
    GlobalSession.instance.userNotifier.removeListener(_onProfileChanged);
    _sync.todayFitnessNotifier.removeListener(_refresh);
    _sync.lastSyncedAtNotifier.removeListener(_refresh);
    _sync.sourcesNotifier.removeListener(_refresh);
    _sync.isSyncingNotifier.removeListener(_refresh);
    super.dispose();
  }

  void _selectMetric(FitnessMetricType type) {
    setState(() => _metric = type);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _chipKeys[type]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, alignment: 0.5, duration: const Duration(milliseconds: 250));
      }
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  // Another profile's data must never stay on screen after a switch.
  void _onProfileChanged() {
    final id = GlobalSession.instance.userNotifier.value?.data?.id ?? '';
    if (mounted && id != _profileId) Navigator.of(context).maybePop();
  }

  Future<void> _start() async {
    if (widget.previewSummary != null || widget.previewToday != null) {
      setState(() {
        _summary = widget.previewSummary;
        _isLoading = false;
      });
      return;
    }
    await _sync.loadCachedStatus();
    // Opened from a shortcut by a profile that hasn't connected on this phone.
    if (!_sync.isConnectedNotifier.value) {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.patientConnectFitness);
      return;
    }
    _stepGoal = await _sync.getStepGoal();
    await _loadSummary(showSpinner: true);
    await _sync.requestNewPermissionsIfNeeded();
    final result = await _sync.syncNow(silent: true);
    if (mounted && result.isSuccess) await _loadSummary();
  }

  Future<void> _loadSummary({bool showSpinner = false}) async {
    if (showSpinner && mounted) setState(() => _isLoading = true);
    final res = await _sync.fetchSummaryFromBackend(period: _period == FitnessPeriod.week ? 'week' : 'month');
    if (!mounted) return;
    setState(() {
      if (res != null) _summary = res;
      _isLoading = false;
    });
  }

  Future<void> _syncNow({bool fullResync = false}) async {
    final result = await _sync.syncNow(fullResync: fullResync);
    await _loadSummary();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: result.isSuccess
            ? null
            : SnackBarAction(
                label: 'Fix',
                textColor: Colors.white,
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.patientConnectFitness),
              ),
      ),
    );
  }

  void _confirmDisconnect() {
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Disconnect fitness?',
        message: 'This phone will stop sending ${Platform.isIOS ? 'Apple Health' : 'Health Connect'} data. '
            'Readings already saved stay in your records. You can reconnect anytime.',
        tone: AppDialogTone.danger,
        icon: PhosphorIconsBold.linkBreak,
        primaryLabel: 'Disconnect',
        onPrimary: () async {
          Navigator.pop(ctx);
          await _sync.disconnectFitness();
          if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.patientConnectFitness);
        },
        secondaryLabel: 'Cancel',
        onSecondary: () => Navigator.pop(ctx),
      ),
    );
  }

  Future<void> _editStepGoal() async {
    const options = [4000, 6000, 8000, 10000, 12000, 15000];
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text('Daily step goal',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 17, fontWeight: FontWeight.w700)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Around 8,000 steps a day is a good target for most adults.',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: Color(0xFF64748B))),
            ),
            for (final g in options)
              ListTile(
                title: Text('${NumberFormat.decimalPattern().format(g)} steps',
                    style: const TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600)),
                trailing: g == _stepGoal ? Icon(PhosphorIconsFill.checkCircle, color: _metrics[FitnessMetricType.steps]!.color) : null,
                onTap: () => Navigator.pop(ctx, g),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;
    await _sync.setStepGoal(picked);
    if (mounted) setState(() => _stepGoal = picked);
  }

  // Today's numbers come from the phone first, then from the server.
  TodayFitnessData? get _today {
    if (widget.previewToday != null) return widget.previewToday;
    final local = _sync.todayFitnessNotifier.value;
    if (local != null && local.date == FitnessService.dateKey(DateTime.now())) return local;
    return _summary?.today;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final syncing = _sync.isSyncingNotifier.value;
    final fg = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF4F6FA),
        leading: IconButton(
          icon: Icon(PhosphorIconsBold.caretLeft, color: fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Fitness',
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 19, fontWeight: FontWeight.w700, color: fg)),
        actions: [
          IconButton(
            tooltip: 'Sync now',
            onPressed: syncing ? null : () => _syncNow(),
            icon: syncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(PhosphorIconsBold.arrowsClockwise, color: fg),
          ),
          PopupMenuButton<String>(
            icon: Icon(PhosphorIconsBold.dotsThreeVertical, color: fg),
            onSelected: (v) {
              if (v == 'goal') _editStepGoal();
              if (v == 'resync') _syncNow(fullResync: true);
              if (v == 'disconnect') _confirmDisconnect();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'goal', child: Text('Change step goal')),
              PopupMenuItem(value: 'resync', child: Text('Re-sync last 30 days')),
              PopupMenuItem(
                value: 'disconnect',
                child: Text('Disconnect', style: TextStyle(color: Color(0xFFEF4444))),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _syncNow(),
        child: _isLoading && _summary == null && _today == null
            ? const PatientFitnessDashboardShimmer()
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  _buildSyncStatus(isDark),
                  const SizedBox(height: 12),
                  _buildTodayCard(isDark),
                  const SizedBox(height: 12),
                  _buildVitalsGrid(isDark),
                  const SizedBox(height: 20),
                  _sectionTitle('Trends', isDark),
                  const SizedBox(height: 10),
                  _buildTrendsCard(isDark),
                  const SizedBox(height: 16),
                  _buildFootnote(isDark),
                ],
              ),
      ),
    );
  }

  Widget _sectionTitle(String text, bool isDark) => Text(
        text,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      );

  BoxDecoration _card(bool isDark) => BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE8ECF2)),
      );

  Color _muted(bool isDark) => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  // ── Sync status ────────────────────────────────────────────────────────
  Widget _buildSyncStatus(bool isDark) {
    final last = _sync.lastSyncedAtNotifier.value ?? _summary?.lastSyncedAt?.toLocal();
    final sources = _sync.sourcesNotifier.value;
    final syncing = _sync.isSyncingNotifier.value;
    final platform = Platform.isIOS ? 'Apple Health' : 'Health Connect';
    final when = syncing ? 'Syncing…' : (last == null ? 'Not synced yet' : 'Synced ${_ago(last)}');
    final from = sources.isEmpty ? platform : sources.take(3).join(', ');

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: syncing ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$when · from $from',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: _muted(isDark)),
          ),
        ),
      ],
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return DateFormat('d MMM, h:mm a').format(t);
  }

  // ── Today ──────────────────────────────────────────────────────────────
  Widget _buildTodayCard(bool isDark) {
    final today = _today;
    final steps = today?.steps ?? 0;
    final progress = _stepGoal == 0 ? 0.0 : (steps / _stepGoal).clamp(0.0, 1.0);
    final green = _metrics[FitnessMetricType.steps]!.color;
    final fmt = NumberFormat.decimalPattern();
    final left = math.max(0, _stepGoal - steps);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _card(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Today',
                  style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const Spacer(),
              Text(DateFormat('EEE, d MMM').format(DateTime.now()),
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: _muted(isDark))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              GestureDetector(
                onTap: _editStepGoal,
                child: SizedBox(
                  width: 128,
                  height: 128,
                  child: CustomPaint(
                    painter: _RingPainter(
                      progress: progress,
                      color: green,
                      track: isDark ? const Color(0xFF1F2937) : const Color(0xFFEAF7EF),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsFill.footprints, color: green, size: 18),
                          const SizedBox(height: 2),
                          FittedBox(
                            child: Text(
                              today?.steps == null ? '--' : fmt.format(steps),
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Text('of ${fmt.format(_stepGoal)}',
                              style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: _muted(isDark))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _todayStat(FitnessMetricType.calories, today?.calories == null ? '--' : fmt.format(today!.calories!.round()),
                        'kcal active', isDark),
                    const SizedBox(height: 12),
                    _todayStat(
                        FitnessMetricType.distance,
                        today?.distanceMeters == null ? '--' : (today!.distanceMeters! / 1000).toStringAsFixed(2),
                        'km',
                        isDark),
                    const SizedBox(height: 12),
                    _todayStat(
                        FitnessMetricType.heartRate,
                        today?.heartRateAvg == null ? '--' : today!.heartRateAvg!.round().toString(),
                        today?.heartRateMin != null && today?.heartRateMax != null
                            ? 'bpm avg · ${today!.heartRateMin!.round()}–${today.heartRateMax!.round()}'
                            : 'bpm avg',
                        isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: green.withValues(alpha: isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              today?.steps == null
                  ? 'No steps recorded yet today. Carry your phone or wear your watch to start counting.'
                  : left == 0
                      ? 'Goal reached! ${fmt.format(steps - _stepGoal)} steps over your goal.'
                      : '${fmt.format(left)} steps to go · ${(progress * 100).round()}% of your daily goal',
              style: TextStyle(
                  fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF14532D)),
            ),
          ),
          if ((today?.hourly ?? const []).any((h) => h.steps > 0)) ...[
            const SizedBox(height: 16),
            Text('Steps by hour',
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: _muted(isDark))),
            const SizedBox(height: 8),
            SizedBox(height: 70, child: _HourlyBars(hourly: today!.hourly, color: green, isDark: isDark)),
          ],
        ],
      ),
    );
  }

  Widget _todayStat(FitnessMetricType type, String value, String label, bool isDark) {
    final m = _metrics[type]!;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: m.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(m.icon, color: m.color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: _muted(isDark))),
            ],
          ),
        ),
      ],
    );
  }

  // ── Sleep and vitals ───────────────────────────────────────────────────
  Widget _buildVitalsGrid(bool isDark) {
    final today = _today;
    final points = _summary?.chartPoints ?? const <ChartFitnessPoint>[];
    ChartFitnessPoint? lastWith(num? Function(ChartFitnessPoint p) pick) {
      for (final p in points.reversed) {
        if (pick(p) != null) return p;
      }
      return null;
    }

    final restingPoint = lastWith((p) => p.restingHeartRate);
    final resting = today?.restingHeartRate ?? restingPoint?.restingHeartRate;
    final restingDate = today?.restingHeartRate != null ? null : restingPoint?.date;

    final spo2 = today?.bloodOxygen ?? _summary?.latestBloodOxygen;
    final spo2Date = today?.bloodOxygen != null ? null : _summary?.latestBloodOxygenDate;
    final weight = today?.weightKg ?? _summary?.latestWeightKg;
    final weightDate = today?.weightKg != null ? null : _summary?.latestWeightDate;

    return Column(
      children: [
        _buildSleepCard(isDark, today, lastWith((p) => p.sleepMinutes)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _vitalTile(FitnessMetricType.restingHeartRate, 'Resting HR',
                  resting == null ? '--' : resting.round().toString(), 'bpm', _when(restingDate, resting), isDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _vitalTile(FitnessMetricType.bloodOxygen, 'SpO2', spo2 == null ? '--' : spo2.round().toString(), '%',
                  _when(spo2Date, spo2), isDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _vitalTile(FitnessMetricType.weight, 'Weight', weight == null ? '--' : weight.toStringAsFixed(1), 'kg',
                  _when(weightDate, weight), isDark),
            ),
          ],
        ),
      ],
    );
  }

  String _when(String? date, num? value) {
    if (value == null) return 'No reading';
    if (date == null || date == FitnessService.dateKey(DateTime.now())) return 'Today';
    final d = DateTime.tryParse(date);
    if (d == null) return '';
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    if (FitnessService.dateKey(d) == FitnessService.dateKey(yesterday)) return 'Yesterday';
    return DateFormat('d MMM').format(d);
  }

  Widget _vitalTile(FitnessMetricType type, String title, String value, String unit, String when, bool isDark) {
    final m = _metrics[type]!;
    final selected = _metric == type;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _selectMetric(type),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: _card(isDark).copyWith(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? m.color.withValues(alpha: 0.6) : (isDark ? const Color(0xFF1F2937) : const Color(0xFFE8ECF2))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(m.icon, color: m.color, size: 18),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(title,
                  maxLines: 1,
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w600, color: _muted(isDark))),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: value,
                      style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  TextSpan(
                      text: ' $unit',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: _muted(isDark))),
                ]),
              ),
            ),
            const SizedBox(height: 2),
            Text(when, style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, color: _muted(isDark))),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepCard(bool isDark, TodayFitnessData? today, ChartFitnessPoint? lastNight) {
    final indigo = _metrics[FitnessMetricType.sleep]!.color;
    final hasToday = today?.sleepMinutes != null;
    final minutes = hasToday ? today!.sleepMinutes : lastNight?.sleepMinutes;
    final deep = hasToday ? today!.sleepDeepMinutes : lastNight?.sleepDeepMinutes;
    final rem = hasToday ? today!.sleepRemMinutes : lastNight?.sleepRemMinutes;
    final light = hasToday ? today!.sleepLightMinutes : lastNight?.sleepLightMinutes;
    final awake = hasToday ? today!.sleepAwakeMinutes : lastNight?.sleepAwakeMinutes;
    final label = hasToday ? 'Last night' : (lastNight == null ? 'Sleep' : 'Night before ${_when(lastNight.date, 1)}');
    final hasStages = (deep ?? 0) + (rem ?? 0) + (light ?? 0) > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _selectMetric(FitnessMetricType.sleep),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _card(isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: indigo.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(PhosphorIconsFill.moonStars, color: indigo, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: _muted(isDark))),
                      Text(
                        minutes == null ? 'No sleep recorded' : formatSleepMinutes(minutes),
                        style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: minutes == null ? 15 : 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
                if (minutes != null) _sleepBadge(minutes, isDark),
              ],
            ),
            if (hasStages) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      for (final s in [
                        (deep, const Color(0xFF3730A3)),
                        (rem, const Color(0xFF8B5CF6)),
                        (light, const Color(0xFFA5B4FC)),
                        (awake, const Color(0xFFFBBF24)),
                      ])
                        if ((s.$1 ?? 0) > 0) Expanded(flex: s.$1!, child: Container(color: s.$2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  if (deep != null) _stageLegend('Deep', deep, const Color(0xFF3730A3), isDark),
                  if (rem != null) _stageLegend('REM', rem, const Color(0xFF8B5CF6), isDark),
                  if (light != null) _stageLegend('Light', light, const Color(0xFFA5B4FC), isDark),
                  if (awake != null) _stageLegend('Awake', awake, const Color(0xFFFBBF24), isDark),
                ],
              ),
            ] else if (minutes == null) ...[
              const SizedBox(height: 8),
              Text('Wear your watch or use a sleep app that writes to ${Platform.isIOS ? 'Apple Health' : 'Health Connect'}.',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: _muted(isDark))),
            ],
          ],
        ),
      ),
    );
  }

  // Adults need 7–9 hours (AASM / CDC).
  Widget _sleepBadge(int minutes, bool isDark) {
    final (text, color) = minutes >= 420 && minutes <= 540
        ? ('On target', const Color(0xFF10B981))
        : minutes < 420
            ? ('Below 7h', const Color(0xFFF59E0B))
            : ('Over 9h', const Color(0xFF6366F1));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _stageLegend(String name, int minutes, Color color, bool isDark) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('$name ${formatSleepMinutes(minutes)}',
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: _muted(isDark))),
        ],
      );

  // ── Trends ─────────────────────────────────────────────────────────────
  double? _value(ChartFitnessPoint p, FitnessMetricType type) {
    switch (type) {
      case FitnessMetricType.steps:
        return p.steps?.toDouble();
      case FitnessMetricType.calories:
        return p.calories;
      case FitnessMetricType.distance:
        return p.distanceMeters == null ? null : p.distanceMeters! / 1000;
      case FitnessMetricType.sleep:
        return p.sleepMinutes == null ? null : p.sleepMinutes! / 60;
      case FitnessMetricType.restingHeartRate:
        return p.restingHeartRate;
      case FitnessMetricType.heartRate:
        return p.heartRateAvg;
      case FitnessMetricType.bloodOxygen:
        return p.bloodOxygen;
      case FitnessMetricType.weight:
        return p.weightKg;
    }
  }

  String _format(double v, FitnessMetricType type) {
    switch (type) {
      case FitnessMetricType.steps:
      case FitnessMetricType.calories:
        return NumberFormat.decimalPattern().format(v.round());
      case FitnessMetricType.distance:
        return v.toStringAsFixed(1);
      case FitnessMetricType.sleep:
        return formatSleepMinutes((v * 60).round());
      case FitnessMetricType.weight:
        return v.toStringAsFixed(1);
      default:
        return v.round().toString();
    }
  }

  Widget _buildTrendsCard(bool isDark) {
    final m = _metrics[_metric]!;
    final points = _summary?.chartPoints ?? const <ChartFitnessPoint>[];
    final values = [for (final p in points) _value(p, _metric)];
    final present = values.whereType<double>().toList();
    final avg = present.isEmpty ? null : present.reduce((a, b) => a + b) / present.length;
    final days = _period == FitnessPeriod.week ? 7 : 30;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: _card(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodToggle(isDark),
          const SizedBox(height: 12),
          SizedBox(
            height: 34,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [for (final type in FitnessMetricType.values) _metricChip(type, isDark)]),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _metric == FitnessMetricType.weight || _metric == FitnessMetricType.bloodOxygen
                          ? 'Average of readings'
                          : 'Daily average',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: _muted(isDark)),
                    ),
                    Text.rich(TextSpan(children: [
                      TextSpan(
                          text: avg == null ? '--' : _format(avg, _metric),
                          style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      if (avg != null && _metric != FitnessMetricType.sleep)
                        TextSpan(
                            text: ' ${m.unit}', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: _muted(isDark))),
                    ])),
                  ],
                ),
              ),
              if (present.isNotEmpty) _buildChange(isDark),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: present.isEmpty
                ? Center(
                    child: Text('No ${m.label.toLowerCase()} readings in the last $days days',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: _muted(isDark))),
                  )
                : (m.bars ? _barChart(points, values, m, isDark) : _lineChart(points, values, m, isDark)),
          ),
          const SizedBox(height: 8),
          Text(
            '${present.length} of $days days have a reading'
            '${_metric == FitnessMetricType.steps && present.isNotEmpty ? ' · dashed line is your goal' : ''}',
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: _muted(isDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildChange(bool isDark) {
    final a = _summary?.analytics;
    if (a == null) return const SizedBox.shrink();
    double? now;
    double? before;
    var higherIsBetter = true;
    switch (_metric) {
      case FitnessMetricType.steps:
        now = a.stepsAverage.toDouble();
        before = a.previousStepsAverage.toDouble();
        break;
      case FitnessMetricType.sleep:
        now = a.sleepAverageMinutes.toDouble();
        before = a.previousSleepAverageMinutes.toDouble();
        break;
      case FitnessMetricType.restingHeartRate:
        now = a.restingHeartRateAverage;
        before = a.previousRestingHeartRateAverage;
        higherIsBetter = false;
        break;
      default:
        return const SizedBox.shrink();
    }
    if (now <= 0 || before <= 0) return const SizedBox.shrink();
    final pct = ((now - before) / before * 100).round();
    if (pct == 0) return _changePill('Same as before', const Color(0xFF64748B), null);
    final up = pct > 0;
    final good = up == higherIsBetter;
    return _changePill(
      '${up ? '+' : ''}$pct% vs previous ${_period == FitnessPeriod.week ? '7' : '30'} days',
      good ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
      up ? PhosphorIconsBold.trendUp : PhosphorIconsBold.trendDown,
    );
  }

  Widget _changePill(String text, Color color, IconData? icon) => Container(
        constraints: const BoxConstraints(maxWidth: 170),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
            Flexible(
              child: Text(text,
                  maxLines: 2,
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
            ),
          ],
        ),
      );

  Widget _buildPeriodToggle(bool isDark) {
    Widget button(String label, FitnessPeriod p) {
      final selected = _period == p;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            if (selected) return;
            setState(() => _period = p);
            _loadSummary();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? (isDark ? const Color(0xFF1F2937) : Colors.white) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))] : null,
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? (isDark ? Colors.white : const Color(0xFF0F172A)) : _muted(isDark),
                )),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(children: [button('7 days', FitnessPeriod.week), button('30 days', FitnessPeriod.month)]),
    );
  }

  Widget _metricChip(FitnessMetricType type, bool isDark) {
    final m = _metrics[type]!;
    final selected = _metric == type;
    return Padding(
      key: _chipKeys[type],
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _selectMetric(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? m.color : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF1F4F8)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(m.icon, size: 14, color: selected ? Colors.white : m.color),
              const SizedBox(width: 6),
              Text(m.label,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  String _axisLabel(ChartFitnessPoint p, int index, int count) {
    final d = p.day;
    if (d == null) return '';
    if (count <= 7) return DateFormat('E').format(d).substring(0, 1);
    final step = 6;
    return (index % step == (count - 1) % step) ? DateFormat('d').format(d) : '';
  }

  FlTitlesData _titles(List<ChartFitnessPoint> points, bool isDark) => FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value == meta.min) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                child: Text(_compact(value),
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 9.5, color: _muted(isDark))),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final i = value.round();
              if (i < 0 || i >= points.length || value != i.toDouble()) return const SizedBox.shrink();
              return SideTitleWidget(
                meta: meta,
                child: Text(_axisLabel(points[i], i, points.length),
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 10, color: _muted(isDark))),
              );
            },
          ),
        ),
      );

  String _compact(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k';
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(1);
  }

  String _tooltipDate(ChartFitnessPoint p) {
    final d = p.day;
    return d == null ? p.date : DateFormat('EEE, d MMM').format(d);
  }

  Widget _barChart(List<ChartFitnessPoint> points, List<double?> values, _Metric m, bool isDark) {
    final goal = _metric == FitnessMetricType.steps ? _stepGoal.toDouble() : null;
    final top = [...values.whereType<double>(), ?goal].reduce(math.max);
    final maxY = top <= 0 ? 1.0 : top * 1.15;
    final todayKey = FitnessService.dateKey(DateTime.now());
    final width = points.length <= 7 ? 18.0 : 6.0;

    return BarChart(
      BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFEEF1F5), strokeWidth: 1),
        ),
        titlesData: _titles(points, isDark),
        extraLinesData: goal == null
            ? null
            : ExtraLinesData(horizontalLines: [
                HorizontalLine(y: goal, color: m.color.withValues(alpha: 0.7), strokeWidth: 1.2, dashArray: const [5, 4]),
              ]),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => isDark ? const Color(0xFF1F2937) : const Color(0xFF0F172A),
            getTooltipItem: (group, _, rod, _) {
              final p = points[group.x];
              final v = values[group.x];
              return BarTooltipItem(
                '${_tooltipDate(p)}\n',
                const TextStyle(fontFamily: appPoppinFont, color: Colors.white70, fontSize: 11),
                children: [
                  TextSpan(
                    text: v == null ? 'No reading' : '${_format(v, _metric)}${_metric == FitnessMetricType.sleep ? '' : ' ${m.unit}'}',
                    style: const TextStyle(fontFamily: appPoppinFont, color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: values[i] ?? 0,
                width: width,
                color: points[i].date == todayKey ? m.color : m.color.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(width / 2.5),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _lineChart(List<ChartFitnessPoint> points, List<double?> values, _Metric m, bool isDark) {
    final present = values.whereType<double>().toList();
    var minY = present.reduce(math.min);
    var maxY = present.reduce(math.max);
    final pad = math.max((maxY - minY) * 0.25, _metric == FitnessMetricType.weight ? 1.0 : 3.0);
    minY = math.max(0, (minY - pad).floorToDouble());
    maxY = (maxY + pad).ceilToDouble();
    if (_metric == FitnessMetricType.bloodOxygen) maxY = math.min(maxY, 100);

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        minX: 0,
        maxX: (points.length - 1).toDouble().clamp(0, double.infinity),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4 == 0 ? 1 : (maxY - minY) / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFEEF1F5), strokeWidth: 1),
        ),
        titlesData: _titles(points, isDark),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => isDark ? const Color(0xFF1F2937) : const Color(0xFF0F172A),
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${_tooltipDate(points[s.x.round()])}\n',
                      const TextStyle(fontFamily: appPoppinFont, color: Colors.white70, fontSize: 11),
                      children: [
                        TextSpan(
                          text: '${_format(s.y, _metric)} ${m.unit}',
                          style: const TextStyle(
                              fontFamily: appPoppinFont, color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                      ],
                    ))
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            // Days without a reading are left as gaps, never drawn as zero.
            spots: [
              for (var i = 0; i < points.length; i++)
                values[i] == null ? FlSpot.nullSpot : FlSpot(i.toDouble(), values[i]!),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            color: m.color,
            barWidth: 2.5,
            dotData: FlDotData(
              getDotPainter: (_, _, _, _) =>
                  FlDotCirclePainter(radius: 3.2, color: m.color, strokeWidth: 1.5, strokeColor: Colors.white),
            ),
            belowBarData: BarAreaData(show: true, color: m.color.withValues(alpha: 0.08)),
          ),
        ],
      ),
    );
  }

  Widget _buildFootnote(bool isDark) {
    final platform = Platform.isIOS ? 'Apple Health' : 'Health Connect';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIconsFill.info, size: 16, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Numbers come from $platform. When two apps record the same walk, it\'s counted once. '
              'Sleep is shown on the morning you woke up. Days with no reading are left blank, not counted as zero.',
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, height: 1.45, color: _muted(isDark)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color, required this.track});
  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    if (progress <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color || old.track != track;
}

class _HourlyBars extends StatelessWidget {
  const _HourlyBars({required this.hourly, required this.color, required this.isDark});
  final List<HourlyFitnessPoint> hourly;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final byHour = List<int>.filled(24, 0);
    for (final h in hourly) {
      if (h.hour >= 0 && h.hour < 24) byHour[h.hour] = h.steps;
    }
    final top = byHour.reduce(math.max);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8);
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var h = 0; h < 24; h++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.2),
                    child: FractionallySizedBox(
                      heightFactor: top == 0 ? 0.04 : math.max(0.04, byHour[h] / top),
                      child: Container(
                        decoration: BoxDecoration(
                          color: byHour[h] == 0 ? (isDark ? const Color(0xFF1F2937) : const Color(0xFFEFF2F6)) : color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final l in const ['12a', '6a', '12p', '6p', '11p'])
              Text(l, style: TextStyle(fontFamily: appPoppinFont, fontSize: 9.5, color: muted)),
          ],
        ),
      ],
    );
  }
}
