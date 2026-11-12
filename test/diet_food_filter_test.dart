import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/presentation/doctor/diet/diet_food_picker_sheet.dart';

void main() {
  test('food suggestions follow the plan diet type', () {
    expect(dietAllowsFood('Veg', 'Veg'), isTrue);
    expect(dietAllowsFood('Veg', 'Vegan'), isTrue);
    expect(dietAllowsFood('Veg', 'Egg'), isFalse);
    expect(dietAllowsFood('Veg', 'Non-Veg'), isFalse);
    expect(dietAllowsFood('Eggetarian', 'Egg'), isTrue);
    expect(dietAllowsFood('Eggetarian', 'Non-Veg'), isFalse);
    expect(dietAllowsFood('Vegan', 'Veg'), isFalse); // dairy
    expect(dietAllowsFood('Vegan', 'Vegan'), isTrue);
    expect(dietAllowsFood('Non-Veg', 'Non-Veg'), isTrue);
    expect(dietAllowsFood(null, 'Non-Veg'), isTrue);
    expect(dietAllowsFood('Veg', ''), isTrue);
  });
}
