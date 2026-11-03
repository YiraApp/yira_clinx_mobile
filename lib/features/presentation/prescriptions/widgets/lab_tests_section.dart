import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/prescriptions/lab_test_entity.dart';
import '../../patient/diet/diet_ui.dart';
import '../../patient_profile/widgets/record_tab_ui.dart';

/// The "Lab Tests" part of the prescribing form: the chosen tests, each with
/// its priority and instructions, and the action that opens the picker.
class LabTestsSection extends StatelessWidget {
  final List<PrescribedLabTest> tests;
  final VoidCallback onAdd;
  final ValueChanged<PrescribedLabTest> onRemove;
  final void Function(PrescribedLabTest test, String priority) onPriorityChanged;
  final void Function(PrescribedLabTest test, String instructions) onInstructionsChanged;

  const LabTestsSection({
    super.key,
    required this.tests,
    required this.onAdd,
    required this.onRemove,
    required this.onPriorityChanged,
    required this.onInstructionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: RecordSectionTitle(icon: Icons.biotech_outlined, title: 'Lab Tests')),
            if (tests.isNotEmpty) RecordPill('${tests.length} ${tests.length == 1 ? 'Test' : 'Tests'}'),
          ],
        ),
        const SizedBox(height: 10),
        if (tests.isNotEmpty) ...[
          RecordCard(
            child: Column(
              children: [
                for (var i = 0; i < tests.length; i++) ...[
                  if (i > 0) const RecordDivider(),
                  _LabTestRow(
                    key: ValueKey(tests[i].key),
                    test: tests[i],
                    onRemove: () => onRemove(tests[i]),
                    onPriorityChanged: (priority) => onPriorityChanged(tests[i], priority),
                    onInstructionsChanged: (text) => onInstructionsChanged(tests[i], text),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: RecordSecondaryButton(label: 'Add Lab Test', icon: Icons.add_rounded, onPressed: onAdd),
        ),
      ],
    );
  }
}

class _LabTestRow extends StatefulWidget {
  final PrescribedLabTest test;
  final VoidCallback onRemove;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<String> onInstructionsChanged;

  const _LabTestRow({
    super.key,
    required this.test,
    required this.onRemove,
    required this.onPriorityChanged,
    required this.onInstructionsChanged,
  });

  @override
  State<_LabTestRow> createState() => _LabTestRowState();
}

class _LabTestRowState extends State<_LabTestRow> {
  late final TextEditingController _instructions = TextEditingController(text: widget.test.instructions);

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = (widget.test.category ?? '').trim();
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: RecordUi.line(isDark)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.test.testName, style: DietUi.text(13.5, FontWeight.w600, RecordUi.ink(isDark), height: 1.3)),
                  if (category.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(category, style: DietUi.text(11.5, FontWeight.w400, DietUi.muted(isDark))),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            RecordIconAction(
              icon: Icons.close_rounded,
              tooltip: 'Remove ${widget.test.testName}',
              danger: true,
              onTap: widget.onRemove,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _PriorityToggle(priority: widget.test.priority, onChanged: widget.onPriorityChanged),
        const SizedBox(height: 8),
        TextField(
          controller: _instructions,
          onChanged: widget.onInstructionsChanged,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          inputFormatters: [LengthLimitingTextInputFormatter(500)],
          style: DietUi.text(12.5, FontWeight.w400, RecordUi.ink(isDark)),
          decoration: InputDecoration(
            hintText: 'Instructions (optional)',
            hintStyle: DietUi.text(12, FontWeight.w400, DietUi.hint(isDark)),
            isDense: true,
            filled: true,
            fillColor: DietUi.sunken(isDark),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(borderSide: const BorderSide(color: DietUi.blue, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _PriorityToggle extends StatelessWidget {
  final String priority;
  final ValueChanged<String> onChanged;

  const _PriorityToggle({required this.priority, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget option(String value, Color tone) {
      final selected = priority == value;
      return Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onChanged(value),
          child: Container(
            constraints: const BoxConstraints(minWidth: 76),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? tone.withValues(alpha: isDark ? 0.22 : 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: DietUi.text(11.5, selected ? FontWeight.w600 : FontWeight.w500, selected ? tone : DietUi.muted(isDark)),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: RecordUi.soft(isDark), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          option(PrescribedLabTest.routine, DietUi.blue),
          const SizedBox(width: 2),
          option(PrescribedLabTest.urgent, RecordUi.urgent),
        ],
      ),
    );
  }
}
