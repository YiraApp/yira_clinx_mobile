import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/data/data_sources/diet/diet_api_error.dart';
import 'package:yiraclinics/features/data/models/diet/patient_diet_plan_model.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/doctor_prescribe_diet_sheet.dart'
    show DoctorMealItemInput;

void main() {
  group('TodayDietMealItem.fromJson', () {
    test('keeps fractional calories and the food id', () {
      final item = TodayDietMealItem.fromJson({
        'Id': 4,
        'PlanId': 9,
        'DayNumber': 2,
        'MealSlot': 'Lunch',
        'MealTime': '01:30 PM',
        'FoodItemId': 31,
        'FoodName': 'Dal',
        'Quantity': 1.5,
        'Unit': 'bowl',
        'Calories': 187.6,
        'ProteinG': '9.2',
        'WeightAmount': 150,
        'WeightUnit': 'g',
        'FoodItem': {'ImageUrl': 'https://x/dal.jpg', 'Category': 'Protein', 'FoodType': 'Veg'},
      });
      expect(item.calories, 188);
      expect(item.foodItemId, 31);
      expect(item.proteinG, 9.2);
      expect(item.weightAmount, 150);
      expect(item.imageUrl, 'https://x/dal.jpg');
    });
  });

  group('TodayDietPlanInfo.fromJson', () {
    test('reads edit fields and decimal targets', () {
      final plan = TodayDietPlanInfo.fromJson({
        'id': 9,
        'targetCalories': 1499.6,
        'canEdit': true,
        'createdByPatient': true,
        'patientModifiedAt': '2026-10-15T08:30:00.000Z',
      });
      expect(plan.targetCalories, 1500);
      expect(plan.canEdit, isTrue);
      expect(plan.patientModifiedAt, isNotNull);
    });

    test('patients can only edit plans they made themselves', () {
      final prescribed = TodayDietPlanInfo.fromJson({'id': 2, 'canEdit': true});
      expect(prescribed.canEdit, isFalse);
    });

    test('is read-only unless the server says otherwise', () {
      expect(TodayDietPlanInfo.fromJson({'id': 1}).canEdit, isFalse);
    });
  });

  group('DoctorMealItemInput.fromTemplateMeal', () {
    test('maps weights and food details, and round-trips through toJson', () {
      final item = DoctorMealItemInput.fromTemplateMeal({
        'DayNumber': 3,
        'MealSlot': 'Breakfast',
        'MealTime': '08:30 AM',
        'FoodItemId': 12,
        'FoodName': 'Idli',
        'Quantity': 2,
        'Unit': 'piece',
        'WeightAmount': 80,
        'WeightUnit': 'g',
        'Calories': 116,
        'FoodItem': {'ImageUrl': 'https://x/idli.jpg', 'Category': 'Breakfast', 'FoodType': 'Veg'},
      });
      expect(item.dayNumber, 3);
      expect(item.weightAmount, 80);
      expect(item.imageUrl, 'https://x/idli.jpg');

      final json = item.toJson(item.dayNumber, 1);
      expect(json['foodItemId'], 12);
      expect(json['weightAmount'], 80);
      expect(json['weightUnit'], 'g');
      expect(json['quantity'], 2.0);
    });

    test('accepts camelCase fields and fills sensible defaults', () {
      final item = DoctorMealItemInput.fromTemplateMeal({'foodName': 'Tea', 'calories': 40.4});
      expect(item.foodName, 'Tea');
      expect(item.calories, 40);
      expect(item.dayNumber, 1);
      expect(item.unit, 'serving');
      expect(item.weightAmount, isNull);
    });
  });

  group('dietApiErrorMessage', () {
    test('uses the server error text', () {
      final options = RequestOptions(path: '/v1/api/diet/templates');
      final error = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 400,
          data: {'error': 'You already have a template named "Diabetic".'},
        ),
      );
      expect(dietApiErrorMessage(error, 'fallback'), 'You already have a template named "Diabetic".');
    });

    test('falls back when the server sent nothing useful', () {
      expect(dietApiErrorMessage(Exception('boom'), 'fallback'), 'fallback');
    });
  });

  group('dietRotationDay', () {
    test('cycles through the plan days from the start date', () {
      expect(dietRotationDay('2026-07-20', 7, DateTime(2026, 7, 20)), 1);
      expect(dietRotationDay('2026-07-20', 7, DateTime(2026, 7, 26)), 7);
      expect(dietRotationDay('2026-07-20', 7, DateTime(2026, 7, 27)), 1);
      expect(dietRotationDay('2026-07-20T00:00:00.000Z', 3, DateTime(2026, 7, 25)), 3);
    });

    test('is null before the plan starts', () {
      expect(dietRotationDay('2026-07-20', 7, DateTime(2026, 7, 19)), isNull);
    });
  });

  group('plan list and logs', () {
    test('PatientDietPlanSummary reads the list endpoint', () {
      final plan = PatientDietPlanSummary.fromJson({
        'id': 3,
        'planName': 'Diabetic Veg',
        'status': 'paused',
        'hospitalName': 'Yira Clinic',
        'organizationName': 'Yira',
        'mealCount': 14,
        'canActivate': true,
        'targetCalories': 1499.5,
      });
      expect(plan.isActive, isFalse);
      expect(plan.canActivate, isTrue);
      expect(plan.clinicName, 'Yira Clinic');
      expect(plan.targetCalories, 1500);
    });

    test('TodayDietPlanInfo.fromPlanEntity reads a full plan record', () {
      final info = TodayDietPlanInfo.fromPlanEntity({
        'Id': 3,
        'PlanName': 'Diabetic Veg',
        'Status': 'paused',
        'TotalDays': 7,
        'StartDate': '2026-07-20',
        'FoodsToAvoid': '["Sugar","Maida"]',
        'AssignedByDoctor': {'FirstName': 'Asha', 'LastName': 'Rao'},
        'Organization': {'Name': 'Yira'},
      });
      expect(info.doctorName, 'Asha Rao');
      expect(info.foodsToAvoid, ['Sugar', 'Maida']);
      expect(info.canEdit, isFalse);
      expect(info.status, 'paused');
    });

    test('DietMealLog trims the date to YYYY-MM-DD', () {
      final log = DietMealLog.fromJson({'planMealId': 9, 'logDate': '2026-07-21T00:00:00.000Z', 'isEaten': true});
      expect(log.logDate, '2026-07-21');
      expect(log.isEaten, isTrue);
      expect(log.photoUrl, isNull);
    });
  });

}
