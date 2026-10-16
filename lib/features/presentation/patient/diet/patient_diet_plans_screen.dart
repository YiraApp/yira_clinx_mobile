import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/custom_dialogue/app_dialog.dart';
import 'package:yiraclinics/features/data/data_sources/diet/diet_api_error.dart';
import 'package:yiraclinics/features/data/data_sources/diet/patient_diet_remote_data_source.dart';
import 'package:yiraclinics/features/data/models/diet/patient_diet_plan_model.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';
import 'package:yiraclinics/features/presentation/patient/diet/patient_diet_edit_screen.dart';
import 'package:yiraclinics/features/presentation/patient/diet/patient_diet_plan_screen.dart';

export 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';

/// Every diet plan the patient's doctors prescribed. The patient can open any
/// plan, and turn plans on or off; only one plan is followed at a time.
class PatientDietPlansScreen extends StatefulWidget {
  /// For tests; the app uses the real API.
  final PatientDietRemoteDataSource? dataSource;

  const PatientDietPlansScreen({super.key, this.dataSource});

  @override
  State<PatientDietPlansScreen> createState() => _PatientDietPlansScreenState();
}

class _PatientDietPlansScreenState extends State<PatientDietPlansScreen> {
  late final PatientDietRemoteDataSource _dataSource = widget.dataSource ?? PatientDietRemoteDataSource();

  bool _isLoading = true;
  String? _error;
  List<PatientDietPlanSummary> _plans = const [];
  int? _busyPlanId;

  static final DateFormat _dateFormat = DateFormat('d MMM yyyy');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final plans = await _dataSource.getMyPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = dietApiErrorMessage(e, "We couldn't load your diet plans. Pull down to try again.");
      });
    }
  }

  PatientDietPlanSummary? get _activePlan {
    for (final p in _plans) {
      if (p.isActive) return p;
    }
    return null;
  }

  String _dates(PatientDietPlanSummary plan) {
    final start = DateTime.tryParse(plan.startDate ?? '');
    final end = DateTime.tryParse(plan.endDate ?? '');
    if (start == null) return '';
    if (end == null) return 'From ${_dateFormat.format(start)}';
    return '${_dateFormat.format(start)} – ${_dateFormat.format(end)}';
  }

  /// Days left until the plan ends, counting today. Null for open-ended plans.
  int? _daysLeft(PatientDietPlanSummary plan) {
    final end = DateTime.tryParse(plan.endDate ?? '');
    if (end == null) return null;
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    return DateTime.utc(end.year, end.month, end.day).difference(today).inDays + 1;
  }

  void _showMessage(String message, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: DietUi.text(12.5, FontWeight.w500, Colors.white)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  Future<void> _toggle(PatientDietPlanSummary plan, bool turnOn) async {
    if (_busyPlanId != null) return;

    if (turnOn && !plan.canActivate) {
      _showMessage(
        plan.status == 'cancelled'
            ? 'Your doctor stopped this plan. Ask them to prescribe it again.'
            : plan.isExpired
            ? 'This plan has ended. Ask your doctor for a new plan.'
            : "This plan can't be turned on.",
      );
      return;
    }

    final current = _activePlan;
    final bool proceed;
    if (turnOn) {
      proceed = await AppDialog.confirm(
        context,
        title: 'Start "${plan.planName}"?',
        message: current != null && current.id != plan.id
            ? 'You follow one plan at a time. "${current.planName}" will be paused, and you can turn it back on later.'
            : 'Your daily meals will follow this plan.',
        confirmLabel: 'Start Plan',
        tone: AppDialogTone.success,
        icon: Icons.play_circle_outline_rounded,
      );
    } else {
      proceed = await AppDialog.confirm(
        context,
        title: 'Pause "${plan.planName}"?',
        message: "You won't see daily meals or reminders for it until you turn it back on.",
        confirmLabel: 'Pause Plan',
        tone: AppDialogTone.warning,
        icon: Icons.pause_circle_outline_rounded,
      );
    }
    if (!proceed || !mounted) return;

    setState(() => _busyPlanId = plan.id);
    try {
      final message = await _dataSource.setMyPlanStatus(plan.id, turnOn ? 'active' : 'paused');
      if (!mounted) return;
      await _load(showLoader: false);
      if (mounted) _showMessage(message, color: turnOn ? DietUi.green : null);
    } catch (e) {
      if (mounted) {
        _showMessage(dietApiErrorMessage(e, "Couldn't change the plan. Please try again."), color: DietUi.red);
      }
    } finally {
      if (mounted) setState(() => _busyPlanId = null);
    }
  }

  Future<void> _createPlan() async {
    final created = await PatientDietEditScreen.create(context);
    if (created == true && mounted) _load(showLoader: false);
  }

  Future<void> _deletePlan(PatientDietPlanSummary plan) async {
    final proceed = await AppDialog.confirm(
      context,
      title: 'Delete "${plan.planName}"?',
      message: 'This plan and your meal records for it will be removed. This cannot be undone.',
      confirmLabel: 'Delete',
      tone: AppDialogTone.danger,
      icon: Icons.delete_outline_rounded,
    );
    if (!proceed || !mounted) return;
    setState(() => _busyPlanId = plan.id);
    try {
      await _dataSource.deleteMyPlan(plan.id);
      if (!mounted) return;
      await _load(showLoader: false);
      if (mounted) _showMessage('Plan deleted.');
    } catch (e) {
      if (mounted) _showMessage(dietApiErrorMessage(e, "Couldn't delete the plan."), color: DietUi.red);
    } finally {
      if (mounted) setState(() => _busyPlanId = null);
    }
  }

  String _byLine(PatientDietPlanSummary plan) =>
      plan.createdByPatient ? 'Made by you' : 'Dr. ${plan.doctorName} · ${plan.clinicName}';

  Future<void> _open(PatientDietPlanSummary plan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDietPlanScreen(planId: plan.id, dataSource: widget.dataSource),
      ),
    );
    if (mounted) _load(showLoader: false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: DietUi.background(isDark),
      appBar: DietUi.appBar(
        context,
        isDark,
        title: 'My Diet Plans',
        subtitle: 'Prescribed & self-made plans',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPlan,
        backgroundColor: DietUi.blue,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
          child: const Center(child: Icon(Icons.add_rounded, size: 16, color: Colors.white)),
        ),
        label: Text('New Plan', style: DietUi.text(13.5, FontWeight.w700, Colors.white, spacing: 0.2)),
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) return _buildSkeleton(isDark);

    final active = _activePlan;
    final others = _plans.where((p) => !p.isActive).toList();

    return RefreshIndicator(
      color: DietUi.blue,
      onRefresh: () => _load(showLoader: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Room at the bottom so the floating New Plan button never covers a card.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          if (_error != null)
            _buildMessageCard(
              isDark,
              icon: Icons.cloud_off_rounded,
              title: "Couldn't load your plans",
              message: _error!,
              action: TextButton(onPressed: _load, child: const Text('Try again')),
            )
          else if (_plans.isEmpty)
            _buildMessageCard(
              isDark,
              icon: Icons.restaurant_menu_rounded,
              title: 'No diet plans yet',
              message: 'When your doctor prescribes a diet plan, it will appear here. You can also make your own.',
              action: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: DietUi.blue.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _createPlan,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Create my own plan', style: DietUi.text(13.5, FontWeight.w700, Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else ...[
            if (active != null) ...[
              DietUi.sectionLabel('CURRENT PLAN', isDark),
              _buildActiveCard(active, isDark),
              const SizedBox(height: 20),
            ] else ...[
              DietUi.notice(
                'No plan is active right now. Turn one on below to see your daily meals.',
                DietUi.amber,
                Icons.pause_circle_outline_rounded,
                isDark,
              ),
              const SizedBox(height: 16),
            ],
            if (others.isNotEmpty) ...[
              DietUi.sectionLabel(active != null ? 'OTHER PLANS' : 'YOUR PLANS', isDark),
              for (final plan in others) _buildPlanCard(plan, isDark),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildActiveCard(PatientDietPlanSummary plan, bool isDark) {
    final daysLeft = _daysLeft(plan);
    final busy = _busyPlanId == plan.id;
    final dates = _dates(plan);

    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(value, style: DietUi.text(15, FontWeight.w700, DietUi.strong(isDark))),
          const SizedBox(height: 1),
          Text(label, style: DietUi.text(10.5, FontWeight.w500, DietUi.muted(isDark))),
        ],
      ),
    );
    Widget divider() => Container(width: 1, height: 26, color: DietUi.line(isDark));

    return Container(
      decoration: DietUi.cardDecoration(isDark, borderColor: DietUi.green.withValues(alpha: 0.45)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(plan),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [DietUi.green.withValues(alpha: 0.8), DietUi.green],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.planName,
                            maxLines: 3,
                            softWrap: true,
                            style: DietUi.text(14.5, FontWeight.w700, DietUi.strong(isDark), height: 1.3),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _byLine(plan),
                            maxLines: 2,
                            softWrap: true,
                            style: DietUi.text(11.5, FontWeight.w400, DietUi.muted(isDark)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    busy
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : Transform.scale(
                            scale: 0.85,
                            child: Switch.adaptive(
                              value: true,
                              activeTrackColor: DietUi.green,
                              onChanged: (_) => _toggle(plan, false),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: DietUi.sunken(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DietUi.line(isDark)),
                  ),
                  child: Row(
                    children: [
                      stat(plan.targetCalories != null ? '${plan.targetCalories}' : '—', 'kcal / day'),
                      divider(),
                      stat('${plan.totalDays}', plan.totalDays == 1 ? 'day menu' : 'day rotation'),
                      divider(),
                      stat(daysLeft != null ? '${daysLeft < 0 ? 0 : daysLeft}' : '∞', 'days left'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    DietUi.pill('Active', DietUi.green, isDark, icon: Icons.check_circle_rounded),
                    const SizedBox(width: 8),
                    if (dates.isNotEmpty)
                      Expanded(
                        child: Text(
                          dates,
                          maxLines: 2,
                          softWrap: true,
                          style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _open(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DietUi.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.visibility_outlined, size: 17),
                        const SizedBox(width: 6),
                        Text('View Diet Plan', style: DietUi.text(13, FontWeight.w600, Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(PatientDietPlanSummary plan, bool isDark) {
    final color = DietUi.statusColor(plan.status, isExpired: plan.isExpired);
    final label = DietUi.statusLabel(plan.status, isExpired: plan.isExpired);
    final busy = _busyPlanId == plan.id;
    final dates = _dates(plan);
    final facts = [
      if (plan.targetCalories != null) '${plan.targetCalories} kcal/day',
      '${plan.mealCount} ${plan.mealCount == 1 ? 'food' : 'foods'}',
      plan.dietType,
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: DietUi.cardDecoration(isDark),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _open(plan),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DietUi.iconBadge(Icons.restaurant_menu_rounded, color, isDark, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.planName,
                            maxLines: 3,
                            softWrap: true,
                            style: DietUi.text(14, FontWeight.w700, DietUi.strong(isDark), height: 1.3),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _byLine(plan),
                            maxLines: 2,
                            softWrap: true,
                            style: DietUi.text(11.5, FontWeight.w400, DietUi.muted(isDark)),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              DietUi.pill(label, color, isDark),
                              if (plan.createdByPatient) DietUi.pill('Self-made', DietUi.violet, isDark),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (dates.isNotEmpty)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(Icons.event_rounded, size: 13, color: DietUi.hint(isDark)),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    dates,
                                    maxLines: 2,
                                    softWrap: true,
                                    style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark)),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 2),
                          Text(
                            facts,
                            maxLines: 2,
                            softWrap: true,
                            style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 56,
                      child: busy
                          ? const Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Opacity(
                                  opacity: plan.canActivate ? 1 : 0.4,
                                  child: Transform.scale(
                                    scale: 0.85,
                                    child: Switch.adaptive(
                                      value: false,
                                      activeTrackColor: DietUi.green,
                                      onChanged: (_) => _toggle(plan, true),
                                    ),
                                  ),
                                ),
                                if (plan.createdByPatient)
                                  IconButton(
                                    tooltip: 'Delete plan',
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(Icons.delete_outline_rounded, size: 20, color: DietUi.hint(isDark)),
                                    onPressed: () => _deletePlan(plan),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: () => _open(plan),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DietUi.blue,
                        side: BorderSide(color: DietUi.blue.withValues(alpha: 0.45)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.visibility_outlined, size: 17),
                      label: Text('View Diet Plan', style: DietUi.text(13, FontWeight.w600, DietUi.blue)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(
    bool isDark, {
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: DietUi.cardDecoration(isDark),
      child: Column(
        children: [
          DietUi.iconBadge(icon, DietUi.blue, isDark, size: 60, iconSize: 28),
          const SizedBox(height: 14),
          Text(title, style: DietUi.text(15.5, FontWeight.w700, DietUi.strong(isDark))),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: DietUi.text(12.5, FontWeight.w400, DietUi.muted(isDark), height: 1.45),
          ),
          ?action,
        ],
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    Widget block(double height) => Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DietUi.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DietUi.line(isDark)),
      ),
    );
    return ListView(padding: const EdgeInsets.all(16), children: [block(240), block(120), block(120)]);
  }
}
