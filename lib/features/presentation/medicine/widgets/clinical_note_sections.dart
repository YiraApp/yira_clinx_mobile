import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';

// The doctor's OPD note, the same as on the web: allergies first, then examination and vitals,
// then the clinical history (family history under H/O). Lists such as allergies are saved as one
// comma-separated text.

const _blue = Color(0xFF2563EB);
const _rose = Color(0xFFE11D48);

/// Splits a list on commas outside brackets, so "Penicillin (rash, itching)" stays one item.
List<String> splitNoteList(String text) {
  final items = <String>[];
  var depth = 0;
  final current = StringBuffer();
  for (final ch in text.split('')) {
    if (ch == '(') depth++;
    if (ch == ')') depth = depth > 0 ? depth - 1 : 0;
    if (ch == ',' && depth == 0) {
      if (current.toString().trim().isNotEmpty) items.add(current.toString().trim());
      current.clear();
    } else {
      current.write(ch);
    }
  }
  if (current.toString().trim().isNotEmpty) items.add(current.toString().trim());
  return items;
}

/// Adds [term] to a comma list unless it is already there.
String appendNoteTerm(String current, String term) {
  final items = splitNoteList(current);
  if (items.any((i) => i.toLowerCase() == term.toLowerCase())) return current;
  return [...items, term].join(', ');
}

const allergySuggestions = ["No known allergies (NKDA)", "Penicillin", "Sulfa drugs", "NSAIDs / Aspirin", "Peanuts", "Seafood", "Dust / Pollen", "Latex"];
const familyHistorySuggestions = ["Diabetes", "Hypertension", "Heart disease", "Cancer", "No significant family history"];
const pastHistorySuggestions = ["Diabetes (DM)", "Hypertension (HTN)", "Asthma", "Thyroid disorder", "Past surgeries", "No known comorbidities"];
const generalExamTerms = ["Pallor", "Icterus", "Cyanosis", "Clubbing", "Lymphadenopathy", "Edema"];
const generalExamNormal = "No pallor, icterus, cyanosis, clubbing, lymphadenopathy or edema";
const systemicNormal = {
  "CVS": "S1, S2 normal; no murmurs",
  "RS": "Bilateral air entry equal; no added sounds",
  "P/A": "Soft, non-tender; no organomegaly",
  "CNS": "Conscious, oriented; no focal deficits",
};

bool _isNoKnown(String t) => t.toLowerCase().startsWith('no known allerg');

/// The white card the record form's sections use.
class NoteCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final List<Widget> children;
  final bool isTab;

  const NoteCard({super.key, required this.icon, required this.title, this.subtitle, this.color = _blue, required this.children, required this.isTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color == _rose ? _rose.withValues(alpha: 0.25) : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontFamily: appPoppinFont, fontSize: isTab ? 17 : 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF121212))),
                    if (subtitle != null)
                      Text(subtitle!, style: TextStyle(fontFamily: appPoppinFont, fontSize: isTab ? 12 : 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

/// A labelled text field with optional quick-pick chips.
class NoteField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final List<String> chips;
  final void Function(String chip)? onChip;
  final Widget? trailing;

  const NoteField({super.key, required this.label, required this.controller, required this.hint, this.maxLines = 2, this.chips = const [], this.onChip, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700))),
              ?trailing,
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: maxLines,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF121212)),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: Colors.grey.shade500),
              filled: true,
              fillColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _blue, width: 1.4)),
            ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: chips.map((c) => QuickChip(label: '+ $c', onTap: () => onChip?.call(c))).toList()),
          ],
        ],
      ),
    );
  }
}

class QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const QuickChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        ),
        child: Text(label, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w500, color: isDark ? Colors.grey.shade300 : const Color(0xFF475569))),
      ),
    );
  }
}

/// Allergies at the top of the record: the doctor types any allergy with its reaction and taps Add
/// (or picks a common one); each shows as a chip that can be removed. "No known allergies" replaces
/// the list.
class AllergiesSection extends StatefulWidget {
  final TextEditingController controller;
  final bool isTab;
  const AllergiesSection({super.key, required this.controller, required this.isTab});

  @override
  State<AllergiesSection> createState() => _AllergiesSectionState();
}

class _AllergiesSectionState extends State<AllergiesSection> {
  final _draft = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Typed but not added: added when the doctor moves on, so it isn't lost.
    _focus.addListener(() {
      if (!_focus.hasFocus && _draft.text.trim().isNotEmpty) _add(_draft.text);
    });
  }

  @override
  void dispose() {
    _draft.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<String> get _items => splitNoteList(widget.controller.text);

  void _add(String raw) {
    final entries = splitNoteList(raw);
    if (entries.isEmpty) return;
    final none = entries.where(_isNoKnown).toList();
    if (none.isNotEmpty) {
      widget.controller.text = none.first;
    } else {
      final next = _items.where((i) => !_isNoKnown(i)).toList();
      for (final e in entries) {
        if (!next.any((i) => i.toLowerCase() == e.toLowerCase())) next.add(e);
      }
      widget.controller.text = next.join(', ');
    }
    _draft.clear();
    setState(() {});
  }

  void _remove(String item) {
    widget.controller.text = _items.where((i) => i != item).join(', ');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _items;
    final suggestions = allergySuggestions.where((s) => !items.any((i) => i.toLowerCase() == s.toLowerCase())).toList();
    return NoteCard(
      icon: Icons.warning_amber_rounded,
      title: "Allergies",
      subtitle: "Drug, food or other allergies, and the reaction",
      color: _rose,
      isTab: widget.isTab,
      children: [
        if (items.isEmpty)
          Text("No allergies added yet.", style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: Colors.grey.shade500))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((item) {
              final none = _isNoKnown(item);
              return Container(
                padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
                decoration: BoxDecoration(color: none ? const Color(0xFFECFDF5) : const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(item, style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: none ? const Color(0xFF065F46) : const Color(0xFF9F1239)))),
                    InkWell(
                      onTap: () => _remove(item),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 14, semanticLabel: 'Remove $item', color: none ? const Color(0xFF065F46) : const Color(0xFF9F1239))),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _draft,
                focusNode: _focus,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: _add,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF121212)),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "e.g. Ibuprofen - rash",
                  hintStyle: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: Colors.grey.shade500),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF121212) : const Color(0xFFFFF7F8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _rose.withValues(alpha: 0.3))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _rose.withValues(alpha: 0.3))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _rose, width: 1.4)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 42,
              child: OutlinedButton.icon(
                onPressed: _draft.text.trim().isEmpty ? null : () => _add(_draft.text),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("Add", style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(foregroundColor: _rose, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ],
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: suggestions.map((s) => QuickChip(label: '+ $s', onTap: () => _add(s))).toList()),
        ],
      ],
    );
  }
}

/// General examination and the four systems, each with its usual normal finding one tap away.
class ExaminationSection extends StatelessWidget {
  final TextEditingController generalController;
  final TextEditingController cvsController;
  final TextEditingController rsController;
  final TextEditingController abdomenController;
  final TextEditingController cnsController;
  final bool isTab;

  const ExaminationSection({super.key, required this.generalController, required this.cvsController, required this.rsController, required this.abdomenController, required this.cnsController, required this.isTab});

  @override
  Widget build(BuildContext context) {
    final systems = {"CVS": cvsController, "RS": rsController, "P/A": abdomenController, "CNS": cnsController};
    Widget normalButton(String label, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(label, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w600, color: _blue)),
          ),
        );
    return NoteCard(
      icon: Icons.medical_services_outlined,
      title: "Clinical Examination",
      subtitle: "General and systemic examination",
      isTab: isTab,
      children: [
        NoteField(
          label: "General Examination",
          controller: generalController,
          hint: "Pallor / Icterus / Cyanosis / Clubbing / Lymphadenopathy / Edema",
          maxLines: 3,
          chips: const ["All normal", ...generalExamTerms],
          onChip: (c) {
            if (c == "All normal") {
              generalController.text = generalExamNormal;
            } else {
              generalController.text = appendNoteTerm(generalController.text == generalExamNormal ? '' : generalController.text, c);
            }
          },
        ),
        Row(
          children: [
            Expanded(child: Text("Systemic Examination", style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700))),
            normalButton("Fill empty as normal", () {
              systems.forEach((name, c) {
                if (c.text.trim().isEmpty) c.text = systemicNormal[name]!;
              });
            }),
          ],
        ),
        const SizedBox(height: 8),
        ...systems.entries.map((e) => NoteField(
              label: e.key,
              controller: e.value,
              hint: {"CVS": "S1, S2 normal / murmurs", "RS": "Bilateral air entry / added sounds", "P/A": "Soft / tenderness / organomegaly", "CNS": "Conscious, oriented / focal deficits"}[e.key]!,
              trailing: normalButton("Normal", () => e.value.text = systemicNormal[e.key]!),
            )),
      ],
    );
  }
}

/// H/O, family history (under it), past/comorbid history and current medicines, for the history card.
List<Widget> historyNoteFields({
  required TextEditingController hpiController,
  required TextEditingController familyController,
  required TextEditingController pastController,
  required TextEditingController medicinesController,
}) {
  return [
    const SizedBox(height: 16),
    NoteField(label: "History of Present Illness (H/O)", controller: hpiController, hint: "Onset, progression, severity, associated symptoms", maxLines: 4),
    NoteField(
      label: "Family History",
      controller: familyController,
      hint: "Illnesses in parents, siblings or children",
      maxLines: 3,
      chips: familyHistorySuggestions,
      onChip: (c) => familyController.text = c.startsWith("No significant")
          ? c
          : appendNoteTerm(familyController.text.startsWith("No significant") ? '' : familyController.text, c),
    ),
    NoteField(
      label: "Relevant Past / Comorbid History",
      controller: pastController,
      hint: "DM / HTN / Asthma / Thyroid / Past surgeries",
      maxLines: 3,
      chips: pastHistorySuggestions,
      onChip: (c) => pastController.text = appendNoteTerm(pastController.text, c),
    ),
    NoteField(label: "Current Medications", controller: medicinesController, hint: "Medicines the patient already takes", maxLines: 3),
  ];
}

/// What the preview shows, in the order the record prints on the prescription.
class RecordPreviewData {
  final String allergies;
  final List<MapEntry<String, String>> vitals;
  final String generalExamination;
  final List<MapEntry<String, String>> systemic;
  final List<MapEntry<String, String>> history;
  const RecordPreviewData({required this.allergies, required this.vitals, required this.generalExamination, required this.systemic, required this.history});
}

/// Shows the record before it is saved. Returns true for Save, false for Edit.
Future<bool> showRecordPreview(BuildContext context, RecordPreviewData data, {required bool isEdit}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
      final ink = isDark ? Colors.white : const Color(0xFF0F172A);
      final muted = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
      Widget heading(String text) => Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(text.toUpperCase(), style: const TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Color(0xFF1E3A8A))),
          );
      Widget row(String label, String value) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w600, color: muted)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, color: ink)),
              ],
            ),
          );
      final hasAllergies = data.allergies.trim().isNotEmpty;
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scroll) => Container(
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Preview medical record", style: TextStyle(fontFamily: appPoppinFont, fontSize: 17, fontWeight: FontWeight.w700, color: ink)),
                    const SizedBox(height: 2),
                    Text("Check the details. Save if they are right, or go back to edit them.", style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: muted)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasAllergies ? const Color(0xFFFFF1F2) : (isDark ? const Color(0xFF232323) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: hasAllergies ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("ALLERGIES", style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: hasAllergies ? const Color(0xFF9F1239) : muted)),
                          const SizedBox(height: 4),
                          Text(hasAllergies ? data.allergies : "Not recorded", style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: hasAllergies ? FontWeight.w700 : FontWeight.w400, color: hasAllergies ? const Color(0xFF881337) : muted)),
                        ],
                      ),
                    ),
                    if (data.vitals.isNotEmpty || data.generalExamination.isNotEmpty || data.systemic.isNotEmpty) ...[
                      heading("Clinical examination & vitals"),
                      if (data.vitals.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: data.vitals
                              .map((v) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(v.key.toUpperCase(), style: TextStyle(fontFamily: appPoppinFont, fontSize: 10, fontWeight: FontWeight.w700, color: muted)),
                                        Text(v.value, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, fontWeight: FontWeight.w700, color: ink)),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      if (data.generalExamination.isNotEmpty) row("General Examination", data.generalExamination),
                      if (data.systemic.isNotEmpty) row("Systemic Examination", data.systemic.map((e) => "${e.key}: ${e.value}").join("\n")),
                    ],
                    if (data.history.isNotEmpty) ...[
                      heading("Clinical history & presentation"),
                      ...data.history.map((e) => row(e.key, e.value)),
                    ],
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(sheetContext).pop(false),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text("Edit", style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 7,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(sheetContext).pop(true),
                          icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                          label: Text(isEdit ? "Save changes" : "Save record", style: const TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: _blue, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
