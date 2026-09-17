import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../colors/colors.dart';

/// Reusable Doctor Avatar widget that displays a doctor's profile image
/// (network URL or base64) and falls back to the official 3D Doctor Logo
/// asset when the profile photo is not available or fails to load.
class DoctorAvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String? doctorName;
  final double size;
  final double? borderRadius;
  final bool isCircular;
  final String fallbackAsset;

  const DoctorAvatarWidget({
    super.key,
    this.photoUrl,
    this.doctorName,
    this.size = 42.0,
    this.borderRadius,
    this.isCircular = false,
    this.fallbackAsset = 'assets/images/dashboard_icons/connected_doctors_thick.png',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = isCircular ? size / 2 : (borderRadius ?? (size * 0.28));
    final cleanPhoto = (photoUrl ?? '').trim();

    Widget content;

    if (cleanPhoto.isNotEmpty) {
      if (cleanPhoto.startsWith('data:image')) {
        try {
          final commaIdx = cleanPhoto.indexOf(',');
          final base64Data = commaIdx != -1 ? cleanPhoto.substring(commaIdx + 1) : cleanPhoto;
          final Uint8List bytes = base64Decode(base64Data);
          content = Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildDoctorLogo(isDark),
          );
        } catch (_) {
          content = _buildDoctorLogo(isDark);
        }
      } else {
        String effectiveUrl = cleanPhoto;
        if (!effectiveUrl.startsWith('http://') && !effectiveUrl.startsWith('https://')) {
          effectiveUrl = 'https://$effectiveUrl';
        }
        content = Image.network(
          effectiveUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDoctorLogo(isDark),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildDoctorLogo(isDark);
          },
        );
      }
    } else {
      content = _buildDoctorLogo(isDark);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircular ? null : BorderRadius.circular(effectiveRadius),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.3 : 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCircular ? size / 2 : (effectiveRadius - 1)),
        child: content,
      ),
    );
  }

  Widget _buildDoctorLogo(bool isDark) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.08),
      padding: EdgeInsets.all(size * 0.08),
      child: Image.asset(
        fallbackAsset,
        width: size * 0.84,
        height: size * 0.84,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/icons_3d/doctor.png',
          width: size * 0.84,
          height: size * 0.84,
          fit: BoxFit.contain,
          errorBuilder: (context2, error2, stackTrace2) => Icon(
            Icons.medical_services_rounded,
            color: primaryColor,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}
