import 'dart:convert';
import 'package:yiraclinics/core/custom_dialogue/app_dialog.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/features/data/data_sources/diet/diet_api_error.dart';
import 'package:yiraclinics/features/data/data_sources/diet/doctor_diet_remote_data_source.dart';
import 'package:yiraclinics/features/data/models/diet/patient_diet_plan_model.dart'
    show formatDietPortion, formatDietWeight;
import 'package:yiraclinics/features/presentation/doctor/diet/diet_food_picker_sheet.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/diet_option_picker.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/diet_food_image.dart';

/// Model representing a meal item prescribed by the doctor
class DoctorMealItemInput {
  int dayNumber;
  String mealSlot;
  String mealTime;
  int? foodItemId;
  String foodName;
  double quantity;
  String unit;
  /// Weight of the whole portion, e.g. 80 (with [weightUnit] "g"). Null when unknown.
  double? weightAmount;
  String? weightUnit;
  int calories;
  double? proteinG;
  double? carbsG;
  double? fatG;
  String? notes;

  /// Photo of the food, for display only (the plan stores the food's id).
  String? imageUrl;
  /// Food category from the nutrient databank (e.g. "Grain", "Vegetable").
  String? category;
  /// Veg / Non-Veg / Egg / Vegan.
  String? foodType;

  DoctorMealItemInput({
    this.dayNumber = 1,
    required this.mealSlot,
    required this.mealTime,
    this.foodItemId,
    required this.foodName,
    required this.quantity,
    required this.unit,
    this.weightAmount,
    this.weightUnit,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.notes,
    this.imageUrl,
    this.category,
    this.foodType,
  });

  /// A meal from a saved template (the API's PascalCase or camelCase fields).
  factory DoctorMealItemInput.fromTemplateMeal(Map<dynamic, dynamic> m) {
    dynamic field(String name) => m[name] ?? m[name[0].toLowerCase() + name.substring(1)];
    double? number(String name) {
      final value = field(name);
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '');
    }

    String? text(String name) {
      final value = field(name)?.toString().trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    final food = field('FoodItem');
    String? foodField(String name) {
      if (food is! Map) return null;
      final value = (food[name] ?? food[name[0].toLowerCase() + name.substring(1)])?.toString().trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    final weight = number('WeightAmount');
    final quantity = number('Quantity') ?? 1.0;
    final protein = number('ProteinG');
    final carbs = number('CarbsG');
    final fat = number('FatG');
    // Older entries may have no calories: use the macros, then the food's own value.
    var calories = number('Calories')?.round() ?? 0;
    if (calories <= 0) calories = ((protein ?? 0) * 4 + (carbs ?? 0) * 4 + (fat ?? 0) * 9).round();
    if (calories <= 0 && food is Map) {
      final perServing = food['CaloriesPerServing'];
      final value = perServing is num ? perServing.toDouble() : double.tryParse('${perServing ?? ''}');
      if (value != null && value > 0) calories = (value * (quantity > 0 ? quantity : 1)).round();
    }
    return DoctorMealItemInput(
      dayNumber: number('DayNumber')?.toInt() ?? 1,
      mealSlot: text('MealSlot') ?? 'Breakfast',
      mealTime: text('MealTime') ?? '08:30 AM',
      foodItemId: number('FoodItemId')?.toInt(),
      foodName: text('FoodName') ?? '',
      quantity: quantity,
      unit: text('Unit') ?? 'serving',
      weightAmount: (weight != null && weight > 0) ? weight : null,
      weightUnit: (weight != null && weight > 0) ? (text('WeightUnit') ?? 'g') : null,
      calories: calories,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      notes: text('Notes'),
      imageUrl: foodField('ImageUrl'),
      category: foodField('Category'),
      foodType: foodField('FoodType'),
    );
  }

  DoctorMealItemInput copyForDay(int day) {
    return DoctorMealItemInput(
      dayNumber: day,
      mealSlot: mealSlot,
      mealTime: mealTime,
      foodItemId: foodItemId,
      foodName: foodName,
      quantity: quantity,
      unit: unit,
      weightAmount: weightAmount,
      weightUnit: weightUnit,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      notes: notes,
      imageUrl: imageUrl,
      category: category,
      foodType: foodType,
    );
  }

  Map<String, dynamic> toJson(int day, int sortOrder) {
    return {
      "dayNumber": day,
      "mealSlot": mealSlot,
      "mealTime": mealTime,
      if (foodItemId != null) "foodItemId": foodItemId,
      "foodName": foodName,
      "quantity": quantity,
      "unit": unit,
      if (weightAmount != null) "weightAmount": weightAmount,
      if (weightAmount != null) "weightUnit": weightUnit ?? "g",
      "calories": calories,
      if (proteinG != null) "proteinG": proteinG,
      if (carbsG != null) "carbsG": carbsG,
      if (fatG != null) "fatG": fatG,
      if (notes != null && notes!.isNotEmpty) "notes": notes,
      "sortOrder": sortOrder,
    };
  }
}

class DoctorPrescribeDietSheet extends StatefulWidget {
  final String patientId;
  final String? patientName;
  final String? orgId;
  final String? hospitalId;
  final String? appointmentId;

  /// When set, the builder opens this prescribed plan for the doctor to edit.
  final int? editPlanId;

  /// For tests: templates to show instead of loading them from the API.
  @visibleForTesting
  final List<dynamic>? debugTemplates;

  const DoctorPrescribeDietSheet({
    super.key,
    required this.patientId,
    this.patientName,
    this.orgId,
    this.hospitalId,
    this.appointmentId,
    this.editPlanId,
    this.debugTemplates,
  });

  /// Opens the Diet Prescribing Suite in a full-screen view adhering to Yira app standards
  static Future<bool?> show(
    BuildContext context, {
    required String patientId,
    String? patientName,
    String? orgId,
    String? hospitalId,
    String? appointmentId,
    int? editPlanId,
  }) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => DoctorPrescribeDietSheet(
          patientId: patientId,
          patientName: patientName,
          orgId: orgId,
          hospitalId: hospitalId,
          appointmentId: appointmentId,
          editPlanId: editPlanId,
        ),
      ),
    );
  }

  @override
  State<DoctorPrescribeDietSheet> createState() =>
      _DoctorPrescribeDietSheetState();
}

class _DoctorPrescribeDietSheetState extends State<DoctorPrescribeDietSheet>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();

  late final TabController _tabController;

  bool _isLoadingTemplates = true;
  bool _isLoadingTemplateMeals = false;
  bool _isSubmitting = false;

  List<dynamic> _templates = [];
  dynamic _selectedTemplate;

  /// Set while the doctor edits one of their own templates. The builder then
  /// saves the template instead of prescribing to the patient.
  int? _editingTemplateId;
  bool get _isTemplateMode => _editingTemplateId != null;

  /// Editing a plan already prescribed to the patient.
  bool get _isPlanEditMode => widget.editPlanId != null;
  bool _isLoadingPlan = false;
  String? _planLoadError;
  Map<String, dynamic>? _editPlan;
  final DoctorDietRemoteDataSource _doctorDiet = DoctorDietRemoteDataSource();
  bool _isSavingTemplate = false;

  /// Which group the templates tab shows: 'mine' or 'shared'.
  String _templateFilter = 'mine';
  final TextEditingController _templateSearchController = TextEditingController();
  String _selectedTemplateCondition = 'All';

  // Plan Details
  late final TextEditingController _planNameController;
  late final TextEditingController _conditionController;
  late final TextEditingController _notesController;
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedDietType = 'Veg';

  // Validity Date Range (From Date to To Date, default 1 month)
  late DateTime _startDate;
  late DateTime _endDate;

  static const List<String> _dietTypes = ['Veg', 'Non-Veg', 'Eggetarian', 'Vegan'];

  static const List<({String label, int days})> _durationPresets = [
    (label: '1 Week', days: 7),
    (label: '2 Weeks', days: 14),
    (label: '1 Month', days: 30),
    (label: '2 Months', days: 60),
    (label: '3 Months', days: 90),
  ];

  // Meal rotation: the plan cycles through days 1.._dayCount until it ends.
  // One day means the same meals every day.
  static const int _maxDays = 30;
  int _dayCount = 1;
  int _selectedDayNumber = 1;

  List<int> get _activeDays => List<int>.generate(_dayCount, (i) => i + 1);

  // Custom plan builder step: 0 = details, 1 = meals, 2 = guidance
  int _builderStep = 0;
  String? _titleError;

  // Meal slots, kept in time order (default: Breakfast, Lunch, Dinner)
  static List<Map<String, String>> _defaultSlots() => [
        {"name": "Breakfast", "emoji": "🍳", "time": "08:30 AM"},
        {"name": "Lunch", "emoji": "🥗", "time": "01:30 PM"},
        {"name": "Dinner", "emoji": "🍲", "time": "08:00 PM"},
      ];

  final List<Map<String, String>> _slots = _defaultSlots();

  // Meals grouped by [dayNumber][slotName] -> list of items
  final Map<int, Map<String, List<DoctorMealItemInput>>> _mealsByDayAndSlot = {};

  final List<String> _foodsToAvoid = [];
  final List<String> _foodsToPrefer = [];

  final TextEditingController _avoidInputController = TextEditingController();
  final TextEditingController _preferInputController = TextEditingController();

  final ScrollController _builderScrollController = ScrollController();

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _amberOrange = Color(0xFFF59E0B);
  static const Color _roseRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.editPlanId != null ? 1 : 0);

    _planNameController = TextEditingController();
    _conditionController = TextEditingController();
    _notesController = TextEditingController();

    // Default validity: From Today to 1 Month ahead (30 days)
    _startDate = DateUtils.dateOnly(DateTime.now());
    _endDate = _addDays(_startDate, 30);

    _mealsByDayAndSlot[1] = _emptyDay();

    if (widget.debugTemplates != null) {
      _templates = widget.debugTemplates!;
      _isLoadingTemplates = false;
    } else {
      _fetchTemplates();
    }
    if (widget.editPlanId != null) _loadPlanForEditing();
  }

  /// Loads the prescribed plan into the builder so the doctor can change it.
  Future<void> _loadPlanForEditing() async {
    setState(() {
      _isLoadingPlan = true;
      _planLoadError = null;
    });
    try {
      final plan = await _doctorDiet.getPlan(widget.editPlanId!, orgId: widget.orgId);
      if (!mounted) return;

      List<String> list(dynamic value) {
        if (value is List) return value.map((e) => e.toString()).toList();
        final text = value?.toString().trim() ?? '';
        if (text.isEmpty) return [];
        try {
          final decoded = jsonDecode(text);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
        return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }

      DateTime? date(dynamic value) {
        final d = DateTime.tryParse(value?.toString() ?? '');
        return d == null ? null : DateTime(d.year, d.month, d.day);
      }

      setState(() {
        _editPlan = plan;
        _planNameController.text = (plan['PlanName'] ?? '').toString();
        _conditionController.text = (plan['Condition'] ?? '').toString();
        _selectedDietType = (plan['DietType'] ?? 'Veg').toString();
        _notesController.text = (plan['DoctorNotes'] ?? '').toString();
        _startDate = date(plan['StartDate']) ?? _startDate;
        _endDate = date(plan['EndDate']) ?? _addDays(_startDate, 30);
        if (!_endDate.isAfter(_startDate)) _endDate = _addDays(_startDate, 1);
        _foodsToAvoid
          ..clear()
          ..addAll(list(plan['FoodsToAvoid']));
        _foodsToPrefer
          ..clear()
          ..addAll(list(plan['FoodsToPrefer']));

        final totalDays = ((plan['TotalDays'] as num?)?.toInt() ?? 1).clamp(1, _maxDays);
        _dayCount = totalDays;
        _selectedDayNumber = 1;
        _slots
          ..clear()
          ..addAll(_defaultSlots());
        _mealsByDayAndSlot.clear();

        final meals = plan['Meals'];
        final seenSlots = <String>{};
        if (meals is List) {
          for (final raw in meals) {
            if (raw is! Map) continue;
            final item = DoctorMealItemInput.fromTemplateMeal(raw);
            if (item.dayNumber < 1 || item.dayNumber > _maxDays) continue;
            if (item.dayNumber > _dayCount) _dayCount = item.dayNumber;
            if (seenSlots.add(item.mealSlot)) {
              final existing = _slots.indexWhere((s) => s["name"] == item.mealSlot);
              if (existing == -1) {
                _slots.add({"name": item.mealSlot, "emoji": _getSlotEmoji(item.mealSlot), "time": item.mealTime});
              } else {
                _slots[existing]["time"] = item.mealTime;
              }
            }
            _mealsByDayAndSlot.putIfAbsent(item.dayNumber, () => {}).putIfAbsent(item.mealSlot, () => []).add(item);
          }
        }
        _sortSlotsByTime();
        for (final day in _activeDays) {
          final dayMap = _mealsByDayAndSlot.putIfAbsent(day, () => {});
          for (final s in _slots) {
            dayMap.putIfAbsent(s["name"]!, () => []);
          }
        }
        _isLoadingPlan = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPlan = false;
        _planLoadError = dietApiErrorMessage(e, "Couldn't load this diet plan.");
      });
    }
  }

  /// Saves the doctor's changes to the prescribed plan.
  Future<void> _savePlanChanges() async {
    if (!_validateDetails()) return;
    final problem = _validateMeals();
    if (problem != null) {
      _showInfo(problem, color: _roseRed);
      return;
    }

    num? target(String key, num average) {
      final value = _editPlan?[key];
      final existing = value is num ? value : num.tryParse('${value ?? ''}');
      if (existing != null && existing > 0) return existing;
      return average > 0 ? average : null;
    }

    final averages = _averageDailyTotals;
    final payload = {
      "planName": _planNameController.text.trim(),
      "condition": _conditionController.text.trim(),
      "dietType": _selectedDietType,
      "totalDays": _dayCount,
      "startDate": _startDate.toIso8601String().substring(0, 10),
      "endDate": _endDate.toIso8601String().substring(0, 10),
      if (target("TargetCalories", averages.calories) != null) "targetCalories": target("TargetCalories", averages.calories),
      if (target("TargetProteinG", averages.protein) != null) "targetProteinG": target("TargetProteinG", averages.protein),
      if (target("TargetCarbsG", averages.carbs) != null) "targetCarbsG": target("TargetCarbsG", averages.carbs),
      if (target("TargetFatG", averages.fat) != null) "targetFatG": target("TargetFatG", averages.fat),
      "doctorNotes": _notesController.text.trim(),
      "foodsToAvoid": _foodsToAvoid,
      "foodsToPrefer": _foodsToPrefer,
      "meals": _mealsPayload(),
    };

    setState(() => _isSubmitting = true);
    try {
      await _doctorDiet.updatePlan(widget.editPlanId!, payload, orgId: widget.orgId);
      if (!mounted) return;
      _showInfo('Diet plan updated. ${widget.patientName ?? 'The patient'} will see the changes.', color: _emeraldGreen);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showInfo(dietApiErrorMessage(e, "Couldn't save the plan. Please try again."), color: _roseRed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _templateSearchController.dispose();
    _planNameController.dispose();
    _conditionController.dispose();
    _notesController.dispose();
    _descriptionController.dispose();
    _avoidInputController.dispose();
    _preferInputController.dispose();
    _builderScrollController.dispose();
    super.dispose();
  }

  /// An empty set of meal slots for one day.
  Map<String, List<DoctorMealItemInput>> _emptyDay() {
    return {for (final s in _slots) s["name"]!: <DoctorMealItemInput>[]};
  }

  /// A deep copy of [sourceDay]'s meals, re-labelled for [targetDay].
  Map<String, List<DoctorMealItemInput>> _cloneDay(int sourceDay, int targetDay) {
    final source = _mealsByDayAndSlot[sourceDay] ?? {};
    return {
      for (final s in _slots)
        s["name"]!: (source[s["name"]!] ?? []).map((m) => m.copyForDay(targetDay)).toList(),
    };
  }

  ({int calories, double protein, double carbs, double fat}) _dayTotals(int day) {
    int calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    _mealsByDayAndSlot[day]?.forEach((_, list) {
      for (final m in list) {
        calories += m.calories;
        protein += m.proteinG ?? 0;
        carbs += m.carbsG ?? 0;
        fat += m.fatG ?? 0;
      }
    });

    return (
      calories: calories,
      protein: (protein * 10).round() / 10,
      carbs: (carbs * 10).round() / 10,
      fat: (fat * 10).round() / 10,
    );
  }

  int _getDayCalories(int day) => _dayTotals(day).calories;

  String get _rotationLabel =>
      _dayCount == 1 ? 'Same meals every day' : 'Repeats every $_dayCount days';

  String _fmtGrams(double? value) {
    final v = value ?? 0;
    return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  DateTime _addDays(DateTime date, int days) => DateTime(date.year, date.month, date.day + days);

  /// Parses "08:30 AM" into minutes from midnight; unparseable times sort last.
  int _timeToMinutes(String time) {
    final match = RegExp(r'^(\d{1,2})[:.](\d{2})\s*([AaPp][Mm])?$').firstMatch(time.trim());
    if (match == null) return 24 * 60;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)?.toUpperCase();
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  /// Keeps meal slots in the order the patient will eat them.
  void _sortSlotsByTime() {
    _slots.sort((a, b) {
      final byTime = _timeToMinutes(a["time"] ?? '').compareTo(_timeToMinutes(b["time"] ?? ''));
      return byTime != 0 ? byTime : (a["name"] ?? '').compareTo(b["name"] ?? '');
    });
  }

  int _getDayItemCount(int day) {
    int count = 0;
    final dayMap = _mealsByDayAndSlot[day];
    if (dayMap != null) {
      dayMap.forEach((_, list) {
        count += list.length;
      });
    }
    return count;
  }

  int get _totalPrescribedItemsCount {
    int count = 0;
    for (final day in _activeDays) {
      count += _getDayItemCount(day);
    }
    return count;
  }

  int get _validityDaysCount {
    final start = DateTime.utc(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime.utc(_endDate.year, _endDate.month, _endDate.day);
    return end.difference(start).inDays.clamp(1, 365);
  }

  /// Daily totals averaged over the days that have meals, so the plan's
  /// targets do not depend on which day happens to be open in the builder.
  ({int calories, double protein, double carbs, double fat}) get _averageDailyTotals {
    int days = 0;
    int calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final day in _activeDays) {
      if (_getDayItemCount(day) == 0) continue;
      days++;
      _mealsByDayAndSlot[day]!.forEach((_, list) {
        for (final m in list) {
          calories += m.calories;
          protein += m.proteinG ?? 0;
          carbs += m.carbsG ?? 0;
          fat += m.fatG ?? 0;
        }
      });
    }

    if (days == 0) return (calories: 0, protein: 0, carbs: 0, fat: 0);
    return (
      calories: (calories / days).round(),
      protein: (protein / days * 10).round() / 10,
      carbs: (carbs / days * 10).round() / 10,
      fat: (fat / days * 10).round() / 10,
    );
  }

  /// The selected template's own target for [key], if it defines one.
  num? _templateTarget(String key) {
    final t = _selectedTemplate;
    if (t == null) return null;
    final value = t[key] ?? t[key[0].toLowerCase() + key.substring(1)];
    final parsed = value is num ? value : num.tryParse(value?.toString() ?? '');
    return (parsed != null && parsed > 0) ? parsed : null;
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String actionLabel,
    String cancelLabel = 'Cancel',
  }) {
    return AppDialog.confirm(
      context,
      title: title,
      message: message,
      confirmLabel: actionLabel,
      cancelLabel: cancelLabel,
      tone: AppDialogTone.danger,
      icon: Icons.warning_amber_rounded,
    );
  }

  /// Asks before throwing away meals already added. Returns true when there
  /// is nothing to lose or the doctor confirms.
  Future<bool> _confirmDiscardMeals({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    if (_totalPrescribedItemsCount == 0) return true;
    return _confirm(
      title: title,
      message: message,
      actionLabel: actionLabel,
      cancelLabel: 'Keep Editing',
    );
  }

  Future<void> _confirmStartBlank() async {
    final proceed = await _confirmDiscardMeals(
      title: 'Start a blank plan?',
      message: 'The $_totalPrescribedItemsCount food item(s) you have added will be cleared.',
      actionLabel: 'Clear & Start Blank',
    );
    if (proceed && mounted) _startCreateNewDietPlan();
  }

  void _showInfo(String message, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12.5),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = d.day.toString().padLeft(2, '0');
    final month = months[d.month - 1];
    final year = d.year;
    return '$day $month $year';
  }

  String get _authToken =>
      GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';

  String get _orgId {
    final currentUser = GlobalSession.instance.userNotifier.value;
    return widget.orgId ??
        (currentUser?.data?.latestOrgId != null
            ? currentUser!.data!.latestOrgId.toString()
            : '1');
  }

  /// 1. Fetch Diet Templates from Database
  Future<void> _fetchTemplates() async {
    setState(() => _isLoadingTemplates = true);
    try {
      final token = _authToken;
      final orgId = _orgId;

      final response = await _apiClient.account(showSuccessSnack: false).get(
        URLs.doctorDietTemplatesUrl,
        options: Options(
          headers: {
            if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
            'x-org-id': orgId,
          },
        ),
      );

      List<dynamic> list = [];
      if (response.data is List) {
        list = response.data;
      } else if (response.data != null && response.data["data"] is List) {
        list = response.data["data"];
      }

      if (mounted) {
        setState(() {
          _templates = list;
          _isLoadingTemplates = false;
          // Open on the doctor's own templates, or shared ones when they have none.
          if (_templateFilter == 'mine' && !list.any(_isMine) && list.isNotEmpty) _templateFilter = 'shared';
          if (_templateFilter == 'starter') _templateFilter = 'mine';
        });
      }
    } catch (e) {
      debugPrint("Error fetching diet templates: $e");
      if (mounted) setState(() => _isLoadingTemplates = false);
    }
  }

  /// Start a clean custom plan: one day, the default meal slots, no food.
  void _startCreateNewDietPlan() {
    setState(() {
      _selectedTemplate = null;
      _isLoadingTemplateMeals = false;
      _planNameController.clear();
      _conditionController.clear();
      _notesController.clear();
      _selectedDietType = 'Veg';
      _dayCount = 1;
      _selectedDayNumber = 1;
      _builderStep = 0;
      _titleError = null;
      _editingTemplateId = null;
      _descriptionController.clear();
      _startDate = DateUtils.dateOnly(DateTime.now());
      _endDate = _addDays(_startDate, 30);
      _foodsToAvoid.clear();
      _foodsToPrefer.clear();

      _slots
        ..clear()
        ..addAll(_defaultSlots());
      _mealsByDayAndSlot.clear();
      _mealsByDayAndSlot[1] = _emptyDay();
    });

    _tabController.animateTo(1);
  }

  // --- Builder steps ---

  /// The plan needs a valid title (and sensible field lengths) before the
  /// doctor can move past the details step.
  bool _validateDetails() {
    final title = _planNameController.text.trim();
    final what = _isTemplateMode ? 'template' : 'plan';
    String? titleError;
    String? otherError;
    if (title.isEmpty) {
      titleError = 'Enter a name for this $what';
    } else if (title.length > 200) {
      titleError = 'Keep the name under 200 characters';
    }
    if (_conditionController.text.trim().length > 100) {
      otherError = 'Medical condition must be 100 characters or fewer.';
    } else if (_descriptionController.text.trim().length > 1000) {
      otherError = 'Description must be 1000 characters or fewer.';
    } else if (!_isTemplateMode && !_endDate.isAfter(_startDate)) {
      otherError = 'The end date must be after the start date.';
    }

    if (titleError == null && otherError == null) return true;
    setState(() {
      _titleError = titleError;
      _builderStep = 0;
    });
    if (otherError != null) _showInfo(otherError, color: _roseRed);
    if (_builderScrollController.hasClients) _builderScrollController.jumpTo(0);
    return false;
  }

  /// Checks every food item before anything is saved. Opens the first bad
  /// item's day and returns why, or null when all is well.
  String? _validateMeals() {
    if (_totalPrescribedItemsCount == 0) {
      setState(() => _builderStep = 1);
      return 'Add at least one food item.';
    }
    if (_notesController.text.trim().length > 4000) {
      setState(() => _builderStep = 2);
      return "Doctor's advice must be 4000 characters or fewer.";
    }
    for (final day in _activeDays) {
      for (final s in _slots) {
        for (final m in _mealsByDayAndSlot[day]?[s["name"]!] ?? const <DoctorMealItemInput>[]) {
          String? problem;
          if (m.foodName.trim().isEmpty) {
            problem = 'a food has no name';
          } else if (!(m.quantity > 0) || m.quantity > 999) {
            problem = 'the quantity of "${m.foodName}" must be between 0 and 999';
          } else if (m.calories < 0 || (m.proteinG ?? 0) < 0 || (m.carbsG ?? 0) < 0 || (m.fatG ?? 0) < 0) {
            problem = '"${m.foodName}" has negative nutrition values';
          } else if ((m.notes ?? '').length > 500) {
            problem = 'the note on "${m.foodName}" is longer than 500 characters';
          }
          if (problem != null) {
            setState(() {
              _builderStep = 1;
              _selectedDayNumber = day;
            });
            final where = _dayCount > 1 ? 'Day $day, ${s["name"]}' : s["name"];
            return '$where: $problem.';
          }
        }
      }
    }
    return null;
  }

  Options _requestOptions({String? orgId}) {
    final token = _authToken;
    return Options(
      extra: dietQuietErrors,
      headers: {
        if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
        'x-org-id': orgId ?? _orgId,
      },
    );
  }

  // --- My Templates ---

  bool _isMine(dynamic t) => t is Map && (t["IsMine"] == true || t["isMine"] == true);

  bool _isSystem(dynamic t) => t is Map && (t["IsSystemDefault"] == true || t["isSystemDefault"] == true);

  dynamic _templateId(dynamic t) => t is Map ? (t["Id"] ?? t["id"]) : null;

  String _templateName(dynamic t) => (t is Map ? (t["Name"] ?? t["name"]) : null)?.toString() ?? 'Template';

  List<dynamic> get _myTemplates => _templates.where(_isMine).toList();

  List<dynamic> get _sharedTemplates => _templates.where((t) => !_isMine(t) && !_isSystem(t)).toList();

  /// The template loaded into the builder, when it belongs to this doctor.
  dynamic get _ownLoadedTemplate =>
      (_selectedTemplate != null && _isMine(_selectedTemplate)) ? _selectedTemplate : null;

  /// Every food item in the builder, in day and slot order, ready to send.
  List<Map<String, dynamic>> _mealsPayload() {
    final meals = <Map<String, dynamic>>[];
    var sortOrder = 1;
    for (final day in _activeDays) {
      final daySlots = _mealsByDayAndSlot[day] ?? {};
      for (final s in _slots) {
        for (final item in daySlots[s["name"]!] ?? const <DoctorMealItemInput>[]) {
          meals.add(item.toJson(day, sortOrder++));
        }
      }
    }
    return meals;
  }

  Map<String, dynamic> _templatePayload(String name, String description) {
    final averages = _averageDailyTotals;
    num? target(String key, num average) => average > 0 ? average : _templateTarget(key);
    return {
      "name": name,
      "description": description,
      "condition": _conditionController.text.trim(),
      "dietType": _selectedDietType,
      "totalDays": _dayCount,
      "targetCalories": target("TargetCalories", averages.calories),
      "targetProteinG": target("TargetProteinG", averages.protein),
      "targetCarbsG": target("TargetCarbsG", averages.carbs),
      "targetFatG": target("TargetFatG", averages.fat),
      "generalNotes": _notesController.text.trim(),
      "meals": _mealsPayload(),
    };
  }

  /// Creates a template (or updates [updateId]) from the builder. Returns the
  /// saved template, or throws with the server's reason.
  Future<Map<String, dynamic>?> _persistTemplate({
    required String name,
    required String description,
    dynamic updateId,
  }) async {
    final client = _apiClient.account(showSuccessSnack: false);
    final payload = _templatePayload(name, description);
    final res = updateId != null
        ? await client.put("${URLs.doctorDietTemplatesUrl}/$updateId", data: payload, options: _requestOptions())
        : await client.post(URLs.doctorDietTemplatesUrl, data: payload, options: _requestOptions());
    return res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
  }

  /// "Save to My Templates": saves the plan being built for reuse, as a new
  /// template or as an update to the doctor's own template it came from.
  Future<void> _showSaveTemplateSheet() async {
    FocusScope.of(context).unfocus();
    final problem = _validateMeals();
    if (problem != null) {
      _showInfo(problem, color: _roseRed);
      return;
    }

    final own = _ownLoadedTemplate;
    final saved = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaveTemplateSheet(
        initialName: _planNameController.text.trim(),
        initialDescription: (own?["Description"] ?? own?["description"] ?? _descriptionController.text).toString(),
        ownTemplateName: own != null ? _templateName(own) : null,
        existingNames: {
          for (final t in _myTemplates)
            if (own == null || _templateId(t) != _templateId(own)) _templateName(t).toLowerCase(),
        },
        allNames: {for (final t in _myTemplates) _templateName(t).toLowerCase()},
        itemCount: _totalPrescribedItemsCount,
        dayCount: _dayCount,
        onSave: ({required String name, required String description, required bool update}) =>
            _persistTemplate(name: name, description: description, updateId: update ? _templateId(own) : null),
      ),
    );
    if (saved == null || !mounted) return;

    setState(() => _selectedTemplate = {...saved, "IsMine": true});
    _fetchTemplates();
    _showInfo('Saved "${_templateName(saved)}" to My Templates.', color: _emeraldGreen);
  }

  /// Saves the template being edited (template mode) and returns to the list.
  Future<void> _saveEditedTemplate() async {
    if (!_validateDetails()) return;
    final problem = _validateMeals();
    if (problem != null) {
      _showInfo(problem, color: _roseRed);
      return;
    }

    final name = _planNameController.text.trim();
    final duplicate = _myTemplates.any(
      (t) => _templateId(t) != _editingTemplateId && _templateName(t).toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      setState(() {
        _titleError = 'You already have a template with this name';
        _builderStep = 0;
      });
      return;
    }

    setState(() => _isSavingTemplate = true);
    try {
      await _persistTemplate(
        name: name,
        description: _descriptionController.text.trim(),
        updateId: _editingTemplateId,
      );
      if (!mounted) return;
      _showInfo('Template "$name" updated.', color: _emeraldGreen);
      _startCreateNewDietPlan();
      _tabController.animateTo(0);
      setState(() => _templateFilter = 'mine');
      _fetchTemplates();
    } catch (e) {
      if (!mounted) return;
      _showInfo(dietApiErrorMessage(e, "Couldn't save the template. Please try again."), color: _roseRed);
    } finally {
      if (mounted) setState(() => _isSavingTemplate = false);
    }
  }

  Future<void> _stopEditingTemplate() async {
    final proceed = await _confirm(
      title: 'Stop editing this template?',
      message: 'Changes you have not saved will be lost.',
      actionLabel: 'Discard Changes',
      cancelLabel: 'Keep Editing',
    );
    if (!proceed || !mounted) return;
    _startCreateNewDietPlan();
    _tabController.animateTo(0);
  }

  Future<void> _deleteTemplate(dynamic t) async {
    final proceed = await _confirm(
      title: 'Delete "${_templateName(t)}"?',
      message: 'It will be removed from My Templates. Plans already prescribed from it are not affected.',
      actionLabel: 'Delete',
    );
    if (!proceed || !mounted) return;

    try {
      await _apiClient.account(showSuccessSnack: false).delete(
            "${URLs.doctorDietTemplatesUrl}/${_templateId(t)}",
            options: _requestOptions(),
          );
      if (!mounted) return;
      if (_editingTemplateId != null && _editingTemplateId == _templateId(t)) _startCreateNewDietPlan();
      if (_selectedTemplate != null && _templateId(_selectedTemplate) == _templateId(t)) {
        setState(() => _selectedTemplate = null);
      }
      setState(() => _templates.removeWhere((x) => _templateId(x) == _templateId(t)));
      _showInfo('Template deleted.', color: _emeraldGreen);
    } catch (e) {
      if (!mounted) return;
      _showInfo(dietApiErrorMessage(e, "Couldn't delete the template."), color: _roseRed);
    }
  }

  /// Copies any visible template into My Templates so the doctor can edit it.
  Future<void> _duplicateTemplate(dynamic t) async {
    try {
      final res = await _apiClient.account(showSuccessSnack: false).post(
            "${URLs.doctorDietTemplatesUrl}/${_templateId(t)}/duplicate",
            options: _requestOptions(),
          );
      if (!mounted) return;
      final name = res.data is Map ? _templateName(res.data) : 'the copy';
      setState(() => _templateFilter = 'mine');
      await _fetchTemplates();
      _showInfo('Saved "$name" to My Templates.', color: _emeraldGreen);
    } catch (e) {
      if (!mounted) return;
      _showInfo(dietApiErrorMessage(e, "Couldn't copy the template."), color: _roseRed);
    }
  }

  void _goToStep(int step) {
    if (step == _builderStep) return;
    if (step > _builderStep && !_validateDetails()) return;
    FocusScope.of(context).unfocus();
    setState(() => _builderStep = step);
    if (_builderScrollController.hasClients) _builderScrollController.jumpTo(0);
  }

  // --- Days in the meal rotation ---

  /// Appends a day to the rotation, optionally as a copy of [copyFrom].
  void _addDay({int? copyFrom}) {
    if (_dayCount >= _maxDays) {
      _showInfo('A plan can rotate through at most $_maxDays days.');
      return;
    }
    setState(() {
      _dayCount++;
      _mealsByDayAndSlot[_dayCount] =
          copyFrom != null ? _cloneDay(copyFrom, _dayCount) : _emptyDay();
      _selectedDayNumber = _dayCount;
    });
  }

  /// Removes [day] and moves the later days up so the rotation has no gaps.
  Future<void> _removeDay(int day) async {
    if (_dayCount <= 1) return;

    final itemCount = _getDayItemCount(day);
    if (itemCount > 0) {
      final proceed = await _confirm(
        title: 'Remove Day $day?',
        message: 'Its $itemCount food item(s) will be deleted. Later days move up by one.',
        actionLabel: 'Remove Day',
      );
      if (!proceed || !mounted) return;
    }

    setState(() {
      for (var d = day; d < _dayCount; d++) {
        final next = _mealsByDayAndSlot[d + 1] ?? _emptyDay();
        for (final list in next.values) {
          for (final m in list) {
            m.dayNumber = d;
          }
        }
        _mealsByDayAndSlot[d] = next;
      }
      _mealsByDayAndSlot.remove(_dayCount);
      _dayCount--;
      if (_selectedDayNumber > _dayCount) _selectedDayNumber = _dayCount;
    });
  }

  /// Replaces [targetDay]'s meals with a copy of [sourceDay]'s.
  Future<void> _copyDayInto(int sourceDay, int targetDay) async {
    final existing = _getDayItemCount(targetDay);
    if (existing > 0) {
      final proceed = await _confirm(
        title: 'Replace Day $targetDay meals?',
        message: 'Its $existing food item(s) will be replaced with a copy of Day $sourceDay.',
        actionLabel: 'Replace',
      );
      if (!proceed || !mounted) return;
    }
    setState(() => _mealsByDayAndSlot[targetDay] = _cloneDay(sourceDay, targetDay));
  }

  Future<void> _copyDayToAll(int sourceDay) async {
    final others = _activeDays.where((d) => d != sourceDay).toList();
    final existing = others.fold<int>(0, (sum, d) => sum + _getDayItemCount(d));
    if (existing > 0) {
      final proceed = await _confirm(
        title: 'Copy Day $sourceDay to all days?',
        message: 'The $existing food item(s) on the other days will be replaced.',
        actionLabel: 'Copy to All',
      );
      if (!proceed || !mounted) return;
    }
    setState(() {
      for (final d in others) {
        _mealsByDayAndSlot[d] = _cloneDay(sourceDay, d);
      }
    });
    _showInfo('Day $sourceDay copied to all $_dayCount days.', color: _emeraldGreen);
  }

  Future<void> _clearDay(int day) async {
    final proceed = await _confirm(
      title: _dayCount > 1 ? 'Clear Day $day?' : 'Clear all meals?',
      message: 'Its ${_getDayItemCount(day)} food item(s) will be deleted.',
      actionLabel: 'Clear',
    );
    if (!proceed || !mounted) return;
    setState(() => _mealsByDayAndSlot[day] = _emptyDay());
  }

  /// Lets the doctor choose which day to copy into the selected one.
  Future<void> _pickDayToCopyFrom() async {
    final target = _selectedDayNumber;
    final sources = _activeDays.where((d) => d != target && _getDayItemCount(d) > 0).toList();
    if (sources.isEmpty) {
      _showInfo('No other day has meals to copy yet.');
      return;
    }

    final source = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          decoration: BoxDecoration(
            color: isDark ? darkModeCardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Copy meals into Day $target from',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  // ListTile paints its ink on the nearest Material.
                  child: Material(
                    type: MaterialType.transparency,
                    child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final d in sources)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(Icons.calendar_today_rounded, size: 18, color: _primaryBlue),
                          title: Text(
                            'Day $d',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          subtitle: Text(
                            '${_dayItemsLabel(_getDayItemCount(d))} · ${_getDayCalories(d)} kcal',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          onTap: () => Navigator.pop(ctx, d),
                        ),
                    ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null && mounted) await _copyDayInto(source, target);
  }

  // --- Food items ---

  /// Opens the food picker to add to a slot of the selected day, or to edit
  /// [existingItem] at [editIndex].
  Future<void> _openFoodPicker(
    String slotName,
    String slotTime, {
    DoctorMealItemInput? existingItem,
    int? editIndex,
  }) {
    final day = _selectedDayNumber;
    return DietFoodPickerSheet.show(
      context,
      slotName: slotName,
      slotTime: slotTime,
      dayLabel: _dayCount > 1 ? 'Day $day' : null,
      existingItem: existingItem,
      authToken: _authToken,
      orgId: _orgId,
      onSubmit: (item) {
        if (!mounted) return;
        item.dayNumber = day;
        setState(() {
          final list = _mealsByDayAndSlot
              .putIfAbsent(day, _emptyDay)
              .putIfAbsent(slotName, () => <DoctorMealItemInput>[]);
          if (editIndex != null && editIndex < list.length) {
            list[editIndex] = item;
          } else {
            list.add(item);
          }
        });
      },
    );
  }

  /// Edits a food's portion weight (e.g. 200 ml -> 300 ml) in place. When the old
  /// weight is known and in the same unit, calories and macros scale with it.
  Future<void> _editItemWeight(int day, String slotName, int index) async {
    final item = _mealsByDayAndSlot[day]?[slotName]?[index];
    if (item == null) return;

    final result = await showDialog<({double amount, String unit})>(
      context: context,
      builder: (_) => _PortionWeightDialog(item: item),
    );
    if (result == null || !mounted) return;

    setState(() {
      final old = item.weightAmount;
      if (old != null && old > 0 && (item.weightUnit ?? 'g') == result.unit) {
        final factor = result.amount / old;
        item.calories = (item.calories * factor).round();
        if (item.proteinG != null) item.proteinG = (item.proteinG! * factor * 10).round() / 10;
        if (item.carbsG != null) item.carbsG = (item.carbsG! * factor * 10).round() / 10;
        if (item.fatG != null) item.fatG = (item.fatG! * factor * 10).round() / 10;
      }
      item.weightAmount = result.amount;
      item.weightUnit = result.unit;
    });
  }

  void _removeMealItem(int day, String slotName, int index) {
    setState(() {
      _mealsByDayAndSlot[day]?[slotName]?.removeAt(index);
    });
  }

  /// Read-only overview of every day in the plan
  void _showSchedulePreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_view_week_rounded, color: _primaryBlue, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Plan Preview',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Valid: ${_formatDate(_startDate)} to ${_formatDate(_endDate)} ($_validityDaysCount Days)',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 11.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _activeDays.length,
                      itemBuilder: (context, idx) {
                        final day = _activeDays[idx];
                        final count = _getDayItemCount(day);
                        final daySlots = _mealsByDayAndSlot[day] ?? {};
                        final cal = _getDayCalories(day);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: isDark ? darkModeCardColor : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _primaryBlue.withOpacity(0.08),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _primaryBlue,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Day $day',
                                            style: const TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          count > 0 ? '$count items' : 'No meals configured',
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (cal > 0)
                                      Text(
                                        '$cal kcal',
                                        style: const TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: _primaryBlue,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (count == 0)
                                const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: Text(
                                    'No meals added for this day yet.',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                )
                              else
                                ..._slots.where((s) => (daySlots[s["name"]!] ?? []).isNotEmpty).map((s) {
                                  final slotName = s["name"]!;
                                  final emoji = s["emoji"] ?? "🍽️";
                                  final slotItems = daySlots[slotName] ?? [];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(emoji, style: const TextStyle(fontSize: 13)),
                                            const SizedBox(width: 6),
                                            Text(
                                              slotName,
                                              style: TextStyle(
                                                fontFamily: appPoppinFont,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        ...slotItems.map((m) => Padding(
                                              padding: const EdgeInsets.only(left: 18, bottom: 3),
                                              child: Text(
                                                "• ${m.foodName} (${formatDietPortion(m.quantity, m.unit)}${formatDietWeight(m.weightAmount, m.weightUnit) != null ? ', ${formatDietWeight(m.weightAmount, m.weightUnit)}' : ''})${m.calories > 0 ? ' - ${m.calories} kcal' : ''}",
                                                style: TextStyle(
                                                  fontFamily: appPoppinFont,
                                                  fontSize: 11.5,
                                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                                ),
                                              ),
                                            )),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Load a template into the builder: to customise it for this patient, or,
  /// with [asTemplate], to edit and save the doctor's own template.
  Future<void> _loadTemplateForEditing(dynamic t, {bool asTemplate = false}) async {
    final proceed = await _confirmDiscardMeals(
      title: asTemplate ? 'Edit this template?' : 'Replace the current plan?',
      message: asTemplate
          ? 'The $_totalPrescribedItemsCount food item(s) you have added to the current plan will be cleared.'
          : 'Loading this template clears the $_totalPrescribedItemsCount food item(s) you have added.',
      actionLabel: asTemplate ? 'Edit Template' : 'Replace',
    );
    if (!proceed || !mounted) return;

    final templateId = t["Id"] ?? t["id"];

    setState(() {
      _selectedTemplate = t;
      _editingTemplateId = asTemplate && templateId is num ? templateId.toInt() : null;
      _planNameController.text = (t["Name"] ?? t["name"] ?? "").toString();
      _conditionController.text = (t["Condition"] ?? t["condition"] ?? "").toString();
      _descriptionController.text = (t["Description"] ?? t["description"] ?? "").toString();
      _selectedDietType = (t["DietType"] ?? t["dietType"] ?? "Veg").toString();
      _notesController.text = (t["GeneralNotes"] ?? t["generalNotes"] ?? "").toString();
      _dayCount = 1;
      _selectedDayNumber = 1;
      _builderStep = 0;
      _titleError = null;
      _startDate = DateUtils.dateOnly(DateTime.now());
      _endDate = _addDays(_startDate, 30);

      _foodsToAvoid.clear();
      _foodsToPrefer.clear();

      // Templates do not store these lists, so suggest some for the patient.
      final cond = _conditionController.text.toLowerCase();
      if (asTemplate) {
        // Nothing to suggest while editing the template itself.
      } else if (cond.contains("diabetes")) {
        _foodsToAvoid.addAll(["Refined Sugar", "Refined Flour (Maida)", "Fried Foods"]);
        _foodsToPrefer.addAll(["Sprouts", "Salad before Meals", "Methi Seeds Water"]);
      } else {
        _foodsToAvoid.addAll(["Excess Salt", "Fried Foods"]);
        _foodsToPrefer.addAll(["Fresh Fruits", "Green Leafy Vegetables"]);
      }

      _slots
        ..clear()
        ..addAll(_defaultSlots());
      _mealsByDayAndSlot.clear();
      _mealsByDayAndSlot[1] = _emptyDay();
      _isLoadingTemplateMeals = templateId != null;
    });

    // Animate to editor tab immediately
    _tabController.animateTo(1);

    if (templateId == null) return;

    try {
      final token = _authToken;
      final orgId = _orgId;

      final res = await _apiClient.account(showSuccessSnack: false).get(
        "${URLs.doctorDietTemplatesUrl}/$templateId",
        options: Options(
          headers: {
            if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
            'x-org-id': orgId,
          },
        ),
      );

      final mealsList = res.data != null
          ? (res.data["Meals"] ?? res.data["meals"])
          : null;
      final templateDays = res.data is Map
          ? ((res.data["TotalDays"] ?? res.data["totalDays"]) as num?)?.toInt()
          : null;

      // The doctor may have started over or picked another template meanwhile.
      if (!mounted || !identical(_selectedTemplate, t)) return;

      setState(() {
        _isLoadingTemplateMeals = false;
        if (mealsList is! List) return;

        // Keep the template's rotation length, even if its last days are empty.
        if (templateDays != null && templateDays > 1) _dayCount = templateDays.clamp(1, _maxDays);

        final seenSlots = <String>{};
        for (final raw in mealsList) {
          if (raw is! Map) continue;
          final item = DoctorMealItemInput.fromTemplateMeal(raw);
          final day = item.dayNumber;
          if (day < 1 || day > _maxDays) continue;
          if (day > _dayCount) _dayCount = day;

          final slot = item.mealSlot;
          final time = item.mealTime;

          // The template's own slots and timings win over the defaults.
          if (seenSlots.add(slot)) {
            final existing = _slots.indexWhere((s) => s["name"] == slot);
            if (existing == -1) {
              _slots.add({"name": slot, "emoji": _getSlotEmoji(slot), "time": time});
            } else {
              _slots[existing]["time"] = time;
            }
          }

          _mealsByDayAndSlot.putIfAbsent(day, () => {}).putIfAbsent(slot, () => []).add(item);
        }

        _sortSlotsByTime();

        // Every day in the rotation needs an entry for every slot.
        for (final day in _activeDays) {
          final dayMap = _mealsByDayAndSlot.putIfAbsent(day, () => {});
          for (final s in _slots) {
            dayMap.putIfAbsent(s["name"]!, () => []);
          }
        }
      });
    } catch (e) {
      debugPrint("Error loading template meals: $e");
      if (!mounted || !identical(_selectedTemplate, t)) return;
      setState(() => _isLoadingTemplateMeals = false);
      _showInfo("Couldn't load this template's meals. You can add them yourself.", color: _roseRed);
    }
  }

  /// Date picker for the start date. The plan keeps its length.
  Future<void> _pickStartDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      // A plan being edited may have started more than a week ago.
      firstDate: _startDate.isBefore(today.subtract(const Duration(days: 7))) ? _startDate : today.subtract(const Duration(days: 7)),
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    final days = _validityDaysCount;
    setState(() {
      _startDate = picked;
      _endDate = _addDays(picked, days);
    });
  }

  /// Date picker for a custom end date
  Future<void> _pickEndDate() async {
    final first = _addDays(_startDate, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(first) ? first : _endDate,
      firstDate: first,
      lastDate: _addDays(_startDate, 365),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  /// Edit Time for a specific meal slot (e.g. modify Breakfast time to 09:00 AM)
  Future<void> _editSlotTime(String slotName, String currentTime) async {
    TimeOfDay initialTime = const TimeOfDay(hour: 8, minute: 30);
    try {
      final parts = currentTime.trim().split(' ');
      final timeParts = parts[0].split(':');
      int h = int.parse(timeParts[0]);
      final int m = int.parse(timeParts[1]);
      if (parts.length > 1) {
        final ampm = parts[1].toUpperCase();
        if (ampm == 'PM' && h < 12) h += 12;
        if (ampm == 'AM' && h == 12) h = 0;
      }
      initialTime = TimeOfDay(hour: h, minute: m);
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryBlue,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final formatted = '${hour.toString().padLeft(2, '0')}:$minute $period';

      setState(() {
        final idx = _slots.indexWhere((s) => s["name"] == slotName);
        if (idx != -1) {
          _slots[idx]["time"] = formatted;
        }
        for (final day in _activeDays) {
          final items = _mealsByDayAndSlot[day]?[slotName] ?? [];
          for (final item in items) {
            item.mealTime = formatted;
          }
        }
        _sortSlotsByTime();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$slotName time set to $formatted'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Add dynamic meal slot (e.g. Snacks, Bedtime, Early Morning)
  void _showAddSlotDialog() {
    final nameCtrl = TextEditingController();
    String selectedEmoji = "🍽️";
    TimeOfDay selectedTime = const TimeOfDay(hour: 16, minute: 0);

    final List<Map<String, String>> presets = [
      {"name": "Early Morning", "emoji": "🌅", "time": "06:30 AM"},
      {"name": "Mid-Morning", "emoji": "🍎", "time": "11:00 AM"},
      {"name": "Evening Snack", "emoji": "☕", "time": "05:00 PM"},
      {"name": "Bedtime", "emoji": "🥛", "time": "10:00 PM"},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (dialogCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? darkModeCardColor : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Meal Slot',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Common Meal Slots',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presets.map((p) {
                        final alreadyAdded = _slots.any((s) => s["name"]?.toLowerCase() == p["name"]?.toLowerCase());
                        return ActionChip(
                          avatar: Text(p["emoji"]!),
                          label: Text(
                            '${p["name"]} (${p["time"]})',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: alreadyAdded
                                  ? (isDark ? Colors.white38 : Colors.black38)
                                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
                            ),
                          ),
                          backgroundColor: alreadyAdded
                              ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                              : _primaryBlue.withOpacity(0.08),
                          onPressed: alreadyAdded
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  _addMealSlot(p["name"]!, p["emoji"]!, p["time"]!);
                                },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 10),
                    Text(
                      'Or Create Custom Slot',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            decoration: InputDecoration(
                              hintText: 'e.g. Pre-Workout, Night Tea',
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (picked != null) {
                              setModalState(() => selectedTime = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 16, color: _primaryBlue),
                                const SizedBox(width: 6),
                                Text(
                                  selectedTime.format(context),
                                  style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Custom Slot', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700)),
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          final hour = selectedTime.hourOfPeriod == 0 ? 12 : selectedTime.hourOfPeriod;
                          final min = selectedTime.minute.toString().padLeft(2, '0');
                          final period = selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
                          final formattedTime = '${hour.toString().padLeft(2, '0')}:$min $period';
                          Navigator.pop(ctx);
                          _addMealSlot(name, selectedEmoji, formattedTime);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _addMealSlot(String name, String emoji, String time) {
    if (_slots.any((s) => s["name"]?.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Meal slot "$name" already exists.')),
      );
      return;
    }
    setState(() {
      _slots.add({"name": name, "emoji": emoji, "time": time});
      _sortSlotsByTime();
      for (final day in _activeDays) {
        _mealsByDayAndSlot[day] ??= {};
        _mealsByDayAndSlot[day]!.putIfAbsent(name, () => []);
      }
    });
  }

  void _removeMealSlot(String slotName) {
    if (_slots.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one meal slot must be kept.')),
      );
      return;
    }
    int totalItems = 0;
    for (final day in _activeDays) {
      totalItems += _mealsByDayAndSlot[day]?[slotName]?.length ?? 0;
    }
    if (totalItems > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AppDialog(
          title: 'Remove $slotName?',
          message: 'This will delete $totalItems food item(s) from $slotName on every day of the plan.',
          tone: AppDialogTone.danger,
          icon: Icons.delete_outline_rounded,
          primaryLabel: 'Remove Slot',
          onPrimary: () {
            Navigator.pop(ctx);
            setState(() {
              _slots.removeWhere((s) => s["name"] == slotName);
              for (final day in _activeDays) {
                _mealsByDayAndSlot[day]?.remove(slotName);
              }
            });
          },
          secondaryLabel: 'Cancel',
          onSecondary: () => Navigator.pop(ctx),
        ),
      );
    } else {
      setState(() {
        _slots.removeWhere((s) => s["name"] == slotName);
        for (final day in _activeDays) {
          _mealsByDayAndSlot[day]?.remove(slotName);
        }
      });
    }
  }

  /// Quick Prescribe template directly without entering builder
  Future<void> _quickPrescribeTemplate(dynamic t) async {
    final templateId = t["Id"] ?? t["id"];
    final templateName = t["Name"] ?? t["name"] ?? "Diet Plan";

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Assign Diet Plan',
      message:
          'Assign "$templateName" to ${widget.patientName ?? 'this patient'} for $_validityDaysCount days (${_formatDate(_startDate)} to ${_formatDate(_endDate)})?\n\nThis replaces any diet plan the patient is currently following.',
      confirmLabel: 'Assign As-Is',
      tone: AppDialogTone.success,
      icon: Icons.assignment_turned_in_rounded,
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final token = _authToken;
      final orgId = _orgId;

      final res = await _apiClient.account(showSuccessSnack: false).get(
        "${URLs.doctorDietTemplatesUrl}/$templateId",
        options: Options(
          headers: {
            if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
            'x-org-id': orgId,
          },
        ),
      );

      final mealsList = res.data != null
          ? (res.data["Meals"] ?? res.data["meals"])
          : null;

      final List<Map<String, dynamic>> allMealsPayload = [];
      int sortCounter = 1;

      if (mealsList is List) {
        // The template says which day each meal belongs to; a single-day
        // template simply repeats daily.
        for (final m in mealsList) {
          if (m is! Map) continue;
          final item = DoctorMealItemInput.fromTemplateMeal(m);
          allMealsPayload.add(item.toJson(item.dayNumber, sortCounter++));
        }
      }
      if (allMealsPayload.isEmpty) {
        throw Exception('This template has no meals to prescribe. Use "Customize" to add some.');
      }
      final templateDays = res.data is Map
          ? ((res.data["TotalDays"] ?? res.data["totalDays"]) as num?)?.toInt()
          : null;
      final lastMealDay = allMealsPayload.map((m) => m["dayNumber"] as int).reduce((a, b) => a > b ? a : b);

      final payload = {
        "patientId": widget.patientId,
        "doctorId": GlobalSession.instance.userNotifier.value?.data?.id ?? '',
        "organizationId": int.tryParse(orgId) ?? 1,
        if (widget.hospitalId != null)
          "hospitalId": int.tryParse(widget.hospitalId!),
        if (widget.appointmentId != null)
          "appointmentId": int.tryParse(widget.appointmentId!),
        "sourceTemplateId": templateId,
        "planName": templateName,
        "condition": t["Condition"] ?? t["condition"] ?? "",
        "dietType": t["DietType"] ?? t["dietType"] ?? "Veg",
        "totalDays": (templateDays != null && templateDays >= lastMealDay) ? templateDays : lastMealDay,
        "startDate": _startDate.toIso8601String().substring(0, 10),
        "endDate": _endDate.toIso8601String().substring(0, 10),
        "targetCalories": t["TargetCalories"] ?? t["targetCalories"] ?? 1500,
        "targetProteinG": t["TargetProteinG"] ?? t["targetProteinG"] ?? 65,
        "targetCarbsG": t["TargetCarbsG"] ?? t["targetCarbsG"] ?? 180,
        "targetFatG": t["TargetFatG"] ?? t["targetFatG"] ?? 45,
        "doctorNotes": t["GeneralNotes"] ?? t["generalNotes"] ?? "",
        "meals": allMealsPayload,
      };

      final assignRes = await _apiClient.account(showSuccessSnack: false).post(
        URLs.doctorDietAssignUrl,
        data: payload,
        options: _requestOptions(orgId: orgId),
      );

      if (!mounted) return;

      if (assignRes.statusCode == 200 || assignRes.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Diet prescribed for ${_formatDate(_startDate)} to ${_formatDate(_endDate)} (${_validityDaysCount} Days)!',
                    style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12.5),
                  ),
                ),
              ],
            ),
            backgroundColor: _emeraldGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      final fallback = e is Exception && e.toString().startsWith('Exception: ')
          ? e.toString().substring('Exception: '.length)
          : "Couldn't prescribe the diet plan. Please try again.";
      _showInfo(dietApiErrorMessage(e, fallback), color: _roseRed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Show Template Meals Preview Sheet
  void _showTemplatePreviewSheet(dynamic t) {
    final templateId = t["Id"] ?? t["id"];
    final templateName = (t["Name"] ?? t["name"] ?? "").toString();
    final condition = (t["Condition"] ?? t["condition"] ?? "General").toString();
    final calories = t["TargetCalories"] ?? t["targetCalories"] ?? 1500;
    final protein = t["TargetProteinG"] ?? t["targetProteinG"] ?? 65;
    final carbs = t["TargetCarbsG"] ?? t["targetCarbsG"] ?? 180;
    final fat = t["TargetFatG"] ?? t["targetFatG"] ?? 45;
    final dietType = (t["DietType"] ?? t["dietType"] ?? "Veg").toString();
    final totalDays = (t["TotalDays"] ?? t["totalDays"] ?? 1) as num;

    List<dynamic> meals = [];
    bool loading = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final condBadge = _getConditionBadgeColors(condition, isDark);
        final dietBadge = _getDietTypeBadge(dietType, isDark);

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            if (loading && templateId != null) {
              final token = _authToken;
              final orgId = _orgId;

              _apiClient
                  .account(showSuccessSnack: false)
                  .get(
                    "${URLs.doctorDietTemplatesUrl}/$templateId",
                    options: Options(
                      headers: {
                        if (token.isNotEmpty)
                          HttpHeaders.authorizationHeader: 'Bearer $token',
                        'x-org-id': orgId,
                      },
                    ),
                  )
                  .then((res) {
                if (res.data != null && (res.data["Meals"] ?? res.data["meals"]) is List) {
                  setModalState(() {
                    meals = res.data["Meals"] ?? res.data["meals"];
                    loading = false;
                  });
                } else {
                  setModalState(() => loading = false);
                }
              }).catchError((_) {
                setModalState(() => loading = false);
              });
            }

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: isDark ? darkModeCardColor : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              templateName,
                              softWrap: true,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: condBadge.bg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: condBadge.border),
                                  ),
                                  child: Text(
                                    condition.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: condBadge.text,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: dietBadge.bg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: dietBadge.border),
                                  ),
                                  child: Text(
                                    dietBadge.label,
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: dietBadge.text,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  totalDays > 1 ? '$totalDays-Day Cycle' : 'Daily',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nutrition Target Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('🔥 $calories kcal', style: const TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w700, color: _primaryBlue)),
                        Text('🥩 ${protein}g P', style: const TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w700, color: _emeraldGreen)),
                        Text('🌾 ${carbs}g C', style: const TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w700, color: _amberOrange)),
                        Text('🥑 ${fat}g F', style: const TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w700, color: _roseRed)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (loading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator(color: _primaryBlue)),
                    )
                  else if (meals.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'No meals found in template.',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: meals.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, idx) {
                          final m = meals[idx];
                          final slot = m["MealSlot"] ?? m["mealSlot"] ?? "";
                          final emoji = _getSlotEmoji(slot);
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _getSlotColor(slot).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m["FoodName"] ?? m["foodName"] ?? "",
                                        softWrap: true,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$slot (${m["MealTime"] ?? m["mealTime"]}) · ${m["Quantity"] ?? m["quantity"]} ${m["Unit"] ?? m["unit"]}',
                                        softWrap: true,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${m["Calories"] ?? m["calories"]} kcal',
                                    style: const TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontWeight: FontWeight.w700,
                                      color: _primaryBlue,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _loadTemplateForEditing(t);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryBlue,
                            side: const BorderSide(color: _primaryBlue, width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text(
                            'Customize',
                            style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _quickPrescribeTemplate(t);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _emeraldGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: const Text(
                            'Assign As-Is',
                            style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Final check before prescribing: what the patient will receive, any days
  /// left empty, and that this replaces their current plan.
  Future<bool> _showPrescribeReview() async {
    final emptyDays = _activeDays.where((d) => _getDayItemCount(d) == 0).toList();
    final patient = widget.patientName ?? 'the patient';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
        final secondaryText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        Widget detailRow(String label, String value) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 68,
                  child: Text(
                    label,
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: secondaryText),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        Widget notice(IconData icon, Color color, String text) {
          return Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11.5,
                      height: 1.4,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return AppDialog(
          title: 'Review & Prescribe',
          tone: AppDialogTone.success,
          icon: Icons.fact_check_outlined,
          primaryLabel: 'Prescribe',
          secondaryLabel: 'Keep Editing',
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.patientName != null) detailRow('Patient', widget.patientName!),
                detailRow('Plan', _planNameController.text.trim()),
                detailRow(
                  'Validity',
                  '${_formatDate(_startDate)} to ${_formatDate(_endDate)} ($_validityDaysCount days)',
                ),
                detailRow('Meals', '$_rotationLabel · $_totalPrescribedItemsCount items'),
                const Divider(height: 16),
                ..._activeDays.map((day) {
                  final count = _getDayItemCount(day);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Day $day',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: primaryText,
                            ),
                          ),
                        ),
                        Text(
                          count > 0 ? '${_dayItemsLabel(count)} · ${_getDayCalories(day)} kcal' : 'No meals',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            fontWeight: count > 0 ? FontWeight.w500 : FontWeight.w700,
                            color: count > 0 ? secondaryText : _amberOrange,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (_foodsToPrefer.isEmpty && _foodsToAvoid.isEmpty)
                  notice(
                    Icons.rule_rounded,
                    _amberOrange,
                    "No do's & don'ts added. $patient will only see general tips. Go back to add them.",
                  ),
                if (emptyDays.isNotEmpty)
                  notice(
                    Icons.warning_amber_rounded,
                    _amberOrange,
                    '${emptyDays.length == 1 ? 'Day' : 'Days'} ${emptyDays.join(', ')} ${emptyDays.length == 1 ? 'has' : 'have'} no meals. $patient will see an empty schedule on ${emptyDays.length == 1 ? 'that day' : 'those days'}.',
                  ),
                notice(
                  Icons.info_outline_rounded,
                  _primaryBlue,
                  'This replaces any diet plan $patient is currently following and sends them a notification.',
                ),
              ],
          ),
        );
      },
    );
    return confirmed == true;
  }

  /// Review and prescribe the custom plan
  Future<void> _submitDietPlanFromBuilder() async {
    if (!_validateDetails()) return;

    final problem = _validateMeals();
    if (problem != null) {
      _showInfo(problem, color: _roseRed);
      return;
    }

    if (!await _showPrescribeReview() || !mounted) return;

    final currentUser = GlobalSession.instance.userNotifier.value;
    final doctorId = currentUser?.data?.id ?? '';

    final orgId = int.tryParse(widget.orgId ?? '') ??
        currentUser?.data?.latestOrgId ??
        1;
    final hospitalId = int.tryParse(widget.hospitalId ?? '') ??
        currentUser?.data?.latestHospitalId;

    final allMealsPayload = _mealsPayload();

    setState(() => _isSubmitting = true);

    try {
      final averages = _averageDailyTotals;
      final targetCalories = _templateTarget("TargetCalories") ?? averages.calories;
      final targetProtein = _templateTarget("TargetProteinG") ?? averages.protein;
      final targetCarbs = _templateTarget("TargetCarbsG") ?? averages.carbs;
      final targetFat = _templateTarget("TargetFatG") ?? averages.fat;

      final payload = {
        "patientId": widget.patientId,
        "doctorId": doctorId,
        "organizationId": orgId,
        if (hospitalId != null) "hospitalId": hospitalId,
        if (widget.appointmentId != null)
          "appointmentId": int.tryParse(widget.appointmentId!),
        if (_selectedTemplate != null && (_selectedTemplate["Id"] != null || _selectedTemplate["id"] != null))
          "sourceTemplateId": _selectedTemplate["Id"] ?? _selectedTemplate["id"],
        "planName": _planNameController.text.trim(),
        "condition": _conditionController.text.trim(),
        "dietType": _selectedDietType,
        "totalDays": _dayCount,
        "startDate": _startDate.toIso8601String().substring(0, 10),
        "endDate": _endDate.toIso8601String().substring(0, 10),
        if (targetCalories > 0) "targetCalories": targetCalories,
        if (targetProtein > 0) "targetProteinG": targetProtein,
        if (targetCarbs > 0) "targetCarbsG": targetCarbs,
        if (targetFat > 0) "targetFatG": targetFat,
        "doctorNotes": _notesController.text.trim(),
        "foodsToAvoid": _foodsToAvoid,
        "foodsToPrefer": _foodsToPrefer,
        "meals": allMealsPayload,
      };

      final response = await _apiClient.account(showSuccessSnack: false).post(
        URLs.doctorDietAssignUrl,
        data: payload,
        options: _requestOptions(orgId: orgId.toString()),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Diet prescribed for ${_formatDate(_startDate)} to ${_formatDate(_endDate)} (${_validityDaysCount} Days)!',
                    style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12.5),
                  ),
                ),
              ],
            ),
            backgroundColor: _emeraldGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      final fallback = e is Exception && e.toString().startsWith('Exception: ')
          ? e.toString().substring('Exception: '.length)
          : "Couldn't prescribe the diet plan. Please try again.";
      _showInfo(dietApiErrorMessage(e, fallback), color: _roseRed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _totalPrescribedItemsCount == 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final leave = await _confirmDiscardMeals(
          title: _isTemplateMode
              ? 'Discard template changes?'
              : (_isPlanEditMode ? 'Discard your changes?' : 'Discard this diet plan?'),
          message: _isTemplateMode
              ? 'Changes to this template have not been saved and will be lost.'
              : _isPlanEditMode
              ? 'Your changes to this plan have not been saved.'
              : 'The $_totalPrescribedItemsCount meal item(s) you have added have not been prescribed and will be lost.',
          actionLabel: 'Discard',
        );
        if (leave && mounted) navigator.pop();
      },
      child: _buildScaffold(isDark),
    );
  }

  Widget _buildScaffold(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? darkBackGroundColor : lightBackGroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? darkModeCardColor : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 56,
        leadingWidth: 48,
        titleSpacing: 6,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.maybePop(context),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
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
            Text(
              _isTemplateMode ? 'Edit Template' : (_isPlanEditMode ? 'Edit Diet Plan' : 'Prescribe Diet Plan'),
              maxLines: 2,
              softWrap: true,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.2,
                height: 1.25,
              ),
            ),
            if (_isTemplateMode || widget.patientName != null) ...[
              const SizedBox(height: 2),
              Text(
                _isTemplateMode ? 'My Templates' : 'Patient: ${widget.patientName}',
                maxLines: 2,
                softWrap: true,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.25,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!_isPlanEditMode)
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryBlue, Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryBlue.withOpacity(0.32),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _confirmStartBlank,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.add_rounded, size: 13, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'New Plan',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: _isPlanEditMode ? null : PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: isDark ? darkModeCardColor : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              labelColor: _primaryBlue,
              unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_stories_rounded, size: 16),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'Templates',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_templates.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: _primaryBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_templates.length}',
                            style: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note_rounded, size: 18),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Custom Plan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isPlanEditMode
          ? _buildPlanEditBody(isDark)
          : TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Predefined Templates Gallery
          _buildTemplatesTab(isDark),

          // TAB 2: Custom plan builder (blank by default)
          _buildBuilderTab(isDark),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: PREDEFINED TEMPLATES SCREEN
  // ==========================================
  Widget _buildTemplatesTab(bool isDark) {
    if (_isLoadingTemplates) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading clinical diet templates...',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Curating nutritional targets & meal plans',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    // Dynamic condition chips
    final uniqueConditions = <String>{};
    for (final t in _templates) {
      final cond = (t["Condition"] ?? t["condition"] ?? "").toString().trim();
      if (cond.isNotEmpty) uniqueConditions.add(cond);
    }
    final filterChips = ['All', 'Veg', 'Non-Veg', ...uniqueConditions];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.1,
            ),
          ),
          child: TextField(
            controller: _templateSearchController,
            onChanged: (_) => setState(() {}),
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search templates by condition, name, diet...',
              hintStyle: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 19,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              suffixIcon: _templateSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      onPressed: () {
                        _templateSearchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            ),
          ),
        ),

        // Quick Condition Filter Chips
        if (filterChips.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filterChips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, idx) {
                final chip = filterChips[idx];
                final isSelected = _selectedTemplateCondition == chip;
                return InkWell(
                  onTap: () => setState(() => _selectedTemplateCondition = chip),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primaryBlue
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? _primaryBlue
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: 1.1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        chip,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 14),

        _buildTemplateFilter(isDark),
        const SizedBox(height: 12),
        ..._buildFilteredTemplates(isDark),
      ],
    );
  }

  Widget _buildTemplateFilter(bool isDark) {
    if (_sharedTemplates.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.bookmark_rounded, size: 16, color: _primaryBlue),
            const SizedBox(width: 6),
            Text(
              'MY SAVED TEMPLATES',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isDark ? const Color(0xFF93C5FD) : _primaryBlue,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_myTemplates.length}',
                style: const TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: _primaryBlue,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final groups = [
      (key: 'mine', label: 'My Templates', count: _myTemplates.length, icon: Icons.bookmark_rounded),
      (key: 'shared', label: 'Shared with Me', count: _sharedTemplates.length, icon: Icons.groups_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _lineColor(isDark)),
      ),
      child: Row(
        children: [
          for (final g in groups)
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _templateFilter = g.key),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                  decoration: BoxDecoration(
                    color: _templateFilter == g.key
                        ? (isDark ? darkModeCardColor : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _templateFilter == g.key
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        g.icon,
                        size: 15,
                        color: _templateFilter == g.key ? _primaryBlue : _mutedText(isDark),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${g.label} (${g.count})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            fontWeight: _templateFilter == g.key ? FontWeight.w700 : FontWeight.w500,
                            color: _templateFilter == g.key ? _primaryBlue : _mutedText(isDark),
                          ),
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

  List<Widget> _buildFilteredTemplates(bool isDark) {
    var list = _templateFilter == 'shared' && _sharedTemplates.isNotEmpty
        ? _sharedTemplates
        : _myTemplates;

    // Apply search filter
    final query = _templateSearchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((t) {
        final name = (t["Name"] ?? t["name"] ?? "").toString().toLowerCase();
        final cond = (t["Condition"] ?? t["condition"] ?? "").toString().toLowerCase();
        final desc = (t["Description"] ?? t["description"] ?? "").toString().toLowerCase();
        final dietType = (t["DietType"] ?? t["dietType"] ?? "").toString().toLowerCase();
        return name.contains(query) || cond.contains(query) || desc.contains(query) || dietType.contains(query);
      }).toList();
    }

    // Apply condition/diet filter
    if (_selectedTemplateCondition != 'All') {
      final chipLower = _selectedTemplateCondition.toLowerCase();
      list = list.where((t) {
        final cond = (t["Condition"] ?? t["condition"] ?? "").toString().toLowerCase();
        final dietType = (t["DietType"] ?? t["dietType"] ?? "").toString().toLowerCase();
        if (chipLower == 'veg') return dietType == 'veg';
        if (chipLower == 'non-veg') return dietType.contains('non');
        return cond.contains(chipLower);
      }).toList();
    }

    if (list.isEmpty) {
      final isFiltering = query.isNotEmpty || _selectedTemplateCondition != 'All';
      return [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDark ? darkModeCardColor : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _lineColor(isDark)),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isFiltering ? Icons.search_off_rounded : Icons.bookmark_border_rounded,
                    size: 28,
                    color: _mutedText(isDark),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isFiltering
                    ? 'No matching templates'
                    : (_templateFilter == 'mine' ? 'No templates saved yet' : 'No shared templates yet'),
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _strongText(isDark),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isFiltering
                    ? 'No templates match your active filters or search terms.'
                    : (_templateFilter == 'mine'
                        ? 'Tap "New Plan" at the top to build one, then "Save template" to reuse it for future patients.'
                        : 'Colleagues haven\'t shared any diet templates with you yet.'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12,
                  height: 1.4,
                  color: _mutedText(isDark),
                ),
              ),
              if (isFiltering) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    _templateSearchController.clear();
                    setState(() => _selectedTemplateCondition = 'All');
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'Clear Filters',
                    style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ];
    }

    return [for (final t in list) _buildTemplateCard(t, isDark)];
  }

  ({Color bg, Color text, Color border}) _getConditionBadgeColors(String condition, bool isDark) {
    final lower = condition.toLowerCase();
    if (lower.contains('diabet') || lower.contains('sugar') || lower.contains('glycemic')) {
      return isDark
          ? (bg: const Color(0xFF1E1B4B), text: const Color(0xFFA5B4FC), border: const Color(0xFF3730A3))
          : (bg: const Color(0xFFEEF2FF), text: const Color(0xFF4338CA), border: const Color(0xFFC7D2FE));
    } else if (lower.contains('hyper') || lower.contains('bp') || lower.contains('heart') || lower.contains('cardio')) {
      return isDark
          ? (bg: const Color(0xFF450A0A), text: const Color(0xFFFCA5A5), border: const Color(0xFF991B1B))
          : (bg: const Color(0xFFFEF2F2), text: const Color(0xFFB91C1C), border: const Color(0xFFFECACA));
    } else if (lower.contains('weight') || lower.contains('obesity') || lower.contains('keto') || lower.contains('fat')) {
      return isDark
          ? (bg: const Color(0xFF451A03), text: const Color(0xFFFCD34D), border: const Color(0xFF92400E))
          : (bg: const Color(0xFFFFFBEB), text: const Color(0xFFB45309), border: const Color(0xFFFDE68A));
    } else if (lower.contains('pco') || lower.contains('thyroid') || lower.contains('women') || lower.contains('hormon')) {
      return isDark
          ? (bg: const Color(0xFF3B0764), text: const Color(0xFFE9D5FF), border: const Color(0xFF7E22CE))
          : (bg: const Color(0xFFFAF5FF), text: const Color(0xFF7E22CE), border: const Color(0xFFE9D5FF));
    } else if (lower.contains('renal') || lower.contains('kidney')) {
      return isDark
          ? (bg: const Color(0xFF042F2E), text: const Color(0xFF5EEAD4), border: const Color(0xFF115E59))
          : (bg: const Color(0xFFF0FDFA), text: const Color(0xFF0F766E), border: const Color(0xFF99F6E4));
    } else {
      return isDark
          ? (bg: const Color(0xFF082F49), text: const Color(0xFF7DD3FC), border: const Color(0xFF075985))
          : (bg: const Color(0xFFF0F9FF), text: const Color(0xFF0369A1), border: const Color(0xFFBAE6FD));
    }
  }

  ({Color bg, Color text, Color border, String label}) _getDietTypeBadge(String dietType, bool isDark) {
    final lower = dietType.toLowerCase();
    if (lower.contains('non')) {
      return (
        bg: isDark ? const Color(0xFF4C0519) : const Color(0xFFFFF1F2),
        text: isDark ? const Color(0xFFFDA4AF) : const Color(0xFFBE123C),
        border: isDark ? const Color(0xFF9F1239) : const Color(0xFFFECDD3),
        label: '🍗 Non-Veg',
      );
    } else if (lower.contains('egg')) {
      return (
        bg: isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB),
        text: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
        border: isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A),
        label: '🥚 Eggetarian',
      );
    } else if (lower.contains('vegan')) {
      return (
        bg: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
        text: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
        border: isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0),
        label: '🌿 Vegan',
      );
    } else {
      return (
        bg: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
        text: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
        border: isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0),
        label: '🥦 Veg',
      );
    }
  }

  Widget _buildTemplateCard(dynamic t, bool isDark) {
    final title = (t["Name"] ?? t["name"] ?? "Diet Plan").toString();
    final condition = (t["Condition"] ?? t["condition"] ?? "").toString().trim();
    final dietType = (t["DietType"] ?? t["dietType"] ?? "Veg").toString();
    num? number(String key) {
      final v = t[key] ?? t[key[0].toLowerCase() + key.substring(1)];
      return v is num ? v : num.tryParse('${v ?? ''}');
    }

    String fmt(num? v) => v == null ? '–' : (v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1));
    final calories = number("TargetCalories");
    final mealCount = number("MealCount")?.toInt() ?? 0;
    final totalDays = number("TotalDays")?.toInt() ?? 1;
    final description = (t["Description"] ?? t["description"] ?? "").toString().trim();
    final isMine = _isMine(t);
    final doctor = t["Doctor"] ?? t["doctor"];
    final owner = doctor is Map ? (doctor["Name"] ?? doctor["name"])?.toString() : null;
    final condBadge = _getConditionBadgeColors(condition.isEmpty ? 'General' : condition, isDark);
    final dietBadge = _getDietTypeBadge(dietType, isDark);

    Widget pill(String label, Color bg, Color fg) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(label, style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, fontWeight: FontWeight.w600, color: fg)),
        );

    final stats = [
      if (calories != null) '${fmt(calories)} kcal',
      'P ${fmt(number("TargetProteinG"))}g',
      'C ${fmt(number("TargetCarbsG"))}g',
      'F ${fmt(number("TargetFatG"))}g',
    ].join('  ·  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _lineColor(isDark)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: _strongText(isDark),
                      ),
                    ),
                  ),
                ),
                _buildTemplateMenu(t, isMine, isDark),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (condition.isNotEmpty) pill(condition, condBadge.bg, condBadge.text),
                      pill(dietBadge.label, dietBadge.bg, dietBadge.text),
                      pill(
                        totalDays > 1 ? '$totalDays-day rotation' : 'Same menu daily',
                        isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        _mutedText(isDark),
                      ),
                    ],
                  ),
                  if (!isMine && owner != null && !_isSystem(t)) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Shared by Dr. $owner',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: _mutedText(isDark)),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, height: 1.35, color: _mutedText(isDark)),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _lineColor(isDark)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.local_fire_department_outlined, size: 15, color: _mutedText(isDark)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            stats,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ),
                        if (mealCount > 0)
                          Text(
                            '$mealCount foods',
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: _mutedText(isDark)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showTemplatePreviewSheet(t),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _strongText(isDark),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: _lineColor(isDark)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: const Text(
                            'Preview',
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _loadTemplateForEditing(t),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: const Text(
                            'Use for patient',
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateMenu(dynamic t, bool isMine, bool isDark) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      icon: Icon(Icons.more_vert_rounded, size: 20, color: _mutedText(isDark)),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (action) {
        switch (action) {
          case 'preview':
            _showTemplatePreviewSheet(t);
          case 'assign':
            _quickPrescribeTemplate(t);
          case 'edit':
            _loadTemplateForEditing(t, asTemplate: true);
          case 'duplicate':
            _duplicateTemplate(t);
          case 'delete':
            _deleteTemplate(t);
        }
      },
      itemBuilder: (_) {
        PopupMenuItem<String> item(String value, IconData icon, String label, {Color? color}) {
          return PopupMenuItem<String>(
            value: value,
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
                Text(label, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: color)),
              ],
            ),
          );
        }

        return [
          item('preview', Icons.visibility_outlined, 'Preview meals'),
          item('assign', Icons.send_rounded, 'Assign as-is', color: _emeraldGreen),
          if (isMine) item('edit', Icons.edit_outlined, 'Edit template'),
          item('duplicate', Icons.copy_rounded, isMine ? 'Duplicate' : 'Copy to My Templates'),
          if (isMine) item('delete', Icons.delete_outline_rounded, 'Delete', color: _roseRed),
        ];
      },
    );
  }


  // ==========================================
  // TAB 2: CUSTOM PLAN BUILDER
  // ==========================================
  Color _strongText(bool isDark) => isDark ? Colors.white : const Color(0xFF0F172A);

  Color _mutedText(bool isDark) => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  Color _lineColor(bool isDark) => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  Widget _buildBuilderTab(bool isDark) {
    return Column(
      children: [
        _buildStepHeader(isDark),
        Expanded(
          child: SingleChildScrollView(
            controller: _builderScrollController,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: switch (_builderStep) {
              0 => _buildDetailsStep(isDark),
              1 => _buildMealsStep(isDark),
              _ => _buildGuidanceStep(isDark),
            },
          ),
        ),
        _buildBuilderBottomBar(isDark),
      ],
    );
  }

  Widget _buildStepHeader(bool isDark) {
    final labels = ['Details', 'Meals', _isTemplateMode ? 'Notes' : "Do's & Don'ts"];

    return Container(
      color: isDark ? darkModeCardColor : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => _goToStep(i),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _builderStep ? _primaryBlue : _lineColor(isDark),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${i + 1}. ${labels[i]}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          fontWeight: i == _builderStep ? FontWeight.w700 : FontWeight.w500,
                          color: i == _builderStep
                              ? (isDark ? const Color(0xFF93C5FD) : _primaryBlue)
                              : _mutedText(isDark),
                        ),
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

  Widget _buildFieldLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final Color foreground = isSelected
        ? (isDark ? const Color(0xFF93C5FD) : _primaryBlue)
        : (isDark ? Colors.white70 : const Color(0xFF334155));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _primaryBlue : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanEditBody(bool isDark) {
    if (_isLoadingPlan) {
      return const Center(child: CircularProgressIndicator(color: _primaryBlue));
    }
    if (_planLoadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 36, color: _mutedText(isDark)),
              const SizedBox(height: 10),
              Text(
                _planLoadError!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: _mutedText(isDark)),
              ),
              TextButton(onPressed: _loadPlanForEditing, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    return _buildBuilderTab(isDark);
  }

  Widget _buildPlanEditBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _amberOrange.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amberOrange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note_rounded, size: 18, color: _amberOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Editing the plan prescribed to ${widget.patientName ?? 'this patient'}. '
              'They will see your changes as soon as you save.',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11.5,
                height: 1.4,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateModeBanner(bool isDark) {
    const accent = Color(0xFF7C3AED);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.18 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark_rounded, size: 18, color: isDark ? const Color(0xFFC4B5FD) : accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editing your template',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFC4B5FD) : accent,
                  ),
                ),
                Text(
                  'Saving updates the template. Nothing is sent to the patient.',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: _mutedText(isDark)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _isSavingTemplate ? null : _stopEditingTemplate,
            style: TextButton.styleFrom(foregroundColor: _roseRed, visualDensity: VisualDensity.compact),
            child: const Text(
              'Stop',
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// Invites the doctor to keep the plan they built for reuse.
  Widget _buildSaveTemplateCard(bool isDark) {
    final own = _ownLoadedTemplate;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _lineColor(isDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bookmark_add_rounded, color: Color(0xFF7C3AED), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reuse this plan later',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _strongText(isDark),
                  ),
                ),
                Text(
                  own != null
                      ? 'Update "${_templateName(own)}" or save a new copy.'
                      : 'Save the meals to My Templates. Only you can see them.',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: _mutedText(isDark)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _totalPrescribedItemsCount == 0 || _isSubmitting ? null : _showSaveTemplateSheet,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7C3AED),
              side: const BorderSide(color: Color(0xFF7C3AED)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 1: plan details ---
  Widget _buildDetailsStep(bool isDark) {
    final template = _selectedTemplate;
    final hasWork = template != null || _totalPrescribedItemsCount > 0;
    final dietTypes = [
      ..._dietTypes,
      if (!_dietTypes.contains(_selectedDietType)) _selectedDietType,
    ];
    final isCustomDuration = !_durationPresets.any((p) => p.days == _validityDaysCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isPlanEditMode) ...[
          _buildPlanEditBanner(isDark),
          const SizedBox(height: 16),
        ] else if (_isTemplateMode) ...[
          _buildTemplateModeBanner(isDark),
          const SizedBox(height: 16),
        ] else if (template != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: isDark ? 0.16 : 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryBlue.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF93C5FD) : _primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isMine(template)
                        ? 'Based on your template: ${_templateName(template)}'
                        : 'Based on template: ${_templateName(template)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF93C5FD) : _primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        _buildTextField(
          controller: _planNameController,
          label: _isTemplateMode ? 'Template name *' : 'Plan title *',
          hint: 'e.g. Diabetes Management Diet',
          isDark: isDark,
          errorText: _titleError,
          onChanged: (value) {
            if (_titleError != null && value.trim().isNotEmpty) {
              setState(() => _titleError = null);
            }
          },
        ),
        const SizedBox(height: 14),

        _buildTextField(
          controller: _conditionController,
          label: 'Medical condition',
          hint: 'e.g. Diabetes, Hypertension, Weight Loss',
          isDark: isDark,
        ),
        const SizedBox(height: 18),

        _buildFieldLabel('Diet type', isDark),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in dietTypes)
              _buildChoiceChip(
                label: type,
                isSelected: _selectedDietType == type,
                isDark: isDark,
                onTap: () => setState(() => _selectedDietType = type),
              ),
          ],
        ),
        const SizedBox(height: 20),

        if (_isTemplateMode) ...[
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'e.g. Low-GI vegetarian plan for newly diagnosed Type 2 diabetes',
            maxLines: 3,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          Text(
            'Only you can see and use this template. Start and end dates are set when you prescribe it.',
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, height: 1.4, color: _mutedText(isDark)),
          ),
        ] else ...[
        _buildFieldLabel('How long should the patient follow it?', isDark),
        InkWell(
          onTap: _pickStartDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: _primaryBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Starts on',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: _mutedText(isDark),
                        ),
                      ),
                      Text(
                        _formatDate(_startDate),
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _strongText(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Change',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF93C5FD) : _primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in _durationPresets)
              _buildChoiceChip(
                label: preset.label,
                isSelected: _validityDaysCount == preset.days,
                isDark: isDark,
                onTap: () => setState(() => _endDate = _addDays(_startDate, preset.days)),
              ),
            _buildChoiceChip(
              label: isCustomDuration ? 'Custom · $_validityDaysCount days' : 'Custom end date',
              icon: Icons.edit_calendar_rounded,
              isSelected: isCustomDuration,
              isDark: isDark,
              onTap: _pickEndDate,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Ends on ${_formatDate(_endDate)} · $_validityDaysCount days in total',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: _mutedText(isDark),
          ),
        ),
        ],

        if (hasWork && !_isTemplateMode && !_isPlanEditMode) ...[
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _confirmStartBlank,
            icon: const Icon(Icons.restart_alt_rounded, size: 16),
            label: const Text('Start over with a blank plan'),
            style: TextButton.styleFrom(
              foregroundColor: _roseRed,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- Step 2: meals ---
  Widget _buildMealsStep(bool isDark) {
    final day = _selectedDayNumber;
    final itemCount = _getDayItemCount(day);
    final daySlots = _mealsByDayAndSlot[day] ?? const <String, List<DoctorMealItemInput>>{};
    final canCopyFromOther =
        itemCount == 0 && _activeDays.any((d) => d != day && _getDayItemCount(d) > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal rotation',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _strongText(isDark),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _dayCount == 1
              ? 'The same meals repeat every day. Add a day to rotate between different menus.'
              : 'The plan cycles through these $_dayCount days until it ends.',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 11.5,
            height: 1.4,
            color: _mutedText(isDark),
          ),
        ),
        const SizedBox(height: 10),
        _buildDayStrip(isDark),
        const SizedBox(height: 18),

        _buildDayHeader(day, itemCount, isDark),
        const SizedBox(height: 10),

        if (_isLoadingTemplateMeals) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(minHeight: 3, color: _primaryBlue),
          ),
          const SizedBox(height: 6),
          Text(
            "Loading the template's meals...",
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: _mutedText(isDark)),
          ),
          const SizedBox(height: 12),
        ],

        if (canCopyFromOther) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: isDark ? 0.16 : 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Day $day is empty. Start from another day?',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _pickDayToCopyFrom,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFF93C5FD) : _primaryBlue,
                    textStyle: const TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Copy a day'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        for (final s in _slots)
          _buildSlotCard(
            day: day,
            slotName: s["name"]!,
            emoji: s["emoji"] ?? "🍽️",
            time: s["time"] ?? '',
            items: daySlots[s["name"]!] ?? const <DoctorMealItemInput>[],
            isDark: isDark,
          ),

        OutlinedButton.icon(
          onPressed: _showAddSlotDialog,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add meal slot'),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? const Color(0xFF93C5FD) : _primaryBlue,
            minimumSize: const Size.fromHeight(46),
            side: BorderSide(color: _primaryBlue.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayStrip(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final day in _activeDays) ...[
            Builder(
              builder: (context) {
                final isSelected = _selectedDayNumber == day;
                final itemCount = _getDayItemCount(day);
                final cal = _getDayCalories(day);
                final canRemove = _dayCount > 1;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedDayNumber = day),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.fromLTRB(12, 8, canRemove ? 6 : 12, 8),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [_primaryBlue, Color(0xFF1D4ED8)],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : (isDark ? darkModeCardColor : Colors.white),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? _primaryBlue
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            width: isSelected ? 1.6 : 1.2,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: _primaryBlue.withValues(alpha: 0.32),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            else
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1.5),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 12,
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : _primaryBlue,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Day $day',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : _strongText(isDark),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withValues(alpha: 0.22)
                                            : (itemCount > 0
                                                ? _emeraldGreen.withValues(alpha: isDark ? 0.22 : 0.12)
                                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        _dayItemsLabel(itemCount),
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : (itemCount > 0
                                                  ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                                                  : _mutedText(isDark)),
                                        ),
                                      ),
                                    ),
                                    if (cal > 0) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '$cal cal',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white.withValues(alpha: 0.9)
                                              : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            if (canRemove) ...[
                              const SizedBox(width: 6),
                              Tooltip(
                                message: 'Remove Day $day',
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _removeDay(day),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.24)
                                          : _roseRed.withValues(alpha: isDark ? 0.2 : 0.09),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 13,
                                      color: isSelected ? Colors.white : _roseRed,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          if (_dayCount < _maxDays)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _addDay,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _emeraldGreen.withValues(alpha: isDark ? 0.14 : 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _emeraldGreen.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          color: _emeraldGreen.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Add day',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                            ),
                          ),
                          Text(
                            'Day ${_dayCount + 1}',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF6EE7B7).withValues(alpha: 0.8)
                                  : const Color(0xFF047857).withValues(alpha: 0.8),
                            ),
                          ),
                        ],
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

  String _dayItemsLabel(int count) {
    if (count == 0) return 'Empty';
    return count == 1 ? '1 item' : '$count items';
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, {Color? color}) {
    return PopupMenuItem<String>(
      value: value,
      height: 42,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChip({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: _mutedText(isDark),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  /// Selected day's title and totals, with the actions that apply to it.
  Widget _buildDayHeader(int day, int itemCount, bool isDark) {
    final totals = _dayTotals(day);
    final hasItems = itemCount > 0;
    final multiDay = _dayCount > 1;

    final actions = <PopupMenuEntry<String>>[
      if (hasItems && _dayCount < _maxDays)
        _menuItem('duplicate', Icons.content_copy_rounded, 'Duplicate as Day ${_dayCount + 1}'),
      if (multiDay) _menuItem('copyFrom', Icons.download_rounded, 'Copy from another day'),
      if (multiDay && hasItems)
        _menuItem('copyAll', Icons.copy_all_rounded, 'Copy this day to all days'),
      if (hasItems) _menuItem('clear', Icons.clear_all_rounded, 'Clear this day'),
      if (multiDay)
        _menuItem('remove', Icons.delete_outline_rounded, 'Remove Day $day', color: _roseRed),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _lineColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        multiDay ? 'Day $day of $_dayCount' : 'Daily Menu',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF93C5FD) : _primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _dayItemsLabel(itemCount),
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        color: _mutedText(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              if (multiDay)
                InkWell(
                  onTap: () => _removeDay(day),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _roseRed.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _roseRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 14, color: _roseRed),
                        const SizedBox(width: 4),
                        Text(
                          'Remove Day $day',
                          style: const TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _roseRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  tooltip: 'More Day options',
                  icon: Icon(Icons.more_horiz_rounded, color: _mutedText(isDark)),
                  color: isDark ? darkModeCardColor : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    switch (value) {
                      case 'duplicate':
                        _addDay(copyFrom: day);
                      case 'copyFrom':
                        _pickDayToCopyFrom();
                      case 'copyAll':
                        _copyDayToAll(day);
                      case 'clear':
                        _clearDay(day);
                      case 'remove':
                        _removeDay(day);
                    }
                  },
                  itemBuilder: (_) => actions,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Macro breakdown chips
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildMacroChip(
                label: 'Calories',
                value: '${totals.calories} kcal',
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
              _buildMacroChip(
                label: 'Protein',
                value: '${_fmtGrams(totals.protein)}g',
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
              _buildMacroChip(
                label: 'Carbs',
                value: '${_fmtGrams(totals.carbs)}g',
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
              _buildMacroChip(
                label: 'Fat',
                value: '${_fmtGrams(totals.fat)}g',
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard({
    required int day,
    required String slotName,
    required String emoji,
    required String time,
    required List<DoctorMealItemInput> items,
    required bool isDark,
  }) {
    final Color slotColor = _getSlotColor(slotName);
    final int slotCal = items.fold(0, (sum, item) => sum + item.calories);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _lineColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot header: name, time and slot actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 2, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: slotColor.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 19)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slotName,
                        maxLines: 2,
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _strongText(isDark),
                        ),
                      ),
                      InkWell(
                        onTap: () => _editSlotTime(slotName, time),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded, size: 12, color: _mutedText(isDark)),
                            const SizedBox(width: 4),
                            Text(
                              time,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: _mutedText(isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (items.isNotEmpty && slotCal > 0)
                  Text(
                    '$slotCal kcal',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    ),
                  ),
                PopupMenuButton<String>(
                  tooltip: '$slotName options',
                  icon: Icon(Icons.more_vert_rounded, size: 20, color: _mutedText(isDark)),
                  color: isDark ? darkModeCardColor : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'time') {
                      _editSlotTime(slotName, time);
                    } else {
                      _removeMealSlot(slotName);
                    }
                  },
                  itemBuilder: (_) => [
                    _menuItem('time', Icons.schedule_rounded, 'Change time'),
                    if (_slots.length > 1)
                      _menuItem('remove', Icons.delete_outline_rounded, 'Remove meal slot', color: _roseRed),
                  ],
                ),
              ],
            ),
          ),

          for (var i = 0; i < items.length; i++) ...[
            Divider(height: 1, color: _lineColor(isDark)),
            _buildMealItemRow(
              day: day,
              slotName: slotName,
              slotTime: time,
              item: items[i],
              index: i,
              isDark: isDark,
            ),
          ],

          Divider(height: 1, color: _lineColor(isDark)),
          InkWell(
            onTap: () => _openFoodPicker(slotName, time),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF93C5FD) : _primaryBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Add food',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF93C5FD) : _primaryBlue,
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

  /// One food in a slot. Tapping it opens the editor.
  Widget _buildMealItemRow({
    required int day,
    required String slotName,
    required String slotTime,
    required DoctorMealItemInput item,
    required int index,
    required bool isDark,
  }) {
    final hasMacros = (item.proteinG ?? 0) + (item.carbsG ?? 0) + (item.fatG ?? 0) > 0;
    final weight = formatDietWeight(item.weightAmount, item.weightUnit);
    final facts = [
      formatDietPortion(item.quantity, item.unit),
      if (item.calories > 0) '${item.calories} kcal',
      if (hasMacros)
        'P ${_fmtGrams(item.proteinG)}g · C ${_fmtGrams(item.carbsG)}g · F ${_fmtGrams(item.fatG)}g',
    ].join(' · ');
    final notes = item.notes?.trim() ?? '';

    return InkWell(
      onTap: () => _openFoodPicker(slotName, slotTime, existingItem: item, editIndex: index),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 9, 2, 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DietFoodImage(imageUrl: item.imageUrl, category: item.category ?? '', foodType: item.foodType ?? '', size: 40),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.foodName,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _strongText(isDark),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    facts,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11.5,
                      height: 1.4,
                      color: _mutedText(isDark),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // The portion weight can be changed right here, without reopening the food.
                  InkWell(
                    onTap: () => _editItemWeight(day, slotName, index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(alpha: isDark ? 0.18 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _primaryBlue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            weight == null ? Icons.add_rounded : Icons.scale_outlined,
                            size: 13,
                            color: isDark ? const Color(0xFF93C5FD) : _primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            weight ?? 'Add weight',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF93C5FD) : _primaryBlue,
                            ),
                          ),
                          if (weight != null) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.edit_outlined, size: 12, color: isDark ? const Color(0xFF93C5FD) : _primaryBlue),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Note: $notes',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove ${item.foodName}',
              icon: Icon(Icons.close_rounded, size: 18, color: _mutedText(isDark)),
              onPressed: () => _removeMealItem(day, slotName, index),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 3: guidance ---
  Widget _buildGuidanceStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isTemplateMode ? 'Clinical notes' : "Do's & Don'ts",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _strongText(isDark),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _isTemplateMode
              ? 'Optional. Filled in as the advice whenever you prescribe this template.'
              : 'Shown to the patient right under their daily intake. Tap a suggestion to add it.',
          style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: _mutedText(isDark)),
        ),
        const SizedBox(height: 12),

        if (!_isTemplateMode) ...[
        _buildChipSection(
          title: "Do's · foods & habits to follow",
          icon: Icons.check_circle_rounded,
          color: _emeraldGreen,
          chips: _foodsToPrefer,
          suggestions: _guidanceSuggestions(dos: true),
          inputController: _preferInputController,
          isDark: isDark,
          onAdd: (item) {
            if (!_foodsToPrefer.contains(item)) {
              setState(() => _foodsToPrefer.add(item));
            }
          },
          onRemove: (item) => setState(() => _foodsToPrefer.remove(item)),
        ),
        const SizedBox(height: 12),

        _buildChipSection(
          title: "Don'ts · foods & habits to avoid",
          icon: Icons.cancel_rounded,
          color: _roseRed,
          chips: _foodsToAvoid,
          suggestions: _guidanceSuggestions(dos: false),
          inputController: _avoidInputController,
          isDark: isDark,
          onAdd: (item) {
            if (!_foodsToAvoid.contains(item)) {
              setState(() => _foodsToAvoid.add(item));
            }
          },
          onRemove: (item) => setState(() => _foodsToAvoid.remove(item)),
        ),
        const SizedBox(height: 16),
        ],

        _buildTextField(
          controller: _notesController,
          label: "Doctor's advice",
          hint: 'e.g. Drink 2.5–3 L of water through the day. 30-min brisk walk daily.',
          maxLines: 4,
          isDark: isDark,
        ),

        if (!_isTemplateMode) ...[
          const SizedBox(height: 20),
          _buildSaveTemplateCard(isDark),
        ],
      ],
    );
  }

  Widget _buildBuilderBottomBar(bool isDark) {
    final items = _totalPrescribedItemsCount;
    final isLastStep = _builderStep == 2;
    final String primaryLabel = switch (_builderStep) {
      0 => 'Next: Add Meals',
      1 => _isTemplateMode ? 'Next: Notes' : "Next: Do's & Don'ts",
      _ => _isTemplateMode ? 'Save Template' : (_isPlanEditMode ? 'Save Changes' : 'Review & Prescribe'),
    };
    final busy = _isSubmitting || _isSavingTemplate;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: bottomInset > 0 ? bottomInset + 6 : 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        border: Border(top: BorderSide(color: _lineColor(isDark))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (items > 0)
            InkWell(
              onTap: _showSchedulePreview,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isTemplateMode
                            ? '$items food ${items == 1 ? 'item' : 'items'} · $_rotationLabel'
                            : '$items food ${items == 1 ? 'item' : 'items'} · $_rotationLabel · $_validityDaysCount days',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _mutedText(isDark),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Preview',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF93C5FD) : _primaryBlue,
                      ),
                    ),
                    if (!_isTemplateMode) ...[
                      const SizedBox(width: 6),
                      Text('·', style: TextStyle(color: _mutedText(isDark))),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: busy ? null : _showSaveTemplateSheet,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark_add_outlined,
                              size: 15,
                              color: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Save template',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          Row(
            children: [
              if (_builderStep > 0) ...[
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _goToStep(_builderStep - 1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: busy
                        ? null
                        : (isLastStep
                            ? (_isTemplateMode
                                ? _saveEditedTemplate
                                : (_isPlanEditMode ? _savePlanChanges : _submitDietPlanFromBuilder))
                            : () => _goToStep(_builderStep + 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLastStep
                          ? (_isTemplateMode ? const Color(0xFF7C3AED) : _emeraldGreen)
                          : _primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            primaryLabel,
                            style: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            hintStyle: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  /// Common do's or don'ts for the plan's condition, not yet added.
  List<String> _guidanceSuggestions({required bool dos}) {
    final c = _conditionController.text.toLowerCase();
    final list = <String>[];
    if (c.contains('diabet') || c.contains('sugar')) {
      list.addAll(dos
          ? ['Millets & whole grains', 'Sprouts', 'Methi seed water', 'Salad before meals']
          : ['Refined sugar', 'Maida', 'Fruit juices', 'Excess white rice']);
    }
    if (c.contains('bp') || c.contains('hypertens') || c.contains('blood pressure')) {
      list.addAll(dos
          ? ['Low-salt cooking', 'Banana & coconut water', 'Fresh vegetables']
          : ['Pickles & papad', 'Processed foods', 'Extra salt at the table']);
    }
    if (c.contains('weight') || c.contains('obes')) {
      list.addAll(dos ? ['High-protein breakfast', 'Smaller portions'] : ['Sweets & desserts', 'Packaged snacks']);
    }
    if (c.contains('pcod') || c.contains('pcos') || c.contains('thyroid')) {
      list.addAll(dos ? ['High-fibre foods', 'Regular exercise'] : ['Refined carbs', 'Sugary drinks']);
    }
    if (c.contains('fever') || c.contains('cold') || c.contains('flu')) {
      list.addAll(dos
          ? ['Plenty of fluids', 'Light, easily digested food', 'Rest well']
          : ['Cold drinks', 'Oily & spicy food']);
    }
    list.addAll(dos
        ? ['Drink 2.5–3 L water daily', 'Eat meals on time', 'Home-cooked food', '30-minute walk daily', 'Seasonal fruits']
        : ['Sugary drinks', 'Fried foods', 'Skipping meals', 'Late-night eating', 'Junk food']);
    final chosen = (dos ? _foodsToPrefer : _foodsToAvoid).map((e) => e.toLowerCase()).toSet();
    final seen = <String>{};
    return list.where((s) => !chosen.contains(s.toLowerCase()) && seen.add(s.toLowerCase())).take(8).toList();
  }

  Widget _buildChipSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> chips,
    List<String> suggestions = const [],
    required TextEditingController inputController,
    required bool isDark,
    required Function(String) onAdd,
    required Function(String) onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (chips.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.map((c) {
                return Chip(
                  label: Text(
                    c,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  backgroundColor: color.withOpacity(isDark ? 0.2 : 0.08),
                  deleteIconColor: color,
                  onDeleted: () => onRemove(c),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: color.withOpacity(0.3)),
                  ),
                );
              }).toList(),
            ),

          if (suggestions.isNotEmpty) ...[
            if (chips.isNotEmpty) const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final sug in suggestions)
                  InkWell(
                    onTap: () => onAdd(sug),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 13, color: color),
                          const SizedBox(width: 3),
                          Text(
                            sug,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: inputController,
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) {
                        onAdd(val.trim());
                        inputController.clear();
                      }
                    },
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add your own, then tap +',
                      hintStyle: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  if (inputController.text.trim().isNotEmpty) {
                    onAdd(inputController.text.trim());
                    inputController.clear();
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getSlotColor(String slot) {
    final s = slot.toLowerCase();
    if (s.contains('early')) return const Color(0xFFF59E0B);
    if (s.contains('breakfast')) return const Color(0xFFEAB308);
    if (s.contains('mid-morning')) return const Color(0xFF10B981);
    if (s.contains('lunch')) return const Color(0xFF2563EB);
    if (s.contains('snack') || s.contains('evening')) return const Color(0xFF8B5CF6);
    if (s.contains('dinner')) return const Color(0xFF6366F1);
    if (s.contains('bed')) return const Color(0xFF475569);
    return _primaryBlue;
  }

  String _getSlotEmoji(String slot) {
    final s = slot.toLowerCase();
    if (s.contains('early')) return '🌅';
    if (s.contains('breakfast')) return '🍳';
    if (s.contains('mid-morning')) return '🍎';
    if (s.contains('lunch')) return '🥗';
    if (s.contains('snack') || s.contains('evening')) return '☕';
    if (s.contains('dinner')) return '🍲';
    if (s.contains('bed')) return '🥛';
    return '🍽️';
  }
}

/// Popup for changing one food's portion weight. Owns its text field, so the
/// field stays valid while the popup animates closed.
class _PortionWeightDialog extends StatefulWidget {
  final DoctorMealItemInput item;

  const _PortionWeightDialog({required this.item});

  @override
  State<_PortionWeightDialog> createState() => _PortionWeightDialogState();
}

class _PortionWeightDialogState extends State<_PortionWeightDialog> {
  late final TextEditingController _controller;
  late String _unit;
  String? _error;

  @override
  void initState() {
    super.initState();
    final weight = widget.item.weightAmount;
    _controller = TextEditingController(
      text: weight == null ? '' : (weight % 1 == 0 ? weight.toInt().toString() : weight.toStringAsFixed(1)),
    );
    _unit = widget.item.weightUnit ?? 'g';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter a weight above 0');
      return;
    }
    Navigator.pop(context, (amount: value, unit: _unit));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final presets = dietWeightPresets(_unit);
    final old = widget.item.weightAmount;
    final scales = old != null && old > 0 && (widget.item.weightUnit ?? 'g') == _unit;

    return AppDialog(
      title: 'Portion weight',
      message: widget.item.foodName,
      icon: Icons.scale_outlined,
      primaryLabel: 'Save',
      onPrimary: _save,
      secondaryLabel: 'Cancel',
      onSecondary: () => Navigator.pop(context),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _save(),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'e.g. 200',
                    suffixText: _unit,
                    errorText: _error,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 96,
                child: DietOptionField(
                  value: _unit,
                  placeholder: 'unit',
                  pickerTitle: 'Weight unit',
                  options: kDietWeightUnits,
                  onChanged: (v) => setState(() => _unit = v),
                ),
              ),
            ],
          ),
          if (presets.isNotEmpty) const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in presets)
                ActionChip(
                  label: Text('$value $_unit', style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12.5)),
                  onPressed: () => setState(() {
                    _controller.text = '$value';
                    _error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            scales
                ? 'Calories and macros will change in proportion to the new weight.'
                : 'Calories and macros stay as they are.',
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: mutedColor),
          ),
        ],
      ),
    );
  }
}

typedef _SaveTemplateCallback = Future<Map<String, dynamic>?> Function({
  required String name,
  required String description,
  required bool update,
});

/// Bottom sheet behind "Save to My Templates". Pops the saved template.
class _SaveTemplateSheet extends StatefulWidget {
  final String initialName;
  final String initialDescription;
  /// Name of the doctor's own template the plan was built from, if any. When
  /// set, the doctor can update that template instead of saving a new one.
  final String? ownTemplateName;
  /// Lower-case names the template may not take when updating (all of the
  /// doctor's other templates).
  final Set<String> existingNames;
  /// Lower-case names of all of the doctor's templates, for a new one.
  final Set<String> allNames;
  final int itemCount;
  final int dayCount;
  final _SaveTemplateCallback onSave;

  const _SaveTemplateSheet({
    required this.initialName,
    required this.initialDescription,
    required this.ownTemplateName,
    required this.existingNames,
    required this.allNames,
    required this.itemCount,
    required this.dayCount,
    required this.onSave,
  });

  @override
  State<_SaveTemplateSheet> createState() => _SaveTemplateSheetState();
}

class _SaveTemplateSheetState extends State<_SaveTemplateSheet> {
  static const Color _accent = Color(0xFF7C3AED);
  static const Color _roseRed = Color(0xFFEF4444);

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late bool _update;
  String? _nameError;
  String? _descError;
  String? _serverError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _update = widget.ownTemplateName != null;
    _nameCtrl = TextEditingController(text: _update ? widget.ownTemplateName : _suggestNewName(widget.initialName));
    _descCtrl = TextEditingController(text: widget.initialDescription == 'null' ? '' : widget.initialDescription);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  /// A name that does not clash with the doctor's templates.
  String _suggestNewName(String base) {
    final name = base.trim();
    if (name.isEmpty || !widget.allNames.contains(name.toLowerCase())) return name;
    var n = 1;
    while (widget.allNames.contains('$name (copy${n == 1 ? '' : ' $n'})'.toLowerCase())) {
      n++;
    }
    return '$name (Copy${n == 1 ? '' : ' $n'})';
  }

  void _setMode(bool update) {
    if (update == _update) return;
    setState(() {
      _update = update;
      _nameError = null;
      _serverError = null;
      _nameCtrl.text = update ? widget.ownTemplateName ?? _nameCtrl.text : _suggestNewName(_nameCtrl.text);
    });
  }

  bool _validate() {
    final name = _nameCtrl.text.trim();
    final taken = _update ? widget.existingNames : widget.allNames;
    String? nameError;
    if (name.isEmpty) {
      nameError = 'Enter a template name';
    } else if (name.length > 200) {
      nameError = 'Keep the name under 200 characters';
    } else if (taken.contains(name.toLowerCase())) {
      nameError = 'You already have a template with this name';
    }
    final descError = _descCtrl.text.trim().length > 1000 ? 'Keep the description under 1000 characters' : null;
    setState(() {
      _nameError = nameError;
      _descError = descError;
      _serverError = null;
    });
    return nameError == null && descError == null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      final saved = await widget.onSave(name: name, description: _descCtrl.text.trim(), update: _update);
      if (!mounted) return;
      Navigator.pop(context, saved ?? {"Name": name});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverError = dietApiErrorMessage(e, "Couldn't save the template. Please try again.");
      });
    }
  }

  InputDecoration _decoration(bool isDark, String hint, String? error) {
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      errorText: error,
      errorMaxLines: 2,
      hintStyle: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: 12.5,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: border(isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      enabledBorder: border(isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      focusedBorder: border(_accent, 1.5),
    );
  }

  Widget _modeOption({
    required bool isDark,
    required bool value,
    required String title,
    required String subtitle,
  }) {
    final selected = _update == value;
    return InkWell(
      onTap: _saving ? null : () => _setMode(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _accent.withValues(alpha: isDark ? 0.18 : 0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _accent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              size: 20,
              color: selected ? _accent : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final strong = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final labelStyle = TextStyle(
      fontFamily: appPoppinFont,
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? darkModeCardColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bookmark_add_rounded, color: _accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Save to My Templates',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: strong,
                            ),
                          ),
                          Text(
                            '${widget.itemCount} food items · '
                            '${widget.dayCount == 1 ? 'same meals daily' : '${widget.dayCount}-day rotation'} · only visible to you',
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.ownTemplateName != null) ...[
                  _modeOption(
                    isDark: isDark,
                    value: true,
                    title: 'Update "${widget.ownTemplateName}"',
                    subtitle: 'Replace the saved meals with these',
                  ),
                  const SizedBox(height: 8),
                  _modeOption(
                    isDark: isDark,
                    value: false,
                    title: 'Save as a new template',
                    subtitle: 'Keep the original as it is',
                  ),
                  const SizedBox(height: 16),
                ],
                Text('Template name *', style: labelStyle),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  enabled: !_saving,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: strong),
                  decoration: _decoration(isDark, 'e.g. Diabetic Veg – 1500 kcal', _nameError)
                      .copyWith(counterText: ''),
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),
                const SizedBox(height: 12),
                Text('Description', style: labelStyle),
                const SizedBox(height: 6),
                TextField(
                  controller: _descCtrl,
                  enabled: !_saving,
                  maxLines: 2,
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: strong),
                  decoration: _decoration(isDark, 'Optional. When to use this template.', _descError),
                ),
                if (_serverError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _roseRed.withValues(alpha: isDark ? 0.15 : 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _roseRed.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 16, color: _roseRed),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _serverError!,
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: strong),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : const Color(0xFF334155),
                            side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _accent.withValues(alpha: 0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _update ? 'Update Template' : 'Save Template',
                                  style: const TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
