import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/domain/entities/provider_profile/provider_profile_entity.dart';

class DoctorProfileHeroHeader extends StatelessWidget {
  final ProviderProfileEntity profile;
  final File? localPhotoFile;
  final bool isPhotoUploading;
  final bool isTab;
  final VoidCallback onPhotoTap;
  final VoidCallback onEditTap;
  final VoidCallback onQrCodeTap;

  const DoctorProfileHeroHeader({
    super.key,
    required this.profile,
    this.localPhotoFile,
    this.isPhotoUploading = false,
    required this.isTab,
    required this.onPhotoTap,
    required this.onEditTap,
    required this.onQrCodeTap,
  });

  String _getInitials(String name) {
    final clean = name.replaceAll(RegExp(r'^Dr\.\s*|^Dr\s*', caseSensitive: false), '').trim();
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'DR';
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].length > 1 ? parts[0].substring(0, 2).toUpperCase() : parts[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    final String name = profile.name?.isNotEmpty == true
        ? profile.name!
        : "${profile.firstName ?? 'Dr.'} ${profile.lastName ?? 'Practitioner'}".trim();
    final String initials = _getInitials(name);
    final String? photoUrl = profile.profileImageUrl ?? profile.imagePath;

    final String specialty = profile.specialty?.isNotEmpty == true ? profile.specialty! : "General Physician";
    final String qualification = profile.qualification?.isNotEmpty == true ? profile.qualification! : "MBBS";
    final String hospitalName = profile.hospitalName?.isNotEmpty == true ? profile.hospitalName! : "Healthcare Facility";

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Hero Section with Ambient Gradient
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              isTab ? 28 : 20,
              isTab ? 26 : 22,
              isTab ? 28 : 20,
              isTab ? 22 : 18,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        primaryColor.withValues(alpha: 0.18),
                        const Color(0xFF0F172A).withValues(alpha: 0.0),
                      ]
                    : [
                        primaryColor.withValues(alpha: 0.09),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Avatar with Camera Badge
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: onPhotoTap,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [primaryColor, const Color(0xFF38BDF8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: isTab ? 50 : 44,
                            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                            child: isPhotoUploading
                                ? SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: primaryColor,
                                    ),
                                  )
                                : localPhotoFile != null
                                    ? ClipOval(
                                        child: Image.file(
                                          localPhotoFile!,
                                          width: (isTab ? 50 : 44) * 2,
                                          height: (isTab ? 50 : 44) * 2,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : photoUrl != null && photoUrl.isNotEmpty
                                        ? ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: photoUrl,
                                              width: (isTab ? 50 : 44) * 2,
                                              height: (isTab ? 50 : 44) * 2,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Center(
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) => Text(
                                                initials,
                                                style: TextStyle(
                                                  fontFamily: appPoppinFont,
                                                  fontSize: isTab ? 28 : 24,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            initials,
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontSize: isTab ? 28 : 24,
                                              fontWeight: FontWeight.w700,
                                              color: primaryColor,
                                            ),
                                          ),
                          ),
                        ),
                      ),

                      // Camera Badge Pill
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: onPhotoTap,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Doctor Name + Verified Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 22 : 19,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Specialty & Qualification Capsule
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    "$specialty • $qualification",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 13 : 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Hospital Affiliation Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.apartment_rounded,
                      size: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        hospitalName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 12.5 : 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Action Buttons Row: Edit Profile + Digital Card
                Row(
                  children: [
                    // Edit Profile (Primary Filled)
                    Expanded(
                      flex: 6,
                      child: InkWell(
                        onTap: onEditTap,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.edit_note_rounded, size: 18, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                "Edit Profile",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // QR Code (Tonal Outline)
                    Expanded(
                      flex: 5,
                      child: InkWell(
                        onTap: onQrCodeTap,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 18,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "QR Code",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),

          // 3-Pillars Clinical Highlights Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetricHighlight(
                      context: context,
                      isDark: isDark,
                      isTab: isTab,
                      title: "Experience",
                      value: profile.experience?.isNotEmpty == true ? profile.experience! : "8+ Years",
                      icon: Icons.timeline_rounded,
                      accentColor: const Color(0xFF4F46E5), // Indigo
                    ),
                  ),
                  _buildVerticalDivider(isDark),
                  Expanded(
                    child: _buildMetricHighlight(
                      context: context,
                      isDark: isDark,
                      isTab: isTab,
                      title: "Department",
                      value: profile.department?.isNotEmpty == true ? profile.department! : "Clinical",
                      icon: Icons.local_hospital_rounded,
                      accentColor: const Color(0xFF0284C7), // Sky Blue
                    ),
                  ),
                  _buildVerticalDivider(isDark),
                  Expanded(
                    child: _buildMetricHighlight(
                      context: context,
                      isDark: isDark,
                      isTab: isTab,
                      title: "Status",
                      value: "Active",
                      icon: Icons.check_circle_rounded,
                      accentColor: const Color(0xFF10B981), // Emerald
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricHighlight({
    required BuildContext context,
    required bool isDark,
    required bool isTab,
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 11.5 : 10.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? 15 : 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
    );
  }
}
