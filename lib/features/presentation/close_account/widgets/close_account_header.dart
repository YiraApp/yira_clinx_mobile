
import 'package:flutter/material.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';

class CloseAccountHeader extends StatelessWidget {
  const CloseAccountHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final width = displayWidth(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Image.asset(
          'assets/images/ic_delete_account.png',
          height: displayHeight(context) * 0.18,
          fit: BoxFit.contain,
        ),
        SizedBox(height: displayHeight(context) * 0.03),
        Text(
          'Are you sure you want to close\nyour account?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: width * 0.045,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'This operation is permanent and cannot be undone.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: width * 0.034,
            fontWeight: FontWeight.w400,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}