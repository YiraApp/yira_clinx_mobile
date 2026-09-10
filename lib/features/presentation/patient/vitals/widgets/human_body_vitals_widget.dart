import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../../core/constants/constants.dart';
import 'vital_info_card.dart';
import 'vital_point_painter.dart';

/// Configuration for each vital mapped to an anatomical body location.
class _VitalConfig {
  final String key;
  final String title;
  final String unit;
  final IconData icon;
  final Color color;

  /// Normalized position on the original 896x1200 body image (x: 0-1, y: 0-1)
  final Offset bodyPos;

  /// Side where the floating pill badge is placed: true = left, false = right
  final bool isLeft;

  const _VitalConfig({
    required this.key,
    required this.title,
    required this.unit,
    required this.icon,
    required this.color,
    required this.bodyPos,
    required this.isLeft,
  });
}

/// Interactive 3D animated human body widget that displays current vitals
/// at pixel-perfect anatomical locations with animated glowing hotspots,
/// leader lines, sleek floating pills, and particle effects.
class HumanBodyVitalsWidget extends StatefulWidget {
  final Map<String, String> currentVitals;
  final void Function(String metricKey)? onVitalTapped;

  const HumanBodyVitalsWidget({
    super.key,
    required this.currentVitals,
    this.onVitalTapped,
  });

  @override
  State<HumanBodyVitalsWidget> createState() => _HumanBodyVitalsWidgetState();
}

class _HumanBodyVitalsWidgetState extends State<HumanBodyVitalsWidget>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _breathController;
  late AnimationController _heartController;
  late AnimationController _entryController;
  late AnimationController _particleController;

  late ParticleSystem _particleSystem;

  // Selected vital for interactive reticle highlight
  String? _selectedKey;

  static const Color _primaryBlue = Color(0xFF2563EB);

  // Pill badge dimensions for layout calculation
  static const double _pillWidth = 84.0;
  static const double _pillHeight = 28.0;
  static const double _stageHeight = 390.0;

  /// Anatomical locations verified on the 896x1200 3D body render:
  /// - Temp: Forehead center
  /// - BP: Right brachial artery (viewer's left arm)
  /// - Heart: Anatomical heart in left chest (viewer's right)
  /// - Weight: Core metabolic center / navel
  /// - SpO2: Left wrist / fingers (viewer's right hand)
  /// - Height: Stature / knee alignment
  static const List<_VitalConfig> _vitals = [
    _VitalConfig(
      key: 'temp',
      title: 'Temperature',
      unit: '°F',
      icon: Icons.thermostat_rounded,
      color: Color(0xFFF59E0B), // amber
      bodyPos: Offset(0.5000, 0.0833), // Forehead
      isLeft: true,
    ),
    _VitalConfig(
      key: 'bp',
      title: 'Blood Pressure',
      unit: 'mmHg',
      icon: Icons.favorite_rounded,
      color: Color(0xFF8B5CF6), // violet
      bodyPos: Offset(0.3683, 0.2792), // Right brachial arm
      isLeft: true,
    ),
    _VitalConfig(
      key: 'pulse',
      title: 'Heart Rate',
      unit: 'BPM',
      icon: Icons.monitor_heart_rounded,
      color: Color(0xFFE11D48), // rose
      bodyPos: Offset(0.5357, 0.2750), // Heart
      isLeft: false,
    ),
    _VitalConfig(
      key: 'weight',
      title: 'Weight',
      unit: 'kg',
      icon: Icons.scale_rounded,
      color: Color(0xFF10B981), // emerald
      bodyPos: Offset(0.5000, 0.4417), // Core / abdomen
      isLeft: true,
    ),
    _VitalConfig(
      key: 'spO2',
      title: 'Blood Oxygen',
      unit: '%',
      icon: Icons.air_rounded,
      color: Color(0xFF06B6D4), // cyan
      bodyPos: Offset(0.7087, 0.5167), // Left wrist / hand
      isLeft: false,
    ),
    _VitalConfig(
      key: 'height',
      title: 'Height',
      unit: 'cm',
      icon: Icons.height_rounded,
      color: Color(0xFF3B82F6), // blue
      bodyPos: Offset(0.4632, 0.7000), // Stature / legs
      isLeft: false,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Breathing: subtle organic scale pulse (2.8s cycle)
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    // Heart rate: synced to BPM
    final bpm = _parseBpm();
    final heartMs = bpm > 0 ? (60000 / bpm).round() : 833;
    _heartController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: heartMs),
    )..repeat();

    // Staggered entry animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Ambient floating particle updates
    _particleSystem = ParticleSystem();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..addListener(() {
        _particleSystem.update();
      })..repeat();
  }

  int _parseBpm() {
    final pulse = widget.currentVitals['pulse'] ?? '';
    final num = double.tryParse(pulse.replaceAll(RegExp(r'[^\d.]'), ''));
    if (num != null && num > 30 && num < 220) return num.round();
    return 72;
  }

  @override
  void didUpdateWidget(covariant HumanBodyVitalsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newBpm = _parseBpm();
    final newMs = newBpm > 0 ? (60000 / newBpm).round() : 833;
    if (_heartController.duration?.inMilliseconds != newMs) {
      _heartController.duration = Duration(milliseconds: newMs);
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _heartController.dispose();
    _entryController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  String _getStatus(String key) {
    final val = widget.currentVitals[key];
    if (val == null || val.isEmpty || val == '--') return 'Pending';
    switch (key) {
      case 'bp':
      case 'pulse':
      case 'temp':
        return 'Normal';
      case 'spO2':
        return 'Healthy';
      case 'weight':
      case 'height':
        return 'Tracked';
      default:
        return 'Normal';
    }
  }

  String _getValue(String key) {
    final val = widget.currentVitals[key];
    if (val == null || val.isEmpty) return '--';
    if (key == 'temp' && !val.endsWith('°F') && !val.endsWith('°')) {
      return '$val°F';
    }
    if (key == 'spO2' && !val.endsWith('%')) {
      return '$val%';
    }
    if (key == 'pulse') {
      return val.replaceAll(RegExp(r'[^\d]'), '');
    }
    return val;
  }

  /// Calculates the exact rendered rectangle of the 896x1200 body image inside
  /// the stage box using BoxFit.contain geometry.
  Rect _calculateImageRect(Size containerSize) {
    const double imageAspect = 896.0 / 1200.0; // ~0.74667
    final containerAspect = containerSize.width / containerSize.height;

    double renderedWidth;
    double renderedHeight;
    double left;
    double top;

    if (containerAspect > imageAspect) {
      // Container is wider than image -> height constrained
      renderedHeight = containerSize.height;
      renderedWidth = renderedHeight * imageAspect;
      left = (containerSize.width - renderedWidth) / 2;
      top = 0;
    } else {
      // Container is taller than image -> width constrained
      renderedWidth = containerSize.width;
      renderedHeight = renderedWidth / imageAspect;
      left = 0;
      top = (containerSize.height - renderedHeight) / 2;
    }

    return Rect.fromLTWH(left, top, renderedWidth, renderedHeight);
  }

  /// Convert normalized anatomical coordinates to exact screen pixels
  Offset _getScreenPoint(
      Offset normalized, Rect imageRect, double breathScale) {
    final center = imageRect.center;
    final unscaled = Offset(
      imageRect.left + normalized.dx * imageRect.width,
      imageRect.top + normalized.dy * imageRect.height,
    );
    return center + (unscaled - center) * breathScale;
  }

  void _handleVitalTap(String metricKey) {
    setState(() {
      _selectedKey = metricKey;
    });
    widget.onVitalTapped?.call(metricKey);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathController,
        _heartController,
        _entryController,
        _particleController,
      ]),
      builder: (context, child) {
        final breathScale = 1.0 + (sin(_breathController.value * pi) * 0.012);
        final entryVal = _entryController.value;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withValues(alpha: isDark ? 0.08 : 0.04),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _primaryBlue.withValues(alpha: 0.18),
                              _primaryBlue.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.accessibility_new_rounded,
                          size: 16,
                          color: _primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vitals',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Live vitals overview',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // BPM pulse badge
                      _buildPulseIndicator(isDark),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // ─── 3D Human Body Stage ─────────────────────────────────
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stageWidth = constraints.maxWidth;
                    final containerSize = Size(stageWidth, _stageHeight);
                    final imageRect = _calculateImageRect(containerSize);

                    // Build vital points for painter & pill anchors
                    final List<VitalPointData> painterPoints = [];
                    final List<Widget> pillWidgets = [];
                    final List<Widget> touchTargets = [];

                    for (int i = 0; i < _vitals.length; i++) {
                      final vc = _vitals[i];
                      final isSelected = _selectedKey == vc.key;
                      final hasData = widget.currentVitals[vc.key] != null &&
                          widget.currentVitals[vc.key]!.isNotEmpty &&
                          widget.currentVitals[vc.key] != '--';

                      // Staggered entry animation progress
                      final staggerDelay = i * 0.10;
                      final pillProgress =
                          ((entryVal - staggerDelay) / (1.0 - staggerDelay))
                              .clamp(0.0, 1.0);

                      // Exact screen position of the anatomical hotspot on the body
                      final bodyScreenPoint =
                          _getScreenPoint(vc.bodyPos, imageRect, breathScale);

                      // Position the floating pill badge safely in the side margins
                      double pillX;
                      Offset anchorPoint;

                      if (vc.isLeft) {
                        // Left side: place outside imageRect.left, clamped to container margin
                        pillX = max(
                            8.0, imageRect.left - _pillWidth - 8.0);
                        final pillY = (bodyScreenPoint.dy - _pillHeight / 2)
                            .clamp(8.0, _stageHeight - _pillHeight - 8.0);

                        anchorPoint = Offset(pillX + _pillWidth, pillY + _pillHeight / 2);

                        pillWidgets.add(
                          Positioned(
                            left: pillX,
                            top: pillY,
                            child: Transform.translate(
                              offset: Offset(
                                -20 * (1.0 - Curves.easeOutCubic.transform(pillProgress)),
                                0,
                              ),
                              child: VitalInfoCard(
                                title: vc.title,
                                value: _getValue(vc.key),
                                unit: vc.unit,
                                status: _getStatus(vc.key),
                                icon: vc.icon,
                                accentColor: vc.color,
                                opacity: pillProgress,
                                isSelected: isSelected,
                                onTap: () => _handleVitalTap(vc.key),
                              ),
                            ),
                          ),
                        );
                      } else {
                        // Right side: place outside imageRect.right, clamped to container margin
                        pillX = min(
                            stageWidth - _pillWidth - 8.0,
                            imageRect.right + 8.0);
                        final pillY = (bodyScreenPoint.dy - _pillHeight / 2)
                            .clamp(8.0, _stageHeight - _pillHeight - 8.0);

                        anchorPoint = Offset(pillX, pillY + _pillHeight / 2);

                        pillWidgets.add(
                          Positioned(
                            left: pillX,
                            top: pillY,
                            child: Transform.translate(
                              offset: Offset(
                                20 * (1.0 - Curves.easeOutCubic.transform(pillProgress)),
                                0,
                              ),
                              child: VitalInfoCard(
                                title: vc.title,
                                value: _getValue(vc.key),
                                unit: vc.unit,
                                status: _getStatus(vc.key),
                                icon: vc.icon,
                                accentColor: vc.color,
                                opacity: pillProgress,
                                isSelected: isSelected,
                                onTap: () => _handleVitalTap(vc.key),
                              ),
                            ),
                          ),
                        );
                      }

                      // Painter point data
                      painterPoints.add(
                        VitalPointData(
                          bodyPosition: vc.bodyPos,
                          cardAnchor: anchorPoint,
                          color: vc.color,
                          pulsePhase: vc.key == 'pulse'
                              ? _heartController.value
                              : (_breathController.value + i * 0.16) % 1.0,
                          hasData: hasData,
                          isSelected: isSelected,
                          label: vc.title,
                          isLeft: vc.isLeft,
                        ),
                      );

                      // Direct touch target on the body point (40x40 hit target)
                      touchTargets.add(
                        Positioned(
                          left: bodyScreenPoint.dx - 20,
                          top: bodyScreenPoint.dy - 20,
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _handleVitalTap(vc.key),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      width: stageWidth,
                      height: _stageHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Ambient radial background glow
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(0.0, -0.1),
                                  radius: 0.75,
                                  colors: [
                                    _primaryBlue.withValues(
                                        alpha: isDark ? 0.07 : 0.035),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // 3D Human Body image (exact pixel placement with breathing scale)
                          Positioned.fromRect(
                            rect: imageRect,
                            child: Center(
                              child: Transform.scale(
                                scale: breathScale * (0.85 + entryVal * 0.15),
                                child: Opacity(
                                  opacity: entryVal.clamp(0.0, 1.0),
                                  child: Image.asset(
                                    'assets/images/3d_human_body.png',
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // CustomPaint overlay: hotspots, reticles, scanline, leader lines
                          Positioned.fill(
                            child: CustomPaint(
                              painter: VitalPointPainter(
                                imageRect: imageRect,
                                breathScale: breathScale,
                                vitalPoints: painterPoints,
                                heartPulse: _heartController.value,
                                breathPhase: _breathController.value,
                                entryProgress: entryVal,
                                particles: _particleSystem.activeParticles,
                                isDark: isDark,
                              ),
                            ),
                          ),

                          // Floating compact pill badges in side margins
                          ...pillWidgets,

                          // Direct touch targets on the body hotspots
                          ...touchTargets,
                        ],
                      ),
                    );
                  },
                ),

                // ─── Footer Interactive Hint ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 13,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Tap any body point or metric below for full clinical history',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 10,
                          color: isDark
                              ? Colors.white38
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPulseIndicator(bool isDark) {
    final bpm = _parseBpm();
    final hasPulse = widget.currentVitals['pulse'] != null &&
        widget.currentVitals['pulse']!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48).withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE11D48).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Beating heart dot
          AnimatedBuilder(
            animation: _heartController,
            builder: (context, _) {
              final scale = 1.0 + sin(_heartController.value * pi * 2) * 0.25;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: hasPulse
                        ? const Color(0xFFE11D48)
                        : const Color(0xFF94A3B8),
                    shape: BoxShape.circle,
                    boxShadow: hasPulse
                        ? [
                            BoxShadow(
                              color: const Color(0xFFE11D48)
                                  .withValues(alpha: 0.5),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 5),
          Text(
            hasPulse ? '$bpm BPM' : '-- BPM',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: hasPulse
                  ? const Color(0xFFE11D48)
                  : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }
}
