import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/core/utils/edit_window.dart';

void main() {
  final saved = DateTime.utc(2026, 11, 18, 6, 30);

  test('open for the first hour, with whole minutes left', () {
    final w = editWindowFor(saved, now: saved.add(const Duration(minutes: 10, seconds: 20)));
    expect(w.open, isTrue);
    expect(w.minutesLeft, 50);
    expect(w.message, 'Edit (50 min left)');
    expect(editWindowFor(saved, now: saved.add(const Duration(minutes: 59, seconds: 59))).minutesLeft, 1);
  });

  test('closed after an hour, with the reason', () {
    final w = editWindowFor(saved, now: saved.add(const Duration(minutes: 60, seconds: 1)));
    expect(w.open, isFalse);
    expect(w.minutesLeft, 0);
    expect(w.message, contains('within 60 minutes'));
  });

  test('unknown age stays editable', () {
    expect(editWindowFor(null).open, isTrue);
  });

  test('reads CreatedAt or createdAt from the API', () {
    expect(createdAtOf({'CreatedAt': '2026-11-18T06:30:00.000Z'}), saved);
    expect(createdAtOf({'createdAt': '2026-11-18T06:30:00.000Z'}), saved);
    expect(createdAtOf({'Id': 'x'}), isNull);
    expect(createdAtOf({'CreatedAt': 'not a date'}), isNull);
  });
}
