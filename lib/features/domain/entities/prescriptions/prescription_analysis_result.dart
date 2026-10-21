/// Data model representing the structured output from Gemini AI
/// after analyzing a prescription image or PDF.
class PrescriptionAnalysisResult {
  final String doctorName;
  final String hospitalName;
  final String specialty;
  final String consultationDate;
  final String diagnosis;
  final String doctorNotes;
  final List<ExtractedMedication> medications;
  final int confidence;

  const PrescriptionAnalysisResult({
    this.doctorName = '',
    this.hospitalName = '',
    this.specialty = '',
    this.consultationDate = '',
    this.diagnosis = '',
    this.doctorNotes = '',
    this.medications = const [],
    this.confidence = 0,
  });

  factory PrescriptionAnalysisResult.fromJson(Map<String, dynamic> json) {
    final medsRaw = json['medications'];
    final List<ExtractedMedication> meds = [];
    if (medsRaw is List) {
      for (final m in medsRaw) {
        if (m is Map<String, dynamic>) {
          meds.add(ExtractedMedication.fromJson(m));
        }
      }
    }

    return PrescriptionAnalysisResult(
      doctorName: (json['doctorName'] ?? '').toString().trim(),
      hospitalName: (json['hospitalName'] ?? '').toString().trim(),
      specialty: (json['specialty'] ?? '').toString().trim(),
      consultationDate: (json['consultationDate'] ?? '').toString().trim(),
      diagnosis: (json['diagnosis'] ?? '').toString().trim(),
      doctorNotes: (json['doctorNotes'] ?? '').toString().trim(),
      medications: meds,
      confidence: _parseConfidence(json['confidence']),
    );
  }

  static int _parseConfidence(dynamic value) {
    if (value is int) return value.clamp(0, 100);
    if (value is double) return value.round().clamp(0, 100);
    if (value is String) {
      final parsed = int.tryParse(value) ?? double.tryParse(value)?.round();
      return (parsed ?? 0).clamp(0, 100);
    }
    return 0;
  }

  /// Whether this result has meaningful data extracted.
  bool get hasData =>
      doctorName.isNotEmpty ||
      hospitalName.isNotEmpty ||
      diagnosis.isNotEmpty ||
      medications.isNotEmpty;

  /// Human-readable confidence level.
  String get confidenceLabel {
    if (confidence >= 80) return 'High';
    if (confidence >= 50) return 'Medium';
    return 'Low';
  }

  PrescriptionAnalysisResult copyWith({
    String? doctorName,
    String? hospitalName,
    String? specialty,
    String? consultationDate,
    String? diagnosis,
    String? doctorNotes,
    List<ExtractedMedication>? medications,
    int? confidence,
  }) {
    return PrescriptionAnalysisResult(
      doctorName: doctorName ?? this.doctorName,
      hospitalName: hospitalName ?? this.hospitalName,
      specialty: specialty ?? this.specialty,
      consultationDate: consultationDate ?? this.consultationDate,
      diagnosis: diagnosis ?? this.diagnosis,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      medications: medications ?? this.medications,
      confidence: confidence ?? this.confidence,
    );
  }
}

/// A single medication extracted from the prescription image.
class ExtractedMedication {
  final String name;
  final String frequency;
  final String mealTiming;
  final int durationDays;
  final bool isContinuous;
  final String notes;

  const ExtractedMedication({
    this.name = '',
    this.frequency = '1-0-1',
    this.mealTiming = 'After Food',
    this.durationDays = 5,
    this.isContinuous = false,
    this.notes = '',
  });

  factory ExtractedMedication.fromJson(Map<String, dynamic> json) {
    return ExtractedMedication(
      name: (json['name'] ?? '').toString().trim(),
      frequency: _normalizeFrequency((json['frequency'] ?? '1-0-1').toString().trim()),
      mealTiming: _normalizeMealTiming((json['mealTiming'] ?? 'After Food').toString().trim()),
      durationDays: _parseDuration(json['durationDays']),
      isContinuous: json['isContinuous'] == true,
      notes: (json['notes'] ?? '').toString().trim(),
    );
  }

  /// Maps various frequency notations to our standard format.
  static String _normalizeFrequency(String raw) {
    final lower = raw.toLowerCase().replaceAll(' ', '');
    if (lower.contains('1-0-1') || lower == 'bd' || lower.contains('twice')) return '1-0-1';
    if (lower.contains('1-0-0') || lower == 'od' || lower.contains('once')) return '1-0-0';
    if (lower.contains('1-1-1') || lower == 'tds' || lower.contains('thrice') || lower.contains('three')) return '1-1-1';
    if (lower.contains('0-0-1') || lower == 'hs' || lower == 'on' || lower.contains('night')) return '0-0-1';
    if (lower.contains('sos') || lower.contains('needed') || lower.contains('prn')) return 'SOS';
    return '1-0-1'; // default
  }

  /// Normalizes meal timing to one of our two supported values.
  static String _normalizeMealTiming(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('before') || lower.contains('empty') || lower.contains('ac')) {
      return 'Before Food';
    }
    return 'After Food';
  }

  static int _parseDuration(dynamic value) {
    if (value is int) return value > 0 ? value : 5;
    if (value is double) return value.round() > 0 ? value.round() : 5;
    if (value is String) {
      final parsed = int.tryParse(value) ?? double.tryParse(value)?.round();
      return (parsed != null && parsed > 0) ? parsed : 5;
    }
    return 5;
  }

  ExtractedMedication copyWith({
    String? name,
    String? frequency,
    String? mealTiming,
    int? durationDays,
    bool? isContinuous,
    String? notes,
  }) {
    return ExtractedMedication(
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      mealTiming: mealTiming ?? this.mealTiming,
      durationDays: durationDays ?? this.durationDays,
      isContinuous: isContinuous ?? this.isContinuous,
      notes: notes ?? this.notes,
    );
  }
}
