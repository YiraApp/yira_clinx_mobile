import 'dart:convert';

/// How a report looks overall, as judged by the AI reader on the server.
enum ReportStatus { normal, attention, critical, unknown }

ReportStatus reportStatusFrom(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'normal':
      return ReportStatus.normal;
    case 'attention':
      return ReportStatus.attention;
    case 'critical':
      return ReportStatus.critical;
    default:
      return ReportStatus.unknown;
  }
}

/// A single test result, e.g. Haemoglobin 10.2 g/dL.
class ReportTest {
  final String name;
  final String value;
  final String unit;
  final String referenceRange;

  /// normal, low, high, critical_low, critical_high, abnormal or unknown.
  final String flag;
  final String meaning;

  const ReportTest({
    required this.name,
    required this.value,
    this.unit = '',
    this.referenceRange = '',
    this.flag = 'unknown',
    this.meaning = '',
  });

  bool get isCritical => flag.startsWith('critical');
  bool get isOutOfRange => flag == 'low' || flag == 'high' || flag == 'abnormal';
  bool get isNormal => flag == 'normal';
  bool get needsAttention => isCritical || isOutOfRange;

  factory ReportTest.fromJson(Map<String, dynamic> json) => ReportTest(
        name: _str(json['name']),
        value: _str(json['value']),
        unit: _str(json['unit']),
        referenceRange: _str(json['referenceRange']),
        flag: _str(json['flag']).isEmpty ? 'unknown' : _str(json['flag']).toLowerCase(),
        meaning: _str(json['meaning']),
      );
}

class ReportSection {
  final String name;
  final List<ReportTest> tests;

  const ReportSection({required this.name, required this.tests});

  factory ReportSection.fromJson(Map<String, dynamic> json) => ReportSection(
        name: _str(json['name']),
        tests: _maps(json['tests']).map(ReportTest.fromJson).toList(),
      );
}

class ReportAlert {
  final String title;
  final String detail;
  final String action;

  const ReportAlert({required this.title, this.detail = '', this.action = ''});

  factory ReportAlert.fromJson(Map<String, dynamic> json) =>
      ReportAlert(title: _str(json['title']), detail: _str(json['detail']), action: _str(json['action']));
}

class ReportCondition {
  final String name;

  /// possible or likely.
  final String likelihood;
  final String explanation;

  const ReportCondition({required this.name, this.likelihood = 'possible', this.explanation = ''});

  factory ReportCondition.fromJson(Map<String, dynamic> json) => ReportCondition(
        name: _str(json['name']),
        likelihood: _str(json['likelihood']).isEmpty ? 'possible' : _str(json['likelihood']),
        explanation: _str(json['explanation']),
      );
}

class ReportConsultation {
  final bool needed;

  /// none, routine, soon, urgent or emergency.
  final String urgency;
  final String specialty;
  final String timeframe;
  final String reason;

  const ReportConsultation({
    this.needed = false,
    this.urgency = 'none',
    this.specialty = '',
    this.timeframe = '',
    this.reason = '',
  });

  bool get isEmergency => urgency == 'emergency';
  bool get isUrgent => urgency == 'urgent' || isEmergency;

  factory ReportConsultation.fromJson(Map<String, dynamic> json) => ReportConsultation(
        needed: json['needed'] == true,
        urgency: _str(json['urgency']).isEmpty ? 'none' : _str(json['urgency']).toLowerCase(),
        specialty: _str(json['specialty']),
        timeframe: _str(json['timeframe']),
        reason: _str(json['reason']),
      );
}

class ReportRecommendation {
  /// diet, lifestyle, monitoring, followUpTest, medication or general.
  final String category;
  final String text;

  const ReportRecommendation({required this.category, required this.text});

  factory ReportRecommendation.fromJson(Map<String, dynamic> json) =>
      ReportRecommendation(category: _str(json['category']).isEmpty ? 'general' : _str(json['category']), text: _str(json['text']));
}

class ReportStats {
  final int total;
  final int normal;
  final int outOfRange;
  final int critical;

  const ReportStats({this.total = 0, this.normal = 0, this.outOfRange = 0, this.critical = 0});

  factory ReportStats.fromJson(Map<String, dynamic> json) => ReportStats(
        total: _int(json['total']),
        normal: _int(json['normal']),
        outOfRange: _int(json['outOfRange']),
        critical: _int(json['critical']),
      );
}

/// What the AI found in a medical document: overall status, every test result,
/// urgent alerts, whether to see a doctor, and practical next steps.
class MedicalReportAnalysis {
  final bool isMedicalDocument;
  final String documentType;
  final String title;
  final String reportDate;
  final String labName;
  final String referringDoctor;
  final String patientName;
  final String patientAge;
  final String patientGender;

  /// good, partial or poor.
  final String readability;
  final String readabilityNote;
  final ReportStatus status;
  final String headline;
  final String summary;
  final List<String> keyFindings;
  final List<ReportAlert> criticalAlerts;
  final List<ReportSection> sections;
  final ReportStats stats;
  final String impression;
  final List<ReportCondition> possibleConditions;
  final ReportConsultation consultation;
  final List<ReportRecommendation> recommendations;
  final List<String> followUpTests;
  final List<String> questionsForDoctor;
  final int confidence;
  final int? pagesAnalyzed;
  final DateTime? analyzedAt;
  final String disclaimer;

  const MedicalReportAnalysis({
    this.isMedicalDocument = true,
    this.documentType = '',
    this.title = '',
    this.reportDate = '',
    this.labName = '',
    this.referringDoctor = '',
    this.patientName = '',
    this.patientAge = '',
    this.patientGender = '',
    this.readability = 'good',
    this.readabilityNote = '',
    this.status = ReportStatus.unknown,
    this.headline = '',
    this.summary = '',
    this.keyFindings = const [],
    this.criticalAlerts = const [],
    this.sections = const [],
    this.stats = const ReportStats(),
    this.impression = '',
    this.possibleConditions = const [],
    this.consultation = const ReportConsultation(),
    this.recommendations = const [],
    this.followUpTests = const [],
    this.questionsForDoctor = const [],
    this.confidence = 0,
    this.pagesAnalyzed,
    this.analyzedAt,
    this.disclaimer = '',
  });

  List<ReportTest> get allTests => [for (final s in sections) ...s.tests];

  /// Results outside the range, critical ones first.
  List<ReportTest> get flaggedTests {
    final flagged = allTests.where((t) => t.needsAttention).toList();
    flagged.sort((a, b) => (b.isCritical ? 1 : 0) - (a.isCritical ? 1 : 0));
    return flagged;
  }

  bool get hasNumericResults => allTests.any((t) => t.flag != 'unknown');

  factory MedicalReportAnalysis.fromJson(Map<String, dynamic> json) {
    final consult = json['doctorConsultation'];
    final stats = json['stats'];
    return MedicalReportAnalysis(
      isMedicalDocument: json['isMedicalDocument'] != false,
      documentType: _str(json['documentType']),
      title: _str(json['title']),
      reportDate: _str(json['reportDate']),
      labName: _str(json['labName']),
      referringDoctor: _str(json['referringDoctor']),
      patientName: _str(json['patientName']),
      patientAge: _str(json['patientAge']),
      patientGender: _str(json['patientGender']),
      readability: _str(json['readability']).isEmpty ? 'good' : _str(json['readability']),
      readabilityNote: _str(json['readabilityNote']),
      status: reportStatusFrom(json['overallStatus']?.toString()),
      headline: _str(json['headline']),
      summary: _str(json['summary']),
      keyFindings: _strings(json['keyFindings']),
      criticalAlerts: _maps(json['criticalAlerts']).map(ReportAlert.fromJson).toList(),
      sections: _maps(json['sections']).map(ReportSection.fromJson).where((s) => s.tests.isNotEmpty).toList(),
      stats: stats is Map ? ReportStats.fromJson(Map<String, dynamic>.from(stats)) : const ReportStats(),
      impression: _str(json['impression']),
      possibleConditions: _maps(json['possibleConditions']).map(ReportCondition.fromJson).toList(),
      consultation: consult is Map ? ReportConsultation.fromJson(Map<String, dynamic>.from(consult)) : const ReportConsultation(),
      recommendations: _maps(json['recommendations']).map(ReportRecommendation.fromJson).where((r) => r.text.isNotEmpty).toList(),
      followUpTests: _strings(json['followUpTests']),
      questionsForDoctor: _strings(json['questionsForDoctor']),
      confidence: _int(json['confidence']),
      pagesAnalyzed: json['pagesAnalyzed'] == null ? null : _int(json['pagesAnalyzed']),
      analyzedAt: DateTime.tryParse(_str(json['analyzedAt']))?.toLocal(),
      disclaimer: _str(json['disclaimer']),
    );
  }

  /// Parses the JSON text stored on a document; null when missing or broken.
  static MedicalReportAnalysis? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? MedicalReportAnalysis.fromJson(Map<String, dynamic>.from(decoded)) : null;
    } catch (_) {
      return null;
    }
  }
}

String _str(dynamic v) => v == null ? '' : v.toString().trim();

int _int(dynamic v) => v is num ? v.round() : int.tryParse(v?.toString() ?? '') ?? 0;

List<String> _strings(dynamic v) =>
    v is List ? v.map((e) => _str(e)).where((e) => e.isNotEmpty).toList() : const [];

List<Map<String, dynamic>> _maps(dynamic v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];
