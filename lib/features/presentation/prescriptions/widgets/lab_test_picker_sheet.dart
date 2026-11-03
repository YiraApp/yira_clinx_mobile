import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/prescriptions/lab_test_entity.dart';
import '../../patient/diet/diet_ui.dart';
import '../../patient_profile/widgets/record_tab_ui.dart';
import '../prescription_bloc/prescription_bloc.dart';

/// Bottom sheet for choosing a prescription's lab tests from the hospital's
/// list, or typing one that is not on it. Pops the whole selection when done.
class LabTestPickerSheet extends StatefulWidget {
  final LabCatalogStatus status;
  final List<HospitalLabTest> tests;
  final List<PrescribedLabTest> selected;
  final VoidCallback? onRetry;

  const LabTestPickerSheet({
    super.key,
    required this.status,
    required this.tests,
    required this.selected,
    this.onRetry,
  });

  /// Loads the hospital's tests and opens the sheet. The doctor's selection
  /// goes back into [bloc] when they finish; dismissing the sheet changes nothing.
  static Future<void> show(BuildContext context, {required PrescriptionBloc bloc, String? hospitalId}) async {
    bloc.add(LoadLabTestCatalog(hospitalId));
    final picked = await showModalBottomSheet<List<PrescribedLabTest>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocBuilder<PrescriptionBloc, PrescriptionState>(
        bloc: bloc,
        buildWhen: (previous, current) =>
            previous.labCatalogStatus != current.labCatalogStatus || previous.labCatalog != current.labCatalog,
        builder: (_, state) => LabTestPickerSheet(
          status: state.labCatalogStatus,
          tests: state.labCatalog,
          selected: state.labTests,
          onRetry: () => bloc.add(LoadLabTestCatalog(hospitalId)),
        ),
      ),
    );
    if (picked != null) bloc.add(SetLabTests(picked));
  }

  @override
  State<LabTestPickerSheet> createState() => _LabTestPickerSheetState();
}

/// One line of the list, from the hospital's tests or from the selection.
class _PickerRow {
  final PrescribedLabTest test;
  final String meta;
  final String? preparation;

  const _PickerRow(this.test, this.meta, this.preparation);
}

class _LabTestPickerSheetState extends State<LabTestPickerSheet> {
  static const String _allCategories = 'All';

  final TextEditingController _search = TextEditingController();
  late final Map<String, PrescribedLabTest> _selected = {for (final test in widget.selected) test.key: test};
  String _category = _allCategories;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim();

  List<String> get _categories {
    final found = <String>{};
    for (final test in widget.tests) {
      final category = (test.category ?? '').trim();
      if (category.isNotEmpty) found.add(category);
    }
    return [_allCategories, ...found.toList()..sort()];
  }

  bool _isListed(String name) => widget.tests.any((test) => PrescribedLabTest.keyOf(test.testName) == PrescribedLabTest.keyOf(name));

  /// Chosen tests the hospital's list does not show, so they can still be
  /// unticked: typed ones, and ones since removed from the list.
  List<_PickerRow> get _unlistedRows {
    if (_category != _allCategories) return const [];
    final q = _query.toLowerCase();
    return _selected.values
        .where((test) => !_isListed(test.testName) && test.testName.toLowerCase().contains(q))
        .map((test) => _PickerRow(test, test.hospitalLabTestId == null ? 'Typed test' : (test.category ?? ''), null))
        .toList();
  }

  List<_PickerRow> get _listedRows {
    final q = _query.toLowerCase();
    return widget.tests.where((test) {
      if (_category != _allCategories && (test.category ?? '').trim() != _category) return false;
      return q.isEmpty ||
          test.testName.toLowerCase().contains(q) ||
          (test.testCode ?? '').toLowerCase().contains(q) ||
          (test.category ?? '').toLowerCase().contains(q);
    }).map((test) {
      final meta = [test.category ?? '', test.sampleType ?? ''].where((part) => part.trim().isNotEmpty).join(' · ');
      return _PickerRow(PrescribedLabTest.fromHospitalTest(test), meta, test.preparation);
    }).toList();
  }

  void _toggle(PrescribedLabTest test) {
    setState(() {
      if (_selected.remove(test.key) == null) _selected[test.key] = test;
    });
  }

  void _addTyped() {
    final name = _query;
    if (name.isEmpty || _isListed(name) || _selected.containsKey(PrescribedLabTest.keyOf(name))) return;
    setState(() {
      final test = PrescribedLabTest(testName: name);
      _selected[test.key] = test;
      _search.clear();
      _category = _allCategories;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final canType = _query.isNotEmpty && !_isListed(_query) && !_selected.containsKey(PrescribedLabTest.keyOf(_query));

    return Container(
      height: math.min(media.size.height * 0.88, 720),
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      decoration: BoxDecoration(
        color: DietUi.card(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(child: Text('Add Lab Test', style: DietUi.text(15, FontWeight.w600, RecordUi.ink(isDark)))),
                RecordIconAction(icon: Icons.close_rounded, tooltip: 'Close', onTap: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _searchField(isDark, canType),
          ),
          if (_categories.length > 1) _categoryChips(isDark),
          Divider(height: 1, thickness: 1, color: RecordUi.line(isDark)),
          Expanded(child: _list(isDark, canType)),
          _footer(isDark, media.viewInsets.bottom > 0 ? 0 : media.padding.bottom),
        ],
      ),
    );
  }

  Widget _searchField(bool isDark, bool canType) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: RecordUi.line(isDark)),
    );
    return TextField(
      controller: _search,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) {
        if (canType) _addTyped();
      },
      textInputAction: TextInputAction.search,
      inputFormatters: [LengthLimitingTextInputFormatter(200)],
      style: DietUi.text(13, FontWeight.w400, RecordUi.ink(isDark)),
      decoration: InputDecoration(
        hintText: 'Search tests',
        hintStyle: DietUi.text(13, FontWeight.w400, DietUi.hint(isDark)),
        prefixIcon: Icon(Icons.search_rounded, size: 19, color: DietUi.muted(isDark)),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        isDense: true,
        filled: true,
        fillColor: DietUi.sunken(isDark),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: DietUi.blue, width: 1.5)),
      ),
    );
  }

  Widget _categoryChips(bool isDark) {
    final categories = _categories;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final category = categories[i];
          final selected = category == _category;
          return Semantics(
            button: true,
            selected: selected,
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => setState(() => _category = category),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  color: selected ? DietUi.blue.withValues(alpha: isDark ? 0.22 : 0.09) : RecordUi.soft(isDark),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  category,
                  style: DietUi.text(11.5, selected ? FontWeight.w600 : FontWeight.w500, selected ? DietUi.blue : DietUi.muted(isDark)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _list(bool isDark, bool canType) {
    final loading = widget.status == LabCatalogStatus.loading || widget.status == LabCatalogStatus.initial;
    final failed = widget.status == LabCatalogStatus.failure;
    final rows = [..._unlistedRows, ..._listedRows];

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        if (canType) _typedRow(isDark),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: RecordUi.line(isDark)),
          _testRow(rows[i], isDark),
        ],
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
          )
        else if (failed) ...[
          const SizedBox(height: 24),
          const RecordEmptyState(
            icon: Icons.error_outline_rounded,
            title: "Couldn't load this hospital's tests.",
            message: 'You can still type a test name above.',
          ),
          const SizedBox(height: 12),
          if (widget.onRetry != null)
            Center(child: RecordSecondaryButton(label: 'Try again', onPressed: widget.onRetry!)),
          const SizedBox(height: 16),
        ] else if (rows.isEmpty && !canType) ...[
          const SizedBox(height: 24),
          RecordEmptyState(
            icon: Icons.biotech_outlined,
            title: widget.tests.isEmpty ? 'No tests listed yet.' : 'No matching tests.',
            message: 'Type a test name above to add it.',
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _typedRow(bool isDark) {
    return InkWell(
      onTap: _addTyped,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.add_rounded, size: 19, color: DietUi.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Add "$_query" as a typed test',
                style: DietUi.text(13, FontWeight.w600, DietUi.blue, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _testRow(_PickerRow row, bool isDark) {
    final selected = _selected.containsKey(row.test.key);
    final preparation = (row.preparation ?? '').trim();
    return Semantics(
      checked: selected,
      child: InkWell(
        onTap: () => _toggle(_selected[row.test.key] ?? row.test),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.test.testName, style: DietUi.text(13, FontWeight.w500, RecordUi.ink(isDark), height: 1.3)),
                    if (row.meta.trim().isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(row.meta, style: DietUi.text(11.5, FontWeight.w400, DietUi.muted(isDark), height: 1.3)),
                    ],
                    if (preparation.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        preparation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DietUi.text(11, FontWeight.w400, DietUi.hint(isDark), height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                size: 21,
                color: selected ? DietUi.blue : DietUi.hint(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(bool isDark, double bottomInset) {
    final count = _selected.length;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: RecordUi.line(isDark)))),
      child: Row(
        children: [
          Expanded(
            child: Text(
              count == 0 ? 'None selected' : '$count selected',
              style: DietUi.text(12.5, FontWeight.w500, DietUi.muted(isDark)),
            ),
          ),
          RecordPrimaryButton(
            label: 'Done',
            compact: true,
            onPressed: () => Navigator.of(context).pop(_selected.values.toList()),
          ),
        ],
      ),
    );
  }
}
