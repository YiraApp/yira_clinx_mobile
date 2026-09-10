import 'package:flutter/material.dart';
import '../../../../../core/constants/constants.dart';

/// An ultra-compact, sleek glassmorphic pill badge representing a vital reading.
/// Designed to float alongside the 3D human body without obscuring anatomical features.
class VitalInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String status;
  final IconData icon;
  final Color accentColor;
  final double opacity;
  final bool isSelected;
  final VoidCallback? onTap;

  const VitalInfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
    required this.icon,
    required this.accentColor,
    this.opacity = 1.0,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValue = value != '--' && value.isNotEmpty;

    // Display string: e.g. "98.6°F", "120/80", "72 BPM", "98%"
    final String displayVal = hasValue ? value : '--';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: opacity.clamp(0.0, 1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? (isSelected
                    ? accentColor.withValues(alpha: 0.22)
                    : const Color(0xFF1E293B).withValues(alpha: 0.88))
                : (isSelected
                    ? accentColor.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.94)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: accentColor.withValues(alpha: isDark ? 0.35 : 0.22),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                )
              else
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : const Color(0xFF64748B).withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mini colored icon badge
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.22 : 0.14),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 11,
                    color: accentColor,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              // Value + Unit
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        displayVal,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hasValue
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                        ),
                      ),
                      if (hasValue && unit.isNotEmpty && !displayVal.contains(unit)) ...[
                        const SizedBox(width: 2),
                        Text(
                          unit,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
