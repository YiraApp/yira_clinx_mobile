import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/constants.dart';
import '../../../data/models/questionnaires/questionnaire_models.dart';

/// Colours and text for the questionnaire screens: black and white with one
/// blue, charcoal in dark mode.
class QUi {
  QUi._();

  static const Color blue = Color(0xFF2563EB);
  static const Color red = Color(0xFFDC2626);

  static Color background(bool isDark) => isDark ? const Color(0xFF121212) : const Color(0xFFF6F7F9);
  static Color card(bool isDark) => isDark ? const Color(0xFF232323) : Colors.white;
  static Color sunken(bool isDark) => isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF6F7F9);
  static Color line(bool isDark) => isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE6E6E6);
  static Color ink(bool isDark) => isDark ? Colors.white : const Color(0xFF111111);
  static Color body(bool isDark) => isDark ? Colors.white70 : const Color(0xFF3F3F3F);
  static Color muted(bool isDark) => isDark ? Colors.white60 : const Color(0xFF6B6B6B);
  static Color blueSoft(bool isDark) => blue.withValues(alpha: isDark ? 0.18 : 0.08);

  static TextStyle text(double size, FontWeight weight, Color color, {double? height}) =>
      TextStyle(fontFamily: appPoppinFont, fontSize: size, fontWeight: weight, color: color, height: height);

  static String day(DateTime? d) => d == null ? '' : DateFormat('d MMM yyyy').format(d);
  static String dayTime(DateTime? d) => d == null ? '' : DateFormat('d MMM yyyy, h:mm a').format(d);
}

/// A white (charcoal) card with a hairline border.
class QCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const QCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16), this.borderColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: QUi.card(isDark),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor ?? QUi.line(isDark)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A small rounded label. Blue when [accent], grey otherwise.
class QChip extends StatelessWidget {
  final String label;
  final bool accent;
  final IconData? icon;

  const QChip(this.label, {super.key, this.accent = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accent ? QUi.blue : QUi.muted(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accent ? QUi.blueSoft(isDark) : QUi.sunken(isDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 4)],
          Text(label, style: QUi.text(11, FontWeight.w600, color)),
        ],
      ),
    );
  }
}

/// One question and its answer, read-only. [changed] marks an answer that
/// differs from the attempt before.
class QAnswerTile extends StatelessWidget {
  final int number;
  final SubmittedAnswer answer;
  final bool changed;

  const QAnswerTile({super.key, required this.number, required this.answer, this.changed = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final empty = answer.display.trim().isEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: changed ? QUi.blueSoft(isDark) : QUi.sunken(isDark),
        borderRadius: BorderRadius.circular(12),
        border: changed ? Border.all(color: QUi.blue.withValues(alpha: 0.35)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('$number. ${answer.questionText}', style: QUi.text(12.5, FontWeight.w500, QUi.muted(isDark), height: 1.35)),
              ),
              if (changed) ...[const SizedBox(width: 8), const QChip('Changed', accent: true)],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            empty ? 'Not answered' : answer.display,
            style: QUi.text(14, empty ? FontWeight.w400 : FontWeight.w600, empty ? QUi.muted(isDark) : QUi.ink(isDark), height: 1.35),
          ),
        ],
      ),
    );
  }
}

/// Centered message for empty and error states.
class QMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const QMessage({super.key, required this.icon, required this.title, this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: QUi.sunken(isDark), shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: QUi.ink(isDark)),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: QUi.text(16, FontWeight.w700, QUi.ink(isDark))),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(message!, textAlign: TextAlign.center, style: QUi.text(13, FontWeight.w400, QUi.muted(isDark), height: 1.45)),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
