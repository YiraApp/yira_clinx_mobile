import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../colors/colors.dart';
import '../common_size_helpers/common_size_helpers.dart';
import '../constants/constants.dart';

class CommonInputAddRecordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final bool? isRecord;
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
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatter;

  const CommonInputAddRecordTextField({
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
    this.isRecord = false,
  });

  @override
  State<CommonInputAddRecordTextField> createState() => _CommonInputAddRecordTextFieldState();
}

class _CommonInputAddRecordTextFieldState extends State<CommonInputAddRecordTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final bool isTab = isTablet(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Fallback logic cleanly extracted
    final double computedRadius = widget.borderRadius ?? fieldBorderRadius ?? 8.0;

    // Adaptive Border Color Matrices
    final Color inactiveBorderColor = isDark ? darkModeBorderColor : lightModeBorderColor;
    final Color activeBorderColor = isDark ? darkModeBorderFocusedColor : lightModeBorderFocusedColor;
    final Color disabledBorderColor = isDark ? darkModeBorderDisabledColor : lightModeBorderDisabledColor;

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
            fontFamily: appPoppinFont,
            decorationThickness: 0,
            decoration: TextDecoration.none,
            fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.035,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w400,
          ),
      cursorColor: activeBorderColor,
      validator: widget.validator,
      onChanged: widget.onChanged,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      obscureText: _obscureText,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        labelStyle: widget.labelStyle,
        hintText: widget.hintText,
        hintStyle: widget.hintStyle ?? TextStyle(
          decoration: TextDecoration.none,
          fontFamily: appPoppinFont,
          fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.032,
          color: isDark ? Colors.white.withOpacity(0.5) : textLightModeColor.withOpacity(0.5),
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        suffixStyle: TextStyle(
            fontFamily: appPoppinFont,
            color: isDark ? Colors.grey : Colors.grey[500],
            fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
            fontWeight: FontWeight.w500),
        prefixIcon: widget.prefixIcon,
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
        fillColor: isDark ? darkModeCardColor.withOpacity(0.8) : lightModeTextFieldBgColor,
        errorStyle: TextStyle(
            fontFamily: appPoppinFont,
            color: errorTextStyleColor,
            fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.025),
        contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

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