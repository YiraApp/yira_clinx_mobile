import 'package:flutter/material.dart';

import '../../../../../core/common_size_helpers/common_size_helpers.dart';

class WelcomeCard extends StatelessWidget {
  final String name;
  final String specialty;
  final Color primaryColor;
  final bool isDark;
  final bool isTab;
  final String fontFamily;

  const WelcomeCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.primaryColor,
    required this.isDark,
    required this.isTab,
    required this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    final textWidth = displayWidth(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          width: 1,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isTab ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Name
            Text(
              name.isNotEmpty ? name : "Doctor",
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: isTab ? textWidth * 0.022 : 18.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),

            if (specialty.isNotEmpty) ...[
              const SizedBox(height: 8.0),
              // Specialty & Hospital Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155).withValues(alpha: 0.6)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: isTab ? 14 : 12.5,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6.0),
                    Flexible(
                      child: Text(
                        specialty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: fontFamily,
                          fontSize: isTab ? textWidth * 0.013 : 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}