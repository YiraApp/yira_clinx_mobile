import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/data/models/medication/medication_reminder_model.dart';
import 'package:yiraclinics/features/presentation/user_prescription/widgets/convert_tablet_sheet.dart';

Map<String, dynamic> _reminder(String start, String end, {bool continuous = false}) => {
      'id': 'med_1',
      'medicineName': 'Paracetamol',
      'times': ['08:00 AM'],
      'startDate': start,
      'endDate': end,
      'durationDays': 5,
      'isContinuous': continuous,
    };

void main() {
  test('a server date sent as local midnight in UTC keeps its calendar day', () {
    // 25 Nov in India comes back as 24 Nov 18:30 UTC.
    final r = MedicationReminder.fromMap(_reminder('2026-11-20T18:30:00.000Z', '2026-11-24T18:30:00.000Z'));
    final utcEnd = DateTime.utc(2026, 11, 24, 18, 30).toLocal();
    expect(r.endDate, DateTime(utcEnd.year, utcEnd.month, utcEnd.day));
    expect(r.endDate.hour, 0);
  });

  test('dates stored on the phone read back unchanged', () {
    final r = MedicationReminder.fromMap(_reminder('2026-11-21T00:00:00.000', '2026-11-25T00:00:00.000'));
    expect(r.startDate, DateTime(2026, 11, 21));
    expect(r.endDate, DateTime(2026, 11, 25));
  });

  test('a course has ended only after its last day; continuous ones never end', () {
    final now = DateTime.now();
    String day(int offset) => DateTime(now.year, now.month, now.day + offset).toIso8601String();
    expect(MedicationReminder.fromMap(_reminder(day(-6), day(-1))).hasEnded, isTrue);
    expect(MedicationReminder.fromMap(_reminder(day(-4), day(0))).hasEnded, isFalse);
    expect(MedicationReminder.fromMap(_reminder(day(-6), day(-1), continuous: true)).hasEnded, isFalse);
  });

  test('the reminder sheet starts from the prescribed days and daily pattern', () {
    expect(ConvertTabletSheet.daysFrom('5 Days'), 5);
    expect(ConvertTabletSheet.daysFrom('2 weeks'), 14);
    expect(ConvertTabletSheet.daysFrom('1 Month'), 30);
    expect(ConvertTabletSheet.daysFrom(''), isNull);
    expect(ConvertTabletSheet.timesFrom('500mg - 1-0-1 (Morning-Night)'), ['08:00 AM', '08:00 PM']);
    expect(ConvertTabletSheet.timesFrom('1-1-1'), ['08:00 AM', '02:00 PM', '08:00 PM']);
    expect(ConvertTabletSheet.timesFrom('0-0-1'), ['08:00 PM']);
    expect(ConvertTabletSheet.timesFrom('As needed'), isNull);
  });
}
