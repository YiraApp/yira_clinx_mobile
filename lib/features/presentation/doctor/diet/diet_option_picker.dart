import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';

/// Household measures a doctor can prescribe a food in. Food names (chapati, idli…)
/// are not units; count those with "piece" / "pieces".
const List<String> kDietPortionUnits = [
  'serving',
  'piece',
  'pieces',
  'bowl',
  'small bowl',
  'katori',
  'cup',
  'glass',
  'tall glass',
  'plate',
  'slice',
  'tablespoon',
  'teaspoon',
  'handful',
  'scoop',
  'sachet',
];

/// Units for a portion's weight or volume.
const List<String> kDietWeightUnits = ['g', 'kg', 'mg', 'ml', 'L', 'oz'];

/// Quick weights to offer for a unit, or none when the unit has no common sizes.
List<int> dietWeightPresets(String unit) {
  switch (unit) {
    case 'g':
      return const [50, 100, 150, 200, 250];
    case 'ml':
      return const [100, 150, 200, 250, 300];
    default:
      return const [];
  }
}

// Units added by the doctor this session, so they can be picked again.
final Set<String> _customUnits = {};

/// Opens a searchable list of [options]. Typing something that is not in the
/// list offers it as a custom value. Resolves to the chosen value, or null.
Future<String?> showDietOptionPicker(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selected,
  String hint = 'Search or type your own',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DietOptionPickerSheet(
      title: title,
      options: options,
      selected: selected,
      hint: hint,
    ),
  );
}

class _DietOptionPickerSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final String? selected;
  final String hint;

  const _DietOptionPickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.hint,
  });

  @override
  State<_DietOptionPickerSheet> createState() => _DietOptionPickerSheetState();
}

class _DietOptionPickerSheetState extends State<_DietOptionPickerSheet> {
  static const Color _primaryBlue = Color(0xFF2563EB);
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<String> get _allOptions {
    final all = <String>[...widget.options];
    for (final extra in [..._customUnits, if (widget.selected != null) widget.selected!]) {
      if (extra.trim().isNotEmpty && !all.any((o) => o.toLowerCase() == extra.toLowerCase())) {
        all.add(extra);
      }
    }
    return all;
  }

  void _choose(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return;
    if (!widget.options.any((o) => o.toLowerCase() == clean.toLowerCase())) {
      _customUnits.add(clean);
    }
    Navigator.pop(context, clean);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final query = _searchCtrl.text.trim();
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final matches = _allOptions
        .where((o) => query.isEmpty || o.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final exactMatch = _allOptions.any((o) => o.toLowerCase() == query.toLowerCase());

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: media.size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? darkModeCardColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: Icon(Icons.close_rounded, color: mutedColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) _choose(matches.length == 1 && !exactMatch ? matches.first : v);
                  },
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: mutedColor),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
                    ),
                  ),
                ),
              ),
              Expanded(
                // ListTile paints its ink on the nearest Material.
                child: Material(
                  type: MaterialType.transparency,
                  child: ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    if (query.isNotEmpty && !exactMatch)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.add_circle_outline_rounded, color: _primaryBlue),
                        title: Text(
                          'Add "$query" as custom',
                          style: const TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w600, color: _primaryBlue),
                        ),
                        onTap: () => _choose(query),
                      ),
                    for (final option in matches)
                      ListTile(
                        dense: true,
                        title: Text(option, style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, color: textColor)),
                        trailing: option.toLowerCase() == widget.selected?.toLowerCase()
                            ? const Icon(Icons.check_rounded, color: _primaryBlue, size: 20)
                            : null,
                        onTap: () => _choose(option),
                      ),
                  ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A form field that looks like a dropdown and opens [showDietOptionPicker].
class DietOptionField extends StatelessWidget {
  final String value;
  final String placeholder;
  final String pickerTitle;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const DietOptionField({
    super.key,
    required this.value,
    required this.placeholder,
    required this.pickerTitle,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value.trim().isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        FocusScope.of(context).unfocus();
        final picked = await showDietOptionPicker(
          context,
          title: pickerTitle,
          options: options,
          selected: hasValue ? value : null,
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value : placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13.5,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                  color: hasValue
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}
