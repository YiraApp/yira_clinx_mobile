import 'package:flutter/material.dart';

import '../constants/constants.dart';
import 'phosphor_icons.dart';
import 'profile_visuals.dart';

/// Header pill showing whose profile (or, for doctors, which workspace) is
/// open, with a switch affordance. Tapping it opens the Switch Profile sheet.
class ActiveProfileChip extends StatelessWidget {
  final String name;
  final String? imagePath;

  /// Relation of the open profile to the account holder ("Self", "Mother"...).
  final String relation;
  final bool isPrimary;

  /// Family profiles on this account; above 1 the chip says how many.
  final int profileCount;
  final VoidCallback onTap;
  final bool isTab;

  /// Replaces the relation line, e.g. "Doctor" for a workspace.
  final String? subtitle;

  /// Colour of the avatar and first word of the subtitle; defaults to the relation colour.
  final Color? accent;

  /// Grey text after the subtitle, e.g. "Switch workspace".
  final String? note;

  const ActiveProfileChip({
    super.key,
    required this.name,
    required this.imagePath,
    required this.relation,
    required this.isPrimary,
    required this.profileCount,
    required this.onTap,
    this.isTab = false,
    this.subtitle,
    this.accent,
    this.note,
  });

  /// A doctor's current workspace: the hospital, with their role underneath.
  const ActiveProfileChip.workspace({
    super.key,
    required this.name,
    this.imagePath,
    required String role,
    required Color color,
    required this.onTap,
    this.isTab = false,
  })  : relation = 'Self',
        isPrimary = true,
        profileCount = 0,
        subtitle = role,
        accent = color,
        note = 'Switch workspace';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rel = relation.trim();
    final isSelf = isPrimary || rel.isEmpty || rel.toLowerCase() == 'self';
    final accent = this.accent ?? profileRelationColor(rel, isPrimary: isSelf);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final subtitle = this.subtitle ?? (isSelf ? 'You' : "${rel[0].toUpperCase()}${rel.substring(1)}'s profile");

    return Semantics(
      button: true,
      label: this.subtitle == null ? 'Viewing $name. Switch profile' : '$name, $subtitle. Switch workspace',
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: StadiumBorder(side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        elevation: 0,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfileAvatar(name: name, imagePath: imagePath, color: accent, size: isTab ? 36 : 32),
                const SizedBox(width: 9),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 15 : 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.2,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: subtitle,
                              style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                            ),
                            if (profileCount > 1) TextSpan(text: '  ·  $profileCount profiles') else if (note != null) TextSpan(text: '  ·  $note'),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: isTab ? 11 : 10.5, height: 1.25, color: muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: PhosphorIcon(PhosphorIconsBold.caretUpDown, size: 14, color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
