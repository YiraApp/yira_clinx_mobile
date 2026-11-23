import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/core/utils/record_display_name.dart';

void main() {
  final day = DateTime(2026, 11, 12);

  test('an id-named prescription reads as Prescription and its date', () {
    expect(recordDisplayName('Prescription_29ACFBFA-09A2-4FCB-8927-C433BFC928F2.pdf', category: 'Prescription', date: day),
        'Prescription · 12 Nov 2026');
  });

  test('date-stamped and timestamped names are replaced', () {
    expect(recordDisplayName('Prescription_2026-11-12.pdf', date: day), 'Prescription · 12 Nov 2026');
    expect(recordDisplayName('Prescription_1731400000000.jpg', date: day), 'Prescription · 12 Nov 2026');
    expect(recordDisplayName('Lab_Report_20261112101010.pdf', date: day), 'Lab Report · 12 Nov 2026');
  });

  test('camera names fall back to the category', () {
    expect(recordDisplayName('IMG_20261112_101010.jpg', category: 'Lab Report', date: day), 'Lab Report · 12 Nov 2026');
    expect(recordDisplayName('document.pdf', category: 'General', date: day), 'Health Record · 12 Nov 2026');
  });

  test('names a person gave stay as they are', () {
    expect(recordDisplayName('Blood test March.pdf', category: 'Lab Report', date: day), 'Blood test March.pdf');
    expect(recordDisplayName('CBC report.pdf'), 'CBC report.pdf');
  });

  test('underscore-joined names read as words', () {
    expect(recordDisplayName('Prescription_sreelatha_devireddy_NutriWellness_05-Nov-2026.pdf'),
        'Prescription sreelatha devireddy NutriWellness 05-Nov-2026');
  });

  test('the readable title has no dot, so downloads can add the extension', () {
    expect(recordDisplayName('Prescription_29ACFBFA-09A2-4FCB-8927-C433BFC928F2.pdf', date: day).contains('.'), isFalse);
  });

  test('extension helper', () {
    expect(recordFileExtension('a.PDF'), 'pdf');
    expect(recordFileExtension('noext'), '');
  });
}
