import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../constants/constants.dart';

/// A medicine-style loading indicator: a two-tone capsule that turns while a heartbeat
/// line traces underneath. With reduced motion on, it shows the still capsule.
class MedicalLoader extends StatefulWidget {
  const MedicalLoader({super.key, this.message, this.size = 1});

  /// Shown under the animation, e.g. "Finding packages near you…".
  final String? message;

  /// Scales the whole loader; 1 is about 120 × 70 points.
  final double size;

  @override
  State<MedicalLoader> createState() => _MedicalLoaderState();
}

class _MedicalLoaderState extends State<MedicalLoader> with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF2563EB);
  static const _lightBlue = Color(0xFF93C5FD);

  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.size;
    return Semantics(
      label: widget.message ?? 'Loading',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                // Half a turn per cycle, easing in and out, with a small bob.
                final turn = Curves.easeInOutCubic.transform(t) * math.pi;
                final bob = math.sin(t * 2 * math.pi) * 3 * s;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 48 * s,
                      child: Center(
                        child: Transform.translate(
                          offset: Offset(0, bob),
                          child: Transform.rotate(angle: turn - math.pi / 4, child: _Capsule(scale: s, isDark: isDark)),
                        ),
                      ),
                    ),
                    SizedBox(height: 6 * s),
                    CustomPaint(
                      size: Size(120 * s, 22 * s),
                      painter: _HeartbeatPainter(progress: t, color: _blue, faint: _lightBlue.withValues(alpha: isDark ? 0.25 : 0.4)),
                    ),
                  ],
                );
              },
            ),
            if (widget.message != null) ...[
              SizedBox(height: 12 * s),
              Text(
                widget.message!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A pill: blue half and white half, with a soft shine.
class _Capsule extends StatelessWidget {
  const _Capsule({required this.scale, required this.isDark});

  final double scale;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final w = 54 * scale, h = 22 * scale;
    final radius = Radius.circular(h / 2);
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(radius),
        boxShadow: [
          BoxShadow(color: _MedicalLoaderState._blue.withValues(alpha: 0.25), blurRadius: 10 * scale, offset: Offset(0, 3 * scale)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.all(radius),
        child: Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                ),
                child: Align(
                  alignment: const Alignment(0, -0.45),
                  child: Container(
                    margin: EdgeInsets.only(left: 6 * scale, right: 4 * scale),
                    height: 3 * scale,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark ? const [Color(0xFFE2E8F0), Color(0xFFCBD5E1)] : const [Colors.white, Color(0xFFE5EDFB)],
                  ),
                  border: Border(
                    top: BorderSide(color: _MedicalLoaderState._blue.withValues(alpha: 0.18)),
                    bottom: BorderSide(color: _MedicalLoaderState._blue.withValues(alpha: 0.18)),
                    right: BorderSide(color: _MedicalLoaderState._blue.withValues(alpha: 0.18)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An ECG line that draws itself left to right, with a bright head and a fading trail.
class _HeartbeatPainter extends CustomPainter {
  _HeartbeatPainter({required this.progress, required this.color, required this.faint});

  final double progress;
  final Color color;
  final Color faint;

  Path _beat(Size size) {
    final w = size.width, h = size.height, mid = h * 0.6;
    return Path()
      ..moveTo(0, mid)
      ..lineTo(w * 0.30, mid)
      ..lineTo(w * 0.36, mid - h * 0.18)
      ..lineTo(w * 0.42, mid)
      ..lineTo(w * 0.47, mid)
      ..lineTo(w * 0.52, h * 0.02)
      ..lineTo(w * 0.58, h * 0.98)
      ..lineTo(w * 0.63, mid)
      ..lineTo(w * 0.70, mid)
      ..lineTo(w * 0.76, mid - h * 0.12)
      ..lineTo(w * 0.82, mid)
      ..lineTo(w, mid);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _beat(size);
    final stroke = size.height * 0.09;
    // The whole trace, faint, so the line never disappears.
    canvas.drawPath(
      path,
      Paint()
        ..color = faint
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final metric = path.computeMetrics().fold<PathMetric?>(null, (_, m) => m);
    if (metric == null) return;
    final head = metric.length * progress;
    final tail = math.max(0.0, head - metric.length * 0.35);
    final trail = metric.extractPath(tail, head);
    canvas.drawPath(
      trail,
      Paint()
        ..shader = LinearGradient(colors: [color.withValues(alpha: 0), color]).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final tip = metric.getTangentForOffset(head)?.position;
    if (tip != null) {
      canvas.drawCircle(tip, stroke * 1.4, Paint()..color = color);
      canvas.drawCircle(tip, stroke * 3, Paint()..color = color.withValues(alpha: 0.18));
    }
  }

  @override
  bool shouldRepaint(_HeartbeatPainter old) => old.progress != progress || old.color != color || old.faint != faint;
}
