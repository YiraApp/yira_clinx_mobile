import '../../../domain/entities/prescriptions/lab_test_entity.dart';

String? _text(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
}

int? _int(dynamic value) => value is int ? value : int.tryParse(value?.toString() ?? '');

class HospitalLabTestModel extends HospitalLabTest {
  const HospitalLabTestModel({
    required super.id,
    required super.testName,
    super.testCode,
    super.category,
    super.sampleType,
    super.price,
    super.preparation,
  });

  factory HospitalLabTestModel.fromJson(Map<String, dynamic> json) {
    return HospitalLabTestModel(
      id: _int(json['Id'] ?? json['id']) ?? 0,
      testName: _text(json['TestName'] ?? json['testName']) ?? '',
      testCode: _text(json['TestCode'] ?? json['testCode']),
      category: _text(json['Category'] ?? json['category']),
      sampleType: _text(json['SampleType'] ?? json['sampleType']),
      // The server's decimal column can arrive as a string.
      price: double.tryParse((json['Price'] ?? json['price'])?.toString() ?? ''),
      preparation: _text(json['Preparation'] ?? json['preparation']),
    );
  }

  static List<HospitalLabTest> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => HospitalLabTestModel.fromJson(Map<String, dynamic>.from(e)))
        .where((test) => test.id > 0 && test.testName.isNotEmpty)
        .toList();
  }
}

class PrescribedLabTestModel extends PrescribedLabTest {
  const PrescribedLabTestModel({
    super.hospitalLabTestId,
    required super.testName,
    super.category,
    super.priority,
    super.instructions,
  });

  factory PrescribedLabTestModel.fromJson(Map<String, dynamic> json) {
    final priority = (json['Priority'] ?? json['priority'])?.toString().toLowerCase();
    return PrescribedLabTestModel(
      hospitalLabTestId: _int(json['HospitalLabTestId'] ?? json['hospitalLabTestId']),
      testName: _text(json['TestName'] ?? json['testName']) ?? '',
      category: _text(json['Category'] ?? json['category']),
      priority: priority == 'urgent' ? PrescribedLabTest.urgent : PrescribedLabTest.routine,
      instructions: _text(json['Instructions'] ?? json['instructions']) ?? '',
    );
  }

  static List<PrescribedLabTest> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => PrescribedLabTestModel.fromJson(Map<String, dynamic>.from(e)))
        .where((test) => test.testName.isNotEmpty)
        .toList();
  }

  /// The body of one entry in a saved prescription's `labTests`.
  static Map<String, dynamic> toJson(PrescribedLabTest test) => {
        'hospitalLabTestId': test.hospitalLabTestId,
        'testName': test.testName.trim(),
        'category': test.category,
        'priority': test.priority,
        'instructions': test.instructions.trim(),
      };
}
