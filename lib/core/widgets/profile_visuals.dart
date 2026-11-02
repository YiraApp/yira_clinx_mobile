import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/constants.dart';

/// Shared look for family profiles: the avatar, relation colour, initials and age
/// shown on the Select Profile screen and the Switch Profile sheet.

/// Colour for a relation tag and avatar.
Color profileRelationColor(String relation, {bool isPrimary = false}) {
  final lower = relation.toLowerCase();
  if (isPrimary || lower == 'primary' || lower == 'self' || lower == 'you') {
    return const Color(0xFF0284C7);
  }
  if (lower.contains('father') || lower.contains('mother') || lower.contains('parent')) {
    return const Color(0xFF1D4ED8);
  }
  if (lower.contains('brother') || lower.contains('sister') || lower.contains('sibling')) {
    return const Color(0xFF0EA5E9);
  }
  if (lower.contains('spouse') || lower.contains('wife') || lower.contains('husband')) {
    return const Color(0xFF06B6D4);
  }
  if (lower.contains('child') || lower.contains('son') || lower.contains('daughter')) {
    return const Color(0xFF38BDF8);
  }
  return const Color(0xFF64748B);
}

/// "TC" for "teja chennu", "GR" for "Greeshma".
String profileInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) {
    return parts[0].length > 1 ? parts[0].substring(0, 2).toUpperCase() : parts[0].toUpperCase();
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

/// Accepts dd-MM-yyyy (what the API sends), dd/MM/yyyy or ISO dates.
DateTime? parseProfileDob(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  final dmy = RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})$').firstMatch(value);
  if (dmy != null) {
    return DateTime(int.parse(dmy.group(3)!), int.parse(dmy.group(2)!), int.parse(dmy.group(1)!));
  }
  return DateTime.tryParse(value);
}

/// "28 yrs", "5 mos" or "12 days"; null for a missing or future date.
String? profileAgeLabel(String? rawDob) {
  final dob = parseProfileDob(rawDob);
  if (dob == null) return null;
  final now = DateTime.now();
  if (dob.isAfter(now)) return null;
  int years = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) years--;
  if (years >= 1) return '$years ${years == 1 ? 'yr' : 'yrs'}';
  final months = (now.year - dob.year) * 12 + now.month - dob.month - (now.day < dob.day ? 1 : 0);
  if (months >= 1) return '$months ${months == 1 ? 'mo' : 'mos'}';
  final days = now.difference(dob).inDays;
  return '$days ${days == 1 ? 'day' : 'days'}';
}

IconData profileGenderIcon(String gender) {
  final lower = gender.toLowerCase();
  if (lower.startsWith('f')) return Icons.female_rounded;
  if (lower.startsWith('m')) return Icons.male_rounded;
  return Icons.person_outline_rounded;
}

/// Round avatar: the profile photo when there is one (web link, embedded image or
/// local file), otherwise the initials on the relation colour. White ring, soft glow.
class ProfileAvatar extends StatelessWidget {
  final String name;
  final String? imagePath;
  final Color color;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.name,
    required this.imagePath,
    required this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final Widget initials = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        profileInitials(name),
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );

    Widget content = initials;
    final path = (imagePath ?? '').trim();
    if (path.startsWith('http')) {
      content = ClipOval(
        child: CachedNetworkImage(
          imageUrl: path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => initials,
          errorWidget: (_, _, _) => initials,
        ),
      );
    } else if (path.startsWith('data:image')) {
      try {
        final comma = path.indexOf(',');
        final bytes = base64Decode(comma != -1 ? path.substring(comma + 1) : path);
        content = ClipOval(
          child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => initials),
        );
      } catch (_) {}
    } else if (path.isNotEmpty) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          content = ClipOval(
            child: Image.file(file, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => initials),
          );
        }
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.28), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: content,
    );
  }
}

/// Small icon + text pair, e.g. "♂ Male" or "📍 Hyderabad".
class ProfileInfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isTab;

  const ProfileInfoItem({super.key, required this.icon, required this.text, required this.color, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: isTab ? 14 : 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: appPoppinFont, fontSize: isTab ? 12.5 : 11.5, fontWeight: FontWeight.w500, color: color),
          ),
        ),
      ],
    );
  }
}

/// Rounded tag such as "Primary", "Brother" or "Provider".
class ProfileTag extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const ProfileTag({super.key, required this.label, required this.color, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

/// Upper-case section label with an optional count bubble.
class ProfileSectionLabel extends StatelessWidget {
  final String title;
  final int? count;
  final bool isDark;

  const ProfileSectionLabel({super.key, required this.title, this.count, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.9, color: color),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count', style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
            ),
          ],
        ],
      ),
    );
  }
}
