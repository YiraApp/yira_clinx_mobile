import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/phosphor_icons.dart';

/// Shared look for My billing and My policies, matching the rest of the app:
/// white cards, the brand blue for icons and actions, colour only for status.

IconData billCategoryIcon(String category) => switch (category) {
      'Consultation' => PhosphorIconsDuotone.stethoscope,
      'Pharmacy' => PhosphorIconsDuotone.pill,
      'Lab tests' => PhosphorIconsDuotone.flask,
      'Hospital stay' => PhosphorIconsDuotone.bed,
      'Procedure' => PhosphorIconsDuotone.firstAidKit,
      _ => PhosphorIconsDuotone.receipt,
    };

IconData policyTypeIcon(String type) => switch (type) {
      'Health' => PhosphorIconsDuotone.heartbeat,
      'Life' => PhosphorIconsDuotone.umbrella,
      'Accident' => PhosphorIconsDuotone.firstAidKit,
      'Critical illness' => PhosphorIconsDuotone.shieldPlus,
      'Government scheme' => PhosphorIconsDuotone.bank,
      _ => PhosphorIconsDuotone.shieldCheck,
    };

class WalletColors {
  final bool isDark;
  const WalletColors(this.isDark);

  Color get card => isDark ? const Color(0xFF232323) : Colors.white;
  Color get line => isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE6EAF0);
  Color get ink => isDark ? Colors.white : const Color(0xFF0F172A);
  Color get muted => isDark ? Colors.white60 : const Color(0xFF64748B);
  Color get faint => isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9);
  static const paid = Color(0xFF059669);
  static const due = Color(0xFFD97706);
  static const danger = Color(0xFFDC2626);
}

/// Rounded tile with a two-tone icon on a soft tint of [color].
class WalletIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool isDark;

  const WalletIconTile({super.key, required this.icon, required this.color, required this.isDark, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: PhosphorIcon(icon, size: size * 0.5, color: color),
    );
  }
}

class WalletPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const WalletPill({super.key, required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

/// Choice chips in a wrap, one selected.
class WalletChoiceChips extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;
  final Color accent;
  final bool isDark;

  const WalletChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final c = WalletColors(isDark);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onSelected(o),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: o == selected ? accent.withValues(alpha: isDark ? 0.25 : 0.1) : c.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: o == selected ? accent : c.line),
              ),
              child: Text(
                o,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12.5,
                  fontWeight: o == selected ? FontWeight.w600 : FontWeight.w500,
                  color: o == selected ? accent : c.ink,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Label above a form field, with an optional "Optional" hint.
class WalletFieldLabel extends StatelessWidget {
  final String text;
  final bool optional;
  final bool isDark;

  const WalletFieldLabel(this.text, {super.key, this.optional = false, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = WalletColors(isDark);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 14),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [if (optional) TextSpan(text: '  Optional', style: TextStyle(fontWeight: FontWeight.w400, color: c.muted))],
        ),
        style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: c.ink),
      ),
    );
  }
}

InputDecoration walletInputDecoration(BuildContext context, {String? hint, Widget? prefix, Widget? suffix}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = WalletColors(isDark);
  final primary = Theme.of(context).primaryColor;
  OutlineInputBorder border(Color color, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: color, width: w));
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, color: c.muted.withValues(alpha: 0.7)),
    prefixIcon: prefix,
    suffixIcon: suffix,
    isDense: true,
    filled: true,
    fillColor: c.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    enabledBorder: border(c.line),
    focusedBorder: border(primary, 1.4),
    errorBorder: border(WalletColors.danger),
    focusedErrorBorder: border(WalletColors.danger, 1.4),
  );
}

/// A label and value row in a detail sheet.
class WalletDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Widget? trailing;

  const WalletDetailRow({super.key, required this.label, required this.value, required this.isDark, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = WalletColors(isDark);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: c.muted)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: c.ink)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Grey handle and rounded top used by the wallet bottom sheets.
class WalletSheet extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const WalletSheet({super.key, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // A Material, not a coloured box, so list rows inside show their tap ripple.
    return Material(
      color: isDark ? const Color(0xFF232323) : const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
