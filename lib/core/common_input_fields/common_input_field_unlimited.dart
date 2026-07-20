import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../colors/colors.dart';
import '../common_size_helpers/common_size_helpers.dart';

class CommonInputFieldUnlimited extends StatefulWidget {
  final TextEditingController? controller;
  final TextCapitalization textCapitalization;
  final String? hintText;
  final String? labelText;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final double? borderRadius;
  final FocusNode? requestFocusNode;
  final EdgeInsetsGeometry? contentPadding;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final int? maxLength;
  final bool readOnly;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Function()? onTap;
  final bool isTab;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatter;

  const CommonInputFieldUnlimited({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.textStyle,
    this.hintStyle,
    this.labelStyle,
    this.borderRadius,
    this.contentPadding,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.requestFocusNode,
    this.focusNode,
    this.maxLength,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatter,
    this.isTab = false,
  });

  @override
  State<CommonInputFieldUnlimited> createState() => _CommonInputFieldUnlimitedState();
}

class _CommonInputFieldUnlimitedState extends State<CommonInputFieldUnlimited> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTabletDevice = isTablet(context);

    // Synchronized border radius fallback logic
    final double computedRadius = widget.borderRadius ?? fieldBorderRadius ?? 8.0;

    // Adaptive System Colors Matrix matching your precise dark/light choices
    final Color inactiveBorderColor = isDark ? darkModeBorderColor : lightModeBorderColor;
    final Color activeBorderColor = isDark ? darkModeBorderFocusedColor : lightModeBorderFocusedColor;
    final Color disabledBorderColor = isDark ? darkModeBorderDisabledColor : lightModeBorderDisabledColor;

    final Color surfaceColor = isDark
        ? darkModeCardColor.withOpacity(0.8)
        : lightModeTextFieldBgColor;

    return TextFormField(
      onTap: widget.onTap,
      controller: widget.controller,
      textCapitalization: widget.textCapitalization,
      focusNode: widget.focusNode,
      inputFormatters: widget.inputFormatter,
      onFieldSubmitted: (value) {
        if (widget.requestFocusNode != null) {
          FocusScope.of(context).requestFocus(widget.requestFocusNode);
        }
      },
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      style: widget.textStyle ??
          TextStyle(
            decorationThickness: 0,
            decoration: TextDecoration.none,
            fontFamily: appPoppinFont,
            fontSize: isTabletDevice
                ? displayWidth(context) * 0.018
                : displayWidth(context) * 0.035,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w400,
          ),
      maxLines: null,
      cursorColor: activeBorderColor,
      validator: widget.validator,
      onChanged: widget.onChanged,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      obscureText: _obscureText,
      textAlignVertical: TextAlignVertical.top,
      maxLength: widget.maxLength,
      expands: true,
      decoration: InputDecoration(
        labelStyle: widget.labelStyle,
        hintText: widget.hintText,
        hintStyle: widget.hintStyle ?? TextStyle(
          decoration: TextDecoration.none,
          fontFamily: appPoppinFont,
          fontSize: isTabletDevice
              ? displayWidth(context) * 0.018
              : displayWidth(context) * 0.032,
          color: isDark
              ? Colors.white.withOpacity(0.5)
              : textLightModeColor.withOpacity(0.5),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: surfaceColor,
        suffixStyle: TextStyle(
          fontFamily: appPoppinFont,
          color: isDark ? Colors.grey : Colors.grey[500],
          fontSize: isTabletDevice
              ? displayWidth(context) * 0.018
              : displayWidth(context) * 0.03,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(
          widget.prefixIcon,
          color: isDark ? Colors.white54 : Colors.grey,
        ),
        suffixIcon: widget.suffixIcon ??
            (widget.obscureText
                ? GestureDetector(
              onTap: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
              child: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            )
                : null),
        errorStyle: TextStyle(
          fontFamily: appPoppinFont,
          color: errorTextStyleColor,
          fontSize: isTabletDevice
              ? displayWidth(context) * 0.018
              : displayWidth(context) * 0.025,
        ),
        contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        // --- Standardized Global Borders Matrix System ---
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(computedRadius),
          borderSide: BorderSide(color: inactiveBorderColor, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(computedRadius),
          borderSide: BorderSide(color: inactiveBorderColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(computedRadius),
          borderSide: BorderSide(color: activeBorderColor, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(computedRadius),
          borderSide: BorderSide(color: disabledBorderColor, width: 1.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(computedRadius),
          borderSide: const BorderSide(color: errorTextStyleColor, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(computedRadius),
          borderSide: const BorderSide(color: errorTextStyleColor, width: 1.5),
        ),
      ),
    );
  }
}