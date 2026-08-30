import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yiraclinics/core/app_bottom_nav_bar/app_bottom_nav_bar.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/custom_dialogue/custom_dialogue.dart';
import 'package:yiraclinics/core/custom_dialogue/sign_out_alert.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/provider_profile/provider_profile_entity.dart';
import 'edit_provider_profile_screen.dart';
import 'provider_profile_bloc/provider_profile_bloc.dart';
import 'widgets/doctor_profile_hero_header.dart';
import 'widgets/doctor_profile_section_card.dart';
import 'widgets/doctor_qr_code_sheet.dart';
import 'widgets/profile_switcher_sheet.dart';
import 'package:yiraclinics/core/tour/provider_tour_controller.dart';

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

  void _openEditProfile(BuildContext context, ProviderProfileEntity profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProviderProfileScreen(profile: profile, bloc: _bloc),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
      appBar: CommonAppBar(
        titleText: "Doctor Profile",
        showBackButton: true,
        actions: [
          IconButton(
            tooltip: "Switch Profile / Workspace",
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
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenHorizontalSpacePadding,
                    vertical: 12,
                  ),
                  children: [
                    // 1. Executive Clinician Hero Header
                    DoctorProfileHeroHeader(
                      profile: profile,
                      localPhotoFile: _localPhotoFile,
                      isPhotoUploading: state.isPhotoUploading,
                      isTab: isTab,
                      onPhotoTap: () => _showPhotoPickerSheet(context, profile),
                      onEditTap: () => _openEditProfile(context, profile),
                      onQrCodeTap: () => DoctorQrCodeSheet.show(context, profile),
                    ),
                    const SizedBox(height: 16),

                    // 2. Profile Strength / Completion Progress
                    if (completionPct < 100) ...[
                      _buildProfileCompletionCard(context, completionPct, profile, isDark, primaryColor, isTab),
                      const SizedBox(height: 16),
                    ],

                    // 3. Medical Credentials & Practice Card
                    DoctorProfileSectionCard(
                      title: "Medical Credentials & Practice",
                      icon: Icons.medical_services_rounded,
                      iconColor: const Color(0xFF10B981), // Emerald
                      isTab: isTab,
                      onEdit: () => _openEditProfile(context, profile),
                      fields: [
                        DoctorProfileFieldItem(
                          label: "Specialty",
                          value: profile.specialty ?? "General Physician",
                          icon: Icons.star_outline_rounded,
                        ),
                        if (profile.subSpecialty != null && profile.subSpecialty!.isNotEmpty)
                          DoctorProfileFieldItem(
                            label: "Sub-Specialty",
                            value: profile.subSpecialty!,
                            icon: Icons.polyline_outlined,
                          ),
                        DoctorProfileFieldItem(
                          label: "Department",
                          value: profile.department ?? "Clinical Care",
                          icon: Icons.apartment_rounded,
                        ),
                        DoctorProfileFieldItem(
                          label: "Qualification",
                          value: profile.qualification ?? "MBBS, MD",
                          icon: Icons.school_outlined,
                        ),
                        DoctorProfileFieldItem(
                          label: "Medical Council Reg. No.",
                          value: profile.registrationNumber ?? "REG-ACTIVE",
                          icon: Icons.verified_user_outlined,
                          isVerified: true,
                          isCopyable: true,
                        ),
                        DoctorProfileFieldItem(
                          label: "Clinical Experience",
                          value: profile.experience ?? "8+ Years",
                          icon: Icons.timeline_rounded,
                        ),
                      ],
                    ),

                    // 4. Personal & Contact Information Card
                    DoctorProfileSectionCard(
                      title: "Personal & Contact Details",
                      icon: Icons.person_rounded,
                      iconColor: primaryColor,
                      isTab: isTab,
                      onEdit: () => _openEditProfile(context, profile),
                      fields: [
                        DoctorProfileFieldItem(
                          label: "Full Name",
                          value: profile.name ?? "${profile.firstName ?? ''} ${profile.lastName ?? ''}".trim(),
                          icon: Icons.badge_outlined,
                          isCopyable: true,
                        ),
                        DoctorProfileFieldItem(
                          label: "Email Address",
                          value: profile.email ?? "Not Provided",
                          icon: Icons.email_outlined,
                          isVerified: profile.isEmailVerified == true,
                          isCopyable: true,
                        ),
                        DoctorProfileFieldItem(
                          label: "Phone Number",
                          value: profile.phoneNumber ?? "Not Provided",
                          icon: Icons.phone_outlined,
                          isVerified: profile.isMobileVerified == true,
                          isCopyable: true,
                        ),
                        DoctorProfileFieldItem(
                          label: "Gender",
                          value: profile.gender ?? "Not Specified",
                          icon: Icons.wc_outlined,
                        ),
                        if (profile.dob != null && profile.dob!.isNotEmpty)
                          DoctorProfileFieldItem(
                            label: "Date of Birth",
                            value: profile.dob!,
                            icon: Icons.cake_outlined,
                          ),
                        if (profile.bloodGroup != null && profile.bloodGroup!.isNotEmpty)
                          DoctorProfileFieldItem(
                            label: "Blood Group",
                            value: profile.bloodGroup!,
                            icon: Icons.bloodtype_outlined,
                          ),
                      ],
                    ),

                    // 5. Hospital & Facility Details Card
                    DoctorProfileSectionCard(
                      title: "Hospital & Practice Facility",
                      icon: Icons.local_hospital_rounded,
                      iconColor: const Color(0xFF6366F1), // Indigo
                      isTab: isTab,
                      fields: [
                        DoctorProfileFieldItem(
                          label: "Hospital Name",
                          value: profile.hospitalName ?? "Healthcare Facility",
                          icon: Icons.local_hospital_outlined,
                          isCopyable: true,
                        ),
                        DoctorProfileFieldItem(
                          label: "Facility Address",
                          value: profile.clinicAddress ?? "Main Facility Campus",
                          icon: Icons.location_on_outlined,
                          isCopyable: true,
                        ),
                      ],
                    ),

                    // 6. Clinical Statement & Bio Card (if present)
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      _buildBioCard(context, profile.bio!, isDark, primaryColor, isTab),
                      const SizedBox(height: 16),
                    ],

                    // 7. Support, About & Privacy Policy
                    _buildSupportAndLegalCard(context, isDark, primaryColor, isTab),
                    const SizedBox(height: 16),

                    // 8. Quick Settings & Account Hub
                    _buildSettingsMenu(context, profile, isDark, primaryColor, isTab),
                    const SizedBox(height: 32),
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
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                "Complete your profile for verified patient trust",
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
                    fontWeight: FontWeight.w700,
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

  Widget _buildBioCard(
    BuildContext context,
    String bio,
    bool isDark,
    Color primaryColor,
    bool isTab,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                "Clinical Bio & Statement",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 15 : 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? 13 : 12,
              height: 1.5,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportAndLegalCard(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    bool isTab,
  ) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF0284C7),
            title: "Read About Us",
            subtitle: "Learn more about Yira Clinx platform",
            isDark: isDark,
            isTab: isTab,
            onTap: () {
              CustomUrlDialog.customLauncherDialogue(
                context,
                'Read About Us',
                'Yira Clinx (ClinicX) is a next-generation, AI-powered clinic management platform designed to automate and optimize medical practice workflows...',
                primaryColor,
                'https://yira.ai/yira-clinx/',
                'More',
                'assets/images/ic_read_abt_us.png',
              );
            },
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          _buildSettingsTile(
            icon: Icons.headset_mic_outlined,
            iconColor: const Color(0xFF10B981),
            title: "Contact Us",
            subtitle: "Technical support & provider assistance",
            isDark: isDark,
            isTab: isTab,
            onTap: () {
              CustomUrlDialog.customContactLauncherDialogue(
                context,
                'Contact Us',
                'We\'re here to help! If you\'re experiencing any system downtime...',
                primaryColor,
                'https://yira.ai/clinx-support',
                'More',
                'assets/images/ic_contact_img.png',
                isContactUs: true,
              );
            },
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: "Privacy Policy",
            subtitle: "Data privacy & clinician terms",
            isDark: isDark,
            isTab: isTab,
            onTap: () {
              CustomUrlDialog.customLauncherDialogue(
                context,
                'Privacy Policy',
                'We at Yira Clinx recognize that as a healthcare professional...',
                primaryColor,
                'https://yira.ai/clinx-privacy',
                'More',
                'assets/images/ic_privacy_plc.png',
              );
            },
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
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.lightbulb_circle_rounded,
            iconColor: const Color(0xFF2563EB),
            title: "Spotlight Product Tour",
            subtitle: "Start live interactive spotlight tour across all tabs",
            isDark: isDark,
            isTab: isTab,
            onTap: () {
              Navigator.pop(context);
              ProviderTourController().restartTour();
            },
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          _buildSettingsTile(
            icon: Icons.switch_account_rounded,
            iconColor: primaryColor,
            title: "Switch Workspace / Facility",
            subtitle: "Switch between assigned hospitals",
            isDark: isDark,
            isTab: isTab,
            onTap: () => ProfileSwitcherSheet.show(context),
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          _buildSettingsTile(
            icon: Icons.logout_rounded,
            iconColor: Colors.red.shade500,
            title: "Sign Out",
            subtitle: "Log out of your clinical session",
            isDark: isDark,
            isTab: isTab,
            isDestructive: true,
            onTap: () => SignOutAlert.showSignCustomDialog(context, primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required bool isTab,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: isTab ? 14 : 13,
            fontWeight: FontWeight.w600,
            color: isDestructive
                ? Colors.red.shade500
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: isTab ? 11.5 : 10.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: isDark ? Colors.white38 : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer(BuildContext context, bool isDark, bool isTab) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: screenHorizontalSpacePadding,
        vertical: 12,
      ),
      child: BaseShimmer(
        child: Column(
          children: [
            Container(
              height: isTab ? 260 : 220,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
