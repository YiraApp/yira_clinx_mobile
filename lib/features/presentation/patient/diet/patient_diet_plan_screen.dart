import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/custom_dialogue/app_dialog.dart';
import 'package:yiraclinics/features/data/data_sources/diet/diet_api_error.dart';
import 'package:yiraclinics/features/data/data_sources/diet/patient_diet_remote_data_source.dart';
import 'package:yiraclinics/features/data/models/diet/patient_diet_plan_model.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/diet_food_image.dart';
import 'package:yiraclinics/features/presentation/patient/diet/patient_diet_edit_screen.dart';
import 'package:yiraclinics/features/presentation/patient/diet/patient_diet_plans_screen.dart';

/// One meal slot on the selected date, with its foods in plan order.
class _DaySlot {
  final String name;
  final String time;
  final List<TodayDietMealItem> items;

  const _DaySlot(this.name, this.time, this.items);

  int get calories => items.fold(0, (sum, m) => sum + m.effectiveCalories);
}

/// The "Food Dashboard" for one diet plan: pick a date, see each meal, tick
/// off what was eaten and add a photo of it.
class PatientDietPlanScreen extends StatefulWidget {
  /// The plan to show. When null, the patient's active plan is shown.
  final int? planId;

  /// Kept for the existing route; the signed-in patient is always used.
  final String? patientId;

  /// For tests; the app uses the real API.
  final PatientDietRemoteDataSource? dataSource;

  const PatientDietPlanScreen({super.key, this.planId, this.patientId, this.dataSource});

  @override
  State<PatientDietPlanScreen> createState() => _PatientDietPlanScreenState();
}

class _PatientDietPlanScreenState extends State<PatientDietPlanScreen> {
  late final PatientDietRemoteDataSource _dataSource = widget.dataSource ?? PatientDietRemoteDataSource();
  final ScrollController _stripController = ScrollController();

  /// Meal photos are switched off for now; the backend support stays in place.
  static const bool _photoUploadEnabled = false;

  static const double _dayWidth = 46;
  static const double _daySpacing = 8;

  /// A meal stays "now" this long after its time, so it opens by default.
  static const int _nowWindowMinutes = 30;

  bool _isLoading = true;
  String? _error;
  bool _noActivePlan = false;

  TodayDietPlanInfo? _plan;
  List<TodayDietMealItem> _meals = const [];
  List<DateTime> _dates = const [];
  late DateTime _selected;

  /// Meal records by date key, then plan meal id.
  final Map<String, Map<int, DietMealLog>> _logs = {};
  final Set<String> _loadedDates = {};

  /// Slots opened on the selected date.
  final Set<String> _expanded = {};

  /// Foods with a toggle or upload in progress.
  final Set<int> _busyMeals = {};
  bool _isChangingStatus = false;

  static final DateFormat _monthTitle = DateFormat('MMMM yyyy');
  static final DateFormat _longDate = DateFormat('EEEE, d MMMM');

  @override
  void initState() {
    super.initState();
    _selected = _today;
    _load();
  }

  @override
  void dispose() {
    _stripController.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  // --- Loading ---

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      var planId = widget.planId ?? _plan?.id;
      if (planId == null) {
        final plans = await _dataSource.getMyPlans();
        final active = plans.where((p) => p.isActive);
        if (active.isEmpty) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _noActivePlan = true;
          });
          return;
        }
        planId = active.first.id;
      }

      final details = await _dataSource.getPlanDetails(planId);
      if (!mounted) return;
      if (details == null) {
        setState(() {
          _isLoading = false;
          _error = "We couldn't load this diet plan. Check your connection and try again.";
        });
        return;
      }

      final plan = TodayDietPlanInfo.fromPlanEntity(details);
      final rawMeals = details['Meals'];
      final meals = rawMeals is List
          ? rawMeals.whereType<Map>().map((m) => TodayDietMealItem.fromJson(Map<String, dynamic>.from(m))).toList()
          : <TodayDietMealItem>[];

      final dates = _buildDates(plan);
      final keepSelected = _dates.isNotEmpty && dates.any((d) => _sameDay(d, _selected));

      setState(() {
        _plan = plan;
        _meals = meals;
        _dates = dates;
        _noActivePlan = false;
        _error = null;
        _isLoading = false;
        if (!keepSelected) _selected = _initialDate(dates);
        _logs.clear();
        _loadedDates.clear();
        _resetExpanded();
      });

      _scrollToSelected(animate: false);
      await _ensureLogs(_selected);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = dietApiErrorMessage(e, "We couldn't load this diet plan. Pull down to try again.");
      });
    }
  }

  /// Every date of the plan, up to six months. Open-ended plans run two
  /// months past today.
  List<DateTime> _buildDates(TodayDietPlanInfo plan) {
    final startRaw = DateTime.tryParse(plan.startDate ?? '');
    final endRaw = DateTime.tryParse(plan.endDate ?? '');
    final start = startRaw != null ? DateTime(startRaw.year, startRaw.month, startRaw.day) : _today;
    var end = endRaw != null ? DateTime(endRaw.year, endRaw.month, endRaw.day) : _today.add(const Duration(days: 60));
    if (end.isBefore(start)) end = start;
    final count = (DateTime.utc(end.year, end.month, end.day).difference(DateTime.utc(start.year, start.month, start.day)).inDays + 1)
        .clamp(1, 183);
    return List.generate(count, (i) => DateTime(start.year, start.month, start.day + i));
  }

  DateTime _initialDate(List<DateTime> dates) {
    if (dates.isEmpty) return _today;
    if (_today.isBefore(dates.first)) return dates.first;
    if (_today.isAfter(dates.last)) return dates.last;
    return _today;
  }

  /// Loads meal records around [date] if they are not loaded yet.
  Future<void> _ensureLogs(DateTime date) async {
    final plan = _plan;
    if (plan == null || _dates.isEmpty) return;

    var from = date.subtract(const Duration(days: 10));
    var to = date.add(const Duration(days: 10));
    if (from.isBefore(_dates.first)) from = _dates.first;
    if (to.isAfter(_dates.last)) to = _dates.last;
    final lastLoggable = _today.add(const Duration(days: 1));
    if (to.isAfter(lastLoggable)) to = lastLoggable;
    if (to.isBefore(from)) return;

    final keys = <String>[];
    for (var d = from; !d.isAfter(to); d = DateTime(d.year, d.month, d.day + 1)) {
      keys.add(dietDateKey(d));
    }
    if (keys.every(_loadedDates.contains)) return;

    try {
      final logs = await _dataSource.getMealLogs(plan.id, from, to);
      if (!mounted || _plan?.id != plan.id) return;
      setState(() {
        _loadedDates.addAll(keys);
        for (final log in logs) {
          _logs.putIfAbsent(log.logDate, () => {})[log.planMealId] = log;
        }
      });
    } catch (e) {
      debugPrint('Diet meal logs could not be loaded: $e');
    }
  }

  // --- Day & slots ---

  int? get _rotationDay => _plan == null ? null : dietRotationDay(_plan!.startDate, _plan!.totalDays, _selected);

  int _minutes(String time) {
    final match = RegExp(r'^(\d{1,2})[:.](\d{2})\s*([AaPp][Mm])?$').firstMatch(time.trim());
    if (match == null) return 24 * 60;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)?.toUpperCase();
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  List<_DaySlot> get _slots {
    final day = _rotationDay;
    if (day == null) return const [];
    final bySlot = <String, List<TodayDietMealItem>>{};
    for (final m in _meals.where((m) => m.dayNumber == day)) {
      bySlot.putIfAbsent(m.mealSlot, () => []).add(m);
    }
    final slots = bySlot.entries.map((e) => _DaySlot(e.key, e.value.first.mealTime ?? '', e.value)).toList()
      ..sort((a, b) => _minutes(a.time).compareTo(_minutes(b.time)));
    return slots;
  }

  /// Opens the meal that is due now (or next) today, or the first meal.
  void _resetExpanded() {
    _expanded.clear();
    final slots = _slots;
    if (slots.isEmpty) return;
    if (_sameDay(_selected, _today)) {
      final now = TimeOfDay.now();
      final nowMinutes = now.hour * 60 + now.minute;
      for (final s in slots) {
        if (_minutes(s.time) >= nowMinutes - _nowWindowMinutes) {
          _expanded.add(s.name);
          return;
        }
      }
      _expanded.add(slots.last.name);
      return;
    }
    _expanded.add(slots.first.name);
  }

  void _selectDate(DateTime date) {
    if (_sameDay(date, _selected)) return;
    setState(() {
      _selected = date;
      _resetExpanded();
    });
    _scrollToSelected();
    _ensureLogs(date);
  }

  void _scrollToSelected({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_stripController.hasClients) return;
      final index = _dates.indexWhere((d) => _sameDay(d, _selected));
      if (index < 0) return;
      final viewport = _stripController.position.viewportDimension;
      final target = (index * (_dayWidth + _daySpacing) - (viewport - _dayWidth) / 2)
          .clamp(0.0, _stripController.position.maxScrollExtent);
      if (animate) {
        _stripController.animateTo(target, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
      } else {
        _stripController.jumpTo(target);
      }
    });
  }

  Future<void> _pickMonthDate() async {
    if (_dates.isEmpty) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: _dates.first,
      lastDate: _dates.last,
      helpText: 'Jump to a date',
    );
    if (picked != null) _selectDate(DateTime(picked.year, picked.month, picked.day));
  }

  // --- Meal tracking ---

  DietMealLog? _logFor(TodayDietMealItem meal) => _logs[dietDateKey(_selected)]?[meal.id];

  /// Why the selected date can't be tracked, or null when it can.
  String? get _trackingBlockedReason {
    final plan = _plan;
    if (plan == null) return 'This plan is still loading.';
    if (plan.status != 'active') return 'Turn this plan on to track your meals.';
    if (_selected.isAfter(_today)) return 'You can tick off meals on the day you eat them.';
    return null;
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

  Future<void> _setEaten(TodayDietMealItem meal, bool eaten) async {
    final blocked = _trackingBlockedReason;
    if (blocked != null) {
      _showMessage(blocked);
      return;
    }
    if (_busyMeals.contains(meal.id)) return;

    final key = dietDateKey(_selected);
    final date = _selected;
    final previous = _logFor(meal);
    setState(() {
      _busyMeals.add(meal.id);
      _logs.putIfAbsent(key, () => {})[meal.id] =
          previous?.copyWith(isEaten: eaten) ?? DietMealLog(planMealId: meal.id, logDate: key, isEaten: eaten);
    });

    try {
      final saved = await _dataSource.saveMealLog(planId: _plan!.id, planMealId: meal.id, date: date, isEaten: eaten);
      if (!mounted) return;
      setState(() => _logs.putIfAbsent(key, () => {})[meal.id] = saved);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (previous != null) {
          _logs[key]![meal.id] = previous;
        } else {
          _logs[key]?.remove(meal.id);
        }
      });
      _showMessage(dietApiErrorMessage(e, "Couldn't save that. Please try again."), color: DietUi.red);
    } finally {
      if (mounted) setState(() => _busyMeals.remove(meal.id));
    }
  }

  Future<void> _photoActions(TodayDietMealItem meal) async {
    final blocked = _trackingBlockedReason;
    final log = _logFor(meal);
    if (blocked != null && log?.photoUrl == null) {
      _showMessage(blocked);
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: DietUi.card(isDark),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: DietUi.line(isDark), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Text(meal.foodName, style: DietUi.text(16, FontWeight.w700, DietUi.strong(isDark))),
              Text('Add a photo of what you ate', style: DietUi.text(12, FontWeight.w400, DietUi.muted(isDark))),
              const SizedBox(height: 8),
              Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    if (log?.photoUrl != null) _sheetOption(ctx, isDark, 'view', Icons.photo_outlined, 'View photo'),
                    if (blocked == null) ...[
                      _sheetOption(ctx, isDark, 'camera', Icons.photo_camera_outlined, 'Take a photo'),
                      _sheetOption(ctx, isDark, 'gallery', Icons.photo_library_outlined, 'Choose from gallery'),
                    ],
                    if (log?.photoUrl != null && blocked == null)
                      _sheetOption(ctx, isDark, 'remove', Icons.delete_outline_rounded, 'Remove photo', color: DietUi.red),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case 'view':
        _viewPhoto(meal, log!.photoUrl!);
      case 'camera':
        _uploadPhoto(meal, ImageSource.camera);
      case 'gallery':
        _uploadPhoto(meal, ImageSource.gallery);
      case 'remove':
        _removePhoto(meal);
    }
  }

  Widget _sheetOption(BuildContext ctx, bool isDark, String value, IconData icon, String label, {Color? color}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? DietUi.blue),
      title: Text(label, style: DietUi.text(14, FontWeight.w500, color ?? DietUi.strong(isDark))),
      onTap: () => Navigator.pop(ctx, value),
    );
  }

  Future<void> _uploadPhoto(TodayDietMealItem meal, ImageSource source) async {
    XFile? photo;
    try {
      photo = await ImagePicker().pickImage(source: source, imageQuality: 75, maxWidth: 1600);
    } catch (e) {
      if (mounted) {
        _showMessage("Couldn't open the ${source == ImageSource.camera ? 'camera' : 'gallery'}. Check the app's permissions.");
      }
      return;
    }
    if (photo == null || !mounted) return;

    final key = dietDateKey(_selected);
    final date = _selected;
    setState(() => _busyMeals.add(meal.id));
    try {
      final saved = await _dataSource.uploadMealPhoto(
        planId: _plan!.id,
        planMealId: meal.id,
        date: date,
        filePath: photo.path,
      );
      if (!mounted) return;
      setState(() => _logs.putIfAbsent(key, () => {})[meal.id] = saved);
      _showMessage('Photo added and ${meal.foodName} marked as eaten.', color: DietUi.green);
    } catch (e) {
      if (mounted) _showMessage(dietApiErrorMessage(e, "Couldn't upload the photo. Please try again."), color: DietUi.red);
    } finally {
      if (mounted) setState(() => _busyMeals.remove(meal.id));
    }
  }

  Future<void> _removePhoto(TodayDietMealItem meal) async {
    final key = dietDateKey(_selected);
    final date = _selected;
    setState(() => _busyMeals.add(meal.id));
    try {
      final saved = await _dataSource.removeMealPhoto(planId: _plan!.id, planMealId: meal.id, date: date);
      if (!mounted) return;
      setState(() => _logs.putIfAbsent(key, () => {})[meal.id] = saved);
    } catch (e) {
      if (mounted) _showMessage(dietApiErrorMessage(e, "Couldn't remove the photo."), color: DietUi.red);
    } finally {
      if (mounted) setState(() => _busyMeals.remove(meal.id));
    }
  }

  void _viewPhoto(TodayDietMealItem meal, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, _) => const SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
                errorWidget: (_, _, _) => const SizedBox(
                  height: 280,
                  child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 40)),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 14,
              child: Text(meal.foodName, style: DietUi.text(14, FontWeight.w600, Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Plan actions ---

  Future<void> _turnOnPlan() async {
    final plan = _plan;
    if (plan == null || _isChangingStatus) return;
    final proceed = await AppDialog.confirm(
      context,
      title: 'Start "${plan.planName}"?',
      message: 'You follow one plan at a time. Any other active plan will be paused.',
      confirmLabel: 'Start Plan',
      tone: AppDialogTone.success,
      icon: Icons.play_circle_outline_rounded,
    );
    if (!proceed || !mounted) return;

    setState(() => _isChangingStatus = true);
    try {
      final message = await _dataSource.setMyPlanStatus(plan.id, 'active');
      if (!mounted) return;
      _showMessage(message, color: DietUi.green);
      await _load(showLoader: false);
    } catch (e) {
      if (mounted) _showMessage(dietApiErrorMessage(e, "Couldn't start this plan."), color: DietUi.red);
    } finally {
      if (mounted) setState(() => _isChangingStatus = false);
    }
  }

  Future<void> _pausePlan() async {
    final plan = _plan;
    if (plan == null || _isChangingStatus) return;
    final proceed = await AppDialog.confirm(
      context,
      title: 'Pause "${plan.planName}"?',
      message: "You won't see daily meals or reminders for it until you turn it back on.",
      confirmLabel: 'Pause Plan',
      tone: AppDialogTone.warning,
      icon: Icons.pause_circle_outline_rounded,
    );
    if (!proceed || !mounted) return;

    setState(() => _isChangingStatus = true);
    try {
      final message = await _dataSource.setMyPlanStatus(plan.id, 'paused');
      if (!mounted) return;
      _showMessage(message);
      await _load(showLoader: false);
    } catch (e) {
      if (mounted) _showMessage(dietApiErrorMessage(e, "Couldn't pause this plan."), color: DietUi.red);
    } finally {
      if (mounted) setState(() => _isChangingStatus = false);
    }
  }

  Future<void> _openEditor() async {
    final plan = _plan;
    if (plan == null) return;
    if (!plan.canEdit || !plan.createdByPatient) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor-prescribed diet plans cannot be modified by patients.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final saved = await PatientDietEditScreen.show(
      context,
      plan: plan,
      meals: _meals,
      initialDay: _rotationDay ?? plan.currentDayNumber,
    );
    if (saved == true && mounted) _load(showLoader: false);
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plan = _plan;
    final isActive = plan?.status.trim().toLowerCase() == 'active';

    return Scaffold(
      backgroundColor: DietUi.background(isDark),
      appBar: DietUi.appBar(
        context,
        isDark,
        title: plan?.planName ?? 'Diet Plan',
        subtitleWidget: plan == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DietUi.pill(
                      plan.createdByPatient ? 'Self-made' : 'Prescribed',
                      plan.createdByPatient ? DietUi.violet : DietUi.blue,
                      isDark,
                      icon: plan.createdByPatient ? Icons.person_rounded : Icons.verified_user_rounded,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        plan.createdByPatient
                            ? 'Day ${plan.currentDayNumber} of ${plan.totalDays}'
                            : 'Dr. ${plan.doctorName}',
                        maxLines: 1,
                        softWrap: true,
                        style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
                      ),
                    ),
                  ],
                ),
              ),
        actions: [
          if (plan != null && !_isLoading)
            DietUi.actionIcon(Icons.calendar_month_rounded, isDark, _pickMonthDate, tooltip: 'Jump to a date'),
          if (plan != null && plan.canEdit && plan.createdByPatient && !_isLoading)
            DietUi.actionIcon(Icons.edit_note_rounded, isDark, _openEditor, tooltip: 'Edit my plan'),
          if (plan != null && isActive && !_isLoading)
            DietUi.actionIcon(Icons.pause_circle_outline_rounded, isDark, _pausePlan, tooltip: 'Pause this plan'),
        ],
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) return _buildSkeleton(isDark);
    if (_noActivePlan) {
      return _buildMessage(
        isDark,
        icon: Icons.restaurant_menu_rounded,
        title: 'No active diet plan',
        message: 'Turn on one of your plans to see your daily meals here.',
        action: ElevatedButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PatientDietPlansScreen()),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: DietUi.blue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('See my plans', style: DietUi.text(13, FontWeight.w600, Colors.white)),
        ),
      );
    }
    if (_error != null || _plan == null) {
      return _buildMessage(
        isDark,
        icon: Icons.cloud_off_rounded,
        title: "Couldn't load the plan",
        message: _error ?? 'Please try again.',
        action: TextButton(onPressed: _load, child: const Text('Try again')),
      );
    }

    final plan = _plan!;
    final slots = _slots;
    final dayKcal = slots.fold<int>(0, (sum, s) => sum + s.calories);

    return Column(
      children: [
        _buildDateHeader(isDark),
        Expanded(
          child: RefreshIndicator(
            color: DietUi.blue,
            onRefresh: () => _load(showLoader: false),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (plan.status != 'active') ...[
                  _buildInactiveBanner(plan, isDark),
                  const SizedBox(height: 10),
                ],
                _buildSummaryCard(plan, slots, isDark),
                const SizedBox(height: 12),
                DietUi.sectionLabel(
                  'MEALS',
                  isDark,
                  trailing: slots.isEmpty
                      ? null
                      : Text(
                          '${slots.length} ${slots.length == 1 ? 'meal' : 'meals'} · $dayKcal kcal',
                          style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
                        ),
                ),
                const SizedBox(height: 8),
                if (slots.isEmpty)
                  _buildEmptyDay(isDark)
                else
                  for (final slot in slots) _buildSlotCard(slot, isDark),
                const SizedBox(height: 12),
                _buildDosDontsCard(plan, isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Compact strip under the app bar: the month and a scrollable row of dates.
  Widget _buildDateHeader(bool isDark) {
    final showToday = !_sameDay(_selected, _today) && _dates.any((d) => _sameDay(d, _today));

    return Container(
      decoration: BoxDecoration(
        color: DietUi.card(isDark),
        border: Border(bottom: BorderSide(color: DietUi.line(isDark))),
      ),
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        children: [
          SizedBox(
            height: 22,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _monthTitle.format(_selected),
                      style: DietUi.text(12, FontWeight.w700, DietUi.strong(isDark)),
                    ),
                  ),
                  if (showToday)
                    InkWell(
                      onTap: () => _selectDate(_today),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: DietUi.blue.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.today_rounded, size: 12, color: DietUi.blue),
                            const SizedBox(width: 4),
                            Text('Today', style: DietUi.text(10.5, FontWeight.w700, DietUi.blue)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 48,
            child: ListView.separated(
              controller: _stripController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _dates.length,
              separatorBuilder: (_, _) => const SizedBox(width: _daySpacing),
              itemBuilder: (_, i) {
                final date = _dates[i];
                final selected = _sameDay(date, _selected);
                final isToday = _sameDay(date, _today);

                return InkWell(
                  onTap: () => _selectDate(date),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _dayWidth,
                    decoration: BoxDecoration(
                      color: selected
                          ? DietUi.blue
                          : (isToday ? DietUi.blue.withValues(alpha: isDark ? 0.15 : 0.08) : DietUi.sunken(isDark)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? DietUi.blue
                            : (isToday ? DietUi.blue.withValues(alpha: 0.5) : DietUi.line(isDark)),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('EEE').format(date).toUpperCase(),
                          style: DietUi.text(
                            9,
                            FontWeight.w700,
                            selected ? Colors.white.withValues(alpha: 0.9) : (isToday ? DietUi.blue : DietUi.muted(isDark)),
                            spacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${date.day}',
                          style: DietUi.text(
                            14,
                            FontWeight.w700,
                            selected ? Colors.white : (isToday ? DietUi.blue : DietUi.strong(isDark)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveBanner(TodayDietPlanInfo plan, bool isDark) {
    final ended = DateTime.tryParse(plan.endDate ?? '')?.isBefore(_today) ?? false;
    final canStart = plan.status != 'cancelled' && !ended;
    final message = plan.status == 'cancelled'
        ? 'Your doctor stopped this plan. You can still look at the meals.'
        : ended
            ? 'This plan has ended. You can still look at the meals.'
            : 'This plan is paused. Start it to follow and track these meals.';

    return DietUi.notice(
      message,
      DietUi.amber,
      Icons.info_outline_rounded,
      isDark,
      action: canStart
          ? TextButton(
              onPressed: _isChangingStatus ? null : _turnOnPlan,
              child: _isChangingStatus
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Start', style: DietUi.text(12.5, FontWeight.w700, DietUi.blue)),
            )
          : null,
    );
  }

  Widget _buildSummaryCard(TodayDietPlanInfo plan, List<_DaySlot> slots, bool isDark) {
    final items = [for (final s in slots) ...s.items];
    final planned = items.fold<int>(0, (sum, m) => sum + m.effectiveCalories);
    final eatenItems = items.where((m) => _logFor(m)?.isEaten == true).toList();
    final eaten = eatenItems.fold<int>(0, (sum, m) => sum + m.effectiveCalories);
    final goal = (plan.targetCalories ?? 0) > 0 ? plan.targetCalories! : planned;
    final progress = goal > 0 ? (eaten / goal).clamp(0.0, 1.0) : 0.0;
    final remaining = (goal - eaten) < 0 ? 0 : goal - eaten;
    final unknown = items.where((m) => m.caloriesUnknown).length;
    final estimated = items.where((m) => m.caloriesEstimated).length;
    final day = _rotationDay;
    final isToday = _sameDay(_selected, _today);

    Widget stat(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: DietUi.text(10.5, FontWeight.w500, DietUi.muted(isDark))),
              const SizedBox(height: 2),
              Text(value, style: DietUi.text(13.5, FontWeight.w700, DietUi.strong(isDark))),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DietUi.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? "Today's intake" : _longDate.format(_selected),
                      style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$eaten', style: DietUi.text(22, FontWeight.w700, DietUi.strong(isDark))),
                        const SizedBox(width: 4),
                        Text('/ $goal kcal', style: DietUi.text(12, FontWeight.w600, DietUi.hint(isDark))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              DietUi.pill(
                '${eatenItems.length}/${items.length} eaten',
                eatenItems.isNotEmpty ? DietUi.green : DietUi.slate,
                isDark,
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: DietUi.blue.withValues(alpha: isDark ? 0.18 : 0.1),
              color: DietUi.blue,
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            children: [
              stat('Planned', '$planned kcal'),
              stat('Remaining', '$remaining kcal'),
              stat(plan.totalDays > 1 ? 'Rotation' : 'Menu', plan.totalDays > 1 && day != null ? 'Day $day of ${plan.totalDays}' : 'Daily'),
            ],
          ),
          if (!plan.createdByPatient) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
              decoration: BoxDecoration(
                color: DietUi.blue.withValues(alpha: isDark ? 0.14 : 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DietUi.blue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 13, color: DietUi.blue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Prescribed by Dr. ${plan.doctorName} · Clinical diet plan (view only)',
                      maxLines: 2,
                      softWrap: true,
                      style: DietUi.text(10.5, FontWeight.w500, isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (unknown > 0 || estimated > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 14, color: DietUi.hint(isDark)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      [
                        if (estimated > 0) '$estimated ${estimated == 1 ? 'food is' : 'foods are'} estimated from protein, carbs and fat',
                        if (unknown > 0) '$unknown ${unknown == 1 ? 'food has' : 'foods have'} no calorie info, so the total may be low',
                      ].join('. '),
                      style: DietUi.text(11, FontWeight.w400, DietUi.muted(isDark), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(_DaySlot slot, bool isDark) {
    final expanded = _expanded.contains(slot.name);
    final style = DietUi.slotStyle(slot.name);
    final eatenCount = slot.items.where((m) => _logFor(m)?.isEaten == true).length;
    final allEaten = eatenCount == slot.items.length && slot.items.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: DietUi.cardDecoration(isDark, borderColor: allEaten ? DietUi.green.withValues(alpha: 0.45) : null),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => expanded ? _expanded.remove(slot.name) : _expanded.add(slot.name)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: [
                    DietUi.iconBadge(style.icon, style.color, isDark, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot.name,
                            maxLines: 2,
                            softWrap: true,
                            style: DietUi.text(14.5, FontWeight.w700, DietUi.strong(isDark)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${slot.time.trim().isEmpty ? 'Any time' : slot.time} · $eatenCount/${slot.items.length} eaten',
                            maxLines: 2,
                            softWrap: true,
                            style: DietUi.text(11.5, FontWeight.w400, DietUi.muted(isDark)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    DietUi.pill('${slot.calories} kcal', DietUi.blue, isDark),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded, color: DietUi.muted(isDark)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    children: [
                      Divider(height: 1, color: DietUi.line(isDark)),
                      for (var i = 0; i < slot.items.length; i++) ...[
                        if (i > 0) Divider(height: 1, indent: 72, color: DietUi.line(isDark)),
                        _buildFoodRow(slot.items[i], isDark),
                      ],
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  String _fmtQty(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  Widget _buildFoodRow(TodayDietMealItem meal, bool isDark) {
    final log = _logFor(meal);
    final eaten = log?.isEaten == true;
    final busy = _busyMeals.contains(meal.id);
    final blocked = _trackingBlockedReason;
    final kcal = meal.effectiveCalories;
    final perUnit = meal.quantity > 0 ? (kcal / meal.quantity).round() : kcal;
    final kcalLine = meal.caloriesUnknown
        ? 'Calories not added'
        : '${_fmtQty(meal.quantity)} x $perUnit = ${meal.caloriesEstimated ? '≈ ' : ''}$kcal kcal';
    final weight = formatDietWeight(meal.weightAmount, meal.weightUnit);
    final portion = [formatDietPortion(meal.quantity, meal.unit), ?weight].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              DietFoodImage(imageUrl: meal.imageUrl, category: meal.category ?? '', foodType: meal.foodType ?? '', size: 46),
              if (eaten)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    decoration: BoxDecoration(color: DietUi.card(isDark), shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle_rounded, color: DietUi.green, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodName,
                  maxLines: 3,
                  softWrap: true,
                  style: DietUi.text(13.5, FontWeight.w600, DietUi.strong(isDark), height: 1.3),
                ),
                const SizedBox(height: 2),
                Text(
                  kcalLine,
                  style: DietUi.text(
                    11.5,
                    meal.caloriesUnknown ? FontWeight.w600 : FontWeight.w500,
                    meal.caloriesUnknown ? DietUi.amber : DietUi.body(isDark),
                  ),
                ),
                Text(portion, maxLines: 2, softWrap: true, style: DietUi.text(11, FontWeight.w400, DietUi.muted(isDark))),
                if ((meal.notes ?? '').trim().isNotEmpty)
                  Text(
                    meal.notes!.trim(),
                    maxLines: 3,
                    softWrap: true,
                    style: DietUi.text(11, FontWeight.w400, DietUi.muted(isDark)).copyWith(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: blocked == null ? 1 : 0.45,
                child: Transform.scale(
                  scale: 0.85,
                  child: Switch.adaptive(
                    value: eaten,
                    activeTrackColor: DietUi.blue,
                    onChanged: busy ? null : (v) => _setEaten(meal, v),
                  ),
                ),
              ),
              if (_photoUploadEnabled) _buildPhotoButton(meal, log, busy, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoButton(TodayDietMealItem meal, DietMealLog? log, bool busy, bool isDark) {
    if (busy) {
      return const SizedBox(
        width: 58,
        height: 26,
        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final photo = log?.photoUrl;
    if (photo != null) {
      return GestureDetector(
        onTap: () => _photoActions(meal),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: photo,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(width: 40, height: 40, color: DietUi.line(isDark)),
            errorWidget: (_, _, _) => Container(
              width: 40,
              height: 40,
              color: DietUi.line(isDark),
              child: Icon(Icons.image_not_supported_outlined, size: 18, color: DietUi.muted(isDark)),
            ),
          ),
        ),
      );
    }

    return TextButton.icon(
      onPressed: () => _photoActions(meal),
      style: TextButton.styleFrom(foregroundColor: DietUi.muted(isDark), visualDensity: VisualDensity.compact),
      icon: const Icon(Icons.upload_rounded, size: 14),
      label: Text('Upload', style: DietUi.text(10.5, FontWeight.w600, DietUi.muted(isDark))),
    );
  }

  Widget _buildEmptyDay(bool isDark) {
    final beforeStart = _rotationDay == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: DietUi.cardDecoration(isDark),
      child: Column(
        children: [
          DietUi.iconBadge(Icons.no_meals_rounded, DietUi.slate, isDark, size: 52, iconSize: 26),
          const SizedBox(height: 10),
          Text(
            beforeStart ? 'This plan has not started yet' : 'No meals planned for this day',
            style: DietUi.text(14, FontWeight.w700, DietUi.strong(isDark)),
          ),
          const SizedBox(height: 4),
          Text(
            beforeStart ? 'Your meals will show from the start date.' : 'Ask your doctor if you are unsure what to eat.',
            textAlign: TextAlign.center,
            style: DietUi.text(12, FontWeight.w400, DietUi.muted(isDark)),
          ),
        ],
      ),
    );
  }

  /// General guidance shown when the doctor gave no do's and don'ts of their own.
  static const List<String> _generalDos = [
    'Drink 8–10 glasses of water a day',
    'Eat your meals at regular times',
    'Add vegetables or salad to lunch and dinner',
    'Stay active: walk for 30 minutes a day',
  ];
  static const List<String> _generalDonts = [
    'Skip meals',
    'Have sugary drinks or sweets often',
    'Eat fried or junk food often',
    'Eat a heavy meal late at night',
  ];

  bool _showAllGuidance = false;

  /// Do's & Don'ts: the doctor's advice and the foods or habits to follow and
  /// avoid. Falls back to general tips, clearly labelled, when there are none.
  Widget _buildDosDontsCard(TodayDietPlanInfo plan, bool isDark) {
    final notes = (plan.doctorNotes ?? '').trim();
    final hasOwn = plan.foodsToPrefer.isNotEmpty || plan.foodsToAvoid.isNotEmpty;
    final dos = hasOwn ? plan.foodsToPrefer : _generalDos;
    final donts = hasOwn ? plan.foodsToAvoid : _generalDonts;
    const preview = 3;
    final hasMore = dos.length > preview || donts.length > preview;
    final shownDos = _showAllGuidance ? dos : dos.take(preview).toList();
    final shownDonts = _showAllGuidance ? donts : donts.take(preview).toList();

    Widget item(String text, bool isDo) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: (isDo ? DietUi.green : DietUi.red).withValues(alpha: isDark ? 0.22 : 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDo ? Icons.check_rounded : Icons.close_rounded,
                size: 11,
                color: isDo ? DietUi.green : DietUi.red,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                softWrap: true,
                style: DietUi.text(12.5, FontWeight.w500, DietUi.strong(isDark), height: 1.38),
              ),
            ),
          ],
        ),
      );
    }

    Widget group({
      required String title,
      required String subtitle,
      required Color color,
      required List<String> items,
      required bool isDo,
      required IconData icon,
    }) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.22),
            width: 1.1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: DietUi.text(13, FontWeight.w800, color, spacing: 0.2),
                      ),
                      Text(
                        subtitle,
                        style: DietUi.text(10.5, FontWeight.w500, color.withValues(alpha: 0.85)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${items.length}',
                    style: DietUi.text(10.5, FontWeight.w700, color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Divider(color: color.withValues(alpha: 0.15), height: 8),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('None specified', style: DietUi.text(11.5, FontWeight.w400, DietUi.muted(isDark))),
              )
            else
              for (final t in items) item(t, isDo),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: DietUi.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DietUi.iconBadge(Icons.health_and_safety_rounded, DietUi.blue, isDark, size: 34, iconSize: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Do's & Don'ts", style: DietUi.text(14.5, FontWeight.w700, DietUi.strong(isDark))),
                    Text(
                      hasOwn
                          ? (plan.createdByPatient ? 'Personal dietary guidelines' : 'Doctor-recommended guidance')
                          : 'General nutritional recommendations',
                      style: DietUi.text(11, FontWeight.w400, DietUi.muted(isDark)),
                    ),
                  ],
                ),
              ),
              if (!hasOwn)
                DietUi.pill('General', DietUi.slate, isDark)
              else if (!plan.createdByPatient)
                DietUi.pill('Prescribed', DietUi.blue, isDark, icon: Icons.verified_user_rounded),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DietUi.blue.withValues(alpha: isDark ? 0.12 : 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DietUi.blue.withValues(alpha: isDark ? 0.25 : 0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, size: 16, color: DietUi.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.createdByPatient ? 'My Notes' : "Doctor's Advice",
                          style: DietUi.text(11, FontWeight.w700, DietUi.blue),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          notes,
                          softWrap: true,
                          style: DietUi.text(12, FontWeight.w400, DietUi.body(isDark), height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (_, constraints) {
              if (constraints.maxWidth < 500) {
                return Column(
                  children: [
                    group(
                      title: "DO'S",
                      subtitle: 'Foods to prefer',
                      color: DietUi.green,
                      items: shownDos,
                      isDo: true,
                      icon: Icons.thumb_up_alt_rounded,
                    ),
                    const SizedBox(height: 10),
                    group(
                      title: "DON'TS",
                      subtitle: 'Foods to avoid',
                      color: DietUi.red,
                      items: shownDonts,
                      isDo: false,
                      icon: Icons.thumb_down_alt_rounded,
                    ),
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: group(
                        title: "DO'S",
                        subtitle: 'Foods to prefer',
                        color: DietUi.green,
                        items: shownDos,
                        isDo: true,
                        icon: Icons.thumb_up_alt_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: group(
                        title: "DON'TS",
                        subtitle: 'Foods to avoid',
                        color: DietUi.red,
                        items: shownDonts,
                        isDo: false,
                        icon: Icons.thumb_down_alt_rounded,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (hasMore) ...[
            const SizedBox(height: 8),
            Center(
              child: InkWell(
                onTap: () => setState(() => _showAllGuidance = !_showAllGuidance),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: DietUi.blue.withValues(alpha: isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showAllGuidance ? 'Show less' : 'View all items (${dos.length + donts.length})',
                        style: DietUi.text(11.5, FontWeight.w700, DietUi.blue),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showAllGuidance ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: DietUi.blue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessage(bool isDark, {required IconData icon, required String title, required String message, Widget? action}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: DietUi.cardDecoration(isDark),
          child: Column(
            children: [
              DietUi.iconBadge(icon, DietUi.blue, isDark, size: 60, iconSize: 28),
              const SizedBox(height: 14),
              Text(title, style: DietUi.text(15.5, FontWeight.w700, DietUi.strong(isDark))),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center, style: DietUi.text(12.5, FontWeight.w400, DietUi.muted(isDark), height: 1.45)),
              if (action != null) ...[const SizedBox(height: 12), action],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton(bool isDark) {
    Widget block(double height, {EdgeInsets margin = const EdgeInsets.fromLTRB(16, 0, 16, 12)}) => Container(
          height: height,
          margin: margin,
          decoration: BoxDecoration(
            color: DietUi.card(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DietUi.line(isDark)),
          ),
        );
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [block(150), block(64), block(64), block(64)],
    );
  }
}
