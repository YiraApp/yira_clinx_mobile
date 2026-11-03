import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/custom_dialogue/app_dialog.dart';
import '../../../../core/widgets/phosphor_icons.dart';
import '../../../data/data_sources/wallet/wallet_remote_data_source.dart';
import '../../../data/models/wallet/wallet_models.dart';
import 'bill_form_sheet.dart';
import 'spending_donut.dart';
import 'wallet_attachment.dart';
import 'wallet_widgets.dart';

enum _BillFilter { all, hospital, mine, due }

/// My billing: every bill from Yira hospitals, synced each time the screen
/// opens or is pulled down, plus bills the patient adds themselves.
class PatientBillingScreen extends StatefulWidget {
  final WalletRemoteDataSource? dataSource;

  const PatientBillingScreen({super.key, this.dataSource});

  @override
  State<PatientBillingScreen> createState() => _PatientBillingScreenState();
}

class _PatientBillingScreenState extends State<PatientBillingScreen> {
  late final WalletRemoteDataSource _source = widget.dataSource ?? WalletRemoteDataSource();
  BillingData? _data;
  String? _error;
  bool _loading = true;
  DateTime? _syncedAt;
  _BillFilter _filter = _BillFilter.all;
  bool _allTime = false;

  static const _portrait = [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown];

  @override
  void initState() {
    super.initState();
    // This screen may turn sideways to show spending as a chart; the rest of the app stays upright.
    SystemChrome.setPreferredOrientations([..._portrait, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _load();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(_portrait);
    super.dispose();
  }

  /// Billed amount per type for the chosen period.
  Map<String, double> _spendByCategory() {
    final year = DateTime.now().year;
    final out = <String, double>{};
    for (final b in _data?.bills ?? const <BillEntry>[]) {
      if (!_allTime && b.date?.year != year) continue;
      out[b.category] = (out[b.category] ?? 0) + b.total;
    }
    return out;
  }

  Future<void> _load() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final data = await _source.getBilling();
      if (!mounted) return;
      setState(() {
        _data = data;
        _syncedAt = DateTime.now();
      });
    } catch (e) {
      if (mounted) setState(() => _error = walletErrorMessage(e, "Couldn't load your bills. Pull down to try again."));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final saved = await BillFormSheet.show(context, _source);
    if (saved != null) {
      _toast('Bill added');
      _load();
    }
  }

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  List<BillEntry> get _visible {
    final bills = _data?.bills ?? const <BillEntry>[];
    return switch (_filter) {
      _BillFilter.all => bills,
      _BillFilter.hospital => bills.where((b) => b.source != BillSource.manual).toList(),
      _BillFilter.mine => bills.where((b) => b.source == BillSource.manual).toList(),
      _BillFilter.due => bills.where((b) => !b.isPaid).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = WalletColors(isDark);
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F7F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'My billing',
          style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700, fontSize: 18, color: c.ink),
        ),
        iconTheme: IconThemeData(color: c.ink),
      ),
      floatingActionButton: _data == null || MediaQuery.of(context).orientation == Orientation.landscape
          ? null
          : FloatingActionButton.extended(
              onPressed: _add,
              backgroundColor: primary,
              foregroundColor: Colors.white,
              icon: const PhosphorIcon(PhosphorIconsBold.plus, size: 18, color: Colors.white),
              label: const Text(
                'Add bill',
                style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700),
              ),
            ),
      body: MediaQuery.of(context).orientation == Orientation.landscape && _data != null
          ? _landscape(c, primary)
          : RefreshIndicator(
              onRefresh: _load,
              color: primary,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _data == null
                  ? _message(c, PhosphorIconsDuotone.cloudSlash, _error ?? '', retry: true)
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      children: [
                        _summaryCard(context, c, _data!.summary),
                        const SizedBox(height: 14),
                        _filters(c, primary),
                        const SizedBox(height: 6),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _error!,
                              style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: WalletColors.danger),
                            ),
                          ),
                        if (_visible.isEmpty) _emptyList(c) else ..._groupedList(c),
                      ],
                    ),
            ),
    );
  }

  Widget _summaryCard(BuildContext context, WalletColors c, BillingSummary s) {
    final primary = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: c.isDark ? [Color.alphaBlend(primary.withValues(alpha: 0.22), c.card), c.card] : [const Color(0xFFE8F0FF), Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spent in ${DateTime.now().year}',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w500, color: c.muted),
                ),
              ),
              if (_syncedAt != null)
                Row(
                  children: [
                    PhosphorIcon(PhosphorIconsBold.arrowsClockwise, size: 12, color: c.muted),
                    const SizedBox(width: 4),
                    Text(
                      'Synced ${DateFormat('h:mm a').format(_syncedAt!)}',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: c.muted),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            formatRupees(s.thisYear),
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 26, fontWeight: FontWeight.w700, color: c.ink, letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _figure(c, 'Paid', formatRupees(s.totalPaid), WalletColors.paid),
              const SizedBox(width: 10),
              _figure(c, 'Due', formatRupees(s.totalDue), s.totalDue > 0 ? WalletColors.due : c.muted),
              const SizedBox(width: 10),
              _figure(c, 'Bills', '${s.count}', c.ink),
            ],
          ),
          if (s.count > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                PhosphorIcon(PhosphorIconsBold.deviceRotate, size: 14, color: c.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Turn your phone sideways to see spending by type',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: c.muted),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Sideways: spending by type as a ring chart, for this year or all time.
  Widget _landscape(WalletColors c, Color primary) {
    final byCategory = _spendByCategory();
    final year = DateTime.now().year;
    final bills = (_data?.bills ?? const <BillEntry>[]).where((b) => _allTime || b.date?.year == year);
    final paid = bills.fold<double>(0, (s, b) => s + b.paid);
    final due = bills.fold<double>(0, (s, b) => s + b.due);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.line),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Spending by type',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700, color: c.ink),
                  ),
                  const Spacer(),
                  Text(
                    'Paid ${formatRupees(paid)}',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: c.muted),
                  ),
                  if (due > 0) ...[
                    const SizedBox(width: 10),
                    Text(
                      'Due ${formatRupees(due)}',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: WalletColors.due),
                    ),
                  ],
                  const SizedBox(width: 14),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: false, label: Text('$year')),
                      const ButtonSegment(value: true, label: Text('All time')),
                    ],
                    selected: {_allTime},
                    showSelectedIcon: false,
                    onSelectionChanged: (v) => setState(() => _allTime = v.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected) ? primary.withValues(alpha: c.isDark ? 0.25 : 0.1) : Colors.transparent,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? primary : c.ink),
                      side: WidgetStatePropertyAll(BorderSide(color: c.line)),
                      textStyle: WidgetStatePropertyAll(
                        const TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SpendingDonut(byCategory: byCategory, centerLabel: _allTime ? 'All time' : 'Spent in $year', isDark: c.isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _figure(WalletColors c, String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.card.withValues(alpha: c.isDark ? 0.6 : 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: c.muted),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 14.5, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _filters(WalletColors c, Color primary) {
    const labels = {
      _BillFilter.all: 'All',
      _BillFilter.hospital: 'From hospitals',
      _BillFilter.mine: 'Added by me',
      _BillFilter.due: 'Due',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in _BillFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(labels[f]!),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
                showCheckmark: false,
                labelStyle: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12.5,
                  fontWeight: _filter == f ? FontWeight.w600 : FontWeight.w500,
                  color: _filter == f ? primary : c.ink,
                ),
                selectedColor: primary.withValues(alpha: c.isDark ? 0.25 : 0.1),
                backgroundColor: c.card,
                side: BorderSide(color: _filter == f ? primary : c.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _groupedList(WalletColors c) {
    final out = <Widget>[];
    String? month;
    for (final b in _visible) {
      final m = b.date == null ? 'Undated' : DateFormat('MMMM yyyy').format(b.date!);
      if (m != month) {
        month = m;
        out.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
            child: Text(
              m.toUpperCase(),
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: c.muted),
            ),
          ),
        );
      }
      out.add(Padding(padding: const EdgeInsets.only(bottom: 8), child: _billTile(c, b)));
    }
    return out;
  }

  Widget _billTile(WalletColors c, BillEntry b) {
    final icon = billCategoryIcon(b.category);
    final color = Theme.of(context).primaryColor;
    final statusColor = b.isPaid ? WalletColors.paid : WalletColors.due;
    final sub = [if (b.provider != null) b.provider!, if (b.date != null) DateFormat('d MMM').format(b.date!)].join(' · ');
    return Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openBill(b),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              WalletIconTile(icon: icon, color: color, isDark: c.isDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                    ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: c.muted),
                      ),
                    const SizedBox(height: 3),
                    Text(
                      b.source == BillSource.manual ? 'Added by you' : 'From hospital',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: c.muted.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRupees(b.total),
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 14.5, fontWeight: FontWeight.w700, color: c.ink),
                  ),
                  const SizedBox(height: 4),
                  WalletPill(
                    label: b.isPaid ? 'Paid' : (b.paid > 0 ? '${formatRupees(b.due)} due' : 'Due'),
                    color: statusColor,
                    isDark: c.isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openBill(BillEntry b) async {
    final action = await BillDetailSheet.show(context, b);
    if (!mounted || action == null) return;
    if (action == 'edit') {
      final saved = await BillFormSheet.show(context, _source, existing: b);
      if (saved != null) {
        _toast('Bill updated');
        _load();
      }
    } else if (action == 'delete') {
      final ok = await AppDialog.confirm(
        context,
        title: 'Delete this bill?',
        message: '${b.title}, ${formatRupees(b.total)}. This can\'t be undone.',
        confirmLabel: 'Delete',
        tone: AppDialogTone.danger,
        icon: Icons.delete_outline_rounded,
      );
      if (!ok || !mounted) return;
      try {
        await _source.deleteBill(b.id);
        _toast('Bill deleted');
        _load();
      } catch (e) {
        _toast(walletErrorMessage(e, "Couldn't delete the bill."));
      }
    }
  }

  Widget _emptyList(WalletColors c) {
    final text = switch (_filter) {
      _BillFilter.due => 'Nothing due. All your bills are paid.',
      _BillFilter.mine => 'Bills you add, like pharmacy or lab bills, show here.',
      _BillFilter.hospital => 'Bills from Yira hospitals show here after your visits.',
      _BillFilter.all => 'No bills yet. Bills from your Yira visits appear here on their own, and you can add any other bill.',
    };
    return Padding(padding: const EdgeInsets.only(top: 40), child: _message(c, PhosphorIconsDuotone.receipt, text));
  }

  Widget _message(WalletColors c, IconData icon, String text, {bool retry = false}) {
    final primary = Theme.of(context).primaryColor;
    return ListView(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        if (retry) SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: WalletIconTile(icon: icon, color: primary, isDark: c.isDark, size: 64),
        ),
        const SizedBox(height: 14),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, height: 1.4, color: c.muted),
        ),
        if (retry) ...[
          const SizedBox(height: 14),
          Center(
            child: OutlinedButton(onPressed: _load, child: const Text('Try again')),
          ),
        ],
      ],
    );
  }
}

/// A bill's full details. Pops 'edit' or 'delete' for bills the patient added.
class BillDetailSheet extends StatelessWidget {
  final BillEntry bill;

  const BillDetailSheet({super.key, required this.bill});

  static Future<String?> show(BuildContext context, BillEntry bill) => showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BillDetailSheet(bill: bill),
  );

  String _shareText() {
    final b = bill;
    return [
      b.title,
      if (b.provider != null) b.provider!,
      if (b.date != null) DateFormat('d MMM yyyy').format(b.date!),
      if (b.billNumber != null) 'Bill no. ${b.billNumber}',
      for (final i in b.items) '${i.name}: ${formatRupees(i.total)}',
      'Total: ${formatRupees(b.total)}',
      'Paid: ${formatRupees(b.paid)}${b.paymentMode != null ? ' (${b.paymentMode})' : ''}',
      if (b.due > 0) 'Due: ${formatRupees(b.due)}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = WalletColors(isDark);
    final b = bill;
    final icon = billCategoryIcon(b.category);
    final color = Theme.of(context).primaryColor;
    final statusColor = b.isPaid ? WalletColors.paid : WalletColors.due;

    Widget money(String label, double v, {bool bold = false, Color? colour}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                color: bold ? c.ink : c.muted,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            formatRupees(v),
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: colour ?? c.ink,
            ),
          ),
        ],
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: WalletSheet(
        isDark: isDark,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          children: [
            Row(
              children: [
                WalletIconTile(icon: icon, color: color, isDark: isDark, size: 46),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.title,
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 16.5, fontWeight: FontWeight.w700, color: c.ink),
                      ),
                      Text(
                        b.source == BillSource.manual ? 'Added by you' : 'From ${b.provider ?? 'hospital'}',
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: c.muted),
                        ),
                        Text(
                          formatRupees(b.total),
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 24, fontWeight: FontWeight.w700, color: c.ink),
                        ),
                      ],
                    ),
                  ),
                  WalletPill(label: b.isPaid ? 'Paid' : (b.paid > 0 ? 'Partly paid' : 'Due'), color: statusColor, isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.line),
              ),
              child: Column(
                children: [
                  if (b.provider != null) WalletDetailRow(label: 'Billed by', value: b.provider!, isDark: isDark),
                  if (b.doctor != null) WalletDetailRow(label: 'Doctor', value: b.doctor!, isDark: isDark),
                  if (b.date != null) WalletDetailRow(label: 'Date', value: DateFormat('d MMM yyyy').format(b.date!), isDark: isDark),
                  WalletDetailRow(label: 'Type', value: b.category, isDark: isDark),
                  if (b.billNumber != null) WalletDetailRow(label: 'Bill number', value: b.billNumber!, isDark: isDark),
                  if (b.paymentMode != null) WalletDetailRow(label: 'Paid by', value: b.paymentMode!, isDark: isDark),
                  if (b.notes != null) WalletDetailRow(label: 'Notes', value: b.notes!, isDark: isDark),
                ],
              ),
            ),
            if (b.items.isNotEmpty || b.discount > 0 || b.tax > 0 || b.due > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.line),
                ),
                child: Column(
                  children: [
                    for (final i in b.items) money(i.quantity > 1 ? '${i.name} × ${i.quantity.toStringAsFixed(0)}' : i.name, i.total),
                    if (b.discount > 0) money('Discount', -b.discount, colour: WalletColors.paid),
                    if (b.tax > 0) money('GST', b.tax),
                    if (b.items.isNotEmpty || b.discount > 0 || b.tax > 0) Divider(color: c.line, height: 16),
                    money('Total', b.total, bold: true),
                    money('Paid', b.paid, colour: WalletColors.paid),
                    if (b.due > 0) money('Due', b.due, bold: true, colour: WalletColors.due),
                  ],
                ),
              ),
            ],
            if (b.fileUrl != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => openWalletFile(context, b.fileUrl!),
                icon: PhosphorIcon(PhosphorIconsBold.fileText, size: 16, color: Theme.of(context).primaryColor),
                label: Text(b.fileName ?? 'View attached bill', overflow: TextOverflow.ellipsis),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => SharePlus.instance.share(ShareParams(text: _shareText(), subject: b.title)),
                    icon: const PhosphorIcon(PhosphorIconsBold.shareNetwork, size: 16),
                    label: const Text('Share'),
                  ),
                ),
                if (b.editable) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, 'edit'),
                      icon: const PhosphorIcon(PhosphorIconsBold.pencilSimple, size: 16),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Delete bill',
                    onPressed: () => Navigator.pop(context, 'delete'),
                    icon: const PhosphorIcon(PhosphorIconsBold.trash, size: 18, color: WalletColors.danger),
                  ),
                ],
              ],
            ),
            if (!b.editable)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Bills from hospitals update on their own. Contact the hospital to correct one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: c.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
