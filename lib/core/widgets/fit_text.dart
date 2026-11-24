import 'package:flutter/material.dart';

/// Shows the whole text: it is never cut with "…" or clipped.
///
/// Use it where the box has a fixed size (app bar titles, buttons with a set
/// height, tiles, tab labels). The text wraps; when it would still not fit in
/// [maxLines] lines or in the height the box allows, the font gets a little
/// smaller (down to [minFontSize]). If even that is not enough, the text keeps
/// wrapping instead of being cut.
class FitText extends StatelessWidget {
  const FitText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.minFontSize = 9,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// Lines the text should fit in before the font shrinks. Null means as many
  /// as the height allows.
  final int? maxLines;
  final double minFontSize;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    return LayoutBuilder(builder: (context, box) {
      var size = base.fontSize ?? 14;
      if (box.hasBoundedWidth) {
        while (size > minFontSize && !_fits(base.copyWith(fontSize: size), box, scaler, direction)) {
          size -= 0.5;
        }
      }
      return Text(
        text,
        style: base.copyWith(fontSize: size),
        textAlign: textAlign,
        softWrap: true,
        overflow: TextOverflow.visible,
      );
    });
  }

  bool _fits(TextStyle style, BoxConstraints box, TextScaler scaler, TextDirection direction) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      textAlign: textAlign ?? TextAlign.start,
    )..layout(maxWidth: box.maxWidth);
    final lines = painter.computeLineMetrics().length;
    final fits = painter.height <= box.maxHeight + 0.5 && (maxLines == null || lines <= maxLines!);
    painter.dispose();
    return fits;
  }
}
