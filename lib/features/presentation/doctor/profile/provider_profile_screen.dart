import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/custom_dialogue/sign_out_alert.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/provider_profile/provider_profile_entity.dart';
import 'provider_profile_bloc/provider_profile_bloc.dart';
import 'edit_provider_profile_screen.dart';
import 'widgets/profile_info_card.dart';
import 'widgets/profile_switcher_sheet.dart';
import 'package:yiraclinics/core/local/global_session.dart';

class ProviderProfileScreen extends StatefulWidget {
  final String? userId;
  final int? hospitalId;
  final int? orgId;

  const ProviderProfileScreen({
    super.key,
    this.userId,
    this.hospitalId,
    this.orgId,
  });

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  late final ProviderProfileBloc _bloc;
  File? _localPhotoFile;
  final ImagePicker _picker = ImagePicker();

  void _openEditProfile(BuildContext context, ProviderProfileEntity profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProviderProfileScreen(profile: profile, bloc: _bloc),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _bloc = sl<ProviderProfileBloc>()
      ..add(LoadProviderProfileEvent(
        userId: widget.userId,
        hospitalId: widget.hospitalId,
        orgId: widget.orgId,
      ));
  }

  String _getInitials(String name) {
    final clean = name.replaceAll(RegExp(r'^Dr\.\s*|^Dr\s*', caseSensitive: false), '').trim();
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'DR';
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].length > 1 ? parts[0].substring(0, 2).toUpperCase() : parts[0].toUpperCase();
  }

  int _calculateProfileCompletion(ProviderProfileEntity profile) {
    int total = 7;
    int filled = 0;
    if (profile.name != null && profile.name!.isNotEmpty) filled++;
    if (profile.email != null && profile.email!.isNotEmpty) filled++;
    if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty) filled++;
    if (profile.specialty != null && profile.specialty!.isNotEmpty) filled++;
    if (profile.qualification != null && profile.qualification!.isNotEmpty) filled++;
    if (profile.registrationNumber != null && profile.registrationNumber!.isNotEmpty) filled++;
    if (profile.bio != null && profile.bio!.isNotEmpty) filled++;
    return ((filled / total) * 100).round();
  }

  Future<void> _showPhotoPickerSheet(BuildContext context, ProviderProfileEntity profile) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Update Profile Photo",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Choose how you want to update your profile photo",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12.5,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPickerOption(
                    context: context,
                    icon: Icons.camera_alt_rounded,
                    label: "Camera",
                    color: primaryColor,
                    isDark: isDark,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                      if (picked != null) {
                        setState(() => _localPhotoFile = File(picked.path));
                        _bloc.add(UploadDoctorPhotoEvent(
                          userId: widget.userId ?? GlobalSession.instance.userNotifier.value?.data?.id ?? '',
                          photoFile: File(picked.path),
                          hospitalId: widget.hospitalId,
                          orgId: widget.orgId,
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildPickerOption(
                    context: context,
                    icon: Icons.photo_library_rounded,
                    label: "Gallery",
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                      if (picked != null) {
                        setState(() => _localPhotoFile = File(picked.path));
                        _bloc.add(UploadDoctorPhotoEvent(
                          userId: widget.userId ?? GlobalSession.instance.userNotifier.value?.data?.id ?? '',
                          photoFile: File(picked.path),
                          hospitalId: widget.hospitalId,
                          orgId: widget.orgId,
                        ));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareDoctorCard(BuildContext context, ProviderProfileEntity profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final isTab = isTablet(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Clinician Digital Card",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Digital Card Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, const Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.verified_user_rounded, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text(
                              "Verified Clinician",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 28),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    profile.name ?? "Dr. Healthcare Provider",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 22 : 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${profile.specialty ?? 'Medical Practitioner'} • ${profile.qualification ?? 'MBBS, MD'}",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Facility",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10.5,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            profile.hospitalName ?? "Care Hospital",
                            style: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Reg. No",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10.5,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            profile.registrationNumber ?? "REG-AVAILABLE",
                            style: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                final info = "Doctor: ${profile.name}\nSpecialty: ${profile.specialty}\nFacility: ${profile.hospitalName}\nRegistration: ${profile.registrationNumber}";
                Clipboard.setData(ClipboardData(text: info));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Clinician details copied to clipboard"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              label: const Text("Copy Clinician Card Info"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CommonAppBar(
        titleText: "Doctor Profile",
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: "Switch Profile",
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.switch_account_rounded, size: 18, color: primaryColor),
            ),
            onPressed: () => ProfileSwitcherSheet.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<ProviderProfileBloc, ProviderProfileState>(
          bloc: _bloc,
          listener: (context, state) {
            if (state is ProviderProfileErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ProviderProfileLoadingState) {
              return _buildLoadingShimmer(context, isDark, isTab);
            }

            if (state is ProviderProfileErrorState) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Failed to Load Profile",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          _bloc.add(LoadProviderProfileEvent(
                            userId: widget.userId,
                            hospitalId: widget.hospitalId,
                            orgId: widget.orgId,
                          ));
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text("Retry"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is ProviderProfileLoadedState) {
              final profile = state.profile;
              final completionPct = _calculateProfileCompletion(profile);

              return RefreshIndicator(
                color: primaryColor,
                onRefresh: () async {
                  _bloc.add(RefreshProviderProfileEvent(
                    userId: widget.userId,
                    hospitalId: widget.hospitalId,
                    orgId: widget.orgId,
                  ));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenHorizontalSpacePadding,
                    vertical: 12,
                  ),
                  children: [
                    // Conditional Profile Switcher (Only shown when multiple profiles exist)
                    _buildProfileSwitcherBanner(context, isDark, primaryColor, isTab),

                    // 1. Ultra-Modern All-In-One Top Hero Card
                    _buildIntegratedTopHeroCard(context, profile, isDark, primaryColor, isTab, state),
                    const SizedBox(height: 16),

                    // 2. Profile Completion Bar (if < 100%)
                    if (completionPct < 100) ...[
                      _buildProfileCompletionCard(context, completionPct, profile, isDark, primaryColor, isTab),
                      const SizedBox(height: 16),
                    ],

                    // 3. Personal & Contact Information Card
                    ProfileInfoCard(
                      icon: Icons.person_rounded,
                      iconColor: primaryColor,
                      title: "Personal Information",
                      isTab: isTab,
                      onEdit: () => _openEditProfile(context, profile),
                      items: [
                        ProfileInfoItem(
                          label: "Full Name",
                          value: profile.name ?? "${profile.firstName ?? ''} ${profile.lastName ?? ''}".trim(),
                          icon: Icons.badge_outlined,
                          isCopyable: true,
                        ),
                        ProfileInfoItem(
                          label: "Email Address",
                          value: profile.email ?? "Not Provided",
                          icon: Icons.email_outlined,
                          isVerified: profile.isEmailVerified,
                          isCopyable: true,
                        ),
                        ProfileInfoItem(
                          label: "Phone Number",
                          value: profile.phoneNumber ?? "Not Provided",
                          icon: Icons.phone_outlined,
                          isVerified: profile.isMobileVerified,
                          isCopyable: true,
                        ),
                        ProfileInfoItem(
                          label: "Gender",
                          value: profile.gender ?? "Not Specified",
                          icon: Icons.wc_outlined,
                        ),
                        if (profile.dob != null && profile.dob!.isNotEmpty)
                          ProfileInfoItem(
                            label: "Date of Birth",
                            value: profile.dob!,
                            icon: Icons.cake_outlined,
                          ),
                        if (profile.bloodGroup != null && profile.bloodGroup!.isNotEmpty)
                          ProfileInfoItem(
                            label: "Blood Group",
                            value: profile.bloodGroup!,
                            icon: Icons.bloodtype_outlined,
                          ),
                      ],
                    ),

                    // 4. Medical Qualifications & Credentials Card
                    ProfileInfoCard(
                      icon: Icons.medical_services_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: "Medical Credentials & Practice",
                      isTab: isTab,
                      onEdit: () => _openEditProfile(context, profile),
                      items: [
                        ProfileInfoItem(
                          label: "Specialty",
                          value: profile.specialty ?? "General Practitioner",
                          icon: Icons.star_border_rounded,
                        ),
                        if (profile.subSpecialty != null && profile.subSpecialty!.isNotEmpty)
                          ProfileInfoItem(
                            label: "Sub-Specialty",
                            value: profile.subSpecialty!,
                            icon: Icons.polyline_outlined,
                          ),
                        ProfileInfoItem(
                          label: "Department",
                          value: profile.department ?? "Clinical Care",
                          icon: Icons.apartment_rounded,
                        ),
                        ProfileInfoItem(
                          label: "Qualification",
                          value: profile.qualification ?? "MBBS, MD",
                          icon: Icons.school_outlined,
                        ),
                        ProfileInfoItem(
                          label: "Registration No.",
                          value: profile.registrationNumber ?? "REG-AVAILABLE",
                          icon: Icons.verified_user_outlined,
                          isVerified: true,
                          isCopyable: true,
                        ),
                        ProfileInfoItem(
                          label: "Experience",
                          value: profile.experience ?? "8+ Years",
                          icon: Icons.timeline_rounded,
                        ),
                        ProfileInfoItem(
                          label: "Consultation Fee",
                          value: "₹${profile.consultationFee?.toStringAsFixed(0) ?? '500'}",
                          icon: Icons.currency_rupee_rounded,
                        ),
                      ],
                    ),

                    // 5. Affiliated Hospital & Facility Details
                    ProfileInfoCard(
                      icon: Icons.local_hospital_rounded,
                      iconColor: const Color(0xFF6366F1),
                      title: "Hospital & Workspace",
                      isTab: isTab,
                      items: [
                        ProfileInfoItem(
                          label: "Hospital Name",
                          value: profile.hospitalName ?? "Care Hospital",
                          icon: Icons.local_hospital_outlined,
                          isCopyable: true,
                        ),
                        if (profile.hospitalId != null && profile.hospitalId! > 0)
                          ProfileInfoItem(
                            label: "Hospital ID",
                            value: "#${profile.hospitalId}",
                            icon: Icons.tag_rounded,
                          ),
                        ProfileInfoItem(
                          label: "Hospital Address",
                          value: profile.clinicAddress ?? "Main Hospital Facility",
                          icon: Icons.location_on_outlined,
                          isCopyable: true,
                        ),
                      ],
                    ),

                    // 6. Clinical Statement & Bio
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      _buildBioCard(context, profile.bio!, isDark, primaryColor, isTab),
                      const SizedBox(height: 18),
                    ],

                    // 7. Quick Settings & Navigation Menu
                    _buildSettingsMenu(context, profile, isDark, primaryColor, isTab),
                    const SizedBox(height: 36),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildProfileSwitcherBanner(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    bool isTab,
  ) {
    final user = GlobalSession.instance.userNotifier.value;
    final roles = user?.data?.roles ?? [];
    if (roles.length <= 1) {
      return const SizedBox.shrink();
    }

    final activeRole = user?.data?.latestUserRole ?? "Healthcare Provider";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.switch_account_rounded,
              color: primaryColor,
              size: isTab ? 18 : 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Active Role: ",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 12 : 11,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        activeRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 13 : 12,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  "${roles.length} profiles linked • Tap to switch workspace",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 11 : 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => ProfileSwitcherSheet.show(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Switch",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletionCard(
    BuildContext context,
    int completionPct,
    ProviderProfileEntity profile,
    bool isDark,
    Color primaryColor,
    bool isTab,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Profile Strength",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                "$completionPct%",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completionPct / 100.0,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white10 : Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                completionPct > 80 ? const Color(0xFF10B981) : primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Complete your profile for patient trust",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 10.5,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
              InkWell(
                onTap: () => _openEditProfile(context, profile),
                child: Text(
                  "Complete >",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// All-in-One Top Hero Card with integrated 3 stats docked directly at the bottom
  Widget _buildIntegratedTopHeroCard(
    BuildContext context,
    ProviderProfileEntity profile,
    bool isDark,
    Color primaryColor,
    bool isTab,
    ProviderProfileLoadedState state,
  ) {
    final initials = _getInitials(profile.name ?? 'Doctor');
    final String? photoUrl = profile.profileImageUrl ?? profile.imagePath;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? primaryColor.withValues(alpha: 0.25) : primaryColor.withValues(alpha: 0.15),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: isDark ? 0.14 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Part: Doctor Profile Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              children: [
                // Avatar with Glowing Ring and Camera Action
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _showPhotoPickerSheet(context, profile),
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
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: isTab ? 48 : 42,
                            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFDBEAFE),
                            child: state.isPhotoUploading
                                ? SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: primaryColor,
                                    ),
                                  )
                                : _localPhotoFile != null
                                    ? ClipOval(
                                        child: Image.file(
                                          _localPhotoFile!,
                                          width: (isTab ? 48 : 42) * 2,
                                          height: (isTab ? 48 : 42) * 2,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : photoUrl != null && photoUrl.isNotEmpty
                                        ? ClipOval(
                                            child: CachedNetworkImage(
                                              imageUrl: photoUrl,
                                              width: (isTab ? 48 : 42) * 2,
                                              height: (isTab ? 48 : 42) * 2,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Center(
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
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
                      // Camera Action Button Badge
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showPhotoPickerSheet(context, profile),
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
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Name + Verified Check Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        profile.name ?? 'Dr. Healthcare Provider',
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

                // Specialty & Qualifications Badge Capsule
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
                    "${profile.specialty ?? 'General Practitioner'} • ${profile.qualification ?? 'MBBS, MD'}",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 13 : 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Registration Pill & Active Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF10B981)),
                          SizedBox(width: 6),
                          Text(
                            "Verified Practitioner",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        if (profile.registrationNumber != null) {
                          Clipboard.setData(ClipboardData(text: profile.registrationNumber!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Registration Number copied"),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 13,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile.registrationNumber ?? "REG-ACTIVE",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Action Buttons (Edit Profile + Share Digital Card)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _openEditProfile(context, profile),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.edit_rounded, size: 15, color: Colors.white),
                              SizedBox(width: 6),
                              Text(
                                "Edit Profile",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 12.5,
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
                    Expanded(
                      child: InkWell(
                        onTap: () => _showShareDoctorCard(context, profile),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_rounded, size: 16, color: primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                "Digital Card",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
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

          // Divider inside top card
          Divider(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
          ),

          // Bottom Part of Top Card: 3 Key Metrics
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161E2E) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Stat 1: Experience
                  Expanded(
                    child: _buildTopCardStatColumn(
                      context: context,
                      label: "Experience",
                      value: profile.experience ?? "8+ Yrs",
                      icon: Icons.work_history_outlined,
                      color: primaryColor,
                      isDark: isDark,
                      isTab: isTab,
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                  // Stat 2: Consultation Fee
                  Expanded(
                    child: _buildTopCardStatColumn(
                      context: context,
                      label: "Consultation",
                      value: "₹${profile.consultationFee?.toStringAsFixed(0) ?? '500'}",
                      icon: Icons.currency_rupee_rounded,
                      color: const Color(0xFF10B981),
                      isDark: isDark,
                      isTab: isTab,
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                  // Stat 3: Primary Facility
                  Expanded(
                    child: _buildTopCardStatColumn(
                      context: context,
                      label: "Facility",
                      value: profile.hospitalName != null && profile.hospitalName!.length > 10
                          ? "${profile.hospitalName!.substring(0, 10)}.."
                          : (profile.hospitalName ?? "Care Clinic"),
                      icon: Icons.local_hospital_outlined,
                      color: const Color(0xFF8B5CF6),
                      isDark: isDark,
                      isTab: isTab,
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

  Widget _buildTopCardStatColumn({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required bool isTab,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: isTab ? 16 : 14, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: isTab ? 14 : 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: isTab ? 11 : 10,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildBioCard(
    BuildContext context,
    String bio,
    bool isDark,
    Color primaryColor,
    bool isTab,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.format_quote_rounded, color: primaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                "About Clinician",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 16 : 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bio,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 13.5,
              height: 1.6,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu(
    BuildContext context,
    ProviderProfileEntity profile,
    bool isDark,
    Color primaryColor,
    bool isTab,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit_note_rounded, size: 18, color: primaryColor),
            ),
            title: Text(
              "Edit Profile Information",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            subtitle: Text(
              "Personal & Medical credentials",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => _openEditProfile(context, profile),
          ),
          Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_a_photo_outlined, size: 18, color: Color(0xFF10B981)),
            ),
            title: Text(
              "Update Profile Photo",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => _showPhotoPickerSheet(context, profile),
          ),
          Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_outlined, size: 18, color: Colors.amber),
            ),
            title: Text(
              "Notification Settings",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => Navigator.pushNamed(context, AppRoutes.notificationSettingsScreen),
          ),
          Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.palette_outlined, size: 18, color: Color(0xFF8B5CF6)),
            ),
            title: Text(
              "Appearance & Theme",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => Navigator.pushNamed(context, AppRoutes.appearanceScreen),
          ),
          Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, size: 18, color: Colors.red),
            ),
            title: Text(
              "Sign Out",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.red.shade400,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.red),
            onTap: () async {
              await SignOutAlert.showSignCustomDialog(context, primaryColor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context, bool isDark, bool isTab) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: screenHorizontalSpacePadding,
        vertical: 16,
      ),
      children: [
        BaseShimmer(
          child: Container(
            height: 240,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        const SizedBox(height: 18),
        BaseShimmer(
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(height: 18),
        BaseShimmer(
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}
