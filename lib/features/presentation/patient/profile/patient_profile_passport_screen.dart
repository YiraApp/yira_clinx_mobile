import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/custom_dialogue/sign_out_alert.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';
import '../../../../di/dependency_injection.dart';
import '../../../domain/entities/login/login_entity.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../doctor/profile/widgets/doctor_profile_section_card.dart';
import '../../doctor/profile/widgets/profile_switcher_sheet.dart';
import '../../patient_profile/patient_over_view_bloc/patient_over_view_bloc.dart';
import '../../../../core/tour/patient_tour_controller.dart';

class PatientProfilePassportScreen extends StatefulWidget {
  const PatientProfilePassportScreen({super.key});

  @override
  State<PatientProfilePassportScreen> createState() => _PatientProfilePassportScreenState();
}

class _PatientProfilePassportScreenState extends State<PatientProfilePassportScreen> {
  File? _localProfileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';
      if (userId.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString('patient_profile_image_$userId');
      if (savedPath != null && savedPath.isNotEmpty && File(savedPath).existsSync()) {
        if (mounted) {
          setState(() {
            _localProfileImage = File(savedPath);
          });
        }
      }
    } catch (_) {}
  }

  void _openPhotoPickerSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
              "Profile Photo",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
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
                    icon: Icons.camera_alt_rounded,
                    label: "Camera",
                    color: primaryColor,
                    isDark: isDark,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                      if (picked != null) {
                        final file = File(picked.path);
                        setState(() => _localProfileImage = file);
                        if (userId.isNotEmpty) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('patient_profile_image_$userId', picked.path);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile photo updated successfully!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildPickerOption(
                    icon: Icons.photo_library_rounded,
                    label: "Gallery",
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                      if (picked != null) {
                        final file = File(picked.path);
                        setState(() => _localProfileImage = file);
                        if (userId.isNotEmpty) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('patient_profile_image_$userId', picked.path);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile photo updated successfully!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_localProfileImage != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text(
                    "Remove Photo",
                    style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    setState(() => _localProfileImage = null);
                    if (userId.isNotEmpty) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('patient_profile_image_$userId');
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProfileSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileSwitcherSheet(),
    );
  }

  void _openEditProfileDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final nameController = TextEditingController(text: '${currentUser?.data?.firstName ?? ''} ${currentUser?.data?.lastName ?? ''}'.trim());
    final phoneController = TextEditingController(text: currentUser?.data?.phoneNumber ?? '');
    final emailController = TextEditingController(text: currentUser?.data?.email ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Profile Details',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openPhotoPickerSheet();
                    },
                    icon: const Icon(Icons.camera_alt_rounded, size: 16),
                    label: const Text("Photo", style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Full Name', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              Text('Phone Number', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 6),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 14),
              Text('Email Address', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
              const SizedBox(height: 6),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile information updated successfully!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Save Changes', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
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

    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final hospitalId = currentUser?.data?.latestHospitalId?.toString() ?? '1';
    final orgId = currentUser?.data?.latestOrgId?.toString() ?? '1';

    return BlocProvider<PatientOverViewBloc>(
      create: (_) => sl<PatientOverViewBloc>()..add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId)),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          title: const Text(
            'My Profile',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Switch Member',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.switch_account_rounded, size: 18, color: primaryColor),
              ),
              onPressed: () => _openProfileSwitcher(context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<PatientOverViewBloc, PatientOverViewState>(
            builder: (context, state) {
              if (state is LoadingPatientViewDetails) {
                return _buildProfileShimmer(context, isDark, isTab);
              }

              PatientOverViewEntity? overViewEntity;
              if (state is LoadPatientDataState) {
                overViewEntity = state.patientOverViewEntity;
              }

              final data = overViewEntity?.data;
              final contact = data?.contactInformation;
              final medical = data?.medicalInformation;
              final emergency = contact?.emergencyContact;
              final insurance = data?.insurance;

              // Determine active member
              final List<ProfileEntity> profiles = currentUser?.data?.profiles ?? [];
              final activeProfile = profiles.isNotEmpty ? profiles.first : null;

              final firstName = currentUser?.data?.firstName ?? '';
              final lastName = currentUser?.data?.lastName ?? '';
              final patientName = '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : 'Patient';

              final initials = patientName.isNotEmpty
                  ? patientName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
                  : 'P';

              final rawRel = (activeProfile?.relation ?? '').trim();
              final bool hasFamilyRelation = rawRel.isNotEmpty &&
                  rawRel.toLowerCase() != 'self' &&
                  rawRel.toLowerCase() != 'primary' &&
                  rawRel.toLowerCase() != 'admin';

              final String relation = hasFamilyRelation
                  ? rawRel
                  : ((activeProfile?.isPrimary == true) ? 'Primary' : 'Dependent');
              final bool isPrimary = (relation == 'Primary');
              final mrn = userId.isNotEmpty
                  ? 'MRN-${userId.length > 5 ? userId.substring(0, 5).toUpperCase() : userId}'
                  : 'MRN-90214';
              final phone = contact?.phone ?? currentUser?.data?.phoneNumber ?? '+91 98765 43210';
              final email = contact?.emailAddress ?? currentUser?.data?.email ?? 'patient@yiraclinics.com';
              final gender = 'Male';
              final dob = '15 Aug 1994';
              final bloodGroup = medical?.bloodGroup ?? 'O+';
              final hospital = data?.nextAppointment?.hospitalName ?? 'Yira Hospitals';

              return RefreshIndicator(
                color: primaryColor,
                onRefresh: () async {
                  context.read<PatientOverViewBloc>().add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId));
                  await Future.delayed(const Duration(milliseconds: 600));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: screenHorizontalSpacePadding,
                    vertical: 12,
                  ),
                  children: [
                    // 1. Executive Hero Header with Profile Picture Upload
                    _buildPatientHeroHeader(
                      context: context,
                      name: patientName,
                      initials: initials,
                      relation: relation,
                      isPrimary: isPrimary,
                      mrn: mrn,
                      hospital: hospital,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      isTab: isTab,
                    ),
                    const SizedBox(height: 16),

                    // 2. Profile Strength / Completeness Card
                    _buildProfileCompletionCard(
                      context: context,
                      completionPct: 85,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      isTab: isTab,
                    ),
                    const SizedBox(height: 16),

                    // 3. Personal Information Card
                    DoctorProfileSectionCard(
                      title: "Personal & Demographics",
                      icon: Icons.person_rounded,
                      iconColor: primaryColor,
                      isTab: isTab,
                      onEdit: () => _openEditProfileDialog(context),
                      fields: [
                        DoctorProfileFieldItem(
                          label: "Full Name",
                          value: patientName,
                          icon: Icons.badge_outlined,
                          isCopyable: true,
                        ),
                        DoctorProfileFieldItem(
                          label: "Medical Record Number (MRN)",
                          value: mrn,
                          icon: Icons.fingerprint_rounded,
                          isCopyable: true,
                          isVerified: true,
                        ),
                        DoctorProfileFieldItem(
                          label: "Date of Birth",
                          value: dob,
                          icon: Icons.cake_outlined,
                        ),
                        DoctorProfileFieldItem(
                          label: "Gender",
                          value: gender,
                          icon: Icons.wc_outlined,
                        ),
                        DoctorProfileFieldItem(
                          label: "Blood Group",
                          value: bloodGroup,
                          icon: Icons.bloodtype_outlined,
                          customValueColor: Colors.redAccent,
                        ),
                        DoctorProfileFieldItem(
                          label: "Phone Number",
                          value: phone,
                          icon: Icons.phone_outlined,
                          isCopyable: true,
                        ),
                        DoctorProfileFieldItem(
                          label: "Email Address",
                          value: email,
                          icon: Icons.email_outlined,
                          isCopyable: true,
                          isVerified: true,
                        ),
                      ],
                    ),

                    // 4. Emergency Contact Card
                    DoctorProfileSectionCard(
                      title: "Emergency Contact",
                      icon: Icons.contact_phone_rounded,
                      iconColor: const Color(0xFF10B981),
                      isTab: isTab,
                      onEdit: () => _openEditProfileDialog(context),
                      fields: [
                        DoctorProfileFieldItem(
                          label: "Contact Name",
                          value: emergency?.name ?? "Family Member",
                          icon: Icons.person_outline_rounded,
                        ),
                        DoctorProfileFieldItem(
                          label: "Relationship",
                          value: "Primary Contact",
                          icon: Icons.family_restroom_rounded,
                        ),
                        DoctorProfileFieldItem(
                          label: "Phone Number",
                          value: emergency?.phone ?? "+91 91234 56789",
                          icon: Icons.phone_forwarded_rounded,
                          isCopyable: true,
                        ),
                      ],
                    ),

                    // 5. Insurance & Healthcare Coverage Card
                    DoctorProfileSectionCard(
                      title: "Insurance & Coverage",
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF0284C7),
                      isTab: isTab,
                      fields: [
                        DoctorProfileFieldItem(
                          label: "Insurance Provider",
                          value: insurance?.policyName ?? "Universal Health Coverage",
                          icon: Icons.business_outlined,
                        ),
                        DoctorProfileFieldItem(
                          label: "Policy Number",
                          value: insurance?.policyNumber ?? "POL-88219401",
                          icon: Icons.numbers_outlined,
                          isCopyable: true,
                          isVerified: true,
                        ),
                        DoctorProfileFieldItem(
                          label: "Coverage Status",
                          value: "Active & Verified",
                          icon: Icons.verified_user_rounded,
                          customValueColor: const Color(0xFF10B981),
                        ),
                      ],
                    ),

                    // 6. Medical History & Allergies Card
                    DoctorProfileSectionCard(
                      title: "Medical Background & History",
                      icon: Icons.healing_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      isTab: isTab,
                      fields: [
                        DoctorProfileFieldItem(
                          label: "Known Allergies",
                          value: (medical?.allergies != null && medical!.allergies!.isNotEmpty)
                              ? medical.allergies!
                              : "No known drug allergies",
                          icon: Icons.warning_amber_rounded,
                          customValueColor: Colors.orange,
                        ),
                        DoctorProfileFieldItem(
                          label: "Chronic Conditions",
                          value: (medical?.condition != null && medical!.condition!.isNotEmpty)
                              ? medical.condition!
                              : "None recorded",
                          icon: Icons.health_and_safety_outlined,
                        ),
                        DoctorProfileFieldItem(
                          label: "Total Consultations",
                          value: "${medical?.totalVisits ?? 4} Visits",
                          icon: Icons.medical_information_outlined,
                        ),
                      ],
                    ),

                    // 7. App Preferences & Security Card
                    DoctorProfileSectionCard(
                      title: "Security & Terms",
                      icon: Icons.lock_outline_rounded,
                      iconColor: const Color(0xFF64748B),
                      isTab: isTab,
                      fields: const [
                        DoctorProfileFieldItem(
                          label: "Data Privacy Policy",
                          value: "Compliant with Health Data Standards",
                          icon: Icons.privacy_tip_outlined,
                        ),
                        DoctorProfileFieldItem(
                          label: "Encryption",
                          value: "256-bit End-to-End Encrypted",
                          icon: Icons.security_rounded,
                          isVerified: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 7.5. Spotlight Product Tour Tile
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.4 : 0.25),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.08 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.lightbulb_circle_rounded, color: Color(0xFF2563EB), size: 20),
                        ),
                        title: Text(
                          "Spotlight Product Tour",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          "Start live interactive spotlight tour across all tabs",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          PatientTourController().restartTour(context: context);
                        },
                      ),
                    ),

                    // 8. Sign Out Tile
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                        ),
                        title: const Text(
                          "Sign Out",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.red, size: 14),
                        onTap: () async {
                          await SignOutAlert.showSignCustomDialog(context, primaryColor);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeroHeader({
    required BuildContext context,
    required String name,
    required String initials,
    required String relation,
    required bool isPrimary,
    required String mrn,
    required String hospital,
    required bool isDark,
    required Color primaryColor,
    required bool isTab,
  }) {
    return Container(
      key: PatientTourController().passportProfileCardKey,
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
          // Top Ambient Gradient Card
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
                // Avatar with Camera Icon Overlay for Photo Upload
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: _openPhotoPickerSheet,
                      child: Container(
                        width: isTab ? 96 : 84,
                        height: isTab ? 96 : 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.4),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _localProfileImage != null
                              ? Image.file(
                                  _localProfileImage!,
                                  width: isTab ? 96 : 84,
                                  height: isTab ? 96 : 84,
                                  fit: BoxFit.cover,
                                )
                              : _buildInitialsAvatar(initials, isTab, primaryColor),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: _openPhotoPickerSheet,
                        child: Container(
                          padding: const EdgeInsets.all(4.5),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1.5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tap to change photo subtitle button
                GestureDetector(
                  onTap: _openPhotoPickerSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 13, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          _localProfileImage != null ? "Change Photo" : "Add Photo",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Name & Verified Badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 20 : 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.verified_rounded, size: 18, color: primaryColor),
                  ],
                ),
                const SizedBox(height: 6),

                // Relation Badge + MRN Badge
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isPrimary ? const Color(0xFF10B981) : const Color(0xFF0284C7)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPrimary ? Icons.star_rounded : Icons.people_rounded,
                            size: 14,
                            color: isPrimary ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            relation,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isPrimary ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        mrn,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Hospital Tag
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_hospital_rounded, size: 13, color: isDark ? Colors.white54 : Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      hospital,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openProfileSwitcher(context),
                    icon: const Icon(Icons.people_outline_rounded, size: 16),
                    label: const Text('Switch Member', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openEditProfileDialog(context),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Profile', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials, bool isTab, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: isTab ? 30 : 26,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProfileCompletionCard({
    required BuildContext context,
    required int completionPct,
    required bool isDark,
    required Color primaryColor,
    required bool isTab,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_outlined, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Profile Strength',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                '$completionPct% Complete',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionPct / 100.0,
              minHeight: 7,
              backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your profile updated for seamless hospital check-ins and verified prescriptions.',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 11.5,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileShimmer(BuildContext context, bool isDark, bool isTab) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(screenHorizontalSpacePadding),
      child: Column(
        children: [
          BaseShimmer(
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const SizedBox(height: 16),
          BaseShimmer(
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
