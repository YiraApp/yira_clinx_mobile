import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/phosphor_icons.dart';
import '../../../data/data_sources/wallet/wallet_remote_data_source.dart';
import '../../../data/models/wallet/wallet_models.dart';
import 'wallet_attachment.dart';
import 'wallet_widgets.dart';

/// Add or edit a bill the patient keeps for themselves. Resolves to the saved
/// bill, or null when closed.
class BillFormSheet extends StatefulWidget {
  final WalletRemoteDataSource dataSource;
  final BillEntry? existing;

  const BillFormSheet({super.key, required this.dataSource, this.existing});

  static Future<BillEntry?> show(BuildContext context, WalletRemoteDataSource dataSource, {BillEntry? existing}) {
    return showModalBottomSheet<BillEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BillFormSheet(dataSource: dataSource, existing: existing),
    );
  }

  @override
  State<BillFormSheet> createState() => _BillFormSheetState();
}

class _BillFormSheetState extends State<BillFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _provider;
  late final TextEditingController _amount;
  late final TextEditingController _paid;
  late final TextEditingController _billNumber;
  late final TextEditingController _notes;
  late String _category;
  String? _mode;
  late DateTime _date;
  late bool _fullyPaid;
  String? _filePath;
  bool _removeFile = false;
  bool _saving = false;
  String? _error;

  static String _plain(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _title = TextEditingController(text: b?.title ?? '');
    _provider = TextEditingController(text: b?.provider ?? '');
    _amount = TextEditingController(text: b == null ? '' : _plain(b.total));
    _paid = TextEditingController(text: b == null ? '' : _plain(b.paid));
    _billNumber = TextEditingController(text: b?.billNumber ?? '');
    _notes = TextEditingController(text: b?.notes ?? '');
    _category = b?.category ?? 'Pharmacy';
    _mode = b?.paymentMode;
    _date = b?.date ?? DateTime.now();
    _fullyPaid = b == null || b.isPaid;
  }

  @override
  void dispose() {
    for (final c in [_title, _provider, _amount, _paid, _billNumber, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(now.year - 15), lastDate: now);
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _attach() async {
    final path = await pickWalletAttachment(context);
    if (path != null && mounted) setState(() => _filePath = path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final total = double.parse(_amount.text.trim());
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final saved = await widget.dataSource.saveBill(
        {
          'title': _title.text.trim().isEmpty ? '$_category bill' : _title.text.trim(),
          'providerName': _provider.text.trim(),
          'category': _category,
          'billDate': walletDateKey(_date),
          'totalAmount': total,
          'paidAmount': _fullyPaid ? total : (double.tryParse(_paid.text.trim()) ?? 0),
          'paymentMode': _mode ?? '',
          'billNumber': _billNumber.text.trim(),
          'notes': _notes.text.trim(),
          if (_removeFile && _filePath == null) 'removeFile': true,
        },
        id: widget.existing?.id,
        filePath: _filePath,
      );
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) setState(() => _error = walletErrorMessage(e, "Couldn't save the bill. Please try again."));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _amountError(String? v, {double? max}) {
    final n = double.tryParse((v ?? '').trim());
    if (n == null) return 'Enter an amount';
    if (n < 0) return "Amount can't be negative";
    if (max != null && n > max) return "Can't be more than the bill amount";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = WalletColors(isDark);
    final primary = Theme.of(context).primaryColor;
    final amountFormatter = [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,9}(\.\d{0,2})?'))];

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
                Text(widget.existing == null ? 'Add a bill' : 'Edit bill',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 18, fontWeight: FontWeight.w700, color: c.ink)),
                Text('Pharmacy, lab or any bill from outside Yira',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: c.muted)),
                WalletFieldLabel('Type', isDark: isDark),
                WalletChoiceChips(
                  options: billCategories,
                  selected: _category,
                  onSelected: (v) => setState(() => _category = v),
                  accent: primary,
                  isDark: isDark,
                ),
                WalletFieldLabel('Amount', isDark: isDark),
                TextFormField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: amountFormatter,
                  validator: (v) => _amountError(v),
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.w700, color: c.ink),
                  decoration: walletInputDecoration(context,
                      hint: '0',
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 6),
                        child: Text('₹', style: TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.w700, color: c.muted)),
                      )).copyWith(prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0)),
                ),
                const SizedBox(height: 4),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _fullyPaid,
                  activeTrackColor: primary,
                  onChanged: (v) => setState(() => _fullyPaid = v),
                  title: Text('Fully paid', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, fontWeight: FontWeight.w600, color: c.ink)),
                ),
                if (!_fullyPaid)
                  TextFormField(
                    controller: _paid,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: amountFormatter,
                    validator: (v) => _amountError(v, max: double.tryParse(_amount.text.trim())),
                    decoration: walletInputDecoration(context, hint: 'Amount paid so far'),
                  ),
                WalletFieldLabel('Bill date', isDark: isDark),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: walletInputDecoration(context, suffix: PhosphorIcon(PhosphorIconsBold.calendarBlank, size: 18, color: c.muted)),
                    child: Text(DateFormat('d MMM yyyy').format(_date),
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, color: c.ink)),
                  ),
                ),
                WalletFieldLabel('Hospital, pharmacy or lab', optional: true, isDark: isDark),
                TextFormField(
                  controller: _provider,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 200,
                  decoration: walletInputDecoration(context, hint: 'e.g. Apollo Pharmacy').copyWith(counterText: ''),
                ),
                WalletFieldLabel('Name', optional: true, isDark: isDark),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 150,
                  decoration: walletInputDecoration(context, hint: '$_category bill').copyWith(counterText: ''),
                ),
                WalletFieldLabel('Paid by', optional: true, isDark: isDark),
                WalletChoiceChips(
                  options: paymentModes,
                  selected: _mode,
                  onSelected: (v) => setState(() => _mode = _mode == v ? null : v),
                  accent: primary,
                  isDark: isDark,
                ),
                WalletFieldLabel('Bill number', optional: true, isDark: isDark),
                TextFormField(
                  controller: _billNumber,
                  maxLength: 80,
                  decoration: walletInputDecoration(context, hint: 'As printed on the bill').copyWith(counterText: ''),
                ),
                WalletFieldLabel('Photo or PDF of the bill', optional: true, isDark: isDark),
                WalletAttachmentField(
                  localPath: _filePath,
                  existingName: _removeFile ? null : widget.existing?.fileName,
                  emptyLabel: 'Attach the bill',
                  onPick: _attach,
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
                  decoration: walletInputDecoration(context, hint: 'Anything to remember, like an insurance claim').copyWith(counterText: ''),
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
                        : Text(widget.existing == null ? 'Save bill' : 'Save changes',
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
