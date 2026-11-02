import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../data/models/wallet/wallet_models.dart';
import 'wallet_widgets.dart';

/// Chart colour per bill type: a fixed slot each, so a type keeps its colour
/// whatever the period or filter. Validated for colour-blind separation on the
/// app's white and slate surfaces; the legend always names each slice.
Color billCategoryChartColor(String category, bool isDark) {
  const light = {
    'Consultation': Color(0xFF2A78D6),
    'Pharmacy': Color(0xFFEB6834),
    'Lab tests': Color(0xFF1BAF7A),
    'Hospital stay': Color(0xFFEDA100),
    'Procedure': Color(0xFFE87BA4),
    'Other': Color(0xFF008300),
  };
  const dark = {
    'Consultation': Color(0xFF3987E5),
    'Pharmacy': Color(0xFFD95926),
    'Lab tests': Color(0xFF199E70),
    'Hospital stay': Color(0xFFC98500),
    'Procedure': Color(0xFFD55181),
    'Other': Color(0xFF008300),
  };
  return (isDark ? dark : light)[category] ?? (isDark ? dark : light)['Other']!;
}

/// Spending by bill type as a ring, with the total (or the tapped type) in the
/// middle and a legend that names every slice with its amount and share.
class SpendingDonut extends StatefulWidget {
  /// Amount per type. Slices keep the fixed type order, not size order.
  final Map<String, double> byCategory;
  final String centerLabel;
  final bool isDark;

  const SpendingDonut({super.key, required this.byCategory, required this.centerLabel, required this.isDark});

  @override
  State<SpendingDonut> createState() => _SpendingDonutState();
}

class _SpendingDonutState extends State<SpendingDonut> {
  String? _selected;

  List<(String, double)> get _slices => [
        for (final cat in billCategories)
          if ((widget.byCategory[cat] ?? 0) > 0) (cat, widget.byCategory[cat]!),
      ];

  @override
  void didUpdateWidget(covariant SpendingDonut old) {
    super.didUpdateWidget(old);
    if (_selected != null && (widget.byCategory[_selected] ?? 0) <= 0) _selected = null;
  }

  void _toggle(String cat) => setState(() => _selected = _selected == cat ? null : cat);

  @override
  Widget build(BuildContext context) {
    final c = WalletColors(widget.isDark);
    final slices = _slices;
    final total = slices.fold<double>(0, (s, e) => s + e.$2);
    if (total <= 0) {
      return Center(
        child: Text('No spending in this period', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: c.muted)),
      );
    }
    final selected = _selected == null ? null : slices.where((s) => s.$1 == _selected).firstOrNull;
    String pct(double v) => '${(v / total * 100).round()}%';

    final ring = LayoutBuilder(
      builder: (context, box) {
        final size = math.min(box.maxWidth, box.maxHeight);
        return Center(
          child: GestureDetector(
            onTapUp: (d) {
              final hit = _hitTest(d.localPosition, Size.square(size), slices, total);
              if (hit != null) _toggle(hit);
            },
            child: SizedBox.square(
              dimension: size,
              child: CustomPaint(
                painter: _DonutPainter(
                  slices: [for (final s in slices) (s.$2, billCategoryChartColor(s.$1, widget.isDark), s.$1 == _selected)],
                  anySelected: _selected != null,
                  gapColor: c.card,
                ),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(size * 0.2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(selected?.$1 ?? widget.centerLabel,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: c.muted)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(formatRupees(selected?.$2 ?? total),
                              style: TextStyle(fontFamily: appPoppinFont, fontSize: 22, fontWeight: FontWeight.w700, color: c.ink)),
                        ),
                        if (selected != null)
                          Text('${pct(selected.$2)} of spending', style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: c.muted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    final legend = ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        for (final (cat, amt) in slices)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _toggle(cat),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _selected == null || _selected == cat ? 1 : 0.45,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: billCategoryChartColor(cat, widget.isDark), borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(cat, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w500, color: c.ink)),
                    ),
                    Text(formatRupees(amt), style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w700, color: c.ink)),
                    SizedBox(
                      width: 44,
                      child: Text(pct(amt),
                          textAlign: TextAlign.right, style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: c.muted)),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    return Row(
      children: [
        Expanded(flex: 5, child: ring),
        const SizedBox(width: 20),
        Expanded(flex: 6, child: Center(child: legend)),
      ],
    );
  }

  /// The type under a tap on the ring, or null for the hole or outside it.
  String? _hitTest(Offset p, Size size, List<(String, double)> slices, double total) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final d = (p - center).distance;
    if (d < r * _DonutPainter.holeRatio - 6 || d > r + 6) return null;
    var angle = math.atan2(p.dy - center.dy, p.dx - center.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    var start = 0.0;
    for (final (cat, amt) in slices) {
      final sweep = amt / total * 2 * math.pi;
      if (angle >= start && angle < start + sweep) return cat;
      start += sweep;
    }
    return null;
  }
}

class _DonutPainter extends CustomPainter {
  /// Amount, colour and whether the slice is the tapped one.
  final List<(double, Color, bool)> slices;
  final bool anySelected;
  final Color gapColor;

  static const holeRatio = 0.62;

  _DonutPainter({required this.slices, required this.anySelected, required this.gapColor});

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (s, e) => s + e.$1);
    if (total <= 0) return;
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final thickness = outer * (1 - holeRatio);
    final radius = outer - thickness / 2;
    // A 2px gap of the card colour between slices, as an angle at mid-ring.
    final gap = slices.length > 1 ? 2.0 / radius : 0.0;
    var start = -math.pi / 2;
    for (final (amount, color, selected) in slices) {
      final sweep = amount / total * 2 * math.pi;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? thickness + 6 : thickness
        ..color = anySelected && !selected ? color.withValues(alpha: 0.35) : color;
      canvas.drawArc(Rect.fromCircle(center: center, radius: selected ? radius + 1 : radius - 2), start + gap / 2,
          math.max(0.0, sweep - gap), false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.slices.length != slices.length ||
      old.anySelected != anySelected ||
      old.gapColor != gapColor ||
      Iterable.generate(slices.length).any((i) => old.slices[i] != slices[i]);
}
