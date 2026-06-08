
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yiraclinics/core/common_input_fields/common_input_field.dart';

import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';

class ConfirmationCodeSection extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String generatedCode;
  final ValueChanged<String> onChanged;

  const ConfirmationCodeSection({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.generatedCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = displayWidth(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
final isTab = isTablet(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Confirmation code : ',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize:isTab? width * 0.022: width * 0.04,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            Text(
              generatedCode,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab? width * 0.022:width * 0.04,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: fieldSpace),
        CommonInputAddRecordTextField(
          controller: controller,
          focusNode: focusNode,
          borderRadius:  fieldBorderRadius,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.number,
          hintText: 'Enter 6-digit code',
          labelText: 'Enter confirmation code to confirm',
          onChanged: (val) {
            onChanged(val);
            if (val.length == 6) focusNode.unfocus();
          },
          inputFormatter: [
            LengthLimitingTextInputFormatter(6),
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
      ],
    );
  }
}