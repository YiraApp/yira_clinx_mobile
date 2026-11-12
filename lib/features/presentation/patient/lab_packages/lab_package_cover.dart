import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/widgets/phosphor_icons.dart';

/// What a lab package is mainly about, for its cover art: a short label, a main illustration,
/// two smaller ones and a gradient.
class LabPackageLook {
  final String label;
  final IconData icon;
  final List<IconData> extras;
  final Color from;
  final Color to;
  const LabPackageLook(this.label, this.icon, this.extras, this.from, this.to);
}

const LabPackageLook _fullBody = LabPackageLook('Full body checkup', PhosphorIconsDuotone.personSimple,
    [PhosphorIconsDuotone.heartbeat, PhosphorIconsDuotone.drop], Color(0xFF3B82F6), Color(0xFF1D4ED8));

/// Checked in order; the first whose words appear in the package's name, description or tests wins.
const List<(List<String>, LabPackageLook)> _looks = [
  (['heart', 'cardiac', 'cardio', 'lipid', 'cholesterol', 'ecg', 'troponin'],
      LabPackageLook('Heart care', PhosphorIconsDuotone.heart, [PhosphorIconsDuotone.heartbeat, PhosphorIconsDuotone.drop], Color(0xFFF43F5E), Color(0xFFBE123C))),
  (['diabet', 'sugar', 'glucose', 'hba1c', 'insulin'],
      LabPackageLook('Diabetes care', PhosphorIconsDuotone.drop, [PhosphorIconsDuotone.syringe, PhosphorIconsDuotone.testTube], Color(0xFF14B8A6), Color(0xFF0F766E))),
  (['thyroid', 'tsh', 't3', 't4'],
      LabPackageLook('Thyroid care', PhosphorIconsDuotone.butterfly, [PhosphorIconsDuotone.testTube, PhosphorIconsDuotone.sparkle], Color(0xFF8B5CF6), Color(0xFF6D28D9))),
  (['women', 'woman', 'female', 'pcos', 'pcod', 'pregnan', 'maternal', 'her '],
      LabPackageLook("Women's health", PhosphorIconsDuotone.genderFemale, [PhosphorIconsDuotone.heart, PhosphorIconsDuotone.sparkle], Color(0xFFEC4899), Color(0xFFBE185D))),
  (['vitamin', 'b12', 'd3', 'iron', 'ferritin', 'calcium', 'deficien'],
      LabPackageLook('Vitamins', PhosphorIconsDuotone.sun, [PhosphorIconsDuotone.pill, PhosphorIconsDuotone.sparkle], Color(0xFFF59E0B), Color(0xFFC2410C))),
  (['fever', 'dengue', 'malaria', 'typhoid', 'infection', 'covid', 'viral'],
      LabPackageLook('Fever & infection', PhosphorIconsDuotone.thermometer, [PhosphorIconsDuotone.virus, PhosphorIconsDuotone.testTube], Color(0xFFF97316), Color(0xFFC2410C))),
  (['kidney', 'renal', 'kft', 'creatinine', 'urea', 'liver', 'lft', 'hepat'],
      LabPackageLook('Kidney & liver', PhosphorIconsDuotone.flask, [PhosphorIconsDuotone.drop, PhosphorIconsDuotone.microscope], Color(0xFF06B6D4), Color(0xFF0E7490))),
  (['bone', 'joint', 'arthritis', 'uric'],
      LabPackageLook('Bone & joint', PhosphorIconsDuotone.bone, [PhosphorIconsDuotone.testTube, PhosphorIconsDuotone.sparkle], Color(0xFF64748B), Color(0xFF334155))),
  (['gene', 'dna', 'allergy', 'cancer', 'tumor', 'marker'],
      LabPackageLook('Advanced screening', PhosphorIconsDuotone.dna, [PhosphorIconsDuotone.microscope, PhosphorIconsDuotone.sparkle], Color(0xFF6366F1), Color(0xFF4338CA))),
  (['senior', 'elder', 'aged', 'men', 'man'],
      LabPackageLook('Senior care', PhosphorIconsDuotone.heartbeat, [PhosphorIconsDuotone.pill, PhosphorIconsDuotone.stethoscope], Color(0xFF0EA5E9), Color(0xFF1E40AF))),
  (['full body', 'complete', 'health package', 'health check', 'master', 'executive', 'wellness', 'basic'],
      _fullBody),
];

/// The cover art for [pkg], from the words in its name first, then its description and tests.
LabPackageLook labPackageLook(Map<String, dynamic> pkg) {
  String words(Object? v) => ' ${(v ?? '').toString().toLowerCase()} ';
  final name = words(pkg['name']);
  final rest = words(pkg['description']) + words((pkg['tests'] is List) ? (pkg['tests'] as List).join(' ') : '');
  for (final text in [name, rest]) {
    for (final (keys, look) in _looks) {
      if (keys.any((k) => RegExp('(^|[^a-z])${RegExp.escape(k.trim())}').hasMatch(text))) return look;
    }
  }
  return _fullBody;
}

/// A package's picture: its uploaded photo when it has one, otherwise drawn cover art. Both work
/// in light and dark mode; [child] is laid over the picture (badges, labels).
class LabPackageCover extends StatelessWidget {
  final Map<String, dynamic> package;
  final double height;
  final BorderRadius borderRadius;
  final Widget? child;
  /// A bigger illustration and a softer bottom edge, for the details page header
  final bool large;

  const LabPackageCover({
    super.key,
    required this.package,
    this.height = 140,
    this.borderRadius = BorderRadius.zero,
    this.child,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final look = labPackageLook(package);
    final url = (package['imageUrl'] ?? '').toString().trim();
    final art = _CoverArt(look: look, isDark: isDark, large: large);

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url.startsWith('https://'))
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, _) => art,
                errorWidget: (_, _, _) => art,
              )
            else
              art,
            if (url.startsWith('https://'))
              // keeps badges readable on any photo
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33000000), Color(0x00000000), Color(0x59000000)],
                    stops: [0, 0.45, 1],
                  ),
                ),
              ),
            ?child,
          ],
        ),
      ),
    );
  }
}

class _CoverArt extends StatelessWidget {
  final LabPackageLook look;
  final bool isDark;
  final bool large;
  const _CoverArt({required this.look, required this.isDark, required this.large});

  @override
  Widget build(BuildContext context) {
    // Dark mode: the same hues, deeper, so the cover doesn't glare on the charcoal page
    Color shade(Color c) => isDark ? Color.lerp(c, Colors.black, 0.35)! : c;
    return LayoutBuilder(builder: (context, box) {
      final h = box.maxHeight.isFinite ? box.maxHeight : 140.0;
      final w = box.maxWidth.isFinite ? box.maxWidth : 360.0;
      final iconSize = math.min(h * (large ? 0.58 : 0.62), w * 0.42);
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [shade(look.from), shade(look.to)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _CoverPattern(seed: look.label.hashCode))),
            // main illustration, right side, on a soft disc
            Positioned(
              right: w * 0.06,
              top: (h - iconSize * 1.35) / 2,
              child: Container(
                width: iconSize * 1.35,
                height: iconSize * 1.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.2),
                ),
                alignment: Alignment.center,
                child: PhosphorIcon(look.icon, size: iconSize, color: Colors.white, duotoneSecondaryOpacity: 0.35),
              ),
            ),
            // two small floating ones
            Positioned(
              right: w * 0.06 + iconSize * 1.3,
              top: h * 0.14,
              child: _Bubble(icon: look.extras.first, size: iconSize * 0.34),
            ),
            if (look.extras.length > 1)
              Positioned(
                right: w * 0.03,
                bottom: h * 0.08,
                child: _Bubble(icon: look.extras[1], size: iconSize * 0.28),
              ),
          ],
        ),
      );
    });
  }
}

class _Bubble extends StatelessWidget {
  final IconData icon;
  final double size;
  const _Bubble({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size),
      ),
      child: PhosphorIcon(icon, size: size, color: Colors.white.withValues(alpha: 0.95), duotoneSecondaryOpacity: 0.3),
    );
  }
}

/// Large soft circles and a dot grid: depth without noise.
class _CoverPattern extends CustomPainter {
  final int seed;
  _CoverPattern({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.10);
    final fill = Paint()..color = Colors.white.withValues(alpha: 0.06);
    canvas.drawCircle(Offset(size.width * 0.92, -size.height * 0.1), size.height * 0.75, fill);
    canvas.drawCircle(Offset(-size.width * 0.05, size.height * 1.05), size.height * 0.6, fill);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.5), size.height * 0.62, ring);

    final dot = Paint()..color = Colors.white.withValues(alpha: 0.16);
    const gap = 14.0;
    final cols = (size.width * 0.38 / gap).floor();
    final rows = (size.height * 0.5 / gap).floor();
    final r = math.Random(seed);
    for (var x = 0; x < cols; x++) {
      for (var y = 0; y < rows; y++) {
        if (r.nextDouble() < 0.18) continue;
        canvas.drawCircle(Offset(16 + x * gap, size.height - 14 - y * gap), 1.3, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CoverPattern old) => old.seed != seed;
}
