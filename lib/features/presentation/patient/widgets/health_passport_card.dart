import 'package:flutter/material.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';

class HealthPassportCard extends StatelessWidget {
  final String patientName;
  final String mrnNumber;
  final String bloodGroup;
  final String emergencyContact;
  final String insurancePolicy;
  final VoidCallback? onShowQrCode;

  const HealthPassportCard({
    super.key,
    required this.patientName,
    required this.mrnNumber,
    required this.bloodGroup,
    required this.emergencyContact,
    required this.insurancePolicy,
    this.onShowQrCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTab ? 24 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [primaryColor, primaryColor.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DIGITAL HEALTH PASSPORT',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        'Universal Health Identifier',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'BLOOD: $bloodGroup',
                  style: const TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Body Content: Patient Details + QR Code Mock
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 22 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MRN: $mrnNumber',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Badges
                    Row(
                      children: [
                        Icon(Icons.phone_in_talk_rounded, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Emergency: $emergencyContact',
                            style: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Insurance: $insurancePolicy',
                            style: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Interactive QR Code Container
              GestureDetector(
                onTap: onShowQrCode,
                child: Container(
                  width: isTab ? 90 : 76,
                  height: isTab ? 90 : 76,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomPaint(
                        size: Size(isTab ? 54 : 44, isTab ? 54 : 44),
                        painter: MockQrPainter(),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'SCAN QR',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Painter for QR Code pattern simulation
class MockQrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    double cellSize = size.width / 5;
    
    // Draw outer corner markers
    canvas.drawRect(Rect.fromLTWH(0, 0, cellSize * 2, cellSize * 2), paint);
    canvas.drawRect(Rect.fromLTWH(size.width - cellSize * 2, 0, cellSize * 2, cellSize * 2), paint);
    canvas.drawRect(Rect.fromLTWH(0, size.height - cellSize * 2, cellSize * 2, cellSize * 2), paint);

    // Inner details
    canvas.drawRect(Rect.fromLTWH(cellSize * 2, cellSize * 2, cellSize, cellSize), paint);
    canvas.drawRect(Rect.fromLTWH(cellSize * 3, cellSize, cellSize, cellSize), paint);
    canvas.drawRect(Rect.fromLTWH(cellSize, cellSize * 3, cellSize, cellSize), paint);
    canvas.drawRect(Rect.fromLTWH(cellSize * 3, cellSize * 3, cellSize * 2, cellSize * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
