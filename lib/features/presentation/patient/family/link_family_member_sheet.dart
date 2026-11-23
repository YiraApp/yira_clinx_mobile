import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/widgets/phosphor_icons.dart';

import 'family_code_card.dart';
import 'family_link_api.dart';

/// "Link an existing Yira user": find someone by their mobile number, then
/// link at once with their family code, or send them a request to accept.
/// Pops with a [FamilyLinkOutcome] when something changed.
class LinkFamilyMemberSheet extends StatefulWidget {
  final FamilyLinkApi api;

  const LinkFamilyMemberSheet({super.key, required this.api});

  static Future<FamilyLinkOutcome?> show(BuildContext context, {required FamilyLinkApi api}) {
    return showModalBottomSheet<FamilyLinkOutcome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LinkFamilyMemberSheet(api: api),
    );
  }

  @override
  State<LinkFamilyMemberSheet> createState() => _LinkFamilyMemberSheetState();
}

class _LinkFamilyMemberSheetState extends State<LinkFamilyMemberSheet> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  FamilyLookupResult? _result;
  String? _resultPhone;
  String? _relation;
  bool _withCode = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  bool get _canLink {
    final r = _result;
    return r != null && r.found && !r.alreadyLinked && !r.requestSent;
  }

  void _onPhoneChanged(String value) {
    // A different number needs a new lookup.
    if (_result != null && normalizeFamilyPhone(value) != _resultPhone) {
      setState(() {
        _result = null;
        _resultPhone = null;
        _error = null;
      });
    } else if (_error != null) {
      setState(() => _error = null);
    }
  }

  Future<void> _find() async {
    FocusScope.of(context).unfocus();
    final problem = validateFamilyPhone(_phoneCtrl.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    final phone = normalizeFamilyPhone(_phoneCtrl.text)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.api.lookup(phone);
      if (!mounted) return;
      setState(() {
        _result = result;
        _resultPhone = phone;
        _withCode = !result.requestReceived;
      });
    } catch (e) {
      if (mounted) setState(() => _error = familyLinkError(e, 'Could not look up this number.').message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// What is missing before linking, or null.
  String? _formProblem() {
    final phoneProblem = validateFamilyPhone(_phoneCtrl.text);
    if (phoneProblem != null) return phoneProblem;
    if (_relation == null) return 'Choose how they are related to you.';
    if (_withCode) return validateFamilyCode(_codeCtrl.text);
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final problem = _formProblem();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    final phone = normalizeFamilyPhone(_phoneCtrl.text)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = _withCode
          ? await widget.api.linkWithCode(phone: phone, code: _codeCtrl.text.trim(), relation: _relation!)
          : await widget.api.sendRequest(phone: phone, relation: _relation!);
      if (mounted) Navigator.of(context).pop(outcome);
    } catch (e) {
      if (!mounted) return;
      final error = familyLinkError(e, 'Could not link this person.');
      setState(() {
        _error = error.message;
        if (error.code == 'NOT_FOUND') _result = const FamilyLookupResult(found: false);
        if (error.code == 'ALREADY_LINKED') {
          _result = FamilyLookupResult(found: true, maskedName: _result?.maskedName ?? '', alreadyLinked: true);
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _fieldDecoration(FamilyPalette p, {required String hint, Widget? prefix}) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.fieldBorder));
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: p.isDark ? Colors.white38 : Colors.grey[400]),
      prefixIcon: prefix,
      counterText: '',
      filled: true,
      fillColor: p.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: const BorderSide(color: FamilyPalette.blue, width: 1.4)),
    );
  }

  Widget _label(String text, FamilyPalette p) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: p.text)),
      );

  @override
  Widget build(BuildContext context) {
    final p = FamilyPalette.of(context);
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
        decoration: BoxDecoration(color: p.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 14, 12),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: p.isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: p.blueSoft, borderRadius: BorderRadius.circular(12)),
                          child: const PhosphorIcon(PhosphorIconsBold.link, color: FamilyPalette.blue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Link an existing Yira user',
                                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.bold, color: p.text)),
                              Text('For family who use Yira with their own number',
                                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: p.muted)),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          icon: PhosphorIcon(PhosphorIconsBold.x, size: 18, color: p.muted),
                          onPressed: () => Navigator.of(context).maybePop(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Before a match the error is about the number, so it sits at the top; after a
                      // match it is about linking, so it shows next to the button (see below).
                      if (_error != null && !_canLink) ...[
                        _ErrorBanner(message: _error!),
                        const SizedBox(height: 14),
                      ],
                      _label('Their mobile number', p),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('familyLink.phone'),
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.search,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                              onChanged: _onPhoneChanged,
                              onSubmitted: (_) => _busy ? null : _find(),
                              style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, color: p.text, letterSpacing: 0.4),
                              decoration: _fieldDecoration(
                                p,
                                hint: '10-digit mobile number',
                                prefix: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: PhosphorIcon(PhosphorIconsBold.phone, size: 16, color: p.muted),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              key: const Key('familyLink.find'),
                              onPressed: _busy ? null : _find,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: FamilyPalette.blue,
                                side: const BorderSide(color: FamilyPalette.blue),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Find', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'We only show part of their name, to make sure you have the right person.',
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: p.muted),
                      ),
                      if (_result != null) ...[
                        const SizedBox(height: 14),
                        _ResultCard(result: _result!, palette: p),
                      ],
                      if (_canLink) ..._linkForm(p),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _linkForm(FamilyPalette p) {
    final received = _result?.requestReceived == true;
    return [
      const SizedBox(height: 18),
      _label('How are they related to you?', p),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final rel in familyLinkRelations)
            ChoiceChip(
              label: Text(rel),
              selected: _relation == rel,
              onSelected: (on) => setState(() {
                _relation = on ? rel : null;
                _error = null;
              }),
              labelStyle: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11.5,
                fontWeight: _relation == rel ? FontWeight.bold : FontWeight.w500,
                color: _relation == rel ? Colors.white : (p.isDark ? Colors.white70 : const Color(0xFF4A4A4A)),
              ),
              // Set through `color` so the theme's selected tint can't replace the blue.
              color: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? FamilyPalette.blue
                    : (p.isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9)),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: _relation == rel ? FamilyPalette.blue : p.fieldBorder),
              ),
              showCheckmark: false,
            ),
        ],
      ),
      const SizedBox(height: 18),
      _label('How do you want to link?', p),
      _MethodTile(
        key: const Key('familyLink.method.code'),
        selected: _withCode,
        icon: PhosphorIconsBold.shieldCheck,
        title: 'I have their family code',
        subtitle: 'Linked at once. The code is in their My Family screen and changes every 10 minutes.',
        palette: p,
        onTap: () => setState(() {
          _withCode = true;
          _error = null;
        }),
      ),
      const SizedBox(height: 8),
      _MethodTile(
        key: const Key('familyLink.method.request'),
        selected: !_withCode,
        icon: PhosphorIconsBold.bellRinging,
        title: received ? 'Accept their request' : 'Send them a request',
        subtitle: received
            ? 'They already asked to link with you. Linking now accepts it.'
            : 'They get a notification and can accept in My Family. Requests expire after 7 days.',
        palette: p,
        onTap: () => setState(() {
          _withCode = false;
          _error = null;
        }),
      ),
      if (_withCode) ...[
        const SizedBox(height: 14),
        _label('Their 4-digit family code', p),
        TextField(
          key: const Key('familyLink.code'),
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
          onChanged: (_) => _error == null ? null : setState(() => _error = null),
          style: TextStyle(fontFamily: appPoppinFont, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 10, color: p.text),
          decoration: _fieldDecoration(p, hint: '• • • •'),
        ),
      ],
      if (_error != null) ...[
        const SizedBox(height: 14),
        _ErrorBanner(message: _error!),
      ],
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          key: const Key('familyLink.submit'),
          onPressed: _busy ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: FamilyPalette.blue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(
                  _withCode ? 'Link now' : (received ? 'Accept and link' : 'Send request'),
                  style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    ];
  }
}

class _ResultCard extends StatelessWidget {
  final FamilyLookupResult result;
  final FamilyPalette palette;

  const _ResultCard({required this.result, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    if (!result.found) {
      return Container(
        key: const Key('familyLink.notFound'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: p.field, borderRadius: BorderRadius.circular(12), border: Border.all(color: p.fieldBorder)),
        child: Row(
          children: [
            PhosphorIcon(PhosphorIconsBold.info, size: 18, color: p.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No Yira account uses this number. Check the number, or add them as a family member instead.',
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, height: 1.35, color: p.text),
              ),
            ),
          ],
        ),
      );
    }
    final String? status = result.alreadyLinked
        ? 'Already in your family'
        : result.requestSent
            ? 'Request sent. Waiting for them to accept.'
            : result.requestReceived
                ? 'They asked to link with you'
                : null;
    return Container(
      key: const Key('familyLink.found'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FamilyPalette.blue.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: p.blueSoft, borderRadius: BorderRadius.circular(12)),
            child: const PhosphorIcon(PhosphorIconsBold.user, size: 18, color: FamilyPalette.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.maskedName.isNotEmpty ? result.maskedName : 'Yira user',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w700, color: p.text)),
                Text(status ?? 'Has a Yira account',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: p.muted)),
              ],
            ),
          ),
          if (result.alreadyLinked || result.requestSent)
            PhosphorIcon(PhosphorIconsBold.checkCircle, size: 18, color: p.muted)
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final FamilyPalette palette;
  final VoidCallback onTap;

  const _MethodTile({
    super.key,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? p.blueSoft : p.field,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? FamilyPalette.blue : p.fieldBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhosphorIcon(icon, size: 18, color: selected ? FamilyPalette.blue : p.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w700, color: p.text)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, height: 1.35, color: p.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PhosphorIcon(
                selected ? PhosphorIconsBold.checkCircle : PhosphorIconsBold.circle,
                size: 18,
                color: selected ? FamilyPalette.blue : p.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('familyLink.error'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const PhosphorIcon(PhosphorIconsBold.warningCircle, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
