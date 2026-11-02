import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/features/data/data_sources/diet/diet_api_error.dart';
import 'package:yiraclinics/features/data/data_sources/diet/doctor_diet_remote_data_source.dart';
import 'package:yiraclinics/features/data/models/diet/patient_diet_plan_model.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/diet_food_image.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/doctor_prescribe_diet_sheet.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/record_tab_ui.dart';

/// The Diet tab of a patient's record: the plans prescribed to them in this
/// organization, and the way to prescribe a new one.
class DoctorPatientDietTab extends StatefulWidget {
  final String patientId;
  final String? patientName;
  final String? orgId;
  final String? hospitalId;
  final String? appointmentId;

  /// Every plan the patient has, from any organization and including ones
  /// they made themselves. Needs the patient's consent.
  final bool fullHistory;

  /// For tests; the app uses the real API.
  final DoctorDietRemoteDataSource? dataSource;

  const DoctorPatientDietTab({
    super.key,
    required this.patientId,
    this.patientName,
    this.orgId,
    this.hospitalId,
    this.appointmentId,
    this.fullHistory = false,
    this.dataSource,
  });

  @override
  State<DoctorPatientDietTab> createState() => _DoctorPatientDietTabState();
}

class _DoctorPatientDietTabState extends State<DoctorPatientDietTab> with AutomaticKeepAliveClientMixin {
  late final DoctorDietRemoteDataSource _dataSource = widget.dataSource ?? DoctorDietRemoteDataSource();

  static const Color _green = Color(0xFF10B981);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFEF4444);
  static const Color _slate = Color(0xFF64748B);

  static final DateFormat _date = DateFormat('d MMM yyyy');

  bool _isLoading = true;
  String? _error;
  List<TodayDietPlanInfo> _plans = const [];

  @override
  bool get wantKeepAlive => true;

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
      final raw = await _dataSource.getPatientPlans(widget.patientId, orgId: widget.orgId, fullHistory: widget.fullHistory);
      if (!mounted) return;
      setState(() {
        _plans = raw.map(TodayDietPlanInfo.fromPlanEntity).toList();
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = dietApiErrorMessage(e, "Couldn't load this patient's diet plans.");
      });
    }
  }

  /// In the full history a doctor may only change plans they prescribed.
  bool _canEdit(TodayDietPlanInfo p) {
    if (p.createdByPatient) return false;
    if (widget.fullHistory) {
      final me = (GlobalSession.instance.userNotifier.value?.data?.id ?? '').toLowerCase();
      if (me.isEmpty || (p.assignedByDoctorId ?? '').toLowerCase() != me) return false;
    }
    return (p.status == 'active' || p.status == 'paused') && !_ended(p);
  }

  Future<void> _editPlan(TodayDietPlanInfo plan) async {
    final saved = await DoctorPrescribeDietSheet.show(
      context,
      patientId: widget.patientId,
      patientName: widget.patientName,
      orgId: widget.orgId,
      hospitalId: widget.hospitalId,
      appointmentId: widget.appointmentId,
      editPlanId: plan.id,
    );
    if (saved == true && mounted) _load(showLoader: false);
  }

  Future<void> _prescribe() async {
    final prescribed = await DoctorPrescribeDietSheet.show(
      context,
      patientId: widget.patientId,
      patientName: widget.patientName,
      orgId: widget.orgId,
      hospitalId: widget.hospitalId,
      appointmentId: widget.appointmentId,
    );
    if (prescribed == true && mounted) _load(showLoader: false);
  }

  bool _ended(TodayDietPlanInfo p) {
    final end = DateTime.tryParse(p.endDate ?? '');
    if (end == null) return false;
    final now = DateTime.now();
    return DateTime(end.year, end.month, end.day).isBefore(DateTime(now.year, now.month, now.day));
  }

  ({String label, Color color}) _status(TodayDietPlanInfo p) {
    final s = p.status.trim().toLowerCase();
    if (_ended(p) && (s == 'active' || s == 'paused')) return (label: 'Ended', color: _slate);
    return switch (s) {
      'active' => (label: 'Active', color: _green),
      'paused' => (label: 'Paused', color: _amber),
      'cancelled' => (label: 'Stopped', color: _red),
      _ => (label: 'Completed', color: _slate),
    };
  }

  String _dates(TodayDietPlanInfo p) {
    final start = DateTime.tryParse(p.startDate ?? '');
    final end = DateTime.tryParse(p.endDate ?? '');
    if (start == null) return '';
    return end == null ? 'From ${_date.format(start)}' : '${_date.format(start)} – ${_date.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: DietUi.blue,
      onRefresh: () => _load(showLoader: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _buildHeaderCard(isDark),
          const SizedBox(height: 18),
          if (_isLoading)
            ...List.generate(
              2,
              (_) => Container(
                height: 120,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: DietUi.card(isDark),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DietUi.line(isDark)),
                ),
              ),
            )
          else if (_error != null)
            _buildMessage(
              Icons.cloud_off_rounded,
              _error!,
              action: TextButton(onPressed: _load, child: const Text('Try again')),
            )
          else if (_plans.isEmpty)
            _buildMessage(
              Icons.restaurant_menu_outlined,
              'No diet plan yet',
              message: 'No diet plan has been prescribed to this patient yet. Tap Prescribe to create one.',
            )
          else ...[
            DietUi.sectionLabel('PRESCRIBED PLANS · ${_plans.length}', isDark),
            for (final plan in _plans) _buildPlanCard(plan, isDark),
          ],
        ],
      ),
    );
  }

  /// Compact header: what this tab is for and the Prescribe button.
  Widget _buildHeaderCard(bool isDark) {
    TodayDietPlanInfo? active;
    for (final p in _plans) {
      if (p.status == 'active' && !_ended(p)) {
        active = p;
        break;
      }
    }

    return RecordCard(
      child: RecordCardHeader(
        icon: Icons.restaurant_menu_outlined,
        title: 'Diet plan',
        subtitle: _isLoading
            ? 'Loading plans…'
            : active != null
                ? 'Following: ${active.planName}'
                : 'No active plan for ${widget.patientName ?? 'this patient'}',
        trailing: RecordPrimaryButton(label: 'Prescribe', icon: Icons.add_rounded, compact: true, onPressed: _prescribe),
      ),
    );
  }

  Widget _buildPlanCard(TodayDietPlanInfo plan, bool isDark) {
    final status = _status(plan);
    final thisAppointment =
        widget.appointmentId != null && plan.appointmentId != null && '${plan.appointmentId}' == widget.appointmentId;
    final facts = [
      if ((plan.targetCalories ?? 0) > 0) '${plan.targetCalories} kcal/day',
      plan.totalDays == 1 ? 'Same menu daily' : '${plan.totalDays}-day rotation',
      plan.dietType,
    ].join(' · ');
    final canEdit = _canEdit(plan);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RecordCard(
        onTap: () => _openPlan(plan),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecordCardHeader(
              icon: Icons.restaurant_menu_outlined,
              title: plan.planName,
              subtitle: plan.condition?.trim(),
              trailing: RecordPill(status.label, color: status.color),
            ),
            if (thisAppointment) ...[
              const SizedBox(height: 10),
              const RecordPill('Prescribed in this appointment', color: DietUi.blue),
            ],
            const SizedBox(height: 10),
            _infoLine(Icons.event_outlined, _dates(plan)),
            _infoLine(Icons.local_fire_department_outlined, facts),
            _infoLine(Icons.person_outline_rounded, plan.prescribedByLabelForDoctor),
            const SizedBox(height: 4),
            Row(
              children: [
                if (canEdit) RecordIconAction(icon: Icons.edit_outlined, tooltip: 'Edit plan', onTap: () => _editPlan(plan)),
                const Expanded(child: RecordCardLink(label: 'View diet')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: RecordMeta(icon: icon, text: text),
    );
  }

  Widget _buildMessage(IconData icon, String title, {String? message, Widget? action}) {
    return RecordCard(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          RecordEmptyState(icon: icon, title: title, message: message),
          ?action,
        ],
      ),
    );
  }

  // --- Plan details ---

  Future<void> _openPlan(TodayDietPlanInfo plan) async {
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _DoctorPlanDetailsSheet(
            plan: plan,
            orgId: widget.orgId,
            dataSource: _dataSource,
            canEdit: _canEdit(plan),
            fullHistory: widget.fullHistory,
          ),
    );
    if (!mounted) return;
    if (result == 'edit') {
      _editPlan(plan);
    } else if (result == true) {
      _load(showLoader: false);
    }
  }
}

/// Read-only view of one prescribed plan, day by day, with status actions.
class _DoctorPlanDetailsSheet extends StatefulWidget {
  final TodayDietPlanInfo plan;
  final String? orgId;
  final DoctorDietRemoteDataSource dataSource;
  final bool canEdit;
  final bool fullHistory;

  const _DoctorPlanDetailsSheet({
    required this.plan,
    required this.orgId,
    required this.dataSource,
    this.canEdit = false,
    this.fullHistory = false,
  });

  @override
  State<_DoctorPlanDetailsSheet> createState() => _DoctorPlanDetailsSheetState();
}

class _DoctorPlanDetailsSheetState extends State<_DoctorPlanDetailsSheet> {
  bool _isLoading = true;
  String? _error;
  List<TodayDietMealItem> _meals = const [];
  int _day = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.dataSource.getPlan(widget.plan.id, orgId: widget.orgId, fullHistory: widget.fullHistory);
      final raw = data['Meals'];
      if (!mounted) return;
      setState(() {
        _meals = raw is List
            ? raw.whereType<Map>().map((m) => TodayDietMealItem.fromJson(Map<String, dynamic>.from(m))).toList()
            : const [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = dietApiErrorMessage(e, "Couldn't load the plan's meals.");
      });
    }
  }

  int _minutes(String? time) {
    final match = RegExp(r'^(\d{1,2})[:.](\d{2})\s*([AaPp][Mm])?$').firstMatch((time ?? '').trim());
    if (match == null) return 24 * 60;
    var hour = int.parse(match.group(1)!);
    final period = match.group(3)?.toUpperCase();
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour * 60 + int.parse(match.group(2)!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plan = widget.plan;
    final strong = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    TextStyle ts(double size, FontWeight w, Color c) =>
        TextStyle(fontFamily: appPoppinFont, fontSize: size, fontWeight: w, color: c);

    final dayMeals = _meals.where((m) => m.dayNumber == _day).toList()
      ..sort((a, b) => _minutes(a.mealTime).compareTo(_minutes(b.mealTime)));
    final bySlot = <String, List<TodayDietMealItem>>{};
    for (final m in dayMeals) {
      bySlot.putIfAbsent(m.mealSlot, () => []).add(m);
    }
    final dayKcal = dayMeals.fold<int>(0, (sum, m) => sum + m.effectiveCalories);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.planName, maxLines: 2, softWrap: true, style: ts(16.5, FontWeight.w700, strong)),
                        Text(
                          '${plan.prescribedByLabelForDoctor} · ${plan.clinicName}',
                          maxLines: 2,
                          softWrap: true,
                          style: ts(12, FontWeight.w400, muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            if (plan.totalDays > 1)
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: plan.totalDays,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final selected = _day == i + 1;
                    return ChoiceChip(
                      label: Text('Day ${i + 1}', style: ts(12, FontWeight.w600, selected ? Colors.white : strong)),
                      selected: selected,
                      selectedColor: const Color(0xFF2563EB),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _day = i + 1),
                    );
                  },
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? RecordEmptyState(icon: Icons.cloud_off_rounded, title: _error!)
                  : ListView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      children: [
                        Text(
                          '$dayKcal kcal planned${plan.totalDays > 1 ? ' on Day $_day' : ' per day'}',
                          style: ts(12.5, FontWeight.w600, muted),
                        ),
                        const SizedBox(height: 10),
                        if (bySlot.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: RecordEmptyState(icon: Icons.no_meals_outlined, title: 'No meals on this day.'),
                          ),
                        for (final entry in bySlot.entries) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 6),
                            child: Text(
                              '${entry.key} · ${entry.value.first.mealTime ?? ''}',
                              style: ts(13.5, FontWeight.w700, strong),
                            ),
                          ),
                          for (final m in entry.value)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  DietFoodImage(
                                    imageUrl: m.imageUrl,
                                    category: m.category ?? '',
                                    foodType: m.foodType ?? '',
                                    size: 40,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m.foodName, style: ts(13, FontWeight.w600, strong)),
                                        Text(
                                          formatDietPortion(m.quantity, m.unit),
                                          style: ts(11.5, FontWeight.w400, muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    m.caloriesUnknown
                                        ? '— kcal'
                                        : '${m.caloriesEstimated ? '≈' : ''}${m.effectiveCalories} kcal',
                                    style: ts(12, FontWeight.w600, muted),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        if ((plan.doctorNotes ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text("Doctor's advice", style: ts(13.5, FontWeight.w700, strong)),
                          const SizedBox(height: 4),
                          Text(plan.doctorNotes!.trim(), style: ts(12.5, FontWeight.w400, muted)),
                        ],
                      ],
                    ),
            ),
            if (widget.canEdit)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: RecordPrimaryButton(
                      label: 'Edit Plan',
                      icon: Icons.edit_outlined,
                      onPressed: () => Navigator.pop(context, 'edit'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
