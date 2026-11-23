import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'yira_story_splash.dart';

/// The launch splash: the Yira brand video (1080x1920, 7 s, no sound).
///
/// The first launch plays all of it: four feature stories, then the service
/// tiles settling on a ring around the Yira.ai logo. Skip jumps to that logo
/// ending. Later launches play only the logo ending (about 2 s).
///
/// It starts on the same dark colour as the native launch screen, so there is
/// no flash. If the video can't play, the app-drawn logo scene stands in.
class YiraVideoSplash extends StatefulWidget {
  const YiraVideoSplash({super.key, this.fullVideo = true, this.onComplete});

  /// The whole video (first launch) or only the logo ending.
  final bool fullVideo;

  /// Fires once, when the video ends or the fallback scene finishes.
  final VoidCallback? onComplete;

  static const String videoAsset = 'assets/videos/yira_splash.mp4';

  /// The video's last frame, for screens shown right after the splash.
  static const String endFrameAsset = 'assets/images/splash_end.jpg';

  /// Where the stories end and the logo scene begins.
  static const Duration logoSceneStart = Duration(milliseconds: 4800);

  static const Color background = Color(0xFF16171B);

  @override
  State<YiraVideoSplash> createState() => _YiraVideoSplashState();
}

class _YiraVideoSplashState extends State<YiraVideoSplash> {
  // Mixes with other audio so opening the app doesn't pause the user's music.
  late final VideoPlayerController _controller = VideoPlayerController.asset(
    YiraVideoSplash.videoAsset,
    videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
  );
  bool _ready = false;
  bool _fallback = false;
  bool _done = false;
  bool _skipped = false;
  Timer? _startTimeout;

  @override
  void initState() {
    super.initState();
    // A video that hasn't started within 3 s isn't coming: show the drawn scene instead.
    _startTimeout = Timer(const Duration(seconds: 3), () {
      if (!_ready) _useFallback();
    });
    _start();
  }

  Future<void> _start() async {
    try {
      await _controller.initialize();
      if (!mounted || _fallback) return;
      await _controller.setVolume(0);
      if (!widget.fullVideo) await _controller.seekTo(YiraVideoSplash.logoSceneStart);
      _controller.addListener(_onTick);
      await _controller.play();
      _startTimeout?.cancel();
      if (mounted) setState(() => _ready = true);
    } catch (error) {
      debugPrint('Splash video could not play: $error');
      _useFallback();
    }
  }

  void _onTick() {
    final value = _controller.value;
    if (value.hasError) {
      _useFallback();
      return;
    }
    final duration = value.duration;
    final ended = value.isCompleted ||
        (duration > Duration.zero && value.position >= duration - const Duration(milliseconds: 50));
    if (ended) _finish();
  }

  void _useFallback() {
    if (!mounted || _fallback || _done) return;
    _startTimeout?.cancel();
    _controller.removeListener(_onTick);
    setState(() => _fallback = true);
  }

  void _skip() {
    if (_skipped || !_ready) return;
    setState(() => _skipped = true);
    if (_controller.value.position < YiraVideoSplash.logoSceneStart) {
      _controller.seekTo(YiraVideoSplash.logoSceneStart);
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _controller.removeListener(_onTick);
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _startTimeout?.cancel();
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_fallback) {
      return YiraStorySplash(playStory: false, onComplete: _finish);
    }
    final size = _controller.value.size;
    final showSkip = widget.fullVideo && _ready && !_skipped;
    return ColoredBox(
      color: YiraVideoSplash.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_ready && size.width > 0 && size.height > 0)
            // Fills the screen like the native launch screen; the sides crop on wider screens.
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(width: size.width, height: size.height, child: VideoPlayer(_controller)),
            ),
          if (showSkip)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                  child: Semantics(
                    button: true,
                    label: 'Skip intro',
                    child: TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: const Size(64, 36),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Skip'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The splash's last frame, still: the backdrop while the app finishes loading
/// after the splash, so the logo stays exactly where the video left it.
class YiraSplashEndFrame extends StatelessWidget {
  const YiraSplashEndFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: YiraVideoSplash.background,
      child: SizedBox.expand(
        child: Image(
          image: AssetImage(YiraVideoSplash.endFrameAsset),
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
