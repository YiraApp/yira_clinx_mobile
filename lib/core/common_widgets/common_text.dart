import 'package:flutter/material.dart';

class CommonText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  const CommonText(
      this.data, {
        super.key,
        this.style,
        this.strutStyle,
        this.textAlign = TextAlign.start,
        this.textDirection,
        this.locale,
        this.softWrap = true,
        this.overflow,
        this.textScaler,
        this.maxLines,
        this.semanticsLabel,
        this.textWidthBasis,
        this.textHeightBehavior,
        this.selectionColor,
      });

  @override
  Widget build(BuildContext context) {
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(context);

    TextStyle? effectiveTextStyle = style;
    if (style == null || style!.inherit) {
      effectiveTextStyle = defaultTextStyle.style.merge(style);
    }

    return Text(
      data,
      style: effectiveTextStyle,
      strutStyle: strutStyle,
      textAlign: textAlign ?? defaultTextStyle.textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap ?? true,
      // Never "…": text wraps in full unless a caller asks otherwise.
      overflow: overflow ?? TextOverflow.visible,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}