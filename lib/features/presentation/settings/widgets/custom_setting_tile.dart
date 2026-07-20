
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class CustomSettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  final bool isTab;

  const CustomSettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = false, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = displayWidth(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(
            horizontal: width * 0.05,
            vertical: width * 0.025,
          ),
          leading: Container(
            padding: EdgeInsets.all(isTab? 10:width * 0.03),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(isTab? 4:width * 0.03),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: isTab? 20:width * 0.055,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab? width*0.02:width * 0.035,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              subtitle,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab? width*0.018:width * 0.029,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size:isTab? 20: width * 0.035,
            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: width * 0.05,
            endIndent: width * 0.05,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
      ],
    );
  }
}