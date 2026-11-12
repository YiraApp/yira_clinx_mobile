import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/widgets/phosphor_icons.dart';

import 'family_code_card.dart';
import 'family_link_api.dart';
import 'link_family_member_sheet.dart';

/// The family-link part of My Family: open requests (to accept or decline, or cancel), plus the
/// family code popup and the link sheet that the screen's "Add member" button opens.
class FamilyLinksSection extends StatefulWidget {
  final FamilyLinkApi api;
  final String? phoneNumber;

  /// False when the family is full; linking is then turned off.
  final bool canAddMore;

  /// Called after someone joined the family, so the list can reload.
  final Future<void> Function() onFamilyChanged;

  /// Change it to reload the requests (pull to refresh).
  final int reloadToken;

  const FamilyLinksSection({
    super.key,
    required this.api,
    required this.onFamilyChanged,
    this.phoneNumber,
    this.canAddMore = true,
    this.reloadToken = 0,
  });

  @override
  State<FamilyLinksSection> createState() => FamilyLinksSectionState();
}

/// Public so My Family's one "Add member" button can open the code popup and the link sheet.
class FamilyLinksSectionState extends State<FamilyLinksSection> {
  FamilyLinkRequests _requests = const FamilyLinkRequests();
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void didUpdateWidget(covariant FamilyLinksSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final requests = await widget.api.getRequests();
      if (mounted) setState(() => _requests = requests);
    } catch (_) {
      // Requests are optional here; the code card shows connection problems.
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFD97706) : FamilyPalette.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// The user's own family code in a popup, with its countdown, copy, share and new-code buttons.
  Future<void> openCode() {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FamilyCodeCard(api: widget.api, phoneNumber: widget.phoneNumber),
              const SizedBox(height: 14),
              Material(
                color: FamilyPalette.of(dialogContext).card,
                shape: CircleBorder(side: BorderSide(color: FamilyPalette.of(dialogContext).border)),
                child: IconButton(
                  key: const Key('familyCode.close'),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: Icon(Icons.close_rounded, color: FamilyPalette.of(dialogContext).text, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> openLinkSheet() async {
    final outcome = await LinkFamilyMemberSheet.show(context, api: widget.api);
    if (outcome == null || !mounted) return;
    _snack(outcome.message);
    await _loadRequests();
    if (outcome.linked) await widget.onFamilyChanged();
  }

  Future<void> _act(FamilyLinkRequest r, Future<void> Function() run, String done, {bool joined = false}) async {
    setState(() => _busy.add(r.id));
    try {
      await run();
      if (!mounted) return;
      _snack(done);
      await _loadRequests();
      if (joined) await widget.onFamilyChanged();
    } catch (e) {
      if (mounted) _snack(familyLinkError(e).message, error: true);
      await _loadRequests();
    } finally {
      if (mounted) setState(() => _busy.remove(r.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = FamilyPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_requests.incoming.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel('REQUESTS FOR YOU', p),
          for (final r in _requests.incoming) ...[
            _RequestCard(
              request: r,
              palette: p,
              busy: _busy.contains(r.id),
              title: r.name,
              subtitle: 'Wants to add you as their ${r.relation.toLowerCase()}'
                  '${r.suggestedRelation.isNotEmpty ? '. They will show as your ${r.suggestedRelation.toLowerCase()}.' : '.'}',
              actions: [
                TextButton(
                  onPressed: () => _act(r, () => widget.api.declineRequest(r.id), 'Request declined'),
                  style: TextButton.styleFrom(foregroundColor: p.muted),
                  child: const Text('Decline', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: () => _act(r, () => widget.api.acceptRequest(r.id), '${r.name} is now in your family', joined: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: FamilyPalette.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Accept', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
        if (_requests.outgoing.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel('WAITING FOR THEM', p),
          for (final r in _requests.outgoing) ...[
            _RequestCard(
              request: r,
              palette: p,
              busy: _busy.contains(r.id),
              title: r.name,
              subtitle: [
                if (r.relation.isNotEmpty) r.relation,
                if (r.phoneHint.isNotEmpty) r.phoneHint,
                _expiryLabel(r.expiresAt),
              ].where((s) => s.isNotEmpty).join(' · '),
              actions: [
                TextButton(
                  onPressed: () => _act(r, () => widget.api.cancelRequest(r.id), 'Request cancelled'),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('Cancel request', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  static String _expiryLabel(DateTime? expiresAt) {
    if (expiresAt == null) return '';
    final left = expiresAt.difference(DateTime.now());
    if (left.inDays >= 1) return 'Expires in ${left.inDays} day${left.inDays == 1 ? '' : 's'}';
    if (left.inHours >= 1) return 'Expires in ${left.inHours} hour${left.inHours == 1 ? '' : 's'}';
    return 'Expires soon';
  }

  Widget _sectionLabel(String text, FamilyPalette p) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Text(text,
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: p.muted)),
      );
}

class _RequestCard extends StatelessWidget {
  final FamilyLinkRequest request;
  final FamilyPalette palette;
  final bool busy;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const _RequestCard({
    required this.request,
    required this.palette,
    required this.busy,
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: request.incoming ? FamilyPalette.blue.withValues(alpha: 0.35) : p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.blueSoft, borderRadius: BorderRadius.circular(10)),
                child: PhosphorIcon(request.incoming ? PhosphorIconsBold.userPlus : PhosphorIconsBold.clock, size: 17, color: FamilyPalette.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w700, color: p.text)),
                    if (subtitle.isNotEmpty)
                      Text(subtitle, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, height: 1.35, color: p.muted)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: busy
                ? const [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: FamilyPalette.blue)),
                    ),
                  ]
                : actions,
          ),
        ],
      ),
    );
  }
}
