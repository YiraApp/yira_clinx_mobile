import 'package:equatable/equatable.dart';

/// A test from a hospital's own lab list, offered to the doctor when prescribing.
class HospitalLabTest extends Equatable {
  final int id;
  final String testName;
  final String? testCode;
  final String? category;
  final String? sampleType;
  final double? price;
  final String? preparation;

  const HospitalLabTest({
    required this.id,
    required this.testName,
    this.testCode,
    this.category,
    this.sampleType,
    this.price,
    this.preparation,
  });

  @override
  List<Object?> get props => [id, testName, testCode, category, sampleType, price, preparation];
}

/// A test ordered on a prescription. [hospitalLabTestId] is null for a test the
/// doctor typed that is not on the hospital's list.
class PrescribedLabTest extends Equatable {
  static const String routine = 'Routine';
  static const String urgent = 'Urgent';

  final int? hospitalLabTestId;
  final String testName;
  final String? category;
  final String priority;
  final String instructions;

  const PrescribedLabTest({
    this.hospitalLabTestId,
    required this.testName,
    this.category,
    this.priority = routine,
    this.instructions = '',
  });

  factory PrescribedLabTest.fromHospitalTest(HospitalLabTest test) =>
      PrescribedLabTest(hospitalLabTestId: test.id, testName: test.testName, category: test.category);

  /// A prescription holds one of each test name, ignoring case; the server
  /// drops repeats the same way.
  String get key => keyOf(testName);

  static String keyOf(String name) => name.trim().toLowerCase();

  bool get isUrgent => priority == urgent;

  /// The line under the test's name: its category and the doctor's instructions.
  String get detail => [category ?? '', instructions]
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(' · ');

  PrescribedLabTest copyWith({String? priority, String? instructions}) {
    return PrescribedLabTest(
      hospitalLabTestId: hospitalLabTestId,
      testName: testName,
      category: category,
      priority: priority ?? this.priority,
      instructions: instructions ?? this.instructions,
    );
  }

  @override
  List<Object?> get props => [hospitalLabTestId, testName, category, priority, instructions];
}
