import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/widgets/phosphor_icons.dart';

import 'family_code_card.dart';

/// What the one "Add member" button on My Family can do.
enum FamilyAddChoice { addMember, linkUser, myCode }

/// The popup behind My Family's single "Add member" button: add a new family member, link someone
/// who already uses Yira, or show your own family code so they can link to you.
class FamilyAddOptionsSheet extends StatelessWidget {
  /// False once the family has its six members: adding and linking are then turned off.
  final bool canAddMore;

  /// False on a family member's profile: linking and the family code belong to the account holder.
  final bool canLink;

  const FamilyAddOptionsSheet({super.key, required this.canAddMore, required this.canLink});

  static Future<FamilyAddChoice?> show(BuildContext context, {required bool canAddMore, required bool canLink}) {
    return showModalBottomSheet<FamilyAddChoice>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FamilyAddOptionsSheet(canAddMore: canAddMore, canLink: canLink),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = FamilyPalette.of(context);
    final full = 'Your family has 6 members. Remove someone first.';
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('Add to your family',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 17, fontWeight: FontWeight.w700, color: p.text)),
            ),
            const SizedBox(height: 12),
            _Option(
              key: const Key('familyAdd.member'),
              icon: PhosphorIconsBold.userPlus,
              title: 'Add a family member',
              subtitle: canAddMore ? 'For someone without their own Yira account, like a child or a parent' : full,
              palette: p,
              onTap: canAddMore ? () => Navigator.of(context).pop(FamilyAddChoice.addMember) : null,
            ),
            if (canLink) ...[
              const SizedBox(height: 10),
              _Option(
                key: const Key('familyAdd.link'),
                icon: PhosphorIconsBold.link,
                title: 'Link an existing Yira user',
                subtitle: canAddMore ? 'They use Yira with their own number: use their family code or send a request' : full,
                palette: p,
                onTap: canAddMore ? () => Navigator.of(context).pop(FamilyAddChoice.linkUser) : null,
              ),
              const SizedBox(height: 10),
              _Option(
                key: const Key('familyAdd.code'),
                icon: PhosphorIconsBold.shieldCheck,
                title: 'My family code',
                subtitle: 'Share it so family can link to you. It changes every 10 minutes.',
                palette: p,
                onTap: () => Navigator.of(context).pop(FamilyAddChoice.myCode),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final FamilyPalette palette;
  final VoidCallback? onTap;

  const _Option({super.key, required this.icon, required this.title, required this.subtitle, required this.palette, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: p.border)),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: p.blueSoft, borderRadius: BorderRadius.circular(12)),
                  child: PhosphorIcon(icon, size: 20, color: p.isDark ? const Color(0xFF93B4FF) : FamilyPalette.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w700, color: p.text)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, height: 1.35, color: p.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PhosphorIcon(PhosphorIconsBold.caretRight, size: 16, color: p.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
