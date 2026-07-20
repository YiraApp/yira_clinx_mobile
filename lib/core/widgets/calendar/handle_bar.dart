

import 'package:flutter/material.dart';


class HandleBar extends StatelessWidget {

  const HandleBar({
    super.key,
    this.decoration,
    this.margin = const EdgeInsets.only(
      top: 0.0,bottom: 8
    ),
    this.onPressed, required this.handlerColor,
  });

  final BoxDecoration? decoration;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onPressed;
final Color handlerColor;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.translucent,
      child: Container(
        margin: margin,
        alignment: Alignment.center,
        child: FractionallySizedBox(
          widthFactor: 0.05,
          child: Container(
            height: 4.0,
            decoration: decoration ??
                BoxDecoration(
                  color: handlerColor,
                  borderRadius: BorderRadius.circular(2.0),
                ),
          ),
        ),
      ),
    );
  }
}
