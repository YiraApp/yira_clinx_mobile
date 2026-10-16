import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/features/data/data_sources/diet/diet_api_error.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/doctor_prescribe_diet_sheet.dart'
    show DoctorMealItemInput;
import 'package:yiraclinics/features/presentation/doctor/diet/diet_option_picker.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/diet_food_image.dart';

/// Splits a serving such as "2 pieces (80g)" into its count (2) and its unit
/// ("pieces"), so the doctor edits them separately. A unit with no leading
/// number ("bowl") counts as one.
({double amount, String unit}) _splitServing(String serving) {
  final text = serving.trim();
  final match = RegExp(r'^(\d+(?:\.\d+)?)\s+(.+)$').firstMatch(text);
  if (match == null) return (amount: 1, unit: text);
  final unit = match.group(2)!.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  final amount = double.parse(match.group(1)!);
  return (amount: amount > 0 ? amount : 1, unit: unit.isEmpty ? 'serving' : unit);
}

/// Finds the weight inside a serving such as "2 pieces (80g)" or "1 glass (250 ml)".
({double amount, String unit})? _servingWeight(String serving) {
  final match = RegExp(r'(\d+(?:\.\d+)?)\s*(g|gm|gms|grams?|ml)\b', caseSensitive: false).firstMatch(serving);
  if (match == null) return null;
  final amount = double.parse(match.group(1)!);
  if (amount <= 0) return null;
  return (amount: amount, unit: match.group(2)!.toLowerCase() == 'ml' ? 'ml' : 'g');
}

/// A food from the master database, with nutrition for one serving.
class _FoodOption {
  final int? id;
  final String name;
  final String serving;
  final String foodType;
  final String category;
  final String imageUrl;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const _FoodOption({
    required this.id,
    required this.name,
    required this.serving,
    required this.foodType,
    required this.category,
    required this.imageUrl,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  ({double amount, String unit}) get servingParts => _splitServing(serving);

  /// The food search returns database columns (`Name`, `CaloriesPerServing`);
  /// the recommendations endpoint uses short keys (`name`, `cal`).
  factory _FoodOption.fromJson(Map<String, dynamic> json) {
    double number(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        final parsed = value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
        if (parsed != null && parsed > 0) return parsed;
      }
      return 0;
    }

    String text(List<String> keys) {
      for (final key in keys) {
        final value = json[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    final id = json['Id'] ?? json['id'];
    final serving = text(['ServingSize', 'servingSize', 'unit']);

    return _FoodOption(
      id: id is num ? id.toInt() : int.tryParse(id?.toString() ?? ''),
      name: text(['Name', 'name']),
      serving: serving.isEmpty ? 'serving' : serving,
      foodType: text(['FoodType', 'foodType']),
      category: text(['Category', 'category']),
      imageUrl: text(['ImageUrl', 'imageUrl']),
      calories: number(['CaloriesPerServing', 'cal', 'calories', 'CaloriesPer100g']),
      protein: number(['ProteinG', 'proteinG', 'p']),
      carbs: number(['CarbsG', 'carbsG', 'c']),
      fat: number(['FatG', 'fatG', 'f']),
    );
  }
}

/// Bottom sheet for adding a food to a meal slot, or editing one.
///
/// The doctor picks a food from the master database (suggestions for the slot
/// are shown before they type) or enters a custom one. Nutrition follows the
/// quantity until the doctor overrides a value.
class DietFoodPickerSheet extends StatefulWidget {
  final String slotName;
  final String slotTime;
  final String? dayLabel;
  final DoctorMealItemInput? existingItem;
  final String authToken;
  final String orgId;
  final ValueChanged<DoctorMealItemInput> onSubmit;
  /// Offers saving a custom food to the doctor's own food list. Off for patients.
  final bool allowSaveToList;

  const DietFoodPickerSheet({
    super.key,
    required this.slotName,
    required this.slotTime,
    this.dayLabel,
    this.existingItem,
    required this.authToken,
    required this.orgId,
    required this.onSubmit,
    this.allowSaveToList = true,
  });

  static Future<void> show(
    BuildContext context, {
    required String slotName,
    required String slotTime,
    String? dayLabel,
    DoctorMealItemInput? existingItem,
    required String authToken,
    required String orgId,
    required ValueChanged<DoctorMealItemInput> onSubmit,
    bool allowSaveToList = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DietFoodPickerSheet(
        slotName: slotName,
        slotTime: slotTime,
        dayLabel: dayLabel,
        existingItem: existingItem,
        authToken: authToken,
        orgId: orgId,
        onSubmit: onSubmit,
        allowSaveToList: allowSaveToList,
      ),
    );
  }

  @override
  State<DietFoodPickerSheet> createState() => _DietFoodPickerSheetState();
}

class _DietFoodPickerSheetState extends State<DietFoodPickerSheet> {
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _emeraldGreen = Color(0xFF10B981);

  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _unitCtrl = TextEditingController(text: 'serving');
  final _calCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  /// Unit of the portion weight: "g" for solids, "ml" for drinks.
  String _weightUnit = 'g';

  /// How many slot suggestions to ask for, and how many to show. The server
  /// returns them sorted by category, so a short page would be one category.
  static const int _suggestionFetchLimit = 300;
  static const int _suggestionShowLimit = 40;

  /// Food categories that suit each kind of meal slot, most relevant first.
  static const Map<String, List<String>> _slotCategories = {
    'early': ['Beverage', 'Snack'],
    'breakfast': ['Breakfast', 'Dairy', 'Beverage'],
    'mid': ['Fruit', 'Snack', 'Beverage'],
    'lunch': ['Grain', 'Protein', 'Vegetable', 'Dairy'],
    'snack': ['Snack', 'Fruit', 'Beverage'],
    'evening': ['Snack', 'Fruit', 'Beverage'],
    'dinner': ['Grain', 'Protein', 'Vegetable', 'Dairy', 'Beverage'],
    'bed': ['Dairy', 'Beverage'],
  };

  Timer? _debounce;
  int _searchSeq = 0;
  List<_FoodOption> _results = const [];
  bool _isLoading = false;
  bool _loadFailed = false;

  /// False while choosing a food, true while setting its quantity and details.
  bool _showDetails = false;
  int? _foodItemId;
  String? _nameError;
  int _addedCount = 0;

  /// How much the quantity buttons add or remove: whole pieces for foods
  /// counted in pieces, half units otherwise.
  double _qtyStep = 0.5;

  /// The database's standard serving for the chosen food, shown for reference.
  String? _servingNote;

  /// Veg / non-veg marker, category and photo of the chosen food, if known.
  String _foodType = '';
  String _foodCategory = '';
  String? _imageUrl;

  // Optional parts of the form stay folded away until the doctor asks for them.
  bool _editingName = false;
  bool _showNutritionFields = false;
  bool _showNotes = false;

  // Nutrition for a quantity of 1. The fields show these multiplied by the
  // quantity; typing into a field replaces the matching base value.
  double? _baseCal;
  double? _baseProtein;
  double? _baseCarbs;
  double? _baseFat;
  double? _baseWeight;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    if (item != null) {
      // Older items kept the serving count inside the unit ("2 pieces (80g)").
      final serving = _splitServing(item.unit);
      final qty = (item.quantity > 0 ? item.quantity : 1.0) * serving.amount;
      _showDetails = true;
      _foodItemId = item.foodItemId;
      _nameCtrl.text = item.foodName;
      _qtyCtrl.text = _fmt(qty);
      _unitCtrl.text = serving.unit;
      _notesCtrl.text = item.notes ?? '';
      _baseCal = item.calories > 0 ? item.calories / qty : null;
      _baseProtein = item.proteinG == null ? null : item.proteinG! / qty;
      _baseCarbs = item.carbsG == null ? null : item.carbsG! / qty;
      _baseFat = item.fatG == null ? null : item.fatG! / qty;
      // Older items only had the weight inside the unit text ("2 pieces (80g)").
      final legacyWeight = _servingWeight(item.unit);
      final totalWeight = item.weightAmount ??
          (legacyWeight == null ? null : legacyWeight.amount * (item.quantity > 0 ? item.quantity : 1.0));
      _weightUnit = item.weightAmount != null ? (item.weightUnit ?? 'g') : (legacyWeight?.unit ?? 'g');
      _baseWeight = totalWeight == null ? null : totalWeight / qty;
      _showNotes = _notesCtrl.text.trim().isNotEmpty;
      _imageUrl = item.imageUrl;
      _foodCategory = item.category ?? '';
      _foodType = item.foodType ?? '';
      _refreshNutritionFields();
    } else {
      _loadFoods('');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _unitCtrl.dispose();
    _calCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _fmt(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  double get _qty => double.tryParse(_qtyCtrl.text.trim()) ?? 0;

  /// With no query this lists foods that suit the slot; with a query it
  /// searches every food, since a slot filter would hide valid matches.
  Future<void> _loadFoods(String query) async {
    final seq = ++_searchSeq;
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    try {
      final res = await ApiClient().account(showSuccessSnack: false).get(
        URLs.doctorDietFoodsUrl,
        queryParameters: {
          if (query.isNotEmpty) 'search': query else 'slot': widget.slotName,
          'limit': query.isNotEmpty ? 30 : _suggestionFetchLimit,
        },
        options: Options(
          headers: {
            if (widget.authToken.isNotEmpty)
              HttpHeaders.authorizationHeader: 'Bearer ${widget.authToken}',
            'x-org-id': widget.orgId,
          },
        ),
      );
      if (!mounted || seq != _searchSeq) return;

      final items = res.data is Map ? res.data['items'] : null;
      final foods = items is List
          ? items
              .whereType<Map>()
              .map((m) => _FoodOption.fromJson(Map<String, dynamic>.from(m)))
              .where((f) => f.name.isNotEmpty)
              .toList()
          : const <_FoodOption>[];
      setState(() {
        _isLoading = false;
        _results = query.isEmpty ? _spreadAcrossCategories(foods) : foods;
      });
    } catch (_) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _isLoading = false;
        _loadFailed = true;
        _results = const [];
      });
    }
  }

  /// Takes one food from each category in turn, so suggestions for "Lunch"
  /// mix grains, proteins and vegetables instead of listing one category.
  List<_FoodOption> _spreadAcrossCategories(List<_FoodOption> foods) {
    final slot = widget.slotName.toLowerCase();
    final preferred = _slotCategories.entries
        .firstWhere((e) => slot.contains(e.key), orElse: () => const MapEntry('', <String>[]))
        .value;

    final byCategory = <String, List<_FoodOption>>{};
    for (final food in foods) {
      byCategory.putIfAbsent(food.category, () => []).add(food);
    }
    final order = [
      ...preferred.where(byCategory.containsKey),
      ...byCategory.keys.where((c) => !preferred.contains(c)),
    ];

    final spread = <_FoodOption>[];
    for (var i = 0; spread.length < _suggestionShowLimit && spread.length < foods.length; i++) {
      for (final category in order) {
        final list = byCategory[category]!;
        if (i < list.length && spread.length < _suggestionShowLimit) spread.add(list[i]);
      }
    }
    return spread;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _loadFoods(value.trim()));
    setState(() {});
  }

  void _pickFood(_FoodOption food) {
    FocusScope.of(context).unfocus();
    final serving = food.servingParts;
    setState(() {
      _foodItemId = food.id;
      _saveToMyList = false;
      _nameCtrl.text = food.name;
      // The database gives nutrition for one standard serving ("2 pieces");
      // start from that serving and keep the values per single unit.
      _unitCtrl.text = serving.unit;
      _qtyCtrl.text = _fmt(serving.amount);
      _qtyStep = serving.amount > 1 ? 1 : 0.5;
      _servingNote = food.calories > 0
          ? 'Standard serving: ${food.serving} · ${food.calories.round()} kcal'
          : 'Standard serving: ${food.serving}';
      _baseCal = food.calories > 0 ? food.calories / serving.amount : null;
      _baseProtein = food.protein / serving.amount;
      _baseCarbs = food.carbs / serving.amount;
      _baseFat = food.fat / serving.amount;
      final weight = _servingWeight(food.serving);
      _baseWeight = weight == null ? null : weight.amount / serving.amount;
      _weightUnit = weight?.unit ?? 'g';
      _foodType = food.foodType;
      _foodCategory = food.category;
      _imageUrl = food.imageUrl.isEmpty ? null : food.imageUrl;
      _editingName = false;
      _showNutritionFields = false;
      _showNotes = false;
      _notesCtrl.clear();
      _nameError = null;
      _refreshNutritionFields();
      _showDetails = true;
    });
  }

  /// When true, the submit button will also save the food to the org's list.
  bool _saveToMyList = false;

  void _useCustomFood(String name, {bool saveToList = false}) {
    setState(() {
      _foodItemId = null;
      _saveToMyList = saveToList;
      _nameCtrl.text = name;
      _qtyStep = 0.5;
      _servingNote = null;
      _unitCtrl.text = 'serving';
      _qtyCtrl.text = '1';
      _baseCal = null;
      _baseProtein = null;
      _baseCarbs = null;
      _baseFat = null;
      _baseWeight = null;
      _weightUnit = 'g';
      _foodType = '';
      _foodCategory = '';
      _imageUrl = null;
      _editingName = false;
      _showNutritionFields = false;
      _showNotes = false;
      _notesCtrl.clear();
      _nameError = null;
      _refreshNutritionFields();
      _showDetails = true;
    });
  }

  void _backToSearch() {
    FocusScope.of(context).unfocus();
    setState(() => _showDetails = false);
  }

  void _refreshNutritionFields() {
    final qty = _qty;
    if (qty <= 0) return;
    _calCtrl.text = _baseCal == null ? '' : (_baseCal! * qty).round().toString();
    _proteinCtrl.text = _baseProtein == null ? '' : _fmt(_baseProtein! * qty);
    _carbsCtrl.text = _baseCarbs == null ? '' : _fmt(_baseCarbs! * qty);
    _fatCtrl.text = _baseFat == null ? '' : _fmt(_baseFat! * qty);
    _weightCtrl.text = _baseWeight == null ? '' : _fmt(_baseWeight! * qty);
  }

  void _stepQuantity(double delta) {
    final current = _qty > 0 ? _qty : 1.0;
    final next = (current + delta).clamp(_qtyStep, 999.0);
    setState(() {
      _qtyCtrl.text = _fmt(next.toDouble());
      _refreshNutritionFields();
    });
  }

  /// Converts a typed total back into its value for a quantity of 1.
  double? _toBase(String text) {
    final value = double.tryParse(text.trim());
    final qty = _qty;
    if (value == null || value < 0 || qty <= 0) return null;
    return value / qty;
  }

  double? _parseAmount(TextEditingController controller) {
    final value = double.tryParse(controller.text.trim());
    return (value == null || value < 0) ? null : value;
  }

  /// Saves the custom food to the doctor's list and returns its id. On failure
  /// the food is still added to this plan, and the doctor is told why.
  Future<int?> _saveCustomFoodToBackend() async {
    try {
      final res = await ApiClient().account(showSuccessSnack: false).post(
        URLs.doctorDietFoodsUrl,
        data: {
          'Name': _nameCtrl.text.trim(),
          'Category': _foodCategory.isNotEmpty ? _foodCategory : 'Other',
          'FoodType': _foodType.isNotEmpty ? _foodType : 'Veg',
          'ServingSize': '${_qtyCtrl.text.trim()} ${_unitCtrl.text.trim()}',
          'CaloriesPerServing': _parseAmount(_calCtrl) ?? 0,
          'ProteinG': _parseAmount(_proteinCtrl) ?? 0,
          'CarbsG': _parseAmount(_carbsCtrl) ?? 0,
          'FatG': _parseAmount(_fatCtrl) ?? 0,
        },
        options: Options(
          extra: dietQuietErrors,
          headers: {
            if (widget.authToken.isNotEmpty)
              HttpHeaders.authorizationHeader: 'Bearer ${widget.authToken}',
            'x-org-id': widget.orgId,
          },
        ),
      );
      final id = res.data is Map ? (res.data['Id'] ?? res.data['id']) : null;
      return id is num ? id.toInt() : null;
    } catch (e) {
      if (mounted) {
        final reason = dietApiErrorMessage(e, "Couldn't save it to your food list.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$reason Added to this plan only.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  bool _isSaving = false;

  Future<void> _submit({required bool addAnother}) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || name.length > 200) {
      setState(() {
        _nameError = name.isEmpty ? 'Enter a food name' : 'Keep the name under 200 characters';
        _editingName = true;
      });
      return;
    }

    int? foodId = _foodItemId;

    if (_saveToMyList && foodId == null) {
      setState(() => _isSaving = true);
      foodId = await _saveCustomFoodToBackend();
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (foodId != null) {
        _foodItemId = foodId;
      }
    }

    final unit = _unitCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    // No calorie value typed in: work it out from the macros (4/4/9 kcal per g).
    final protein = _parseAmount(_proteinCtrl);
    final carbs = _parseAmount(_carbsCtrl);
    final fat = _parseAmount(_fatCtrl);
    final typedCalories = (_parseAmount(_calCtrl) ?? 0).round();
    final calories = typedCalories > 0
        ? typedCalories
        : ((protein ?? 0) * 4 + (carbs ?? 0) * 4 + (fat ?? 0) * 9).round();

    widget.onSubmit(
      DoctorMealItemInput(
        mealSlot: widget.slotName,
        mealTime: widget.slotTime,
        foodItemId: foodId,
        foodName: name,
        quantity: _qty > 0 ? _qty : 1.0,
        unit: unit.isEmpty ? 'serving' : unit,
        weightAmount: _parseAmount(_weightCtrl),
        weightUnit: _parseAmount(_weightCtrl) == null ? null : _weightUnit,
        calories: calories,
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
        notes: notes.isEmpty ? null : notes,
        imageUrl: _imageUrl,
        category: _foodCategory.isEmpty ? null : _foodCategory,
        foodType: _foodType.isEmpty ? null : _foodType,
      ),
    );

    if (!addAnother) {
      Navigator.pop(context);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _addedCount++;
      _showDetails = false;
      _searchCtrl.clear();
    });
    _loadFoods('');
  }

  // --- Styling helpers ---

  Color _textPrimary(bool isDark) => isDark ? Colors.white : const Color(0xFF0F172A);

  Color _textSecondary(bool isDark) => isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  Color _borderColor(bool isDark) => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  TextStyle _ts(double size, FontWeight weight, Color color) {
    return TextStyle(fontFamily: appPoppinFont, fontSize: size, fontWeight: weight, color: color);
  }

  InputDecoration _decoration(
    bool isDark, {
    String? hint,
    String? suffix,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      hintText: hint,
      hintStyle: _ts(12.5, FontWeight.w400, isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
      suffixText: suffix,
      suffixStyle: _ts(12, FontWeight.w500, _textSecondary(isDark)),
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: true,
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border(_borderColor(isDark)),
      enabledBorder: border(_borderColor(isDark)),
      focusedBorder: border(_primaryBlue, 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final maxHeight = media.size.height * 0.88;

    final decoration = BoxDecoration(
      color: isDark ? darkModeCardColor : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    );

    // While choosing a food the sheet keeps one height, so it does not jump
    // as results load or the keyboard opens; the list just gets shorter.
    if (!_showDetails) {
      return Container(
        height: maxHeight,
        decoration: decoration,
        padding: EdgeInsets.only(bottom: keyboard),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(child: _buildSearch(isDark)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: decoration,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isDark),
              Flexible(child: _buildDetails(isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final subtitle = [
      if (widget.dayLabel != null) widget.dayLabel!,
      widget.slotName,
      if (widget.slotTime.isNotEmpty) widget.slotTime,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 6),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (_showDetails && !_isEditing)
                IconButton(
                  tooltip: 'Choose a different food',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(Icons.arrow_back_rounded, size: 20, color: _textPrimary(isDark)),
                  onPressed: _backToSearch,
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit food' : 'Add food',
                      style: _ts(16, FontWeight.w700, _textPrimary(isDark)),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(11.5, FontWeight.w500, _textSecondary(isDark)),
                    ),
                  ],
                ),
              ),
              if (_addedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _emeraldGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_addedCount added',
                    style: _ts(11, FontWeight.w700, isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857)),
                  ),
                ),
              IconButton(
                tooltip: 'Close',
                icon: Icon(Icons.close_rounded, color: _textSecondary(isDark)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Step 1: choose a food ---
  Widget _buildSearch(bool isDark) {
    final query = _searchCtrl.text.trim();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.sentences,
            style: _ts(13.5, FontWeight.w500, _textPrimary(isDark)),
            decoration: _decoration(
              isDark,
              hint: 'Search foods or type your own',
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: _textSecondary(isDark)),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.clear_rounded, size: 18, color: _textSecondary(isDark)),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearchChanged('');
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              if (query.isNotEmpty) _buildCustomFoodRow(query, isDark),
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(
                  query.isEmpty ? 'SUGGESTED FOR ${widget.slotName.toUpperCase()}' : 'FROM THE FOOD DATABASE',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: _textSecondary(isDark),
                  ),
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: _primaryBlue),
                    ),
                  ),
                )
              else if (_results.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Text(
                    _loadFailed
                        ? "Couldn't load foods. Type a name above to add it yourself."
                        : (query.isEmpty
                            ? 'Type a food name to search, or to add your own.'
                            : 'No match in the database. Use the option above to add it yourself.'),
                    textAlign: TextAlign.center,
                    style: _ts(12.5, FontWeight.w400, _textSecondary(isDark)),
                  ),
                )
              else
                for (final food in _results) _buildFoodRow(food, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomFoodRow(String query, bool isDark) {
    final accent = isDark ? const Color(0xFF93C5FD) : _primaryBlue;
    final saveColor = isDark ? const Color(0xFF6EE7B7) : _emeraldGreen;

    Widget option({
      required String label,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.14 : 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      softWrap: true,
                      style: _ts(13, FontWeight.w600, color),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      softWrap: true,
                      style: _ts(11, FontWeight.w400, color.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        option(
          label: 'Add "$query" as custom food',
          subtitle: 'Use for this plan only',
          icon: Icons.add_circle_outline_rounded,
          color: accent,
          onTap: () => _useCustomFood(query),
        ),
        if (widget.allowSaveToList)
        option(
          label: 'Add "$query" & save in my list',
          subtitle: 'Available in future plans too',
          icon: Icons.bookmark_add_outlined,
          color: saveColor,
          onTap: () => _useCustomFood(query, saveToList: true),
        ),
      ],
    );
  }

  Widget _buildFoodRow(_FoodOption food, bool isDark) {
    final facts = [
      food.serving,
      if (food.calories > 0) '${food.calories.round()} kcal',
      if (food.protein + food.carbs + food.fat > 0)
        'P ${_fmt(food.protein)}g · C ${_fmt(food.carbs)}g · F ${_fmt(food.fat)}g',
    ].join(' · ');

    return InkWell(
      onTap: () => _pickFood(food),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          children: [
            DietFoodImage(
              imageUrl: food.imageUrl,
              category: food.category,
              foodType: food.foodType,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name, style: _ts(13.5, FontWeight.w600, _textPrimary(isDark))),
                  const SizedBox(height: 1),
                  Text(facts, style: _ts(11.5, FontWeight.w400, _textSecondary(isDark))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: _textSecondary(isDark)),
          ],
        ),
      ),
    );
  }

  // --- Step 2: how much, plus optional nutrition and instructions ---
  Widget _buildDetails(bool isDark) {
    final fieldStyle = _ts(14, FontWeight.w600, _textPrimary(isDark));
    const decimal = TextInputType.numberWithOptions(decimal: true);
    final accent = isDark ? const Color(0xFF93C5FD) : _primaryBlue;
    final cardColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    Widget section(String title, {Widget? trailing}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: _textSecondary(isDark),
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      );
    }

    Widget linkButton(String label, IconData icon, VoidCallback onTap) {
      return TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(0, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      );
    }

    Widget stepButton(IconData icon, double delta) {
      return InkWell(
        onTap: () => _stepQuantity(delta),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 46,
          decoration: BoxDecoration(
            color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: accent),
        ),
      );
    }

    Widget nutritionField(String label, TextEditingController controller, String suffix, ValueChanged<String> onChanged) {
      return Expanded(
        child: TextField(
          controller: controller,
          keyboardType: decimal,
          onChanged: onChanged,
          style: fieldStyle,
          decoration: _decoration(isDark, hint: label, suffix: suffix),
        ),
      );
    }

    Widget nutritionTile(String label, String value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(value, style: _ts(14, FontWeight.w700, _textPrimary(isDark))),
              Text(label, style: _ts(10.5, FontWeight.w500, _textSecondary(isDark))),
            ],
          ),
        ),
      );
    }

    final hasNutrition = [_calCtrl, _proteinCtrl, _carbsCtrl, _fatCtrl].any((c) => c.text.trim().isNotEmpty);
    String show(TextEditingController c, String unit) => c.text.trim().isEmpty ? '—' : '${c.text.trim()}$unit';
    final presets = dietWeightPresets(_weightUnit);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. The food
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _borderColor(isDark)),
            ),
            child: (_editingName || _nameCtrl.text.trim().isEmpty)
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextField(
                      controller: _nameCtrl,
                      autofocus: _nameCtrl.text.trim().isEmpty,
                      textCapitalization: TextCapitalization.sentences,
                      // An edited name no longer refers to the database food it came from.
                      onChanged: (_) {
                        _foodItemId = null;
                        if (_nameError != null) setState(() => _nameError = null);
                      },
                      style: fieldStyle,
                      decoration: _decoration(isDark, hint: 'Food name, e.g. Vegetable Upma', errorText: _nameError),
                    ),
                  )
                : Row(
                    children: [
                      DietFoodImage(
                        imageUrl: _imageUrl,
                        category: _foodCategory,
                        foodType: _foodType,
                        size: 56,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_nameCtrl.text.trim(), style: _ts(15, FontWeight.w700, _textPrimary(isDark))),
                            if (_servingNote != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(_servingNote!, style: _ts(11.5, FontWeight.w400, _textSecondary(isDark))),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Rename',
                        icon: Icon(Icons.edit_outlined, size: 18, color: _textSecondary(isDark)),
                        onPressed: () => setState(() => _editingName = true),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),

          // 2. How much
          section('How much'),
          Row(
            children: [
              stepButton(Icons.remove_rounded, -_qtyStep),
              const SizedBox(width: 6),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: decimal,
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(_refreshNutritionFields),
                  style: _ts(16, FontWeight.w700, _textPrimary(isDark)),
                  decoration: _decoration(isDark, hint: '1'),
                ),
              ),
              const SizedBox(width: 6),
              stepButton(Icons.add_rounded, _qtyStep),
              const SizedBox(width: 10),
              Expanded(
                child: DietOptionField(
                  value: _unitCtrl.text,
                  placeholder: 'Unit',
                  pickerTitle: 'Unit',
                  options: kDietPortionUnits,
                  onChanged: (v) => setState(() => _unitCtrl.text = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: decimal,
                  onChanged: (v) => _baseWeight = _toBase(v),
                  style: fieldStyle,
                  decoration: _decoration(
                    isDark,
                    hint: 'Weight (optional)',
                    prefixIcon: Icon(Icons.scale_outlined, size: 18, color: _textSecondary(isDark)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 96,
                child: DietOptionField(
                  value: _weightUnit,
                  placeholder: 'unit',
                  pickerTitle: 'Weight unit',
                  options: kDietWeightUnits,
                  onChanged: (v) => setState(() => _weightUnit = v),
                ),
              ),
            ],
          ),
          if (presets.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final value in presets)
                  ChoiceChip(
                    label: Text('$value $_weightUnit'),
                    labelStyle: _ts(12, FontWeight.w600, _weightCtrl.text == '$value' ? Colors.white : _textPrimary(isDark)),
                    selected: _weightCtrl.text == '$value',
                    showCheckmark: false,
                    selectedColor: _primaryBlue,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() {
                      _weightCtrl.text = '$value';
                      _baseWeight = _toBase('$value');
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // 3. Nutrition: worked out from the food, editable on request
          section(
            'Nutrition for this amount',
            trailing: (hasNutrition || _showNutritionFields)
                ? linkButton(
                    _showNutritionFields ? 'Done' : 'Edit',
                    _showNutritionFields ? Icons.check_rounded : Icons.edit_outlined,
                    () {
                      FocusScope.of(context).unfocus();
                      setState(() => _showNutritionFields = !_showNutritionFields);
                    },
                  )
                : null,
          ),
          if (_showNutritionFields) ...[
            Row(
              children: [
                nutritionField('Calories', _calCtrl, 'kcal', (v) => _baseCal = _toBase(v)),
                const SizedBox(width: 8),
                nutritionField('Protein', _proteinCtrl, 'g', (v) => _baseProtein = _toBase(v)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                nutritionField('Carbs', _carbsCtrl, 'g', (v) => _baseCarbs = _toBase(v)),
                const SizedBox(width: 8),
                nutritionField('Fats', _fatCtrl, 'g', (v) => _baseFat = _toBase(v)),
              ],
            ),
          ] else if (hasNutrition)
            Row(
              children: [
                nutritionTile('kcal', _calCtrl.text.trim().isEmpty ? '—' : _calCtrl.text.trim(), const Color(0xFF2563EB)),
                const SizedBox(width: 6),
                nutritionTile('Protein', show(_proteinCtrl, 'g'), const Color(0xFF10B981)),
                const SizedBox(width: 6),
                nutritionTile('Carbs', show(_carbsCtrl, 'g'), const Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                nutritionTile('Fats', show(_fatCtrl, 'g'), const Color(0xFFEF4444)),
              ],
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: linkButton('Add calories & macros (optional)', Icons.add_rounded, () {
                setState(() => _showNutritionFields = true);
              }),
            ),
          const SizedBox(height: 14),

          // 4. Instruction for the patient
          if (_showNotes)
            TextField(
              controller: _notesCtrl,
              autofocus: _notesCtrl.text.isEmpty,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              minLines: 1,
              style: _ts(13, FontWeight.w500, _textPrimary(isDark)),
              decoration: _decoration(
                isDark,
                hint: 'Instruction, e.g. cook with ½ tsp oil, no sugar',
                prefixIcon: Icon(Icons.sticky_note_2_outlined, size: 18, color: _textSecondary(isDark)),
              ),
            )
          else
            Align(
              alignment: Alignment.centerLeft,
              child: linkButton('Add instruction for the patient', Icons.sticky_note_2_outlined, () {
                setState(() => _showNotes = true);
              }),
            ),
          const SizedBox(height: 20),

          // 5. Save-to-list indicator
          if (_saveToMyList && !_isEditing)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _emeraldGreen.withValues(alpha: isDark ? 0.14 : 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _emeraldGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.bookmark_added_rounded, size: 16, color: isDark ? const Color(0xFF6EE7B7) : _emeraldGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Will be saved to your food list',
                      style: _ts(12, FontWeight.w500, isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857)),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _saveToMyList = false),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 14, color: isDark ? const Color(0xFF6EE7B7) : _emeraldGreen),
                    ),
                  ),
                ],
              ),
            ),

          // 6. Actions
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _submit(addAnother: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: _saveToMyList ? _emeraldGreen : _primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: (_saveToMyList ? _emeraldGreen : _primaryBlue).withValues(alpha: 0.5),
                elevation: 0,
                minimumSize: const Size(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      _isEditing
                          ? 'Save Changes'
                          : _saveToMyList
                              ? 'Add & Save to My List'
                              : 'Add to ${widget.slotName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: appPoppinFont, fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          if (!_isEditing)
            Center(
              child: linkButton('Add and choose another food', Icons.playlist_add_rounded, () => _submit(addAnother: true)),
            ),
        ],
      ),
    );
  }
}
