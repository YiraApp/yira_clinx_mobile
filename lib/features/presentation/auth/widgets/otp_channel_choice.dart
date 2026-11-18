import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/auth/login_bloc/login_bloc.dart';

/// "Get the code on: WhatsApp | SMS" for mobile numbers outside India.
/// Shows nothing for +91, where the code always goes by SMS.
class OtpChannelChoice extends StatelessWidget {
  const OtpChannelChoice({
    super.key,
    required this.countryCode,
    required this.channel,
    required this.onChanged,
  });

  final String countryCode;
  final String channel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (LoginBloc.isIndianCode(countryCode)) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget option(String value, String label, IconData icon) {
      final selected = channel == value;
      final accent = isDark ? Colors.white : primaryColor;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          child: InkWell(
            key: ValueKey('otp-channel-$value'),
            onTap: () => onChanged(value),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: isDark ? 0.12 : 0.06)
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? accent : (isDark ? Colors.white24 : const Color(0xFFD9D9DC)),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: selected ? accent : (isDark ? Colors.white60 : const Color(0xFF6E6E70))),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? accent : (isDark ? Colors.white70 : const Color(0xFF474749)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get the code on',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF6E6E70),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              option(LoginBloc.otpChannelWhatsApp, 'WhatsApp', CupertinoIcons.chat_bubble_2),
              const SizedBox(width: 10),
              option(LoginBloc.otpChannelSms, 'SMS', CupertinoIcons.chat_bubble_text),
            ],
          ),
        ],
      ),
    );
  }
}
