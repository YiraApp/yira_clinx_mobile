import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/widgets/phosphor_icons.dart';

import 'family_link_api.dart';

/// Colours the My Family screen uses, light and dark.
class FamilyPalette {
  final bool isDark;
  const FamilyPalette(this.isDark);

  factory FamilyPalette.of(BuildContext context) => FamilyPalette(Theme.of(context).brightness == Brightness.dark);

  static const Color blue = Color(0xFF2563EB);
  Color get card => isDark ? const Color(0xFF232323) : Colors.white;
  Color get border => isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE6EAF0);
  Color get text => isDark ? Colors.white : const Color(0xFF121212);
  Color get muted => isDark ? Colors.white60 : const Color(0xFF64748B);
  Color get field => isDark ? const Color(0xFF121212).withValues(alpha: 0.6) : const Color(0xFFF8FAFC);
  Color get fieldBorder => isDark ? Colors.white12 : const Color(0xFFE2E8F0);
  Color get blueSoft => blue.withValues(alpha: isDark ? 0.2 : 0.1);
}

/// "9:05" for a duration.
String formatFamilyCountdown(Duration d) {
  final seconds = d.isNegative ? 0 : d.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// The user's own family code: four digits, a live countdown, and copy,
/// share and new-code actions. A new code is fetched when this one runs out.
class FamilyCodeCard extends StatefulWidget {
  final FamilyLinkApi api;

  /// The user's number, named in the shared message so family can link quickly.
  final String? phoneNumber;

  /// Overridable for tests.
  final DateTime Function() clock;
  final Future<void> Function(String text)? onShare;

  const FamilyCodeCard({super.key, required this.api, this.phoneNumber, this.clock = DateTime.now, this.onShare});

  @override
  State<FamilyCodeCard> createState() => _FamilyCodeCardState();
}

class _FamilyCodeCardState extends State<FamilyCodeCard> {
  FamilyCodeInfo? _info;
  DateTime? _receivedAt;
  String? _error;
  bool _loading = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration get _remaining {
    final info = _info;
    final at = _receivedAt;
    if (info == null || at == null) return Duration.zero;
    final left = Duration(seconds: info.secondsLeft) - widget.clock().difference(at);
    return left.isNegative ? Duration.zero : left;
  }

  void _tick() {
    if (!mounted) return;
    if (_info != null && _remaining == Duration.zero && !_loading && _error == null) {
      _load();
      return;
    }
    setState(() {});
  }

  Future<void> _load({bool fresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = fresh ? await widget.api.refreshCode() : await widget.api.getCode();
      if (!mounted) return;
      setState(() {
        _info = info;
        _receivedAt = widget.clock();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = familyLinkError(e, 'Could not load your family code.').message;
      });
    }
  }

  String _shareText(String code) {
    final minutes = (_remaining.inSeconds / 60).ceil().clamp(1, 10);
    final phone = (widget.phoneNumber ?? '').trim();
    final number = phone.isNotEmpty ? ' with my number $phone' : '';
    return 'My Yira family code is $code. It works for the next $minutes minute${minutes == 1 ? '' : 's'}. '
        'In Yira, open My Family, tap "Link an existing Yira user" and link me$number and this code.';
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('Family code copied'), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)),
    );
  }

  Future<void> _share(String code) async {
    final text = _shareText(code);
    if (widget.onShare != null) {
      await widget.onShare!(text);
      return;
    }
    await SharePlus.instance.share(ShareParams(text: text, subject: 'My Yira family code'));
  }

  @override
  Widget build(BuildContext context) {
    final p = FamilyPalette.of(context);
    final info = _info;
    final remaining = _remaining;
    final expired = info != null && remaining == Duration.zero;
    final code = info?.code ?? '';
    final canUse = info != null && !expired && !_loading && code.length == 4;

    return Container(
      key: const Key('familyCode.card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: p.blueSoft, borderRadius: BorderRadius.circular(12)),
                child: const PhosphorIcon(PhosphorIconsBold.shieldCheck, size: 20, color: FamilyPalette.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your family code',
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 14.5, fontWeight: FontWeight.w700, color: p.text)),
                    const SizedBox(height: 2),
                    Text(
                      'Share it only with family. With your number and this code they can link to you at once.',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, height: 1.35, color: p.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_error != null && info == null)
            _ErrorRow(message: _error!, onRetry: () => _load(), palette: p)
          else ...[
            Semantics(
              label: canUse ? 'Family code ${code.split('').join(' ')}' : 'Family code loading',
              excludeSemantics: true,
              child: Row(
                key: const Key('familyCode.digits'),
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: _DigitBox(digit: canUse ? code[i] : '', palette: p, faded: !canUse)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                PhosphorIcon(PhosphorIconsBold.clock, size: 14, color: p.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _loading
                        ? 'Getting your code…'
                        : expired
                            ? 'Getting a new code…'
                            : 'Valid for ${formatFamilyCountdown(remaining)}',
                    key: const Key('familyCode.countdown'),
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: p.muted, fontWeight: FontWeight.w500),
                  ),
                ),
                _ActionIcon(
                  key: const Key('familyCode.copy'),
                  icon: PhosphorIconsBold.copy,
                  tooltip: 'Copy code',
                  onTap: canUse ? () => _copy(code) : null,
                  palette: p,
                ),
                const SizedBox(width: 6),
                _ActionIcon(
                  key: const Key('familyCode.share'),
                  icon: PhosphorIconsBold.shareNetwork,
                  tooltip: 'Share code',
                  onTap: canUse ? () => _share(code) : null,
                  palette: p,
                ),
                const SizedBox(width: 6),
                _ActionIcon(
                  key: const Key('familyCode.refresh'),
                  icon: PhosphorIconsBold.arrowsClockwise,
                  tooltip: 'New code',
                  onTap: _loading ? null : () => _load(fresh: true),
                  palette: p,
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: Colors.redAccent)),
            ],
          ],
        ],
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  final String digit;
  final FamilyPalette palette;
  final bool faded;

  const _DigitBox({required this.digit, required this.palette, required this.faded});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: faded ? palette.fieldBorder : FamilyPalette.blue.withValues(alpha: 0.35)),
      ),
      child: Text(
        digit.isEmpty ? '•' : digit,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: digit.isEmpty ? palette.muted : palette.text,
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final FamilyPalette palette;

  const _ActionIcon({super.key, required this.icon, required this.tooltip, required this.onTap, required this.palette});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: palette.fieldBorder),
            ),
            child: PhosphorIcon(icon, size: 17, color: enabled ? FamilyPalette.blue : palette.muted.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final FamilyPalette palette;

  const _ErrorRow({required this.message, required this.onRetry, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PhosphorIcon(PhosphorIconsBold.warningCircle, size: 16, color: Colors.redAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: palette.text)),
        ),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(foregroundColor: FamilyPalette.blue),
          child: const Text('Try again', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
