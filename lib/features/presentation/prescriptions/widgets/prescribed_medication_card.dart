import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/common_widgets/snomed_search_picker.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'medication_drop_down_selector.dart';

/// Parsed drug info from a SNOMED CT term string
class _ParsedDrugInfo {
  final String? dosage;
  final String? route;

  const _ParsedDrugInfo({this.dosage, this.route});
}

class PrescribedPrescriptionCard extends StatefulWidget {
  final int index;
  final String medicineName;
  final String? currentDosage;
  final String? currentFreq;
  final String? currentDuration;
  final String? currentRoute;
  final VoidCallback onRemove;
  final Function(String name, String? dosage, String? route) onDrugSelected;
  final Function(String?) onDosageChanged;
  final Function(String?) onFreqChanged;
  final Function(String?) onDurationChanged;
  final Function(String?) onRouteChanged;
  final bool isTab;
  final bool showRemove;

  const PrescribedPrescriptionCard({
    super.key,
    required this.index,
    required this.medicineName,
    this.currentDosage,
    this.currentFreq,
    this.currentDuration,
    this.currentRoute,
    required this.onRemove,
    required this.onDrugSelected,
    required this.onDosageChanged,
    required this.onFreqChanged,
    required this.onDurationChanged,
    required this.onRouteChanged,
    required this.isTab,
    this.showRemove = true,
  });

  @override
  State<PrescribedPrescriptionCard> createState() =>
      _PrescribedPrescriptionCardState();
}

class _PrescribedPrescriptionCardState
    extends State<PrescribedPrescriptionCard> {
  late TextEditingController _dosageController;
  late TextEditingController _durationController;

  static const Color _primaryBlue = Color(0xFF2563EB);

  static const List<String> _quickDosages = [
    '250mg',
    '500mg',
    '650mg',
    '5ml',
    '10ml',
    '1 Tab',
  ];

  static const List<Map<String, String>> _quickFrequencies = [
    {'code': '1-0-1', 'label': '1-0-1 (Morning-Night)'},
    {'code': '1-1-1', 'label': '1-1-1 (Morning-Afternoon-Night)'},
    {'code': '1-0-0', 'label': '1-0-0 (Morning)'},
    {'code': '0-0-1', 'label': '0-0-1 (Night)'},
    {'code': 'PRN', 'label': 'As needed (PRN)'},
  ];

  static const List<String> _quickDurations = [
    '3',
    '5',
    '7',
    '10',
    '14',
    '30',
  ];

  @override
  void initState() {
    super.initState();
    _dosageController = TextEditingController(text: widget.currentDosage ?? '');
    _durationController = TextEditingController();
    _syncDurationState();
  }

  void _syncDurationState() {
    final raw = widget.currentDuration ?? '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      _durationController.text = '';
      return;
    }
    final match = RegExp(r'^(\d+)').firstMatch(trimmed);
    if (match != null) {
      _durationController.text = match.group(1) ?? '';
    } else {
      _durationController.text = trimmed;
    }
  }

  void _notifyDurationChanged() {
    final numVal = _durationController.text.trim();
    widget.onDurationChanged(numVal.isNotEmpty ? '$numVal Days' : '');
  }

  @override
  void didUpdateWidget(covariant PrescribedPrescriptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDosage != widget.currentDosage &&
        _dosageController.text != (widget.currentDosage ?? '')) {
      _dosageController.text = widget.currentDosage ?? '';
    }
    if (oldWidget.currentDuration != widget.currentDuration) {
      _syncDurationState();
    }
  }

  @override
  void dispose() {
    _dosageController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  static _ParsedDrugInfo _parseDrugTerm(String term) {
    final lower = term.toLowerCase();

    String? dosage;
    final dosageRegex = RegExp(
      r'(\d+\.?\d*\s*(?:mg|mcg|µg|g|ml|l|iu|units?|meq)(?:\s*/\s*\d*\.?\d*\s*(?:mg|mcg|µg|g|ml|l|dose|actuation|puff|hr|h))?)',
      caseSensitive: false,
    );
    final dosageMatch = dosageRegex.firstMatch(term);
    if (dosageMatch != null) {
      dosage = dosageMatch.group(0)?.trim();
    }

    String? route;
    const routeMap = {
      'oral': 'Oral',
      'injection': 'Injection',
      'intravenous': 'Intravenous (IV)',
      'intramuscular': 'Intramuscular (IM)',
      'subcutaneous': 'Subcutaneous',
      'topical': 'Topical',
    };

    const oralForms = ['tablet', 'capsule', 'syrup', 'suspension', 'solution', 'elixir', 'granule', 'powder for oral', 'chewable', 'lozenge', 'sachet'];
    const topicalForms = ['cream', 'ointment', 'gel', 'lotion', 'patch', 'plaster', 'spray'];
    const injectionForms = ['injection', 'infusion', 'ampoule', 'vial'];

    for (final entry in routeMap.entries) {
      if (lower.contains(entry.key)) {
        route = entry.value;
        break;
      }
    }

    if (route == null) {
      for (final form in oralForms) {
        if (lower.contains(form)) {
          route = 'Oral';
          break;
        }
      }
    }
    if (route == null) {
      for (final form in topicalForms) {
        if (lower.contains(form)) {
          route = 'Topical';
          break;
        }
      }
    }
    if (route == null) {
      for (final form in injectionForms) {
        if (lower.contains(form)) {
          route = 'Injection';
          break;
        }
      }
    }

    return _ParsedDrugInfo(dosage: dosage, route: route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final isTab = widget.isTab;
    final hasDrugName = widget.medicineName.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Medicine Index + Title + Delete Action ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.index}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: appPoppinFont,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasDrugName ? widget.medicineName : 'Medication #${widget.index}',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 14.5 : 13.5,
                      fontWeight: FontWeight.bold,
                      color: hasDrugName
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (widget.showRemove)
                  InkWell(
                    onTap: widget.onRemove,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Body Fields ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Drug name search with SNOMED
                SnomedSearchPicker(
                  label: 'Medication / Generic Name',
                  hintText: 'Search drug (e.g. Paracetamol, Amoxicillin)...',
                  snomedType: 'drug',
                  isRequired: true,
                  initialValue:
                      widget.medicineName.isNotEmpty ? widget.medicineName : null,
                  onSelected: (term, code) {
                    final parsed = _parseDrugTerm(term);
                    if (parsed.dosage != null && parsed.dosage!.isNotEmpty) {
                      _dosageController.text = parsed.dosage!;
                    }
                    widget.onDrugSelected(term, parsed.dosage, parsed.route);
                  },
                ),
                const SizedBox(height: 12),

                // 2. Dosage input + Quick Dosage Chips
                _FieldLabel('Dosage', isDark, isRequired: true),
                const SizedBox(height: 5),
                TextField(
                  controller: _dosageController,
                  onChanged: (val) => widget.onDosageChanged(val),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 13.5 : 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: _fieldDecoration(
                    'e.g. 500mg, 10ml, 1 tablet',
                    isDark,
                    theme,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _quickDosages.map((d) {
                    final isSelected = _dosageController.text.trim().toLowerCase() == d.toLowerCase();
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _dosageController.text = d;
                        });
                        widget.onDosageChanged(d);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _primaryBlue.withValues(alpha: isDark ? 0.25 : 0.12)
                              : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? _primaryBlue
                                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          d,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? _primaryBlue : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // 3. Frequency with Quick Timing Presets
                _FieldLabel('Frequency / Timing', isDark, isRequired: true),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _quickFrequencies.map((f) {
                    final isSelected = widget.currentFreq == f['label'];
                    return InkWell(
                      onTap: () => widget.onFreqChanged(f['label']),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _primaryBlue
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? _primaryBlue
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                        ),
                        child: Text(
                          f['code']!,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                MedicationDropdownSelector(
                  label: '',
                  value: widget.currentFreq,
                  items: const [
                    '1-0-1 (Morning-Night)',
                    '1-1-1 (Morning-Afternoon-Night)',
                    '1-0-0 (Morning)',
                    '0-0-1 (Night)',
                    '0-1-0 (Afternoon)',
                    '1-1-0 (Morning-Afternoon)',
                    '0-1-1 (Afternoon-Night)',
                    'As needed (PRN)',
                    'Every 8 hours',
                    'Every 12 hours',
                  ],
                  onChanged: widget.onFreqChanged,
                ),
                const SizedBox(height: 12),

                // 4. Duration & Route side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Duration Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Duration (Days)', isDark, isRequired: true),
                          const SizedBox(height: 5),
                          TextField(
                            controller: _durationController,
                            onChanged: (_) => _notifyDurationChanged(),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 13 : 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            decoration: _fieldDecoration(
                              'e.g. 5',
                              isDark,
                              theme,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            children: _quickDurations.map((d) {
                              final isSelected = _durationController.text.trim() == d;
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _durationController.text = d;
                                  });
                                  _notifyDurationChanged();
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _primaryBlue.withValues(alpha: isDark ? 0.25 : 0.12)
                                        : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? _primaryBlue
                                          : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '${d}d',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 10,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? _primaryBlue : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Route Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Route', isDark, isRequired: true),
                          const SizedBox(height: 5),
                          MedicationDropdownSelector(
                            label: '',
                            value: widget.currentRoute ?? 'Oral',
                            items: const [
                              'Oral',
                              'Injection',
                              'Intravenous (IV)',
                              'Intramuscular (IM)',
                              'Subcutaneous',
                              'Topical',
                              'Inhalation',
                            ],
                            onChanged: widget.onRouteChanged,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, bool isDark, ThemeData theme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: 12,
        color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  final bool isRequired;
  const _FieldLabel(this.text, this.isDark, {this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}
