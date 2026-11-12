import 'package:intl/intl.dart';

final RegExp _guid = RegExp(r'[0-9a-fA-F]{8}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{12}');
final RegExp _longDigits = RegExp(r'\d{8,}');
final RegExp _longHex = RegExp(r'[0-9a-fA-F]{16,}');
final RegExp _dateStamp = RegExp(r'\d{4}[-_]\d{2}[-_]\d{2}([-_T]\d{2}[-_:]?\d{2}([-_:]?\d{2})?)?');
final RegExp _extension = RegExp(r'\.([A-Za-z0-9]{2,5})$');
const Set<String> _generic = {'document', 'file', 'image', 'img', 'photo', 'scan', 'upload', 'record', 'report', 'pdf'};

/// The file extension of [name] in lower case ("pdf"), or "" when it has none.
String recordFileExtension(String name) => _extension.firstMatch(name.trim())?.group(1)?.toLowerCase() ?? '';

/// A readable title for a health record whose stored name was made by a machine:
/// "Prescription_29ACFBFA-09A2-4FCB-8927-C433BFC928F2.pdf" → "Prescription · 12 Nov 2026",
/// "IMG_20261112_101010.jpg" → "Lab Report · 12 Nov 2026" (from [category]).
/// Names a person gave ("Blood test March.pdf") are returned unchanged.
///
/// The result never contains a dot, so a download can still add the file extension.
String recordDisplayName(String rawName, {String? category, DateTime? date}) {
  final raw = rawName.trim();
  if (raw.isEmpty) return _label(null, category, date);
  final base = raw.replaceFirst(_extension, '');
  final machine = _guid.hasMatch(base) ||
      _longDigits.hasMatch(base) ||
      _longHex.hasMatch(base) ||
      _dateStamp.hasMatch(base) ||
      _generic.contains(base.toLowerCase().replaceAll(RegExp(r'[^a-z]'), ''));
  if (!machine) {
    // "Prescription_sreelatha_devireddy_05-Nov-2026.pdf" → "Prescription sreelatha devireddy 05-Nov-2026"
    if (base.contains('_') && !base.contains(' ')) return base.replaceAll(RegExp(r'_+'), ' ').trim();
    return raw;
  }

  // The word(s) before the id often name the record: "Prescription_<id>", "Lab_Report_<id>"
  final prefix = base
      .replaceAll(_guid, ' ')
      .replaceAll(_longHex, ' ')
      .replaceAll(_dateStamp, ' ')
      .replaceAll(_longDigits, ' ')
      .replaceAll(RegExp(r'\d{4,}'), ' ')
      .replaceAll(RegExp(r'[_\-.]+'), ' ')
      .replaceAll(RegExp(r'\b(IMG|DOC|PXL|SCAN|VID|WA|DCIM|file|image|document|upload)\b', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return _label(prefix.length >= 3 ? prefix : null, category, date);
}

String _label(String? prefix, String? category, DateTime? date) {
  final cat = (category ?? '').trim();
  final name = _titleCase(prefix ?? (cat.isNotEmpty && cat.toLowerCase() != 'general' ? cat : 'Health record'));
  return date == null ? name : '$name · ${DateFormat('d MMM yyyy').format(date)}';
}

String _titleCase(String s) => s
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => w.length <= 3 && w.toUpperCase() == w ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ')
    .replaceAll('.', '');
