import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../colors/colors.dart';
import '../common_size_helpers/common_size_helpers.dart';

import '../constants/constants.dart';
class CommonInputAddRecordTextField extends StatelessWidget {
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
    this.borderRadius = 2.0,
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
    this.isRecord = false
  });

  @override
  Widget build(BuildContext context) {
   bool isTab= isTablet(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
      style:
          textStyle ??
              TextStyle(
                fontFamily: appPoppinFont,
                decorationThickness: 0,
                decoration: TextDecoration.none,
            fontSize: isTab
                ? displayWidth(context) * 0.018
                : displayWidth(context) * 0.035,
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w400,
          ),

      cursorColor: theme.primaryColor,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      enabled: enabled,
      obscureText: obscureText,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelStyle: labelStyle,
        hintText: hintText,

        hintStyle: TextStyle(
          decoration: TextDecoration.none,
          fontFamily: appPoppinFont,
          fontSize: isTab? displayWidth(context) * 0.018:displayWidth(context) * 0.032,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.5)
              : textLightModeColor.withOpacity(0.5),
          fontWeight: FontWeight.w400,
        ),
       filled: true,
        suffixStyle: TextStyle(
            fontFamily: appPoppinFont,

            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey
                : Colors.grey[500],
            fontSize: isTab? displayWidth(context) * 0.018:displayWidth(context) * 0.03,

            fontWeight: FontWeight.w500),
        prefixIcon:prefixIcon,
        suffixIcon: suffixIcon ?? (obscureText
            ? GestureDetector(
          onTap: () {

          },
          child: Icon(
            obscureText
                ? Icons.visibility_off
                : Icons.visibility,
            color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.black,
          ),
        )
            : null),
        fillColor:
        Theme.of(context).brightness == Brightness.dark
            ?isRecord ?? false? darkModeFieldBgColor.withOpacity(0.3): darkModeFieldBgColor
            : lightModeTextFieldBgColor,
        errorStyle: TextStyle(
            fontFamily: appPoppinFont,
            color: errorTextStyleColor,
            fontSize: isTab? displayWidth(context) * 0.018:displayWidth(context) * 0.025),
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius == null? fieldBorderRadius:borderRadius ?? 8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius == null? fieldBorderRadius:borderRadius ?? 8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius == null? fieldBorderRadius:borderRadius ?? 8),
            borderSide: BorderSide.none
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius == null? fieldBorderRadius:borderRadius ?? 8),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 0.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius == null? fieldBorderRadius:borderRadius ?? 8),
          borderSide: const BorderSide(
            color: Colors.red, // Color for error border when focused
            width: 0.5,
          ),
        ),
      ),
    );
  }
}
