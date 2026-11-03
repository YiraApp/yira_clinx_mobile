import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/phosphor_icons.dart';
import '../../../data/data_sources/wallet/wallet_remote_data_source.dart';
import '../../../data/models/wallet/wallet_models.dart';
import 'wallet_attachment.dart';
import 'wallet_widgets.dart';

/// Common insurers and schemes, offered as one-tap suggestions.
const _insurerSuggestions = [
  'Star Health',
  'HDFC ERGO',
  'ICICI Lombard',
  'Niva Bupa',
  'Care Health',
  'Aditya Birla Health',
  'LIC',
  'Ayushman Bharat (PM-JAY)',
  'Aarogyasri',
  'CGHS',
];

/// Add or edit an insurance policy or health scheme.
class PolicyFormSheet extends StatefulWidget {
  final WalletRemoteDataSource dataSource;
  final PolicyEntry? existing;

  const PolicyFormSheet({super.key, required this.dataSource, this.existing});

  static Future<PolicyEntry?> show(BuildContext context, WalletRemoteDataSource dataSource, {PolicyEntry? existing}) {
    return showModalBottomSheet<PolicyEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PolicyFormSheet(dataSource: dataSource, existing: existing),
    );
  }

  @override
  State<PolicyFormSheet> createState() => _PolicyFormSheetState();
}

class _PolicyFormSheetState extends State<PolicyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _insurer;
  late final TextEditingController _name;
  late final TextEditingController _number;
  late final TextEditingController _member;
  late final TextEditingController _sum;
  late final TextEditingController _premium;
  late final TextEditingController _tpa;
  late final TextEditingController _helpline;
  late final TextEditingController _covered;
  late final TextEditingController _notes;
  late String _type;
  DateTime? _start;
  DateTime? _end;
  String? _filePath;
  bool _removeFile = false;
  bool _saving = false;
  String? _error;

  static String _plain(double? v) => v == null ? '' : (v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2));

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _insurer = TextEditingController(text: p?.insurer ?? '');
    _name = TextEditingController(text: p?.policyName ?? '');
    _number = TextEditingController(text: p?.policyNumber ?? '');
    _member = TextEditingController(text: p?.memberId ?? '');
    _sum = TextEditingController(text: _plain(p?.sumInsured));
    _premium = TextEditingController(text: _plain(p?.premium));
    _tpa = TextEditingController(text: p?.tpaName ?? '');
    _helpline = TextEditingController(text: p?.helplineNumber ?? '');
    _covered = TextEditingController(text: p?.coveredMembers ?? '');
    _notes = TextEditingController(text: p?.notes ?? '');
    _type = p?.policyType ?? 'Health';
    _start = p?.startDate;
    _end = p?.endDate;
  }

  @override
  void dispose() {
    for (final c in [_insurer, _name, _number, _member, _sum, _premium, _tpa, _helpline, _covered, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final initial = (start ? _start : _end) ?? (start ? now : DateTime(now.year + 1, now.month, now.day));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 40),
    );
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_start != null && _end != null && _end!.isBefore(_start!)) {
      setState(() => _error = 'Renewal date must be after the start date.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.dataSource.savePolicy(
        {
          'policyType': _type,
          'insurer': _insurer.text.trim(),
          'policyName': _name.text.trim(),
          'policyNumber': _number.text.trim(),
          'memberId': _member.text.trim(),
          'sumInsured': _sum.text.trim(),
          'premium': _premium.text.trim(),
          'startDate': _start == null ? '' : walletDateKey(_start!),
          'endDate': _end == null ? '' : walletDateKey(_end!),
          'tpaName': _tpa.text.trim(),
          'helplineNumber': _helpline.text.trim(),
          'coveredMembers': _covered.text.trim(),
          'notes': _notes.text.trim(),
          if (_removeFile && _filePath == null) 'removeFile': true,
        },
        id: widget.existing?.id,
        filePath: _filePath,
      );
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) setState(() => _error = walletErrorMessage(e, "Couldn't save the policy. Please try again."));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = WalletColors(isDark);
    final primary = Theme.of(context).primaryColor;
    final amount = [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,10}(\.\d{0,2})?'))];

    Widget field(String label, TextEditingController ctrl,
            {String? hint, bool optional = true, int max = 200, TextInputType? keyboard, List<TextInputFormatter>? formatters, String? Function(String?)? validator, Widget? prefix}) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WalletFieldLabel(label, optional: optional, isDark: isDark),
            TextFormField(
              controller: ctrl,
              maxLength: max,
              keyboardType: keyboard,
              inputFormatters: formatters,
              validator: validator,
              textCapitalization: keyboard == null ? TextCapitalization.words : TextCapitalization.none,
              decoration: walletInputDecoration(context, hint: hint, prefix: prefix)
                  .copyWith(counterText: '', prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0)),
            ),
          ],
        );
    final rupee = Padding(
      padding: const EdgeInsets.only(left: 14, right: 6),
      child: Text('₹', style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w600, color: c.muted)),
    );

    Widget dateBox(String label, DateTime? value, bool start) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WalletFieldLabel(label, optional: true, isDark: isDark),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _pickDate(start),
                child: InputDecorator(
                  decoration: walletInputDecoration(context,
                      suffix: value == null
                          ? PhosphorIcon(PhosphorIconsBold.calendarBlank, size: 17, color: c.muted)
                          : IconButton(
                              tooltip: 'Clear',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(() => start ? _start = null : _end = null),
                              icon: PhosphorIcon(PhosphorIconsBold.x, size: 15, color: c.muted),
                            )),
                  child: Text(value == null ? 'Pick date' : DateFormat('d MMM yyyy').format(value),
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, color: value == null ? c.muted : c.ink)),
                ),
              ),
            ],
          ),
        );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        child: WalletSheet(
          isDark: isDark,
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              children: [
                Text(widget.existing == null ? 'Add a policy' : 'Edit policy',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 18, fontWeight: FontWeight.w700, color: c.ink)),
                Text('Health insurance, life cover or a government scheme',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: c.muted)),
                WalletFieldLabel('Type', isDark: isDark),
                WalletChoiceChips(options: policyTypes, selected: _type, onSelected: (v) => setState(() => _type = v), accent: primary, isDark: isDark),
                field('Insurer or scheme', _insurer,
                    hint: 'e.g. Star Health', optional: false, validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the insurer' : null),
                if (widget.existing == null) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final s in _insurerSuggestions)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(s, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: c.ink)),
                              backgroundColor: c.card,
                              side: BorderSide(color: c.line),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              onPressed: () => setState(() {
                                _insurer.text = s;
                                if (s.contains('PM-JAY') || s == 'Aarogyasri' || s == 'CGHS') _type = 'Government scheme';
                                if (s == 'LIC') _type = 'Life';
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                field('Policy or card number', _number,
                    hint: 'As printed on the policy', optional: false, max: 100, keyboard: TextInputType.visiblePassword,
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the policy number' : null),
                field('Plan name', _name, hint: 'e.g. Family Health Optima'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: field('Sum insured', _sum, keyboard: const TextInputType.numberWithOptions(decimal: true), formatters: amount, prefix: rupee, hint: '5,00,000')),
                    const SizedBox(width: 10),
                    Expanded(child: field('Yearly premium', _premium, keyboard: const TextInputType.numberWithOptions(decimal: true), formatters: amount, prefix: rupee)),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [dateBox('Start date', _start, true), const SizedBox(width: 10), dateBox('Renewal date', _end, false)],
                ),
                field('Who is covered', _covered, hint: 'e.g. Self, spouse, 2 children', max: 500),
                field('Member ID', _member, hint: 'On the health card, if different', max: 100, keyboard: TextInputType.visiblePassword),
                field('TPA', _tpa, hint: 'e.g. Medi Assist'),
                field('Claims helpline', _helpline, keyboard: TextInputType.phone, max: 40, formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))]),
                WalletFieldLabel('Policy document or health card', optional: true, isDark: isDark),
                WalletAttachmentField(
                  localPath: _filePath,
                  existingName: _removeFile ? null : widget.existing?.fileName,
                  emptyLabel: 'Attach the policy or card',
                  onPick: () async {
                    final path = await pickWalletAttachment(context);
                    if (path != null && mounted) setState(() => _filePath = path);
                  },
                  onClear: () => setState(() {
                    _filePath = null;
                    _removeFile = true;
                  }),
                ),
                WalletFieldLabel('Notes', optional: true, isDark: isDark),
                TextFormField(
                  controller: _notes,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 1000,
                  decoration: walletInputDecoration(context, hint: 'Agent, waiting periods, anything to remember').copyWith(counterText: ''),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: WalletColors.danger)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : Text(widget.existing == null ? 'Save policy' : 'Save changes',
                            style: const TextStyle(fontFamily: appPoppinFont, fontSize: 14.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
