import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../yira_splash_screen.dart';

/// Interactive preview screen that allows choosing between 10 animation styles.
class SplashPreviewScreen extends StatefulWidget {
  const SplashPreviewScreen({super.key});

  @override
  State<SplashPreviewScreen> createState() => _SplashPreviewScreenState();
}

class _SplashPreviewScreenState extends State<SplashPreviewScreen> {
  int _replayKey = 0;
  SplashAnimationStyle _selectedStyle = SplashAnimationStyle.cosmicOrbit;

  void _replay() {
    setState(() {
      _replayKey++;
    });
  }

  void _selectStyle(SplashAnimationStyle style) {
    setState(() {
      _selectedStyle = style;
      _replayKey++; // Replay immediately with the new style
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // Active splash animation
          KeyedSubtree(
            key: ValueKey('${_selectedStyle.name}_$_replayKey'),
            child: YiraSplashScreen(
              animationStyle: _selectedStyle,
            ),
          ),

          // Top Header Bar: Replay + Close
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Replay Button
                GestureDetector(
                  onTap: _replay,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF2563EB).withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.replay_rounded,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Replay',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Close Button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom 10 Animation Styles Selector Bar
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 85,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Active style title pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    'Active: ${_selectedStyle.title} — ${_selectedStyle.description}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                      color: Colors.white,
                    ),
                  ),
                ),

                // Horizontal scrollable chips for the 10 animation styles
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: SplashAnimationStyle.values.length,
                    itemBuilder: (context, index) {
                      final style = SplashAnimationStyle.values[index];
                      final isSelected = style == _selectedStyle;

                      return GestureDetector(
                        onTap: () => _selectStyle(style),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF1D4ED8)
                                  : const Color(0xFF2563EB)
                                      .withValues(alpha: 0.25),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                        .withValues(alpha: 0.35)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: isSelected ? 10 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${index + 1}. ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                  color: isSelected
                                      ? Colors.white70
                                      : const Color(0xFF2563EB),
                                ),
                              ),
                              Text(
                                style.title,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontFamily: 'Inter',
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
