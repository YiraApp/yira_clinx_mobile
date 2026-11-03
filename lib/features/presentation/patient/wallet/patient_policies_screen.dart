import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/custom_dialogue/app_dialog.dart';
import '../../../../core/widgets/phosphor_icons.dart';
import '../../../data/data_sources/wallet/wallet_remote_data_source.dart';
import '../../../data/models/wallet/wallet_models.dart';
import 'policy_form_sheet.dart';
import 'wallet_attachment.dart';
import 'wallet_widgets.dart';

/// My policies: insurance and health schemes the patient adds, plus the
/// insurance Yira hospitals recorded when registering them.
class PatientPoliciesScreen extends StatefulWidget {
  final WalletRemoteDataSource? dataSource;

  const PatientPoliciesScreen({super.key, this.dataSource});

  @override
  State<PatientPoliciesScreen> createState() => _PatientPoliciesScreenState();
}

class _PatientPoliciesScreenState extends State<PatientPoliciesScreen> {
  late final WalletRemoteDataSource _source = widget.dataSource ?? WalletRemoteDataSource();
  List<PolicyEntry>? _policies;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _policies == null;
      _error = null;
    });
    try {
      final list = await _source.getPolicies();
      // Policies due for renewal first, then active, then expired.
      int rank(PolicyEntry p) => switch (p.state()) {
            PolicyState.renewSoon => 0,
            PolicyState.active => 1,
            PolicyState.noDate => 2,
            PolicyState.expired => 3,
          };
      list.sort((a, b) => rank(a).compareTo(rank(b)));
      if (mounted) setState(() => _policies = list);
    } catch (e) {
      if (mounted) setState(() => _error = walletErrorMessage(e, "Couldn't load your policies. Pull down to try again."));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  Future<void> _add() async {
    final saved = await PolicyFormSheet.show(context, _source);
    if (saved != null) {
      _toast('Policy added');
      _load();
    }
  }

  Future<void> _open(PolicyEntry p) async {
    final action = await PolicyDetailSheet.show(context, p);
    if (!mounted || action == null) return;
    if (action == 'edit') {
      final saved = await PolicyFormSheet.show(context, _source, existing: p);
      if (saved != null) {
        _toast('Policy updated');
        _load();
      }
    } else if (action == 'delete') {
      final ok = await AppDialog.confirm(
        context,
        title: 'Delete this policy?',
        message: '${p.insurer}, ${p.policyNumber}. This can\'t be undone.',
        confirmLabel: 'Delete',
        tone: AppDialogTone.danger,
        icon: Icons.delete_outline_rounded,
      );
      if (!ok || !mounted) return;
      try {
        await _source.deletePolicy(p.id);
        _toast('Policy deleted');
        _load();
      } catch (e) {
        _toast(walletErrorMessage(e, "Couldn't delete the policy."));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = WalletColors(isDark);
    final primary = Theme.of(context).primaryColor;
    final policies = _policies ?? const <PolicyEntry>[];
    final cover = policies.where((p) => p.state() != PolicyState.expired && p.sumInsured != null).fold<double>(0, (s, p) => s + p.sumInsured!);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF6F7F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text('My policies', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700, fontSize: 18, color: c.ink)),
        iconTheme: IconThemeData(color: c.ink),
      ),
      floatingActionButton: _policies == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _add,
              backgroundColor: primary,
              foregroundColor: Colors.white,
              icon: const PhosphorIcon(PhosphorIconsBold.plus, size: 18, color: Colors.white),
              label: const Text('Add policy', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700)),
            ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: primary,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                children: [
                  if (_error != null && _policies == null) ...[
                    const SizedBox(height: 80),
                    Center(child: WalletIconTile(icon: PhosphorIconsDuotone.cloudSlash, color: primary, isDark: isDark, size: 64)),
                    const SizedBox(height: 14),
                    Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, color: c.muted)),
                    const SizedBox(height: 12),
                    Center(child: OutlinedButton(onPressed: _load, child: const Text('Try again'))),
                  ] else if (policies.isEmpty) ...[
                    const SizedBox(height: 60),
                    Center(child: WalletIconTile(icon: PhosphorIconsDuotone.shieldCheck, color: primary, isDark: isDark, size: 72)),
                    const SizedBox(height: 16),
                    Text('Keep your policies handy',
                        textAlign: TextAlign.center, style: TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
                    const SizedBox(height: 6),
                    Text('Add your health insurance, life cover or a scheme like Ayushman Bharat, and see renewal dates at a glance.',
                        textAlign: TextAlign.center, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, height: 1.4, color: c.muted)),
                  ] else ...[
                    if (cover > 0) _coverBanner(c, cover, policies),
                    for (final p in policies) Padding(padding: const EdgeInsets.only(bottom: 12), child: PolicyCard(policy: p, onTap: () => _open(p))),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _coverBanner(WalletColors c, double cover, List<PolicyEntry> policies) {
    final soon = policies.where((p) => p.state() == PolicyState.renewSoon).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: c.isDark
              ? [Color.alphaBlend(Theme.of(context).primaryColor.withValues(alpha: 0.22), c.card), c.card]
              : [const Color(0xFFE8F0FF), Colors.white],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          WalletIconTile(icon: PhosphorIconsDuotone.shieldCheck, color: Theme.of(context).primaryColor, isDark: c.isDark, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total cover', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: c.muted)),
                Text(formatRupees(cover), style: TextStyle(fontFamily: appPoppinFont, fontSize: 20, fontWeight: FontWeight.w700, color: c.ink)),
              ],
            ),
          ),
          if (soon > 0) WalletPill(label: '$soon to renew', color: WalletColors.due, isDark: c.isDark),
        ],
      ),
    );
  }
}

String policyStateLabel(PolicyEntry p) {
  final left = p.daysLeft();
  return switch (p.state()) {
    PolicyState.expired => 'Expired',
    PolicyState.renewSoon => left == 0 ? 'Renew today' : 'Renew in $left ${left == 1 ? 'day' : 'days'}',
    PolicyState.active => 'Active',
    PolicyState.noDate => p.fromHospital ? 'On file' : 'Active',
  };
}

Color policyStateColor(PolicyEntry p) => switch (p.state()) {
      PolicyState.expired => WalletColors.danger,
      PolicyState.renewSoon => WalletColors.due,
      _ => WalletColors.paid,
    };

/// A policy shown like the card in your wallet.
class PolicyCard extends StatelessWidget {
  final PolicyEntry policy;
  final VoidCallback onTap;

  const PolicyCard({super.key, required this.policy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = WalletColors(isDark);
    final p = policy;
    final icon = policyTypeIcon(p.policyType);
    final color = Theme.of(context).primaryColor;
    final expired = p.state() == PolicyState.expired;

    Widget fact(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, color: c.muted)),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w700, color: c.ink)),
            ],
          ),
        );

    return Opacity(
      opacity: expired ? 0.7 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      WalletIconTile(icon: icon, color: color, isDark: isDark, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.insurer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
                            Text(p.policyName ?? p.policyType,
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: c.muted)),
                          ],
                        ),
                      ),
                      WalletPill(label: policyStateLabel(p), color: policyStateColor(p), isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(p.policyNumber,
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: c.ink)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      fact('Sum insured', p.sumInsured == null ? '—' : formatRupees(p.sumInsured!)),
                      fact(expired ? 'Expired on' : 'Renews on', p.endDate == null ? '—' : DateFormat('d MMM yyyy').format(p.endDate!)),
                      if (p.coveredMembers != null) fact('Covers', p.coveredMembers!),
                    ],
                  ),
                  if (p.fromHospital) ...[
                    const SizedBox(height: 10),
                    Text('Recorded by ${p.addedBy ?? 'your hospital'}',
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, fontWeight: FontWeight.w500, color: c.muted)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Every detail of a policy. Pops 'edit' or 'delete' for policies the patient added.
class PolicyDetailSheet extends StatelessWidget {
  final PolicyEntry policy;

  const PolicyDetailSheet({super.key, required this.policy});

  static Future<String?> show(BuildContext context, PolicyEntry policy) => showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PolicyDetailSheet(policy: policy),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = WalletColors(isDark);
    final p = policy;
    final primary = Theme.of(context).primaryColor;
    final fmt = DateFormat('d MMM yyyy');
    final rows = <(String, String)>[
      ('Type', p.policyType),
      if (p.policyName != null) ('Plan', p.policyName!),
      if (p.memberId != null) ('Member ID', p.memberId!),
      if (p.sumInsured != null) ('Sum insured', formatRupees(p.sumInsured!)),
      if (p.premium != null) ('Yearly premium', formatRupees(p.premium!)),
      if (p.startDate != null) ('Start date', fmt.format(p.startDate!)),
      if (p.endDate != null) ('Renewal date', fmt.format(p.endDate!)),
      if (p.coveredMembers != null) ('Covers', p.coveredMembers!),
      if (p.tpaName != null) ('TPA', p.tpaName!),
      if (p.notes != null) ('Notes', p.notes!),
      if (p.fromHospital) ('Recorded by', p.addedBy ?? 'Your hospital'),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      child: WalletSheet(
        isDark: isDark,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          children: [
            PolicyCard(policy: p, onTap: () {}),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
              child: Column(
                children: [
                  WalletDetailRow(
                    label: 'Policy number',
                    value: p.policyNumber,
                    isDark: isDark,
                    trailing: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: p.policyNumber));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Policy number copied'), behavior: SnackBarBehavior.floating));
                      },
                      child: Padding(padding: const EdgeInsets.all(2), child: PhosphorIcon(PhosphorIconsBold.copy, size: 16, color: primary)),
                    ),
                  ),
                  for (final (label, value) in rows) WalletDetailRow(label: label, value: value, isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (p.helplineNumber != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FilledButton.icon(
                  onPressed: () => launchUrl(Uri(scheme: 'tel', path: p.helplineNumber!.replaceAll(' ', ''))),
                  style: FilledButton.styleFrom(backgroundColor: primary, minimumSize: const Size.fromHeight(44)),
                  icon: const PhosphorIcon(PhosphorIconsBold.phoneCall, size: 16, color: Colors.white),
                  label: Text('Call claims helpline ${p.helplineNumber}'),
                ),
              ),
            if (p.fileUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton.icon(
                  onPressed: () => openWalletFile(context, p.fileUrl!),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                  icon: PhosphorIcon(PhosphorIconsBold.fileText, size: 16, color: primary),
                  label: Text(p.fileName ?? 'View policy document', overflow: TextOverflow.ellipsis),
                ),
              ),
            if (p.editable)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, 'edit'),
                      icon: const PhosphorIcon(PhosphorIconsBold.pencilSimple, size: 16),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Delete policy',
                    onPressed: () => Navigator.pop(context, 'delete'),
                    icon: const PhosphorIcon(PhosphorIconsBold.trash, size: 18, color: WalletColors.danger),
                  ),
                ],
              )
            else
              Text('Recorded by your hospital at registration. Add your own copy to keep more details.',
                  textAlign: TextAlign.center, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: c.muted)),
          ],
        ),
      ),
    );
  }
}
