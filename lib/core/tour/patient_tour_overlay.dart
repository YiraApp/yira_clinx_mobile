import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'patient_tour_model.dart';

class PatientTourOverlay extends StatefulWidget {
  final List<PatientTourStep> steps;
  final int currentStepIndex;
  final bool dontShowAgain;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final ValueChanged<bool> onDontShowAgainChanged;

  const PatientTourOverlay({
    super.key,
    required this.steps,
    required this.currentStepIndex,
    required this.dontShowAgain,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
    required this.onDontShowAgainChanged,
  });

  @override
  State<PatientTourOverlay> createState() => _PatientTourOverlayState();
}

class _PatientTourOverlayState extends State<PatientTourOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Rect? _getTargetRect(GlobalKey? key, EdgeInsets padding) {
    if (key == null || key.currentContext == null) return null;
    try {
      final ctx = key.currentContext!;
      if (!ctx.mounted) return null;
      final renderBox = ctx.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize || renderBox.size.isEmpty) return null;
      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero);
      return Rect.fromLTWH(
        offset.dx - padding.left,
        offset.dy - padding.top,
        size.width + padding.horizontal,
        size.height + padding.vertical,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);
    final size = MediaQuery.of(context).size;
    final step = widget.steps[widget.currentStepIndex];
    final isFirstStep = widget.currentStepIndex == 0;
    final isLastStep = widget.currentStepIndex == widget.steps.length - 1;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final targetRect = _getTargetRect(step.targetKey, step.targetPadding);
        final scale = _pulseAnimation.value;

        // Determine card positioning (above or below the target)
        bool placeCardBelow = true;
        if (targetRect != null) {
          final spaceBelow = size.height - targetRect.bottom;
          final spaceAbove = targetRect.top;
          if (step.position == TourCardPosition.top) {
            placeCardBelow = false;
          } else if (step.position == TourCardPosition.bottom) {
            placeCardBelow = true;
          } else {
            placeCardBelow = spaceBelow >= 290 || spaceBelow >= spaceAbove;
          }
        }

        final double cardLeft = isTab ? size.width * 0.15 : 16.0;
        final double cardRight = isTab ? size.width * 0.15 : 16.0;
        final double cardWidth = size.width - cardLeft - cardRight;

        // Calculate pointer arrow X position relative to the screen
        double arrowTargetX = size.width / 2;
        if (targetRect != null) {
          arrowTargetX = targetRect.center.dx.clamp(cardLeft + 24, size.width - cardRight - 24);
        }

        double cardTop = (size.height - 280) / 2;
        if (targetRect != null) {
          if (placeCardBelow) {
            cardTop = math.min(targetRect.bottom + 14, size.height - 310);
          } else {
            cardTop = math.max(MediaQuery.of(context).padding.top + 16, targetRect.top - 290);
          }
        }

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // 1. Semi-transparent cutout backdrop (Spotlight Mask)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: CustomPaint(
                  size: size,
                  painter: _SpotlightPainter(
                    targetRect: targetRect,
                    borderRadius: step.borderRadius,
                  ),
                ),
              ),

              // 2. Animated Pulsing Halo Ring around the target widget
              if (targetRect != null)
                Positioned.fromRect(
                  rect: targetRect.inflate(4 * scale),
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(step.borderRadius + 4),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.7 * (1.1 - (scale - 0.95))),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.35),
                            blurRadius: 12 * scale,
                            spreadRadius: 2.5 * scale,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 3. Pointer Arrow Indicator pointing directly to target
              if (targetRect != null)
                Positioned(
                  left: arrowTargetX - 10,
                  top: placeCardBelow ? (cardTop - 9) : (targetRect.top - 11),
                  child: CustomPaint(
                    size: const Size(20, 10),
                    painter: _ArrowPainter(
                      pointingUp: placeCardBelow,
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),

              // 4. Floating Spotlight Tooltip Card
              Positioned(
                left: cardLeft,
                width: cardWidth,
                top: cardTop,
                child: _buildTourCard(
                  context,
                  step,
                  isDark,
                  isTab,
                  isFirstStep,
                  isLastStep,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTourCard(
    BuildContext context,
    PatientTourStep step,
    bool isDark,
    bool isTab,
    bool isFirstStep,
    bool isLastStep,
  ) {
    final progress = (widget.currentStepIndex + 1) / widget.steps.length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent Progress Strip
            LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 3.5,
            ),

            Padding(
              padding: EdgeInsets.all(isTab ? 20.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Badge & Icon Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(step.icon, size: 14, color: primaryColor),
                            const SizedBox(width: 6),
                            Text(
                              "STEP ${widget.currentStepIndex + 1} OF ${widget.steps.length}",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? 11.5 : 10.5,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onSkip();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Skip Tour",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 12 : 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.close_rounded,
                                size: 15,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Step Title
                  Text(
                    step.title,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 17.5 : 15.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Rich Patient Guidance Description
                  Text(
                    step.description,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 13.5 : 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom Action Bar: [x] Don't show again | Back | Next / Finish
                  Row(
                    children: [
                      // "Don't show again" Checkbox
                      InkWell(
                        onTap: () {
                          widget.onDontShowAgainChanged(!widget.dontShowAgain);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: Checkbox(
                                value: widget.dontShowAgain,
                                onChanged: (val) {
                                  widget.onDontShowAgainChanged(val ?? false);
                                },
                                activeColor: primaryColor,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Don't show again",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? 11.5 : 10.5,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Back Button
                      if (!isFirstStep) ...[
                        InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onBack();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTab ? 16 : 12,
                              vertical: isTab ? 9 : 7,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Text(
                              "Back",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? 12.5 : 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Next / Finish Primary Button
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onNext();
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTab ? 18 : 14,
                            vertical: isTab ? 10 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLastStep ? "Finish Tour" : "Next",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 13 : 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                isLastStep ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

/// Custom painter that creates the dark spotlight overlay with a rounded cutout
class _SpotlightPainter extends CustomPainter {
  final Rect? targetRect;
  final double borderRadius;

  _SpotlightPainter({
    required this.targetRect,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.76)
      ..style = PaintingStyle.fill;

    if (targetRect == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);
      return;
    }

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(targetRect!, Radius.circular(borderRadius)));

    // Combine by difference to leave the clear cutout
    final combined = Path.combine(PathOperation.difference, path, cutoutPath);
    canvas.drawPath(combined, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || oldDelegate.borderRadius != borderRadius;
  }
}

/// Painter for pointer arrow triangle pointing at the spotlight target
class _ArrowPainter extends CustomPainter {
  final bool pointingUp;
  final Color color;
  final Color borderColor;

  _ArrowPainter({
    required this.pointingUp,
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path();
    if (pointingUp) {
      // Triangle pointing UP
      path.moveTo(0, size.height);
      path.lineTo(size.width / 2, 0);
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      // Triangle pointing DOWN
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
      path.close();
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) {
    return oldDelegate.pointingUp != pointingUp ||
        oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor;
  }
}
