import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/widgets/huge_icons.dart';

/// The launch splash.
///
/// 1. Story (optional): five feature slides drawn by the app, with photos
///    from the brand video, a slow zoom, a progress bar and sharp captions.
///    Tap anywhere (or Skip) to jump ahead.
/// 2. Scene: six service tiles settle onto a ring around the Yira.ai logo,
///    then the tagline.
///
/// [onComplete] fires once the scene has finished. Without it the scene simply
/// stays on screen (used as a loading backdrop).
class YiraStorySplash extends StatefulWidget {
  const YiraStorySplash({super.key, this.playStory = true, this.onComplete});

  final bool playStory;
  final VoidCallback? onComplete;

  static const String logoAsset = 'assets/images/svgs/yira_logo_white.svg';

  static const Duration slideLength = Duration(milliseconds: 1150);
  static const Duration sceneLength = Duration(milliseconds: 2600);

  static const List<StorySlide> slides = [
    StorySlide('assets/images/splash_story/story_1.jpg', HugeIcons.video02, Color(0xFF8FE3DA), 'Video Consult', 'Talk to a doctor in minutes'),
    StorySlide('assets/images/splash_story/story_2.jpg', HugeIcons.testTube02, Color(0xFFD2C4FF), 'Health Packages', 'Book full-body checkups'),
    StorySlide('assets/images/splash_story/story_3.jpg', HugeIcons.riceBowl01, Color(0xFFA6EBCB), 'Diet & Food', 'Snap a meal, track it'),
    StorySlide('assets/images/splash_story/story_4.jpg', HugeIcons.file02, Color(0xFFE6E8EE), 'Health Records', 'Every report, one place'),
    StorySlide('assets/images/splash_story/story_5.jpg', HugeIcons.cardiogram02, Color(0xFFFFA9BC), 'Heart & Vitals', 'ECG, BP, SpO2 at a glance'),
  ];

  @override
  State<YiraStorySplash> createState() => _YiraStorySplashState();
}

/// One story slide: a photo and its caption.
class StorySlide {
  const StorySlide(this.image, this.icon, this.tint, this.title, this.subtitle);
  final String image;
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
}

class _YiraStorySplashState extends State<YiraStorySplash> with TickerProviderStateMixin {
  late final AnimationController _story = AnimationController(
    vsync: this,
    duration: YiraStorySplash.slideLength * YiraStorySplash.slides.length,
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _startScene();
    });
  late final AnimationController _scene = AnimationController(vsync: this, duration: YiraStorySplash.sceneLength)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _complete();
    });
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 60));

  bool _storyVisible = false;
  bool _storyStarted = false;
  bool _sceneStarted = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _storyVisible = widget.playStory;
    if (!widget.playStory) _startScene();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.playStory && !_storyStarted) {
      _storyStarted = true;
      _prepareStory();
    }
  }

  /// Decode the photos first so no slide flashes in blank; never wait long.
  Future<void> _prepareStory() async {
    try {
      await Future.wait([
        for (final slide in YiraStorySplash.slides) precacheImage(AssetImage(slide.image), context),
      ]).timeout(const Duration(milliseconds: 1500));
    } catch (_) {
      // Start anyway; a late photo simply fades in.
    }
    if (mounted && !_sceneStarted) _story.forward();
  }

  void _startScene() {
    if (_sceneStarted || !mounted) return;
    _sceneStarted = true;
    _story.stop();
    setState(() => _storyVisible = false);
    _scene.forward();
    _spin.repeat();
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _story.dispose();
    _scene.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF16171B),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _OrbitScene(scene: _scene, spin: _spin),
          if (widget.playStory)
            IgnorePointer(
              ignoring: !_storyVisible,
              child: AnimatedOpacity(
                opacity: _storyVisible ? 1 : 0,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOut,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _startScene,
                  child: _StoryView(story: _story, onSkip: _startScene),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The five photo slides with progress, zoom and captions.
class _StoryView extends StatelessWidget {
  const _StoryView({required this.story, required this.onSkip});

  final Animation<double> story;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final slides = YiraStorySplash.slides;
    final padding = MediaQuery.paddingOf(context);
    return ColoredBox(
      color: const Color(0xFF0E0F12),
      child: AnimatedBuilder(
        animation: story,
        builder: (context, _) {
          final position = story.value * slides.length; // 0..5
          final index = position.floor().clamp(0, slides.length - 1);
          final local = (position - index).clamp(0.0, 1.0);

          Widget photo(int i, double opacity) {
            // Slow zoom across the slide's life, a little past its end for the cross-fade.
            final life = ((position - i) / 1.25).clamp(0.0, 1.0);
            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: 1.04 + 0.07 * Curves.easeOut.transform(life),
                alignment: const Alignment(0, -0.2),
                child: Image.asset(
                  slides[i].image,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.4),
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                ),
              ),
            );
          }

          final fadeIn = index == 0 ? 1.0 : Curves.easeOut.transform((local / 0.28).clamp(0.0, 1.0));
          final captionIn = Curves.easeOutCubic.transform((local / 0.32).clamp(0.0, 1.0));

          return Stack(
            fit: StackFit.expand,
            children: [
              if (index > 0) photo(index - 1, 1),
              photo(index, fadeIn),
              // Legibility: soft shade at the top and a deeper one at the bottom.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x99000000), Color(0x00000000), Color(0x00000000), Color(0xE60E0F12)],
                    stops: [0, 0.2, 0.62, 0.9],
                  ),
                ),
              ),
              // Progress, one segment per slide.
              Positioned(
                left: 16,
                right: 16,
                top: padding.top + 10,
                child: Row(
                  children: [
                    for (var i = 0; i < slides.length; i++) ...[
                      if (i > 0) const SizedBox(width: 5),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            value: i < index ? 1 : (i == index ? local : 0),
                            backgroundColor: Colors.white.withValues(alpha: 0.25),
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: padding.top + 22,
                left: 16,
                child: SvgPicture.asset(YiraStorySplash.logoAsset, height: 26, semanticsLabel: 'Yira.ai'),
              ),
              Positioned(
                top: padding.top + 18,
                right: 8,
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: padding.bottom + 28,
                child: Opacity(
                  opacity: captionIn,
                  child: Transform.translate(
                    offset: Offset(0, (1 - captionIn) * 14),
                    child: _Caption(slide: slides[index]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.slide});
  final StorySlide slide;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1B20).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF30333A), Color(0xFF1F2126)],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                  boxShadow: [BoxShadow(color: slide.tint.withValues(alpha: 0.18), blurRadius: 14)],
                ),
                child: Icon(slide.icon, size: 22, color: slide.tint),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      slide.title,
                      style: const TextStyle(fontFamily: appPoppinFont, fontSize: 16.5, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      slide.subtitle,
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: Colors.white.withValues(alpha: 0.72)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One service tile on the ring.
class _Tile {
  const _Tile(this.icon, this.tint, this.angleDeg);
  final IconData icon;
  final Color tint;
  final double angleDeg; // 0 = top, clockwise
}

const List<_Tile> _tiles = [
  _Tile(HugeIcons.stethoscope, Color(0xFFE6E8EE), -40),
  _Tile(HugeIcons.video02, Color(0xFF8FE3DA), 20),
  _Tile(HugeIcons.testTube02, Color(0xFFD2C4FF), 80),
  _Tile(HugeIcons.riceBowl01, Color(0xFFA6EBCB), 140),
  _Tile(HugeIcons.file02, Color(0xFFE6E8EE), 200),
  _Tile(HugeIcons.cardiogram02, Color(0xFFFFA9BC), 260),
];

class _OrbitScene extends StatelessWidget {
  const _OrbitScene({required this.scene, required this.spin});

  final Animation<double> scene;
  final Animation<double> spin;

  static double _interval(double t, double begin, double end, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      final radius = math.min(w * 0.37, h * 0.2);
      final center = Offset(w / 2, h * 0.42);
      const tileSize = 54.0;

      return AnimatedBuilder(
        animation: Listenable.merge([scene, spin]),
        builder: (context, _) {
          final t = scene.value;
          final bg = _interval(t, 0, 0.18);
          final ring = _interval(t, 0.05, 0.4);
          final logo = _interval(t, 0.32, 0.78);
          final tagline = _interval(t, 0.6, 0.92);
          // Tiles sweep in from 70 degrees back and then drift slowly with the ring.
          final settle = _interval(t, 0.08, 0.7, Curves.easeOutQuart);
          final drift = spin.value * 360 * 0.15;
          final rotation = (1 - settle) * -70 + drift;

          return Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: bg,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, (center.dy / h) * 2 - 1),
                        radius: 0.95,
                        colors: const [Color(0xFF3A3E47), Color(0xFF24272D), Color(0xFF16171B)],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                ),
              ),
              // A touch of brand blue behind the logo.
              Positioned(
                left: center.dx - radius * 1.4,
                top: center.dy - radius * 1.4,
                width: radius * 2.8,
                height: radius * 2.8,
                child: Opacity(
                  opacity: bg * 0.9,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x332563EB), Color(0x002563EB)],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(painter: _RingPainter(center: center, radius: radius, progress: ring)),
              ),
              // Logo: comes into focus.
              Positioned(
                left: center.dx - radius * 0.72,
                top: center.dy - radius * 0.72,
                width: radius * 1.44,
                height: radius * 1.44,
                child: Opacity(
                  opacity: logo,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: (1 - logo) * 10 + 0.001, sigmaY: (1 - logo) * 10 + 0.001),
                    child: Center(
                      child: SvgPicture.asset(
                        YiraStorySplash.logoAsset,
                        width: radius * 1.3,
                        semanticsLabel: 'Yira.ai',
                      ),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < _tiles.length; i++)
                _buildTile(_tiles[i], i, t, rotation, center, radius, tileSize),
              Positioned(
                left: 24,
                right: 24,
                top: center.dy + radius + 72,
                child: Opacity(
                  opacity: tagline,
                  child: Transform.translate(
                    offset: Offset(0, (1 - tagline) * 10),
                    child: const Column(
                      children: [
                        Text(
                          'Your complete health, in one app.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Good health. Better intelligence.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12.5,
                            color: Color(0xFF9A9DA6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildTile(_Tile tile, int index, double t, double rotation, Offset center, double radius, double size) {
    final start = 0.08 + index * 0.06;
    final appear = _interval(t, start, start + 0.3, Curves.easeOutBack);
    final angle = (tile.angleDeg + rotation) * math.pi / 180;
    final pos = Offset(center.dx + radius * math.sin(angle), center.dy - radius * math.cos(angle));
    return Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      width: size,
      height: size,
      child: Opacity(
        opacity: appear.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.6 + 0.4 * appear,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF30333A), Color(0xFF1F2126)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 6)),
                BoxShadow(color: tile.tint.withValues(alpha: 0.10), blurRadius: 16),
              ],
            ),
            child: Icon(tile.icon, size: 24, color: tile.tint),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.center, required this.radius, required this.progress});

  final Offset center;
  final double radius;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.10 * progress);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.radius != radius || old.center != center;
}
