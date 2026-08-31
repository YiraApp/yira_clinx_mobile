
class SlotAppointmentEntity {
  final String id;
  final String patientName;
  final String contactNumber;
  final String? reason;

  SlotAppointmentEntity({
    required this.id,
    required this.patientName,
    required this.contactNumber,
    this.reason,
  });
}

class SlotEntity {
  final String id;
  final String startTime;
  final String endTime;
  final String label;
  final SlotAppointmentEntity? appointment;

  SlotEntity({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.label,
    this.appointment,
  });

  bool get hasAppointment => appointment != null;

  String get duration {
    try {
      final s = _parseToMinutes(startTime);
      final e = _parseToMinutes(endTime);
      if (e <= s) return '';
      final diff = e - s;
      final hours = diff ~/ 60;
      final mins = diff % 60;
      if (hours > 0 && mins > 0) return '${hours}h ${mins}m';
      if (hours > 0) return '${hours}h';
      return '$mins mins';
    } catch (_) {
      return '';
    }
  }

  static int _parseToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 0;
    try {
      final cleaned = timeStr.replaceAll(RegExp(r'[\s\u00A0\u2000-\u200B\u202F]+'), ' ').trim();
      final match = RegExp(r'^(\d{1,2}):(\d{2})\s*([a-zA-Z]{2})?', caseSensitive: false).firstMatch(cleaned);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        String? ampm = match.group(3)?.toUpperCase();
        if (ampm == 'PM' && hour < 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        return hour * 60 + minute;
      }
    } catch (_) {}
    return 0;
  }

  SlotEntity copyWith({
    String? startTime,
    String? endTime,
    String? label,
    SlotAppointmentEntity? Function()? appointment,
  }) {
    return SlotEntity(
      id: id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      label: label ?? this.label,
      appointment: appointment != null ? appointment() : this.appointment,
    );
  }
}

class BreakTimeEntity {
  final String id;
  final String label;
  final String fromTime;
  final String toTime;

  BreakTimeEntity({
    required this.id,
    required this.label,
    required this.fromTime,
    required this.toTime,
  });

  BreakTimeEntity copyWith({
    String? id,
    String? label,
    String? fromTime,
    String? toTime,
  }) {
    return BreakTimeEntity(
      id: id ?? this.id,
      label: label ?? this.label,
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
    );
  }
}