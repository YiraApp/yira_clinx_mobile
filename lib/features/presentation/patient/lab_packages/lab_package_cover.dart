import 'dart:math' as math;
import 'dart:ui' as ui;

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
      LabPackageLook('Senior care', PhosphorIconsDuotone.heartbeat, [PhosphorIconsDuotone.pill, PhosphorIconsDuotone.stethoscope], Color(0xFF0EA5E9), Color(0xFF1D4ED8))),
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
  /// For list cards: when the package has a photo, size the cover to the photo's
  /// own shape so the whole photo shows edge to edge. [height] is used until it loads
  /// and for packages without a photo.
  final bool fitPhoto;

  const LabPackageCover({
    super.key,
    required this.package,
    this.height = 140,
    this.borderRadius = BorderRadius.zero,
    this.child,
    this.large = false,
    this.fitPhoto = false,
  });

  /// Where package photos come from; tests swap in a local image.
  @visibleForTesting
  static ImageProvider Function(String url) photoProvider = (url) => CachedNetworkImageProvider(url);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final look = labPackageLook(package);
    final url = (package['imageUrl'] ?? '').toString().trim();
    final art = _CoverArt(look: look, isDark: isDark, large: large);

    if (fitPhoto && url.startsWith('https://')) {
      return _PhotoSizedCover(url: url, fallbackHeight: height, borderRadius: borderRadius, art: art, child: child);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url.startsWith('https://')) ...[
              // The whole photo is shown (never cropped); a blurred copy fills the sides.
              ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22, tileMode: TileMode.clamp),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  placeholder: (_, _) => art,
                  errorWidget: (_, _, _) => art,
                ),
              ),
              const ColoredBox(color: Color(0x26000000)),
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (_, _) => const SizedBox.shrink(),
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            ] else
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

/// A cover that takes its uploaded photo's own aspect ratio, so the photo shows whole
/// with no cropping and no bars. Very tall or very wide photos are held between
/// square and 2.4:1; the spare room then gets a blurred copy of the photo.
class _PhotoSizedCover extends StatefulWidget {
  final String url;
  final double fallbackHeight;
  final BorderRadius borderRadius;
  final Widget art;
  final Widget? child;
  const _PhotoSizedCover({
    required this.url,
    required this.fallbackHeight,
    required this.borderRadius,
    required this.art,
    this.child,
  });

  @override
  State<_PhotoSizedCover> createState() => _PhotoSizedCoverState();
}

class _PhotoSizedCoverState extends State<_PhotoSizedCover> {
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener(
    (info, _) {
      final r = info.image.width / info.image.height;
      if (mounted && r.isFinite && r > 0) setState(() => _ratio = r);
    },
    onError: (_, _) {
      if (mounted) setState(() => _failed = true);
    },
  );
  double? _ratio;
  bool _failed = false;

  late final ImageProvider _provider = LabPackageCover.photoProvider(widget.url);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = _provider.resolve(createLocalImageConfiguration(context));
    if (stream.key != _stream?.key) {
      _stream?.removeListener(_listener);
      _stream = stream..addListener(_listener);
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _ratio;
    final Widget body;
    if (ratio == null || _failed) {
      body = SizedBox(height: widget.fallbackHeight, width: double.infinity, child: widget.art);
    } else {
      final shown = ratio.clamp(1.0, 2.4);
      body = AspectRatio(
        aspectRatio: shown,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (shown != ratio)
              ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22, tileMode: TileMode.clamp),
                child: Image(image: _provider, fit: BoxFit.cover),
              ),
            Image(image: _provider, fit: BoxFit.contain),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          body,
          if (ratio != null && !_failed)
            // keeps badges readable on any photo
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33000000), Color(0x00000000), Color(0x00000000), Color(0x4D000000)],
                    stops: [0, 0.3, 0.7, 1],
                  ),
                ),
              ),
            ),
          if (widget.child != null) Positioned.fill(child: widget.child!),
        ],
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
      // Everything fits inside the frame with a margin: disc, ring and both bubbles.
      final iconSize = math.min(h * (large ? 0.46 : 0.48), w * 0.34);
      final disc = iconSize * 1.35;
      final discRight = w * 0.08;
      final ringRadius = math.min(disc / 2 + h * 0.08, h / 2 - 6);
      final ringRight = discRight + disc / 2 - ringRadius;
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
            Positioned.fill(
              child: CustomPaint(
                painter: _CoverPattern(seed: look.label.hashCode, ringRadius: ringRadius, ringRight: ringRight),
              ),
            ),
            // main illustration, right side, on a soft disc
            Positioned(
              right: discRight,
              top: (h - disc) / 2,
              child: Container(
                width: disc,
                height: disc,
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
              right: discRight + disc + w * 0.02,
              top: h * 0.16,
              child: _Bubble(icon: look.extras.first, size: iconSize * 0.36),
            ),
            if (look.extras.length > 1)
              // The details header keeps its bottom row for labels, so its second
              // bubble sits up beside the first one instead.
              Positioned(
                right: large ? discRight + disc + w * 0.02 + iconSize * 0.36 * 1.64 + 12 : discRight + disc + w * 0.035,
                top: large ? h * 0.3 : null,
                bottom: large ? null : h * 0.14,
                child: _Bubble(icon: look.extras[1], size: iconSize * 0.3),
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
  /// The outer ring around the main illustration: its radius and gap from the right edge.
  final double ringRadius;
  final double ringRight;
  _CoverPattern({required this.seed, required this.ringRadius, required this.ringRight});

  @override
  void paint(Canvas canvas, Size size) {
    // Soft light from the top right and a gentle ring behind the illustration,
    // all kept inside the frame so the cover reads as a complete picture.
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.85, 0), radius: size.height * 0.9));
    canvas.drawRect(Offset.zero & size, glow);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.10);
    final c = Offset(size.width - ringRight - ringRadius, size.height / 2);
    canvas.drawCircle(c, ringRadius, ring);

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
  bool shouldRepaint(covariant _CoverPattern old) =>
      old.seed != seed || old.ringRadius != ringRadius || old.ringRight != ringRight;
}
