import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../colors/colors.dart';
import '../common_size_helpers/common_size_helpers.dart';

class CommonInputFieldUnlimited extends StatelessWidget {
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
    this.borderRadius = 8.0, // Updated baseline to standard field token radius
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTabletDevice = isTablet(context);

    // Dynamic border color strategy matching your app's style configurations
    final Color borderStrokeColor = Colors.grey.withOpacity(0.2);

    final Color focusedStrokeColor = theme.primaryColor.withOpacity(0.5);

    return TextFormField(
      onTap: onTap,
      controller: controller,
      textCapitalization: textCapitalization,
      focusNode: focusNode,
      inputFormatters: inputFormatter,
      onFieldSubmitted: (value) {
        if (requestFocusNode != null) {
          FocusScope.of(context).requestFocus(requestFocusNode);
        }
      },
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: textStyle ??
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
      cursorColor: theme.primaryColor,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      enabled: enabled,
      obscureText: obscureText,
      textAlignVertical: TextAlignVertical.top,
      maxLength: maxLength,
      expands: true,
      decoration: InputDecoration(
        labelStyle: labelStyle,
        hintText: hintText,
        hintStyle: TextStyle(
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
        fillColor:isDark?darkModeInnerCardColor: Colors.transparent,
        suffixStyle: TextStyle(
          color: isDark ? Colors.grey : Colors.grey[500],
          fontSize: isTabletDevice
              ? displayWidth(context) * 0.018
              : displayWidth(context) * 0.03,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(
          prefixIcon,
          color: isDark ? Colors.white70 : Colors.grey,
        ),
        suffixIcon: suffixIcon ??
            (obscureText
                ? GestureDetector(
              onTap: () {},
              child: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: isDark ? Colors.white70 : Colors.black,
              ),
            )
                : null),
        errorStyle: TextStyle(
          color: errorTextStyleColor,
          fontSize: isTabletDevice
              ? displayWidth(context) * 0.018
              : displayWidth(context) * 0.025,
        ),
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),

        // --- BEAUTIFUL OUTER STROKE BORDERS INTERFACE SYSTEM ---
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          borderSide: BorderSide(color: borderStrokeColor, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          borderSide: BorderSide(color: borderStrokeColor, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          borderSide: BorderSide(color: focusedStrokeColor, width: 0.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 0.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 0.5),
        ),
      ),
    );
  }
}