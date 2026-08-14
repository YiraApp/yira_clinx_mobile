import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/common_widgets/snomed_search_picker.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../../core/colors/colors.dart';
import '../../../../core/common_widgets/common_text.dart';
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
    // Sync dosage controller when the bloc value changes externally
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

  /// Extract dosage (e.g. "500mg", "250 mg") and route (e.g. "oral", "topical")
  /// from a SNOMED CT drug term like "Paracetamol 500mg oral tablet"
  static _ParsedDrugInfo _parseDrugTerm(String term) {
    final lower = term.toLowerCase();

    // ── Parse dosage ──
    // Match patterns like 500mg, 250 mg, 10ml, 5 ml, 100mcg, 0.5mg/ml
    String? dosage;
    final dosageRegex = RegExp(
      r'(\d+\.?\d*\s*(?:mg|mcg|µg|g|ml|l|iu|units?|meq)(?:\s*/\s*\d*\.?\d*\s*(?:mg|mcg|µg|g|ml|l|dose|actuation|puff|hr|h))?)',
      caseSensitive: false,
    );
    final dosageMatch = dosageRegex.firstMatch(term);
    if (dosageMatch != null) {
      dosage = dosageMatch.group(0)?.trim();
    }

    // ── Parse route ──
    String? route;
    const routeMap = {
      'oral': 'Oral',
      'injection': 'Injection',
      'intravenous': 'Intravenous (IV)',
      'intramuscular': 'Intramuscular (IM)',
      'subcutaneous': 'Subcutaneous',
      'topical': 'Topical',
      'rectal': 'Oral',
      'nasal': 'Oral',
      'ophthalmic': 'Topical',
      'otic': 'Topical',
      'inhalation': 'Oral',
      'sublingual': 'Oral',
      'transdermal': 'Topical',
      'vaginal': 'Topical',
      'cutaneous': 'Topical',
    };

    // Check for dose form keywords that imply route
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? const Color(0xFF1A1D27) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Medication # + Remove ──
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.index}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: appPoppinFont,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasDrugName ? widget.medicineName : 'New Medication',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 14 : 13,
                      fontWeight: FontWeight.w600,
                      color: hasDrugName
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.white38 : Colors.grey.shade400),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (widget.showRemove)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 18, color: Colors.red.shade400),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    splashRadius: 18,
                  ),
              ],
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drug name via SNOMED search
                SnomedSearchPicker(
                  label: 'Medication Name',
                  hintText: 'Search drug (e.g. Paracetamol)...',
                  snomedType: 'drug',
                  isRequired: true,
                  initialValue:
                      widget.medicineName.isNotEmpty ? widget.medicineName : null,
                  onSelected: (term, code) {
                    // Parse dosage and route from the SNOMED term
                    final parsed = _parseDrugTerm(term);

                    // Update dosage controller immediately if parsed
                    if (parsed.dosage != null && parsed.dosage!.isNotEmpty) {
                      _dosageController.text = parsed.dosage!;
                    }

                    // Notify parent with name + auto-filled dosage + route
                    widget.onDrugSelected(term, parsed.dosage, parsed.route);
                  },
                ),
                const SizedBox(height: 14),

                // Dosage & Frequency side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Dosage', isDark, isRequired: true),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _dosageController,
                            onChanged: (val) => widget.onDosageChanged(val),
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 13 : 13,
                            ),
                            decoration: _fieldDecoration(
                              'e.g. 500mg',
                              isDark,
                              theme,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MedicationDropdownSelector(
                        label: 'Frequency *',
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
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Duration (Days) & Route side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Duration (in Days)', isDark, isRequired: true),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _durationController,
                            onChanged: (_) => _notifyDurationChanged(),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 13 : 13,
                            ),
                            decoration: _fieldDecoration(
                              'e.g. 5',
                              isDark,
                              theme,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel('Route', isDark, isRequired: true),
                          const SizedBox(height: 6),
                          MedicationDropdownSelector(
                            label: '',
                            value: widget.currentRoute,
                            items: const [
                              'Oral',
                              'Injection',
                              'Intravenous (IV)',
                              'Intramuscular (IM)',
                              'Subcutaneous',
                              'Topical',
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
        color: Colors.grey.shade400,
      ),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
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
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }
}
