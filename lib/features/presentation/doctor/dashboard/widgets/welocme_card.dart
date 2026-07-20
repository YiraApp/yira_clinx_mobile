
import 'package:flutter/material.dart';

import '../../../../../core/colors/colors.dart';
import '../../../../../core/common_size_helpers/common_size_helpers.dart';

class WelcomeCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String clinicAddress;
  final Color primaryColor;
  final bool isDark;
  final bool isTab;
  final String fontFamily;

  const WelcomeCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.clinicAddress,
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
        color: isDark ? darkModeCardColor : const Color(0xFFd8eaff).withOpacity(0.4),
        border: Border.all(width: 0.5, color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME BACK',
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: isTab ? textWidth * 0.014 : textWidth * 0.028,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: isTab ? textWidth * 0.018 : textWidth * 0.044,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    specialty,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: isTab ? textWidth * 0.015 : textWidth * 0.034,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4.0),
                      Expanded(
                        child: Text(
                          clinicAddress,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: isTab ? textWidth * 0.015 : textWidth * 0.03,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800]!.withOpacity(0.4) : primaryColor.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wb_sunny_outlined, color: Colors.amberAccent, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}