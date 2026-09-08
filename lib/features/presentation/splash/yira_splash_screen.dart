import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'painters/splash_background_painter.dart';
import 'painters/hand_glow_painter.dart';
import 'painters/ecosystem_lines_painter.dart';
import 'painters/heartbeat_painter.dart';
import 'widgets/service_icon_widget.dart';

/// 10 Distinct Animation Styles available for the Yira Splash Screen.
enum SplashAnimationStyle {
  cosmicOrbit('Cosmic Orbit', 'Smooth elliptical planetary orbit with laser pulses'),
  dnaHelix('DNA Helix', '3D double-helix weave rotating vertically around the hand'),
  vortexWhirlpool('Vortex Spiral', 'Centrifugal black-hole spiral accelerating into the palm'),
  radialBloom('Radial Bloom', 'Explosive 360° floral burst with elastic spring settle'),
  hexagonalMatrix('Hexagon Hive', 'Futuristic honeycomb medical diagnostic grid'),
  cardiacPulse('Cardiac Pulse', 'Rhythmic double-beat heartbeat pulses sending shockwaves'),
  carousel3D('3D Carousel', 'True 3D perspective depth cylinder rotating around the Y-axis'),
  starConstellation('Star Polygon', 'Geometric 8-pointed star constellation with energy beams'),
  zeroGravity('Zero-Gravity', 'Organic harmonic drift physics floating in microgravity'),
  hyperspaceWarp('Hyperspace Warp', 'Warp speed light-streak zoom from deep space into the palm');

  final String title;
  final String description;
  const SplashAnimationStyle(this.title, this.description);
}

/// Calculated position and scale for a service node in an animation frame.
class NodeTransform {
  final Offset position;
  final double scale;
  final double opacity;

  const NodeTransform({
    required this.position,
    required this.scale,
    required this.opacity,
  });
}

/// Premium Light Mode cinematic animated splash screen for Yira healthcare platform.
class YiraSplashScreen extends StatefulWidget {
  final SplashAnimationStyle animationStyle;

  const YiraSplashScreen({
    super.key,
    this.animationStyle = SplashAnimationStyle.cosmicOrbit,
  });

  @override
  State<YiraSplashScreen> createState() => _YiraSplashScreenState();
}

class _YiraSplashScreenState extends State<YiraSplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──
  late final AnimationController _bgController;
  late final AnimationController _handController;
  late final AnimationController _orbitController;
  late final AnimationController _convergeController;
  late final AnimationController _shockwaveController;
  late final AnimationController _logoController;
  late final AnimationController _heartbeatLoopController;

  // ── Animations ──
  late final Animation<double> _bgFadeIn;
  late final Animation<double> _handFadeIn;
  late final Animation<double> _handScale;
  late final Animation<double> _nodesReveal;
  late final Animation<double> _linesReveal;
  late final Animation<double> _convergeFactor;
  late final Animation<double> _shockwaveProgress;
  late final Animation<double> _logoFadeIn;
  late final Animation<double> _logoScale;
  late final Animation<double> _taglineFadeIn;
  late final Animation<double> _heartbeatReveal;

  // Background particles
  late final List<SplashParticle> _particles;

  // Hand center in exact visual center
  static const Offset _handCenter = Offset(0.5, 0.48);

  @override
  void initState() {
    super.initState();
    _particles = generateSplashParticles(count: 32);
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    _bgFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bgController,
        curve: const Interval(0.0, 0.06, curve: Curves.easeOut),
      ),
    );

    // Hand entrance (0.5s – 1.8s)
    _handController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _handFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _handController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _handScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _handController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    // Nodes reveal (1.8s – 3.6s)
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _nodesReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _orbitController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _linesReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _orbitController,
        curve: const Interval(0.1, 0.9, curve: Curves.easeOut),
      ),
    );

    // Convergence into palm (3.6s – 4.6s)
    _convergeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _convergeFactor = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _convergeController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // Shockwave explosion
    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shockwaveProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shockwaveController,
        curve: Curves.easeOutQuart,
      ),
    );

    // Logo reveal (4.6s – 6.8s)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _logoFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _taglineFadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
      ),
    );
    _heartbeatReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _heartbeatLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  void _startAnimationSequence() async {
    _bgController.repeat();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    _handController.forward();

    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    _orbitController.forward();

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    _convergeController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    _shockwaveController.forward();

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _heartbeatLoopController.repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _handController.dispose();
    _orbitController.dispose();
    _convergeController.dispose();
    _shockwaveController.dispose();
    _logoController.dispose();
    _heartbeatLoopController.dispose();
    super.dispose();
  }

  /// Calculates node position, scale, and opacity according to the selected animation style.
  List<NodeTransform> _calculateNodeTransforms(Size size) {
    const count = 8;
    final converge = _convergeFactor.value;
    final bgLoop = _bgController.value;
    final reveal = _nodesReveal.value;

    final transforms = <NodeTransform>[];

    for (int i = 0; i < count; i++) {
      final stagger = i * 0.06;
      final nodeReveal = ((reveal - stagger) / (1.0 - stagger)).clamp(0.0, 1.0);
      final baseOpacity = (nodeReveal * (1.0 - converge * 1.3)).clamp(0.0, 1.0);
      final angle = -pi / 2 + (2 * pi * i / count);

      double x = _handCenter.dx;
      double y = _handCenter.dy;
      double scale = (0.2 + 0.8 * nodeReveal) * (1.0 - converge * 0.7);

      switch (widget.animationStyle) {
        // 1. Cosmic Orbit: Elliptical planetary orbit
        case SplashAnimationStyle.cosmicOrbit:
          const rX = 0.38;
          const rY = 0.25;
          final currentAngle = angle + bgLoop * 0.4;
          final targetX = _handCenter.dx + rX * cos(currentAngle);
          final targetY = _handCenter.dy + rY * sin(currentAngle);
          x = targetX + (_handCenter.dx - targetX) * converge;
          y = targetY + (_handCenter.dy - targetY) * converge;
          break;

        // 2. DNA Double Helix: Vertically oscillating rotating pairs
        case SplashAnimationStyle.dnaHelix:
          final pairIdx = i ~/ 2;
          final isRight = i % 2 == 1;
          final t = (pairIdx / 4.0) + bgLoop * 0.6;
          final helixPhase = t * 2 * pi + (isRight ? pi : 0);
          final helixX = _handCenter.dx + 0.32 * cos(helixPhase);
          final helixY = _handCenter.dy + (pairIdx - 1.5) * 0.13;
          x = helixX + (_handCenter.dx - helixX) * converge;
          y = helixY + (_handCenter.dy - helixY) * converge;
          scale *= 0.85 + 0.25 * sin(helixPhase);
          break;

        // 3. Vortex Whirlpool: Accelerating logarithmic spiral into the palm
        case SplashAnimationStyle.vortexWhirlpool:
          final spiralSpin = angle + bgLoop * 1.5 + converge * 4.5 * pi;
          final spiralRadius = (1.0 - converge) * 0.38;
          x = _handCenter.dx + spiralRadius * cos(spiralSpin);
          y = _handCenter.dy + spiralRadius * 0.65 * sin(spiralSpin);
          scale *= (1.0 - converge * 0.85);
          break;

        // 4. Radial Bloom: Explosive 360° bloom with spring bounce
        case SplashAnimationStyle.radialBloom:
          final spring = nodeReveal < 0.7
              ? sin((nodeReveal / 0.7) * pi * 0.5) * 1.15
              : 1.0 + 0.04 * sin(bgLoop * 4 * pi + i);
          final bloomX = _handCenter.dx + 0.38 * cos(angle) * spring;
          final bloomY = _handCenter.dy + 0.26 * sin(angle) * spring;
          x = bloomX + (_handCenter.dx - bloomX) * converge;
          y = bloomY + (_handCenter.dy - bloomY) * converge;
          break;

        // 5. Hexagonal Matrix: High-tech honeycomb shield arrangement
        case SplashAnimationStyle.hexagonalMatrix:
          final double hexX;
          final double hexY;
          if (i < 6) {
            final hexAngle = (2 * pi * i / 6);
            hexX = _handCenter.dx + 0.36 * cos(hexAngle);
            hexY = _handCenter.dy + 0.24 * sin(hexAngle);
          } else if (i == 6) {
            hexX = _handCenter.dx;
            hexY = _handCenter.dy - 0.29; // Top
          } else {
            hexX = _handCenter.dx;
            hexY = _handCenter.dy + 0.29; // Bottom
          }
          final pulse = 1.0 + 0.03 * sin(bgLoop * 3 * pi + i);
          x = hexX * pulse + (_handCenter.dx - hexX * pulse) * converge;
          y = hexY * pulse + (_handCenter.dy - hexY * pulse) * converge;
          break;

        // 6. Cardiac Pulse: Double-beat rhythmic heartbeat expansion
        case SplashAnimationStyle.cardiacPulse:
          final beatT = (bgLoop * 5) % 1.0;
          double beatFactor = 1.0;
          if (beatT < 0.15) {
            beatFactor += sin(beatT / 0.15 * pi) * 0.18; // Lub
          } else if (beatT > 0.20 && beatT < 0.35) {
            beatFactor += sin((beatT - 0.20) / 0.15 * pi) * 0.24; // Dub
          }
          final cardiacX = _handCenter.dx + 0.38 * cos(angle) * beatFactor;
          final cardiacY = _handCenter.dy + 0.25 * sin(angle) * beatFactor;
          x = cardiacX + (_handCenter.dx - cardiacX) * converge;
          y = cardiacY + (_handCenter.dy - cardiacY) * converge;
          scale *= beatFactor;
          break;

        // 7. 3D Carousel: True 3D perspective cylinder rotating around Y-axis
        case SplashAnimationStyle.carousel3D:
          final carouselAngle = angle + bgLoop * 2 * pi * 0.5;
          final depth = sin(carouselAngle); // -1.0 (back) to +1.0 (front)
          final depthScale = 0.72 + 0.38 * ((depth + 1.0) / 2.0);
          final carX = _handCenter.dx + 0.38 * cos(carouselAngle);
          final carY = _handCenter.dy + 0.06 * depth;
          x = carX + (_handCenter.dx - carX) * converge;
          y = carY + (_handCenter.dy - carY) * converge;
          scale *= depthScale;
          break;

        // 8. Star Constellation: Alternating 8-pointed geometric star
        case SplashAnimationStyle.starConstellation:
          final isPoint = i % 2 == 0;
          final rX = isPoint ? 0.39 : 0.26;
          final rY = isPoint ? 0.26 : 0.17;
          final starX = _handCenter.dx + rX * cos(angle + bgLoop * 0.3);
          final starY = _handCenter.dy + rY * sin(angle + bgLoop * 0.3);
          x = starX + (_handCenter.dx - starX) * converge;
          y = starY + (_handCenter.dy - starY) * converge;
          break;

        // 9. Zero-Gravity: Organic floating cells with harmonic wobble
        case SplashAnimationStyle.zeroGravity:
          final wobbleX = 0.035 * sin(bgLoop * 2 * pi * 1.4 + i * 1.3);
          final wobbleY = 0.035 * cos(bgLoop * 2 * pi * 1.1 + i * 1.7);
          final gravX = _handCenter.dx + 0.37 * cos(angle) + wobbleX;
          final gravY = _handCenter.dy + 0.24 * sin(angle) + wobbleY;
          x = gravX + (_handCenter.dx - gravX) * converge;
          y = gravY + (_handCenter.dy - gravY) * converge;
          break;

        // 10. Hyperspace Warp: Light-streak warp speed zoom into center
        case SplashAnimationStyle.hyperspaceWarp:
          final warpZ = pow(nodeReveal, 2.2).toDouble();
          final warpDist = (1.0 - warpZ * 0.4) * 0.42;
          final warpX = _handCenter.dx + warpDist * cos(angle);
          final warpY = _handCenter.dy + warpDist * 0.65 * sin(angle);
          x = warpX + (_handCenter.dx - warpX) * converge;
          y = warpY + (_handCenter.dy - warpY) * converge;
          scale *= (0.3 + 0.9 * warpZ);
          break;
      }

      transforms.add(NodeTransform(
        position: Offset(x, y),
        scale: scale.clamp(0.05, 1.4),
        opacity: baseOpacity,
      ));
    }

    return transforms;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _bgController,
        _handController,
        _orbitController,
        _convergeController,
        _shockwaveController,
        _logoController,
        _heartbeatLoopController,
      ]),
      builder: (context, _) {
        final size = MediaQuery.of(context).size;
        final nodeTransforms = _calculateNodeTransforms(size);
        final rawPositions = nodeTransforms.map((t) => t.position).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ── Layer 1: Pristine Light Mode Gradient & Particles ──
              RepaintBoundary(
                child: Opacity(
                  opacity: _bgFadeIn.value,
                  child: CustomPaint(
                    size: size,
                    painter: SplashBackgroundPainter(
                      animationValue: _bgController.value,
                      particles: _particles,
                    ),
                  ),
                ),
              ),

              // ── Layer 2: Connecting Royal Blue Laser Lines ──
              RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: EcosystemLinesPainter(
                    iconPositions: rawPositions,
                    revealProgress: _linesReveal.value,
                    convergence: _convergeFactor.value,
                    dashOffset: _bgController.value * 4,
                    convergenceCenter: _handCenter,
                  ),
                ),
              ),

              // ── Layer 3: Centered Cybernetic Hand ("Health in Your Hands") ──
              _buildCenteredHand(size),

              // ── Layer 4: Biometric Rings & Shockwave ──
              RepaintBoundary(
                child: CustomPaint(
                  size: size,
                  painter: HandGlowPainter(
                    fadeIn: (_handFadeIn.value - _shockwaveProgress.value * 1.5)
                        .clamp(0.0, 1.0),
                    glowPulse: sin(_bgController.value * 2 * pi * 3),
                    scale: _handScale.value,
                    shockwaveProgress: _shockwaveProgress.value,
                    normalizedCenter: _handCenter,
                  ),
                ),
              ),

              // ── Layer 5: 8 Enlarged Colorful 3D PNG Healthcare Nodes ──
              _buildHealthcareNodes(size, nodeTransforms),

              // ── Layer 6: Brand Climax (Logo, Tagline, ECG Heartbeat) ──
              _buildBrandClimax(size),

              // ── Layer 7: Bottom Security Environment Badge ──
              _buildBottomBadge(size),
            ],
          ),
        );
      },
    );
  }

  /// Builds the cybernetic hand centered on the screen.
  Widget _buildCenteredHand(Size size) {
    final handOpacity =
        (_handFadeIn.value * (1.0 - _shockwaveProgress.value * 1.2))
            .clamp(0.0, 1.0);

    if (handOpacity <= 0.01) return const SizedBox.shrink();

    final handWidth = size.width * 0.90 * _handScale.value;
    final handHeight = handWidth;

    return Positioned(
      left: size.width * _handCenter.dx - handWidth / 2,
      top: size.height * _handCenter.dy - handHeight / 2,
      child: Opacity(
        opacity: handOpacity,
        child: Image.asset(
          'assets/images/yira_hand_light_centered.png',
          width: handWidth,
          height: handHeight,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.volunteer_activism_rounded,
                size: 96,
                color: const Color(0xFF2563EB).withValues(alpha: 0.9),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the 8 enlarged, colorful 3D PNG healthcare nodes.
  Widget _buildHealthcareNodes(Size size, List<NodeTransform> transforms) {
    final services = splashHealthcareServices;

    return Stack(
      children: List.generate(services.length, (i) {
        final t = transforms[i];

        return Positioned(
          left: t.position.dx * size.width - 35,
          top: t.position.dy * size.height - 35,
          child: ServiceIconWidget(
            service: services[i],
            opacity: t.opacity,
            scale: t.scale,
          ),
        );
      }),
    );
  }

  /// Builds the official Yira logo reveal, bold typography, tagline, and animated heartbeat.
  Widget _buildBrandClimax(Size size) {
    if (_logoFadeIn.value <= 0.01) return const SizedBox.shrink();

    return Center(
      child: Opacity(
        opacity: _logoFadeIn.value,
        child: Transform.scale(
          scale: _logoScale.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Official Yira SVG Logo in 3D Elevated Card
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB)
                          .withValues(alpha: _logoFadeIn.value * 0.32),
                      blurRadius: 36,
                      offset: const Offset(0, 12),
                      spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF60A5FA),
                          Color(0xFF2563EB),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SvgPicture.asset(
                        'assets/images/svgs/ic_apps_logo.svg',
                        width: 82,
                        height: 82,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // 2. High-Contrast Title: "Yira ClinX"
              Text(
                'Yira ClinX',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                  color: const Color(0xFF0F172A),
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF2563EB)
                          .withValues(alpha: _logoFadeIn.value * 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // 3. Tagline: "HEALTH IN YOUR HANDS"
              Opacity(
                opacity: _taglineFadeIn.value,
                child: Text(
                  'HEALTH IN YOUR HANDS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                    color: const Color(0xFF2563EB)
                        .withValues(alpha: _taglineFadeIn.value),
                    letterSpacing: 4.5,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 4. Animated Royal Blue ECG Heartbeat Line
              Opacity(
                opacity: _heartbeatReveal.value,
                child: SizedBox(
                  width: size.width * 0.55,
                  height: 34,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: HeartbeatPainter(
                        revealProgress: _heartbeatReveal.value,
                        opacity: _heartbeatReveal.value * 0.95,
                        loopValue: _heartbeatLoopController.value,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the bottom security indicator for Light Mode.
  Widget _buildBottomBadge(Size size) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 48,
      child: Opacity(
        opacity: _taglineFadeIn.value,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 15,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'SECURE AI HEALTH ENVIRONMENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                      color: Color(0xFF1E293B),
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
