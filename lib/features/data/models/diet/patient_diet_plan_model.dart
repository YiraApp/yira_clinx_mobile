import 'dart:convert';

/// Formats a food quantity for display, e.g. "2 bowl".
///
/// Database foods use their serving size as the unit. A single-unit serving
/// ("1 bowl") just takes the quantity: "2 bowl". Any other serving that
/// already starts with an amount ("2 pieces (80g)") reads "2 pieces (80g)" for
/// one serving and "2 × 2 pieces (80g)" for more.
String formatDietPortion(double quantity, String unit) {
  final amount = quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
  final label = unit.trim();
  if (label.isEmpty) return amount;
  final single = RegExp(r'^1\s+(\D.*)$').firstMatch(label);
  if (single != null) return '$amount ${single.group(1)}';
  if (RegExp(r'^\d').hasMatch(label)) {
    return quantity == 1 ? label : '$amount × $label';
  }
  return '$amount $label';
}

/// Formats a portion weight, e.g. "80 g" or "250 ml". Null when unknown.
String? formatDietWeight(double? amount, String? unit) {
  if (amount == null || amount <= 0) return null;
  final value = amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(1);
  final label = (unit ?? '').trim().isEmpty ? 'g' : unit!.trim();
  return '$value $label';
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

/// Parses whole or fractional numbers ("1500", 1499.6) and rounds them.
int? _toRoundedInt(dynamic value) => _toDouble(value)?.round();

class TodayDietResponse {
  final bool hasActivePlan;
  final String? message;
  final TodayDietPlanInfo? plan;
  final TodayDietSummary? summary;
  final List<TodayDietSlot> slots;

  TodayDietResponse({
    required this.hasActivePlan,
    this.message,
    this.plan,
    this.summary,
    this.slots = const [],
  });

  factory TodayDietResponse.fromJson(Map<String, dynamic> json) {
    return TodayDietResponse(
      hasActivePlan: json['hasActivePlan'] == true,
      message: json['message'] as String?,
      plan: json['plan'] != null ? TodayDietPlanInfo.fromJson(json['plan']) : null,
      summary: json['summary'] != null ? TodayDietSummary.fromJson(json['summary']) : null,
      slots: json['slots'] != null && json['slots'] is List
          ? (json['slots'] as List).map((s) => TodayDietSlot.fromJson(s as Map<String, dynamic>)).toList()
          : [],
    );
  }
}

class TodayDietPlanInfo {
  final int id;
  final String planName;
  final String doctorName;
  final String organizationName;
  final String? hospitalName;
  final String? condition;
  final String dietType;
  final String? doctorNotes;
  final List<String> foodsToAvoid;
  final List<String> foodsToPrefer;
  final int? targetCalories;
  final double? targetProteinG;
  final double? targetCarbsG;
  final double? targetFatG;
  final int totalDays;
  final int currentDayNumber;
  final String? startDate;
  final String? endDate;
  /// When the patient last changed this plan themselves, if ever.
  final DateTime? patientModifiedAt;
  /// Whether the signed-in patient may edit this plan.
  final bool canEdit;
  /// active / paused / completed / cancelled.
  final String status;
  /// The patient made this plan themselves (no doctor prescribed it).
  final bool createdByPatient;
  /// The appointment the plan was prescribed in, if any.
  final int? appointmentId;
  /// The doctor who prescribed it (the patient, for a self-made plan).
  final String? assignedByDoctorId;

  TodayDietPlanInfo({
    required this.id,
    required this.planName,
    required this.doctorName,
    required this.organizationName,
    this.hospitalName,
    this.condition,
    this.dietType = 'Veg',
    this.doctorNotes,
    this.foodsToAvoid = const [],
    this.foodsToPrefer = const [],
    this.targetCalories,
    this.targetProteinG,
    this.targetCarbsG,
    this.targetFatG,
    this.totalDays = 7,
    this.currentDayNumber = 1,
    this.startDate,
    this.endDate,
    this.patientModifiedAt,
    this.canEdit = false,
    this.status = 'active',
    this.createdByPatient = false,
    this.appointmentId,
    this.assignedByDoctorId,
  });

  /// "Dr. Asha Rao", or "You" for a plan the patient made.
  String get prescribedByLabel => createdByPatient ? 'You' : 'Dr. $doctorName';

  /// The same for a doctor reading the patient's plans.
  String get prescribedByLabelForDoctor => createdByPatient ? 'Made by the patient' : 'Dr. $doctorName';

  String get clinicName => (hospitalName ?? '').trim().isNotEmpty ? hospitalName!.trim() : organizationName;

  /// Builds the plan info from a full plan record (`GET /plan/:id`), which uses
  /// PascalCase fields and works for plans that are not active too.
  factory TodayDietPlanInfo.fromPlanEntity(Map<String, dynamic> json) {
    List<String> parseList(dynamic value) {
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String && value.trim().isNotEmpty) {
        final text = value.trim();
        if (text.startsWith('[')) {
          try {
            final decoded = jsonDecode(text);
            if (decoded is List) return decoded.map((e) => e.toString()).toList();
          } catch (_) {}
        }
        return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    String? name(dynamic entity) {
      if (entity is! Map) return null;
      final full = entity['Name']?.toString().trim();
      if (full != null && full.isNotEmpty) return full;
      final parts = [entity['FirstName'], entity['LastName']].where((p) => p != null && '$p'.trim().isNotEmpty);
      return parts.isEmpty ? null : parts.join(' ');
    }

    final startDate = json['StartDate']?.toString();
    final totalDays = _toDouble(json['TotalDays'])?.toInt() ?? 1;
    final status = (json['Status'] ?? 'active').toString().trim().toLowerCase();
    final selfMade = json['CreatedByPatient'] == true || json['CreatedByPatient'] == 1;

    return TodayDietPlanInfo(
      id: _toDouble(json['Id'])?.toInt() ?? 0,
      planName: json['PlanName']?.toString() ?? 'Diet Plan',
      doctorName: selfMade ? 'You' : (name(json['AssignedByDoctor']) ?? 'Doctor'),
      organizationName: name(json['Organization']) ?? 'Clinic',
      hospitalName: name(json['Hospital']),
      condition: json['Condition']?.toString(),
      dietType: json['DietType']?.toString() ?? 'Veg',
      doctorNotes: json['DoctorNotes']?.toString(),
      foodsToAvoid: parseList(json['FoodsToAvoid']),
      foodsToPrefer: parseList(json['FoodsToPrefer']),
      targetCalories: _toRoundedInt(json['TargetCalories']),
      targetProteinG: _toDouble(json['TargetProteinG']),
      targetCarbsG: _toDouble(json['TargetCarbsG']),
      targetFatG: _toDouble(json['TargetFatG']),
      totalDays: totalDays < 1 ? 1 : totalDays,
      currentDayNumber: dietRotationDay(startDate, totalDays, DateTime.now()) ?? 1,
      startDate: startDate,
      endDate: json['EndDate']?.toString(),
      patientModifiedAt: DateTime.tryParse(json['PatientModifiedAt']?.toString() ?? '')?.toLocal(),
      canEdit: status == 'active' && selfMade,
      status: status,
      createdByPatient: selfMade,
      appointmentId: _toDouble(json['AppointmentId'])?.toInt(),
      assignedByDoctorId: json['AssignedByDoctorId']?.toString(),
    );
  }

  factory TodayDietPlanInfo.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      return [];
    }

    final isSelfMade = json['createdByPatient'] == true;
    final status = (json['status'] ?? 'active').toString().trim().toLowerCase();

    return TodayDietPlanInfo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      planName: json['planName'] as String? ?? 'Prescribed Diet Plan',
      doctorName: json['doctorName'] as String? ?? 'Doctor',
      organizationName: json['organizationName'] as String? ?? 'Clinic',
      hospitalName: json['hospitalName'] as String?,
      condition: json['condition'] as String?,
      dietType: json['dietType'] as String? ?? 'Veg',
      doctorNotes: json['doctorNotes'] as String?,
      foodsToAvoid: parseStringList(json['foodsToAvoid']),
      foodsToPrefer: parseStringList(json['foodsToPrefer']),
      targetCalories: _toRoundedInt(json['targetCalories']),
      targetProteinG: _toDouble(json['targetProteinG']),
      targetCarbsG: _toDouble(json['targetCarbsG']),
      targetFatG: _toDouble(json['targetFatG']),
      totalDays: json['totalDays'] is int ? json['totalDays'] : int.tryParse(json['totalDays']?.toString() ?? '7') ?? 7,
      currentDayNumber: json['currentDayNumber'] is int
          ? json['currentDayNumber']
          : int.tryParse(json['currentDayNumber']?.toString() ?? '1') ?? 1,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      patientModifiedAt: DateTime.tryParse(json['patientModifiedAt']?.toString() ?? '')?.toLocal(),
      canEdit: json['canEdit'] == true && isSelfMade && status == 'active',
      status: status,
      createdByPatient: isSelfMade,
    );
  }
}

class TodayDietSummary {
  final int totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;

  TodayDietSummary({
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
  });

  factory TodayDietSummary.fromJson(Map<String, dynamic> json) {
    return TodayDietSummary(
      totalCalories: _toRoundedInt(json['totalCalories']) ?? 0,
      totalProteinG: (json['totalProteinG'] is num)
          ? (json['totalProteinG'] as num).toDouble()
          : double.tryParse(json['totalProteinG']?.toString() ?? '0') ?? 0.0,
      totalCarbsG: (json['totalCarbsG'] is num)
          ? (json['totalCarbsG'] as num).toDouble()
          : double.tryParse(json['totalCarbsG']?.toString() ?? '0') ?? 0.0,
      totalFatG: (json['totalFatG'] is num)
          ? (json['totalFatG'] as num).toDouble()
          : double.tryParse(json['totalFatG']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class TodayDietSlot {
  final String slotName;
  final String time;
  final List<TodayDietMealItem> meals;

  TodayDietSlot({
    required this.slotName,
    required this.time,
    this.meals = const [],
  });

  factory TodayDietSlot.fromJson(Map<String, dynamic> json) {
    return TodayDietSlot(
      slotName: json['slotName'] as String? ?? '',
      time: json['time'] as String? ?? '',
      meals: json['meals'] != null && json['meals'] is List
          ? (json['meals'] as List).map((m) => TodayDietMealItem.fromJson(m as Map<String, dynamic>)).toList()
          : [],
    );
  }

  int get slotCalories {
    return meals.fold(0, (sum, item) => sum + item.effectiveCalories);
  }
}

class TodayDietMealItem {
  final int id;
  final int planId;
  final int dayNumber;
  final String mealSlot;
  final String? mealTime;
  /// The food database entry this item came from; null for a custom food.
  final int? foodItemId;
  final String foodName;
  final double quantity;
  final String unit;
  final double? weightAmount;
  final String? weightUnit;
  /// Photo of the food from the food database, when it has one.
  final String? imageUrl;
  /// Food category from the nutrient databank (e.g. "Grain", "Vegetable", "Fruit").
  final String? category;
  /// Veg / Non-Veg / Egg / Vegan.
  final String? foodType;
  final int calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final String? notes;
  /// Calories for one serving of the linked database food, if any.
  final double? foodCaloriesPerServing;

  TodayDietMealItem({
    required this.id,
    required this.planId,
    required this.dayNumber,
    required this.mealSlot,
    this.mealTime,
    this.foodItemId,
    required this.foodName,
    required this.quantity,
    required this.unit,
    this.weightAmount,
    this.weightUnit,
    this.imageUrl,
    this.category,
    this.foodType,
    required this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.notes,
    this.foodCaloriesPerServing,
  });

  /// Calories to show and add up. When the food was saved without a value,
  /// they are worked out from protein, carbs and fat (4/4/9 kcal per gram),
  /// or from the linked database food. 0 when nothing is known.
  int get effectiveCalories {
    if (calories > 0) return calories;
    final fromMacros = ((proteinG ?? 0) * 4 + (carbsG ?? 0) * 4 + (fatG ?? 0) * 9).round();
    if (fromMacros > 0) return fromMacros;
    final perServing = foodCaloriesPerServing ?? 0;
    if (perServing > 0) return (perServing * (quantity > 0 ? quantity : 1)).round();
    return 0;
  }

  /// True when [effectiveCalories] is an estimate rather than a saved value.
  bool get caloriesEstimated => calories <= 0 && effectiveCalories > 0;

  /// True when there is no way to know this food's calories.
  bool get caloriesUnknown => effectiveCalories <= 0;

  factory TodayDietMealItem.fromJson(Map<String, dynamic> json) {
    return TodayDietMealItem(
      id: json['Id'] is int ? json['Id'] : int.tryParse(json['Id']?.toString() ?? '0') ?? 0,
      planId: json['PlanId'] is int ? json['PlanId'] : int.tryParse(json['PlanId']?.toString() ?? '0') ?? 0,
      dayNumber: json['DayNumber'] is int ? json['DayNumber'] : int.tryParse(json['DayNumber']?.toString() ?? '1') ?? 1,
      mealSlot: json['MealSlot'] as String? ?? '',
      mealTime: json['MealTime'] as String?,
      foodItemId: _toDouble(json['FoodItemId'])?.toInt(),
      foodName: json['FoodName'] as String? ?? '',
      quantity: (json['Quantity'] is num)
          ? (json['Quantity'] as num).toDouble()
          : double.tryParse(json['Quantity']?.toString() ?? '1') ?? 1.0,
      unit: json['Unit'] as String? ?? 'serving',
      weightAmount: _toDouble(json['WeightAmount']),
      weightUnit: json['WeightUnit'] as String?,
      imageUrl: (json['FoodItem'] is Map ? (json['FoodItem'] as Map)['ImageUrl'] : json['ImageUrl']) as String?,
      category: (json['FoodItem'] is Map ? (json['FoodItem'] as Map)['Category'] : json['Category']) as String?,
      foodType: (json['FoodItem'] is Map ? (json['FoodItem'] as Map)['FoodType'] : json['FoodType']) as String?,
      calories: _toRoundedInt(json['Calories']) ?? 0,
      proteinG: _toDouble(json['ProteinG']),
      carbsG: _toDouble(json['CarbsG']),
      fatG: _toDouble(json['FatG']),
      notes: json['Notes'] as String?,
      foodCaloriesPerServing: json['FoodItem'] is Map ? _toDouble((json['FoodItem'] as Map)['CaloriesPerServing']) : null,
    );
  }
}


/// "2026-07-21" for a local calendar date.
String dietDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Which day of a plan's rotation falls on [date]; null before the plan starts.
int? dietRotationDay(String? startDate, int totalDays, DateTime date) {
  final start = DateTime.tryParse(startDate ?? '');
  if (start == null) return null;
  final startDay = DateTime.utc(start.year, start.month, start.day);
  final day = DateTime.utc(date.year, date.month, date.day);
  final diff = day.difference(startDay).inDays;
  if (diff < 0) return null;
  final cycle = totalDays < 1 ? 1 : totalDays;
  return (diff % cycle) + 1;
}

/// One plan in the patient's list of prescribed plans.
class PatientDietPlanSummary {
  final int id;
  final String planName;
  final String? description;
  final String? condition;
  final String dietType;
  final String status;
  final String? startDate;
  final String? endDate;
  final int totalDays;
  final int? targetCalories;
  final String doctorName;
  final String organizationName;
  final String? hospitalName;
  final int mealCount;
  final bool isExpired;
  final bool canActivate;
  final bool canDeactivate;
  final bool createdByPatient;
  final DateTime? createdAt;

  PatientDietPlanSummary({
    required this.id,
    required this.planName,
    this.description,
    this.condition,
    this.dietType = 'Veg',
    this.status = 'active',
    this.startDate,
    this.endDate,
    this.totalDays = 1,
    this.targetCalories,
    this.doctorName = 'Doctor',
    this.organizationName = 'Clinic',
    this.hospitalName,
    this.mealCount = 0,
    this.isExpired = false,
    this.canActivate = false,
    this.canDeactivate = false,
    this.createdByPatient = false,
    this.createdAt,
  });

  bool get isActive => status.trim().toLowerCase() == 'active';

  String get clinicName => (hospitalName ?? '').trim().isNotEmpty ? hospitalName! : organizationName;

  factory PatientDietPlanSummary.fromJson(Map<String, dynamic> json) {
    return PatientDietPlanSummary(
      id: _toDouble(json['id'])?.toInt() ?? 0,
      planName: json['planName']?.toString() ?? 'Diet Plan',
      description: json['description']?.toString(),
      condition: json['condition']?.toString(),
      dietType: json['dietType']?.toString() ?? 'Veg',
      status: (json['status'] ?? 'active').toString().trim().toLowerCase(),
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      totalDays: _toDouble(json['totalDays'])?.toInt() ?? 1,
      targetCalories: _toRoundedInt(json['targetCalories']),
      doctorName: json['doctorName']?.toString() ?? 'Doctor',
      organizationName: json['organizationName']?.toString() ?? 'Clinic',
      hospitalName: json['hospitalName']?.toString(),
      mealCount: _toDouble(json['mealCount'])?.toInt() ?? 0,
      isExpired: json['isExpired'] == true,
      canActivate: json['canActivate'] == true,
      canDeactivate: json['canDeactivate'] == true,
      createdByPatient: json['createdByPatient'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal(),
    );
  }
}

/// The patient's record of one prescribed food on one date.
class DietMealLog {
  final int planMealId;
  final String logDate;
  final bool isEaten;
  final String? photoUrl;

  const DietMealLog({
    required this.planMealId,
    required this.logDate,
    this.isEaten = false,
    this.photoUrl,
  });

  DietMealLog copyWith({bool? isEaten}) =>
      DietMealLog(planMealId: planMealId, logDate: logDate, isEaten: isEaten ?? this.isEaten, photoUrl: photoUrl);

  factory DietMealLog.fromJson(Map<String, dynamic> json) {
    final photo = json['photoUrl']?.toString();
    return DietMealLog(
      planMealId: _toDouble(json['planMealId'])?.toInt() ?? 0,
      logDate: (json['logDate']?.toString() ?? '').padRight(10).substring(0, 10).trim(),
      isEaten: json['isEaten'] == true,
      photoUrl: (photo == null || photo.isEmpty) ? null : photo,
    );
  }
}
