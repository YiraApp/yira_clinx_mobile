import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    this.fallbackAsset = 'assets/images/dashboard_icons/doctor.svg',
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
        color: isDark ? const Color(0xFF232323) : const Color(0xFFF1F5F9),
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
    final pad = size * 0.1;
    // The doctor icon in the same black-fill style as the dashboard icons.
    if (fallbackAsset.endsWith('.svg')) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: isDark ? const Color(0xFF232323) : Colors.white,
        padding: EdgeInsets.all(pad),
        child: SvgPicture(
          SvgAssetLoader(
            fallbackAsset,
            theme: SvgTheme(currentColor: isDark ? Colors.white : const Color(0xFF111111)),
            colorMapper: isDark ? const _DarkDoctorIcon() : null,
          ),
          width: size - pad * 2,
          height: size - pad * 2,
        ),
      );
    }
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
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.medical_services_rounded,
          color: primaryColor,
          size: size * 0.55,
        ),
      ),
    );
  }
}

/// On dark cards: white fills become the card colour and the cut-out details follow.
class _DarkDoctorIcon extends ColorMapper {
  const _DarkDoctorIcon();

  @override
  Color substitute(String? id, String elementName, String attributeName, Color color) {
    final argb = color.toARGB32();
    if (attributeName == 'stroke') return argb == 0xFFFEFEFE ? const Color(0xFF232323) : color;
    if (attributeName != 'fill') return color;
    if (argb == 0xFFFFFFFF) return const Color(0xFF232323);
    if (argb == 0xFF111111) return Colors.white;
    return color;
  }
}
