import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/custom_dialogue/app_dialog.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/features/data/data_sources/diet/diet_api_error.dart';
import 'package:yiraclinics/features/data/data_sources/diet/patient_diet_remote_data_source.dart';
import 'package:yiraclinics/features/data/models/diet/patient_diet_plan_model.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/diet_food_image.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/diet_food_picker_sheet.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/doctor_prescribe_diet_sheet.dart'
    show DoctorMealItemInput;

/// Lets a patient adjust their own active diet plan: change portions, swap or
/// remove foods, add foods to a meal, and add notes. In create mode the
/// patient builds a brand-new plan for themselves. Pops `true` once saved.
class PatientDietEditScreen extends StatefulWidget {
  final TodayDietPlanInfo plan;
  final List<TodayDietMealItem> meals;
  final int initialDay;
  final bool createMode;

  const PatientDietEditScreen({
    super.key,
    required this.plan,
    required this.meals,
    this.initialDay = 1,
    this.createMode = false,
  });

  /// Opens an empty plan for the patient to build without a prescription.
  static Future<bool?> create(BuildContext context) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PatientDietEditScreen(
          createMode: true,
          meals: const [],
          plan: TodayDietPlanInfo(
            id: 0,
            planName: '',
            doctorName: 'You',
            organizationName: '',
            totalDays: 1,
            currentDayNumber: 1,
            canEdit: true,
            createdByPatient: true,
          ),
        ),
      ),
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required TodayDietPlanInfo plan,
    required List<TodayDietMealItem> meals,
    int initialDay = 1,
  }) {
    if (!plan.createdByPatient) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor-prescribed diet plans cannot be modified by patients.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return Future.value(null);
    }
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PatientDietEditScreen(plan: plan, meals: meals, initialDay: initialDay),
      ),
    );
  }

  @override
  State<PatientDietEditScreen> createState() => _PatientDietEditScreenState();
}

class _PatientDietEditScreenState extends State<PatientDietEditScreen> {
  final PatientDietRemoteDataSource _dataSource = PatientDietRemoteDataSource();

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _amberOrange = Color(0xFFF59E0B);
  static const Color _roseRed = Color(0xFFEF4444);

  static const double _maxQuantity = 99;
  static const int _maxNameLength = 200;
  static const int _maxNotesLength = 500;

  static const List<({String name, String time})> _standardSlots = [
    (name: 'Early Morning', time: '06:30 AM'),
    (name: 'Breakfast', time: '08:30 AM'),
    (name: 'Mid-Morning', time: '11:00 AM'),
    (name: 'Lunch', time: '01:30 PM'),
    (name: 'Evening Snack', time: '05:00 PM'),
    (name: 'Dinner', time: '08:00 PM'),
    (name: 'Bedtime', time: '10:00 PM'),
  ];

  late List<DoctorMealItemInput> _meals;
  late final String _originalSignature;
  late int _selectedDay;

  /// Meals that failed validation, with the reason shown under each one.
  final Map<DoctorMealItemInput, String> _errors = {};

  /// Slots added during this edit that have no food yet, per day.
  final Map<int, List<({String name, String time})>> _pendingSlots = {};

  bool _isSaving = false;

  late int _totalDays;

  // Create mode: the plan's own details.
  static const int _maxCreateDays = 7;
  static const List<({String label, int? days})> _durations = [
    (label: '1 week', days: 7),
    (label: '2 weeks', days: 14),
    (label: '1 month', days: 30),
    (label: '3 months', days: 90),
    (label: 'No end date', days: null),
  ];
  static const List<String> _dietTypes = ['Veg', 'Non-Veg', 'Eggetarian', 'Vegan'];
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _goalCtrl = TextEditingController();
  String _dietType = 'Veg';
  late DateTime _startDate;
  int? _durationDays = 30;
  String? _nameError;

  bool get _isCreate => widget.createMode;

  @override
  void initState() {
    super.initState();
    _totalDays = widget.plan.totalDays < 1 ? 1 : widget.plan.totalDays;
    _meals = widget.meals.map(_fromPlanItem).toList();
    _originalSignature = _signature();
    _selectedDay = widget.initialDay.clamp(1, _totalDays);
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    if (_isCreate) {
      _pendingSlots[1] = [_standardSlots[1], _standardSlots[3], _standardSlots[5]];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  DoctorMealItemInput _fromPlanItem(TodayDietMealItem m) {
    return DoctorMealItemInput(
      dayNumber: m.dayNumber,
      mealSlot: m.mealSlot,
      mealTime: (m.mealTime ?? '').trim().isEmpty ? _defaultTime(m.mealSlot) : m.mealTime!,
      foodItemId: m.foodItemId,
      foodName: m.foodName,
      quantity: m.quantity,
      unit: m.unit,
      weightAmount: m.weightAmount,
      weightUnit: m.weightUnit,
      calories: m.effectiveCalories,
      proteinG: m.proteinG,
      carbsG: m.carbsG,
      fatG: m.fatG,
      notes: m.notes,
      imageUrl: m.imageUrl,
      category: m.category,
      foodType: m.foodType,
    );
  }

  String _defaultTime(String slot) {
    for (final s in _standardSlots) {
      if (s.name.toLowerCase() == slot.toLowerCase()) return s.time;
    }
    return '12:00 PM';
  }

  String _signature() => _orderedMeals()
      .map((m) => m.toJson(m.dayNumber, 0).toString())
      .join('|');

  bool get _isDirty =>
      _signature() != _originalSignature || (_isCreate && (_nameCtrl.text.trim().isNotEmpty || _goalCtrl.text.trim().isNotEmpty));

  // --- Ordering ---

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

  List<DoctorMealItemInput> _orderedMeals() {
    final indexed = _meals.asMap().entries.toList()
      ..sort((a, b) {
        final byDay = a.value.dayNumber.compareTo(b.value.dayNumber);
        if (byDay != 0) return byDay;
        final byTime = _minutes(a.value.mealTime).compareTo(_minutes(b.value.mealTime));
        return byTime != 0 ? byTime : a.key.compareTo(b.key);
      });
    return indexed.map((e) => e.value).toList();
  }

  /// The selected day's slots in time order, including empty ones just added.
  List<({String name, String time, List<DoctorMealItemInput> items})> _slotsForDay(int day) {
    final bySlot = <String, List<DoctorMealItemInput>>{};
    final times = <String, String>{};
    for (final m in _meals.where((m) => m.dayNumber == day)) {
      bySlot.putIfAbsent(m.mealSlot, () => []).add(m);
      times.putIfAbsent(m.mealSlot, () => m.mealTime);
    }
    for (final pending in _pendingSlots[day] ?? const <({String name, String time})>[]) {
      bySlot.putIfAbsent(pending.name, () => []);
      times.putIfAbsent(pending.name, () => pending.time);
    }
    final slots = bySlot.entries
        .map((e) => (name: e.key, time: times[e.key] ?? '', items: e.value))
        .toList()
      ..sort((a, b) => _minutes(a.time).compareTo(_minutes(b.time)));
    return slots;
  }

  ({int calories, double protein, double carbs, double fat}) _dayTotals(int day) {
    var calories = 0;
    double protein = 0, carbs = 0, fat = 0;
    for (final m in _meals.where((m) => m.dayNumber == day)) {
      calories += m.calories;
      protein += m.proteinG ?? 0;
      carbs += m.carbsG ?? 0;
      fat += m.fatG ?? 0;
    }
    return (calories: calories, protein: protein, carbs: carbs, fat: fat);
  }

  // --- Editing ---

  double _round1(double v) => (v * 10).round() / 10;

  /// Changes a portion and scales its nutrition (and weight) to match.
  void _setQuantity(DoctorMealItemInput item, double quantity) {
    final next = _round1(quantity.clamp(0.5, _maxQuantity).toDouble());
    if (next == item.quantity) return;
    final factor = item.quantity > 0 ? next / item.quantity : 1.0;
    setState(() {
      item.quantity = next;
      item.calories = (item.calories * factor).round();
      if (item.proteinG != null) item.proteinG = _round1(item.proteinG! * factor);
      if (item.carbsG != null) item.carbsG = _round1(item.carbsG! * factor);
      if (item.fatG != null) item.fatG = _round1(item.fatG! * factor);
      if (item.weightAmount != null) item.weightAmount = _round1(item.weightAmount! * factor);
      _errors.remove(item);
    });
  }

  Future<void> _removeItem(DoctorMealItemInput item) async {
    final slotCount = _meals.where((m) => m.dayNumber == item.dayNumber && m.mealSlot == item.mealSlot).length;
    final dayCount = _meals.where((m) => m.dayNumber == item.dayNumber).length;
    if (_meals.length == 1 && !_isCreate) {
      _showMessage('Your plan needs at least one food. Add another food before removing this one.', color: _roseRed);
      return;
    }
    if (dayCount == 1 && !_isCreate) {
      final proceed = await AppDialog.confirm(
        context,
        title: 'Remove the last food of the day?',
        message: _totalDays > 1
            ? 'Day ${item.dayNumber} will have no meals.'
            : 'You will have no meals planned.',
        confirmLabel: 'Remove',
        tone: AppDialogTone.danger,
        icon: Icons.delete_outline_rounded,
      );
      if (!proceed || !mounted) return;
    }
    setState(() {
      _meals.remove(item);
      _errors.remove(item);
      if (slotCount == 1) {
        // Keep the slot on screen so a replacement can be added straight away.
        final pending = _pendingSlots.putIfAbsent(item.dayNumber, () => []);
        if (!pending.any((p) => p.name == item.mealSlot)) {
          pending.add((name: item.mealSlot, time: item.mealTime));
        }
      }
    });
    _showMessage('Removed ${item.foodName}.');
  }

  String get _orgId {
    final orgId = GlobalSession.instance.userNotifier.value?.data?.latestOrgId;
    return orgId?.toString() ?? '';
  }

  String get _authToken => GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';

  /// Opens the food picker to add a food to [slotName], or to change [existing].
  Future<void> _openPicker(String slotName, String slotTime, {DoctorMealItemInput? existing}) {
    final day = _selectedDay;
    return DietFoodPickerSheet.show(
      context,
      slotName: slotName,
      slotTime: slotTime,
      dayLabel: _totalDays > 1 ? 'Day $day' : null,
      existingItem: existing,
      authToken: _authToken,
      orgId: _orgId,
      allowSaveToList: false,
      onSubmit: (item) {
        if (!mounted) return;
        item.dayNumber = day;
        setState(() {
          if (existing != null) {
            final index = _meals.indexOf(existing);
            if (index != -1) _meals[index] = item;
            _errors.remove(existing);
          } else {
            _meals.add(item);
          }
          _pendingSlots[day]?.removeWhere((p) => p.name == slotName);
        });
      },
    );
  }

  void _addSlot(({String name, String time}) slot) {
    setState(() {
      _pendingSlots.putIfAbsent(_selectedDay, () => []).add(slot);
    });
    _openPicker(slot.name, slot.time);
  }

  // --- Validation & saving ---

  /// Returns the first problem, after marking every bad item on screen.
  String? _validate() {
    _errors.clear();
    if (_meals.isEmpty) return 'Your plan needs at least one food.';

    for (final m in _meals) {
      final name = m.foodName.trim();
      String? error;
      if (name.isEmpty) {
        error = 'Food name is missing.';
      } else if (name.length > _maxNameLength) {
        error = 'Food name is too long.';
      } else if (!(m.quantity > 0)) {
        error = 'Quantity must be more than 0.';
      } else if (m.quantity > _maxQuantity) {
        error = 'Quantity can be at most ${_maxQuantity.toInt()}.';
      } else if (m.calories < 0 || (m.proteinG ?? 0) < 0 || (m.carbsG ?? 0) < 0 || (m.fatG ?? 0) < 0) {
        error = 'Nutrition values cannot be negative.';
      } else if ((m.notes ?? '').length > _maxNotesLength) {
        error = 'Note can be at most $_maxNotesLength characters.';
      }
      if (error != null) _errors[m] = error;
    }

    if (_errors.isEmpty) return null;
    final first = _orderedMeals().firstWhere(_errors.containsKey);
    _selectedDay = first.dayNumber;
    final where = _totalDays > 1 ? 'Day ${first.dayNumber}, ${first.mealSlot}' : first.mealSlot;
    return '$where: ${_errors[first]}';
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_isCreate) {
      final name = _nameCtrl.text.trim();
      final nameError = name.isEmpty
          ? 'Give your plan a name'
          : (name.length > 200 ? 'Keep the name under 200 characters' : null);
      setState(() => _nameError = nameError);
      if (nameError != null) {
        _showMessage(nameError, color: _roseRed);
        return;
      }
      if (_goalCtrl.text.trim().length > 100) {
        _showMessage('Keep the goal under 100 characters.', color: _roseRed);
        return;
      }
    }
    final problem = _validate();
    setState(() {});
    if (problem != null) {
      _showMessage(problem, color: _roseRed);
      return;
    }

    final emptyDays = [
      for (var d = 1; d <= _totalDays; d++)
        if (!_meals.any((m) => m.dayNumber == d)) d,
    ];
    if (emptyDays.isNotEmpty) {
      final proceed = await AppDialog.confirm(
        context,
        title: 'Some days have no meals',
        message: '${emptyDays.length == 1 ? 'Day' : 'Days'} ${emptyDays.join(', ')} '
            '${emptyDays.length == 1 ? 'has' : 'have'} no meals. Save anyway?',
        confirmLabel: 'Save Anyway',
        cancelLabel: 'Keep Editing',
        tone: AppDialogTone.warning,
        icon: Icons.warning_amber_rounded,
      );
      if (!proceed || !mounted) return;
    }

    setState(() => _isSaving = true);
    try {
      final ordered = _orderedMeals();
      final payload = [
        for (var i = 0; i < ordered.length; i++) ordered[i].toJson(ordered[i].dayNumber, i + 1),
      ];
      if (_isCreate) {
        String date(DateTime d) =>
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        await _dataSource.createMyPlan({
          'planName': _nameCtrl.text.trim(),
          'condition': _goalCtrl.text.trim(),
          'dietType': _dietType,
          'totalDays': _totalDays,
          'startDate': date(_startDate),
          if (_durationDays != null) 'endDate': date(_startDate.add(Duration(days: _durationDays! - 1))),
          'activate': true,
          'meals': payload,
        });
      } else {
        await _dataSource.updateMyPlan(widget.plan.id, payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isCreate ? 'Your plan is ready and active.' : 'Your diet plan has been updated.',
            style: const TextStyle(fontFamily: appPoppinFont),
          ),
          backgroundColor: _emeraldGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showMessage(
        dietApiErrorMessage(e, _isCreate ? "Couldn't create your plan. Please try again." : "Couldn't save your changes. Please try again."),
        color: _roseRed,
      );
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    return AppDialog.confirm(
      context,
      title: 'Discard your changes?',
      message: 'The changes you made to your diet plan have not been saved.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep Editing',
      tone: AppDialogTone.danger,
      icon: Icons.warning_amber_rounded,
    );
  }

  void _showMessage(String message, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12.5)),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  // --- Styling helpers ---

  Color _cardColor(bool isDark) => isDark ? const Color(0xFF1E293B) : Colors.white;
  Color _borderColor(bool isDark) => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  Color _textPrimary(bool isDark) => isDark ? Colors.white : const Color(0xFF0F172A);
  Color _textSecondary(bool isDark) => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  TextStyle _ts(double size, FontWeight weight, Color color, {double? height}) =>
      TextStyle(fontFamily: appPoppinFont, fontSize: size, fontWeight: weight, color: color, height: height);

  String _fmt(double v) => v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_isDirty || _isSaving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard() && mounted) navigator.pop(false);
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: _cardColor(isDark),
          toolbarHeight: 56,
          leadingWidth: 48,
          titleSpacing: 6,
          centerTitle: false,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _borderColor(isDark),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(19),
                    onTap: () => Navigator.maybePop(context),
                    child: Center(
                      child: Icon(Icons.close_rounded, size: 18, color: _textPrimary(isDark)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_isCreate ? 'Create My Plan' : 'Edit My Plan', style: _ts(17, FontWeight.w700, _textPrimary(isDark))),
              const SizedBox(height: 2),
              Text(
                _isCreate ? 'Plan your own meals' : widget.plan.planName,
                maxLines: 2,
                softWrap: true,
                style: _ts(11.5, FontWeight.w500, _textSecondary(isDark)),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: _borderColor(isDark),
              height: 1,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  _buildInfoBanner(isDark),
                  const SizedBox(height: 14),
                  if (_isCreate) ...[
                    _buildDetailsCard(isDark),
                    const SizedBox(height: 14),
                  ],
                  if (_isCreate) ...[
                    _buildRotationRow(isDark),
                    const SizedBox(height: 10),
                  ],
                  if (_totalDays > 1) ...[
                    _buildDayStrip(isDark),
                    const SizedBox(height: 14),
                  ],
                  _buildTotals(isDark),
                  const SizedBox(height: 16),
                  ..._buildSlots(isDark),
                  _buildAddSlotRow(isDark),
                ],
              ),
            ),
            _buildBottomBar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primaryBlue.withValues(alpha: isDark ? 0.16 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: isDark ? const Color(0xFF93C5FD) : _primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isCreate
                  ? 'Build a plan for yourself. It is private to you and becomes your active plan. '
                      'If you have a health condition, check with your doctor first.'
                  : widget.plan.createdByPatient
                      ? 'Adjust portions, swap or remove foods, and add notes.'
                      : 'Adjust portions, swap or remove foods, and add notes. Dr. ${widget.plan.doctorName} '
                          'can see the changes you save. Check with your doctor before big changes.',
              style: _ts(11.5, FontWeight.w500, isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E3A8A), height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickStartDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 1, today.month, today.day),
      helpText: 'Plan starts on',
    );
    if (picked != null) setState(() => _startDate = DateTime(picked.year, picked.month, picked.day));
  }

  Widget _chip(String label, bool selected, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _primaryBlue.withValues(alpha: isDark ? 0.25 : 0.1) : _cardColor(isDark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _primaryBlue : _borderColor(isDark), width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: _ts(12, selected ? FontWeight.w700 : FontWeight.w500, selected ? _primaryBlue : _textPrimary(isDark)),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(bool isDark, String hint, {String? error}) {
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: c, width: w));
    return InputDecoration(
      hintText: hint,
      errorText: error,
      hintStyle: _ts(12.5, FontWeight.w400, _textSecondary(isDark)),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: border(_borderColor(isDark)),
      enabledBorder: border(_borderColor(isDark)),
      focusedBorder: border(_primaryBlue, 1.5),
      errorBorder: border(_roseRed),
      focusedErrorBorder: border(_roseRed, 1.5),
    );
  }

  /// Create mode: name, goal, diet type, start date and how long to follow it.
  Widget _buildDetailsCard(bool isDark) {
    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 12),
          child: Text(text, style: _ts(11.5, FontWeight.w600, _textSecondary(isDark))),
        );
    final end = _durationDays == null ? null : _startDate.add(Duration(days: _durationDays! - 1));

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      decoration: BoxDecoration(
        color: _cardColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label('Plan name *'),
          TextField(
            controller: _nameCtrl,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            style: _ts(13.5, FontWeight.w500, _textPrimary(isDark)),
            decoration: _fieldDecoration(isDark, 'e.g. My weight loss plan', error: _nameError).copyWith(counterText: ''),
            onChanged: (_) => setState(() => _nameError = null),
          ),
          label('Goal (optional)'),
          TextField(
            controller: _goalCtrl,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            style: _ts(13.5, FontWeight.w500, _textPrimary(isDark)),
            decoration: _fieldDecoration(isDark, 'e.g. Lose weight, eat more protein').copyWith(counterText: ''),
            onChanged: (_) => setState(() {}),
          ),
          label('Diet type'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _dietTypes) _chip(t, _dietType == t, isDark, () => setState(() => _dietType = t)),
            ],
          ),
          label('Starts on'),
          InkWell(
            onTap: _pickStartDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor(isDark)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: _primaryBlue),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_fmtDate(_startDate), style: _ts(13.5, FontWeight.w600, _textPrimary(isDark)))),
                  Text('Change', style: _ts(12, FontWeight.w700, _primaryBlue)),
                ],
              ),
            ),
          ),
          label('Follow it for'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in _durations) _chip(d.label, _durationDays == d.days, isDark, () => setState(() => _durationDays = d.days)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            end == null ? 'No end date. Pause it any time.' : 'Ends on ${_fmtDate(end)}',
            style: _ts(11.5, FontWeight.w500, _textSecondary(isDark)),
          ),
        ],
      ),
    );
  }

  /// Create mode: how many different daily menus the plan cycles through.
  Widget _buildRotationRow(bool isDark) {
    Future<void> change(int next) async {
      if (next < 1 || next > _maxCreateDays) return;
      if (next < _totalDays) {
        final dropped = _meals.where((m) => m.dayNumber > next).length;
        if (dropped > 0) {
          final proceed = await AppDialog.confirm(
            context,
            title: 'Remove Day $_totalDays?',
            message: 'Its $dropped food(s) will be removed.',
            confirmLabel: 'Remove',
            tone: AppDialogTone.danger,
            icon: Icons.delete_outline_rounded,
          );
          if (!proceed || !mounted) return;
        }
      }
      setState(() {
        _meals.removeWhere((m) => m.dayNumber > next);
        _pendingSlots.removeWhere((day, _) => day > next);
        if (next > _totalDays) {
          for (var d = _totalDays + 1; d <= next; d++) {
            _pendingSlots[d] = [_standardSlots[1], _standardSlots[3], _standardSlots[5]];
          }
        }
        _totalDays = next;
        if (_selectedDay > next) _selectedDay = next;
      });
    }

    Widget stepButton(IconData icon, VoidCallback? onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: onTap == null ? _borderColor(isDark) : _primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: onTap == null ? _textSecondary(isDark) : _primaryBlue),
          ),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _cardColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(isDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily menus', style: _ts(13, FontWeight.w700, _textPrimary(isDark))),
                Text(
                  _totalDays == 1 ? 'Same meals every day' : 'Repeats every $_totalDays days',
                  style: _ts(11.5, FontWeight.w400, _textSecondary(isDark)),
                ),
              ],
            ),
          ),
          stepButton(Icons.remove_rounded, _totalDays > 1 ? () => change(_totalDays - 1) : null),
          SizedBox(
            width: 34,
            child: Text('$_totalDays', textAlign: TextAlign.center, style: _ts(15, FontWeight.w800, _textPrimary(isDark))),
          ),
          stepButton(Icons.add_rounded, _totalDays < _maxCreateDays ? () => change(_totalDays + 1) : null),
        ],
      ),
    );
  }

  Widget _buildDayStrip(bool isDark) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _totalDays,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final day = i + 1;
          final selected = day == _selectedDay;
          final isToday = day == widget.plan.currentDayNumber;
          final hasError = _errors.keys.any((m) => m.dayNumber == day);
          final isEmpty = !_meals.any((m) => m.dayNumber == day);
          final Color border = selected
              ? _primaryBlue
              : hasError
                  ? _roseRed
                  : _borderColor(isDark);

          return InkWell(
            onTap: () => setState(() => _selectedDay = day),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 64,
              decoration: BoxDecoration(
                color: selected ? _primaryBlue : _cardColor(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: selected || hasError ? 1.5 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? 'TODAY' : 'DAY',
                    style: _ts(9.5, FontWeight.w700, selected ? Colors.white70 : _textSecondary(isDark)),
                  ),
                  Text(
                    '$day',
                    style: _ts(17, FontWeight.w800, selected ? Colors.white : _textPrimary(isDark)),
                  ),
                  if (isEmpty || hasError)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: hasError ? _roseRed : _amberOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotals(bool isDark) {
    final totals = _dayTotals(_selectedDay);
    final plan = widget.plan;

    Widget tile(String label, String value, num? target, String unit, Color color) {
      return Expanded(
        child: Column(
          children: [
            Text(label, style: _ts(10.5, FontWeight.w600, _textSecondary(isDark))),
            const SizedBox(height: 2),
            Text(value, style: _ts(14, FontWeight.w800, color)),
            if (target != null && target > 0)
              Text('of ${_fmt(target.toDouble())}$unit', style: _ts(9.5, FontWeight.w500, _textSecondary(isDark))),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: _cardColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(isDark)),
      ),
      child: Row(
        children: [
          tile('Calories', '${totals.calories}', plan.targetCalories, ' kcal', _primaryBlue),
          tile('Protein', '${_fmt(_round1(totals.protein))}g', plan.targetProteinG, 'g', _emeraldGreen),
          tile('Carbs', '${_fmt(_round1(totals.carbs))}g', plan.targetCarbsG, 'g', _amberOrange),
          tile('Fat', '${_fmt(_round1(totals.fat))}g', plan.targetFatG, 'g', _roseRed),
        ],
      ),
    );
  }

  List<Widget> _buildSlots(bool isDark) {
    final slots = _slotsForDay(_selectedDay);
    if (slots.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: _cardColor(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor(isDark)),
          ),
          child: Column(
            children: [
              Icon(Icons.no_meals_rounded, size: 32, color: _textSecondary(isDark)),
              const SizedBox(height: 8),
              Text(
                'No meals planned for this day. Add a meal below.',
                textAlign: TextAlign.center,
                style: _ts(12.5, FontWeight.w500, _textSecondary(isDark)),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      for (final slot in slots)
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: _cardColor(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: slot.items.any(_errors.containsKey) ? _roseRed : _borderColor(isDark),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(slot.name, style: _ts(13.5, FontWeight.w700, _textPrimary(isDark))),
                    ),
                    Icon(Icons.schedule_rounded, size: 13, color: _textSecondary(isDark)),
                    const SizedBox(width: 4),
                    Text(slot.time, style: _ts(11.5, FontWeight.w600, _textSecondary(isDark))),
                  ],
                ),
              ),
              if (slot.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                  child: Text('No food yet.', style: _ts(11.5, FontWeight.w500, _textSecondary(isDark))),
                ),
              for (final item in slot.items) _buildItemRow(item, slot.name, slot.time, isDark),
              InkWell(
                onTap: () => _openPicker(slot.name, slot.time),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: _borderColor(isDark))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, size: 17, color: _primaryBlue),
                      const SizedBox(width: 4),
                      Text('Add food', style: _ts(12.5, FontWeight.w700, _primaryBlue)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _buildItemRow(DoctorMealItemInput item, String slotName, String slotTime, bool isDark) {
    final error = _errors[item];
    final weight = formatDietWeight(item.weightAmount, item.weightUnit);
    final portion = [formatDietPortion(item.quantity, item.unit), ?weight].join(' · ');

    return InkWell(
      onTap: () => _openPicker(slotName, slotTime, existing: item),
      child: Container(
        color: error != null ? _roseRed.withValues(alpha: isDark ? 0.12 : 0.05) : null,
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DietFoodImage(
                  imageUrl: item.imageUrl,
                  category: item.category ?? '',
                  foodType: item.foodType ?? '',
                  size: 42,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.foodName,
                        maxLines: 3,
                        softWrap: true,
                        style: _ts(13, FontWeight.w600, _textPrimary(isDark)),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$portion · ${item.calories} kcal',
                        maxLines: 2,
                        softWrap: true,
                        style: _ts(11, FontWeight.w500, _textSecondary(isDark)),
                      ),
                      if ((item.notes ?? '').trim().isNotEmpty)
                        Text(
                          item.notes!.trim(),
                          maxLines: 2,
                          softWrap: true,
                          style: _ts(10.5, FontWeight.w400, _textSecondary(isDark)).copyWith(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
                _buildStepper(item, isDark),
                IconButton(
                  tooltip: 'Remove ${item.foodName}',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: _roseRed),
                  onPressed: () => _removeItem(item),
                ),
              ],
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(left: 52, top: 4),
                child: Text(error, style: _ts(11, FontWeight.w600, _roseRed)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(DoctorMealItemInput item, bool isDark) {
    Widget button(IconData icon, VoidCallback? onTap, String tooltip) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(
              icon,
              size: 16,
              color: onTap == null ? _textSecondary(isDark).withValues(alpha: 0.4) : _primaryBlue,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(
            Icons.remove_rounded,
            item.quantity > 0.5 ? () => _setQuantity(item, item.quantity - 0.5) : null,
            'Less',
          ),
          SizedBox(
            width: 30,
            child: Text(
              _fmt(item.quantity),
              textAlign: TextAlign.center,
              style: _ts(12.5, FontWeight.w700, _textPrimary(isDark)),
            ),
          ),
          button(
            Icons.add_rounded,
            item.quantity < _maxQuantity ? () => _setQuantity(item, item.quantity + 0.5) : null,
            'More',
          ),
        ],
      ),
    );
  }

  Widget _buildAddSlotRow(bool isDark) {
    final used = _slotsForDay(_selectedDay).map((s) => s.name.toLowerCase()).toSet();
    final available = _standardSlots.where((s) => !used.contains(s.name.toLowerCase())).toList();
    if (available.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add a meal', style: _ts(12, FontWeight.w700, _textSecondary(isDark))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final slot in available)
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 16, color: _primaryBlue),
                label: Text(slot.name, style: _ts(11.5, FontWeight.w600, _textPrimary(isDark))),
                backgroundColor: _cardColor(isDark),
                side: BorderSide(color: _borderColor(isDark)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onPressed: () => _addSlot(slot),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final canSave = (_isCreate || (_isDirty && widget.plan.createdByPatient)) && !_isSaving;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset > 0 ? bottomInset + 6 : 12),
      decoration: BoxDecoration(
        color: _cardColor(isDark),
        border: Border(top: BorderSide(color: _borderColor(isDark))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isCreate
                  ? '${_meals.length} ${_meals.length == 1 ? 'food' : 'foods'} added'
                  : (_isDirty ? 'You have unsaved changes' : 'No changes yet'),
              style: _ts(12, FontWeight.w500, !_isCreate && _isDirty ? _amberOrange : _textSecondary(isDark)),
            ),
          ),
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: canSave ? _save : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _emeraldGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _emeraldGreen.withValues(alpha: 0.4),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_isCreate ? 'Create Plan' : 'Save Changes', style: _ts(13.5, FontWeight.w700, Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
