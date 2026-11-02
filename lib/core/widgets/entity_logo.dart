import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yiraclinics/core/constants/constants.dart';

/// A hospital logo or doctor photo. Shows the real image when there is one,
/// and a tinted initials badge otherwise (or while the image loads or fails).
class EntityLogo extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final double radius;

  /// Logos are drawn whole on white with padding; photos fill the tile.
  final bool isLogo;

  const EntityLogo({
    super.key,
    required this.imageUrl,
    required this.name,
    this.size = 56,
    this.radius = 14,
    this.isLogo = true,
  });

  static const List<Color> _palette = [
    Color(0xFF2563EB),
    Color(0xFF0D9488),
    Color(0xFF7C3AED),
    Color(0xFFDB2777),
    Color(0xFFEA580C),
    Color(0xFF0891B2),
    Color(0xFF4F46E5),
    Color(0xFF059669),
  ];

  /// A stable colour for a name, so a hospital keeps its colour everywhere.
  static Color colorFor(String name) {
    var hash = 0;
    for (final c in name.toLowerCase().codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return _palette[hash % _palette.length];
  }

  /// Up to two initials, ignoring a leading "Dr." and words in brackets.
  static String initialsFor(String name) {
    final cleaned = name
        .replaceFirst(RegExp(r'^\s*(dr\.?|doctor)\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .trim();
    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && RegExp(r'[A-Za-z0-9]').hasMatch(w[0])).toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  static bool isUsableUrl(String? url) {
    final u = (url ?? '').trim();
    return u.startsWith('http://') || u.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = (imageUrl ?? '').trim();
    if (!isUsableUrl(url)) return _monogram(isDark);

    // Inside the image tile: blank while loading, plain initials if it fails.
    final Widget loading = const SizedBox.shrink();
    final Widget failed = Center(
      child: Text(
        initialsFor(name),
        style: TextStyle(fontFamily: appPoppinFont, fontSize: size * 0.3, fontWeight: FontWeight.w700, color: colorFor(name)),
      ),
    );

    Widget content;
    if (url.toLowerCase().split('?').first.endsWith('.svg')) {
      content = SvgPicture.network(
        url,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => loading,
        errorBuilder: (_, _, _) => failed,
      );
    } else {
      content = CachedNetworkImage(
        imageUrl: url,
        fit: isLogo ? BoxFit.contain : BoxFit.cover,
        placeholder: (_, _) => loading,
        errorWidget: (_, _, _) => failed,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isLogo ? Colors.white : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Padding(
          padding: EdgeInsets.all(isLogo ? size * 0.12 : 0),
          child: SizedBox.expand(child: content),
        ),
      ),
    );
  }

  Widget _monogram(bool isDark) {
    final color = colorFor(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.1),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.35 : 0.18)),
      ),
      child: Text(
        initialsFor(name),
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
