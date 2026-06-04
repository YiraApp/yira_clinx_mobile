import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class TermsAndPrivacyCheckbox extends StatelessWidget {
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  const TermsAndPrivacyCheckbox({
    super.key,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = displayWidth(context);
    final isTab = isTablet(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!isChecked),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isChecked ? Theme.of(context).colorScheme.primary : Colors.transparent,
              border: Border.all(
                color: isChecked ? Colors.transparent : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: isChecked
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: 'By clicking on confirm & close you accept our ',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: isTab ? width * 0.018 : width * 0.032,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Navigate to Terms WebView / Screen
                      },
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Navigate to Privacy Policy WebView / Screen
                      },
                  ),
                  const TextSpan(text: ' to safely purge your practice records.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}