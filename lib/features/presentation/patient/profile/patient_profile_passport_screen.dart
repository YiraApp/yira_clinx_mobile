import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/custom_dialogue/sign_out_alert.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/over_view/over_view_entity.dart';
import 'package:yiraclinics/features/presentation/doctor/profile/widgets/profile_info_card.dart';
import 'package:yiraclinics/features/presentation/doctor/profile/widgets/profile_switcher_sheet.dart';
import 'package:yiraclinics/features/presentation/patient_profile/patient_over_view_bloc/patient_over_view_bloc.dart';

class PatientProfilePassportScreen extends StatefulWidget {
  const PatientProfilePassportScreen({super.key});

  @override
  State<PatientProfilePassportScreen> createState() => _PatientProfilePassportScreenState();
}

class _PatientProfilePassportScreenState extends State<PatientProfilePassportScreen> {
  late final PatientOverViewBloc _bloc;

  @override
  void initState() {
    super.initState();
    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final orgId = currentUser?.data?.latestOrgId?.toString() ?? '1';
    final hospitalId = currentUser?.data?.latestHospitalId?.toString() ?? '1';

    _bloc = sl<PatientOverViewBloc>()
      ..add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  String _getInitials(String name) {
    final clean = name.trim();
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'PT';
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].length > 1 ? parts[0].substring(0, 2).toUpperCase() : parts[0].toUpperCase();
  }

  int _calculateProfileCompletion(DataEntity? data, String phone, String email) {
    int total = 7;
    int filled = 0;
    if (phone.isNotEmpty) {
      filled++;
    }
    if (email.isNotEmpty) {
      filled++;
    }
    if (data?.contactInformation?.residentialAddress != null &&
        data!.contactInformation!.residentialAddress!.isNotEmpty) {
      filled++;
    }
    if (data?.contactInformation?.emergencyContact?.name != null &&
        data!.contactInformation!.emergencyContact!.name!.isNotEmpty) {
      filled++;
    }
    if (data?.medicalInformation?.bloodGroup != null &&
        data!.medicalInformation!.bloodGroup!.isNotEmpty) {
      filled++;
    }
    if (data?.medicalInformation?.allergies != null &&
        data!.medicalInformation!.allergies!.isNotEmpty) {
      filled++;
    }
    if (data?.insurance?.policyNumber != null &&
        data!.insurance!.policyNumber!.isNotEmpty) {
      filled++;
    }
    return ((filled / total) * 100).round();
  }

  void _showPatientDigitalCard(BuildContext context, DataEntity? data, String patientName, String mrnNumber) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    final bloodGroup = data?.medicalInformation?.bloodGroup ?? 'O+ Positive';
    final phone = data?.contactInformation?.phone ?? GlobalSession.instance.userNotifier.value?.data?.phoneNumber ?? '+91 98765 43210';
    final emergencyContact = data?.contactInformation?.emergencyContact?.phone ?? '+91 98490 12345';
    final policyNumber = data?.insurance?.policyNumber ?? 'POL-992019482';

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
                  "Digital Health Passport",
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
                            Icon(Icons.shield_rounded, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text(
                              "Universal Health Passport",
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "BLOOD: $bloodGroup",
                          style: const TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    patientName,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 22 : 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "MRN: $mrnNumber • Emergency: $emergencyContact",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
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
                            "Mobile",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10.5,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            phone,
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
                            "Policy No",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10.5,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            policyNumber,
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
                final info = "Patient: $patientName\nMRN: $mrnNumber\nBlood Group: $bloodGroup\nPhone: $phone\nEmergency Contact: $emergencyContact\nPolicy: $policyNumber";
                Clipboard.setData(ClipboardData(text: info));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Patient Passport details copied to clipboard"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy_all_rounded, size: 18),
              label: const Text("Copy Passport Information"),
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

    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final orgId = currentUser?.data?.latestOrgId?.toString() ?? '1';
    final hospitalId = currentUser?.data?.latestHospitalId?.toString() ?? '1';
    final firstName = currentUser?.data?.firstName ?? '';
    final lastName = currentUser?.data?.lastName ?? '';
    final sessionPatientName = '$firstName $lastName'.trim().isNotEmpty
        ? '$firstName $lastName'.trim()
        : 'Ch. Raja Vardan';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CommonAppBar(
        titleText: "Patient Profile",
        showBackButton: false,
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
        child: BlocProvider<PatientOverViewBloc>.value(
          value: _bloc,
          child: BlocBuilder<PatientOverViewBloc, PatientOverViewState>(
            builder: (context, state) {
              if (state is LoadingPatientViewDetails) {
                return _buildLoadingShimmer(context, isDark, isTab);
              }

              if (state is LoadPatientDataFailureState) {
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
                          state.error,
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
                            _bloc.add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId));
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

              PatientOverViewEntity? overViewEntity;
              if (state is LoadPatientDataState) {
                overViewEntity = state.patientOverViewEntity;
              }

              final data = overViewEntity?.data;
              final patientName = sessionPatientName;
              final mrnNumber = 'MRN-998241';
              final phone = data?.contactInformation?.phone ?? currentUser?.data?.phoneNumber ?? '+91 98765 43210';
              final email = data?.contactInformation?.emailAddress ?? currentUser?.data?.email ?? 'raja.vardan@yiramail.com';
              final address = data?.contactInformation?.residentialAddress ?? 'Plot #42, Health City, Jubilee Hills, Hyderabad';
              final emergencyName = data?.contactInformation?.emergencyContact?.name ?? 'Srinivas Rao (Father)';
              final emergencyPhone = data?.contactInformation?.emergencyContact?.phone ?? '+91 98490 12345';
              final condition = data?.medicalInformation?.condition ?? 'Mild Hypertension, Seasonal Asthma';
              final allergies = data?.medicalInformation?.allergies ?? 'Penicillin (Severe Reaction)';
              final bloodGroup = data?.medicalInformation?.bloodGroup ?? 'O+ Positive';
              final policyName = data?.insurance?.policyName ?? 'HDFC Ergo Health Insurance';
              final policyNumber = data?.insurance?.policyNumber ?? 'POL-992019482';
              final totalVisits = data?.medicalInformation?.totalVisits ?? 12;

              final completionPct = _calculateProfileCompletion(data, phone, email);

              return RefreshIndicator(
                color: primaryColor,
                onRefresh: () async {
                  _bloc.add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: screenHorizontalSpacePadding,
                    vertical: 12,
                  ),
                  children: [
                    // Conditional Profile Switcher Banner
                    _buildProfileSwitcherBanner(context, isDark, primaryColor, isTab),

                    // 1. Ultra-Modern All-In-One Top Hero Card
                    _buildIntegratedTopHeroCard(
                      context: context,
                      data: data,
                      patientName: patientName,
                      mrnNumber: mrnNumber,
                      bloodGroup: bloodGroup,
                      totalVisits: totalVisits,
                      policyName: policyName,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      isTab: isTab,
                    ),
                    const SizedBox(height: 16),

                    // 2. Profile Completion Bar
                    _buildProfileCompletionCard(context, completionPct, isDark, primaryColor, isTab),
                    const SizedBox(height: 16),

                    // 3. Personal & Contact Information Card
                    ProfileInfoCard(
                      icon: Icons.person_rounded,
                      iconColor: primaryColor,
                      title: "Personal Information",
                      isTab: isTab,
                      items: [
                        ProfileInfoItem(
                          label: "Full Name",
                          value: patientName,
                          icon: Icons.badge_outlined,
                          isCopyable: true,
                        ),
                        ProfileInfoItem(
                          label: "Date of Birth",
                          value: "14 May 1995 (31 Yrs)",
                          icon: Icons.cake_outlined,
                        ),
                        ProfileInfoItem(
                          label: "Gender",
                          value: "Male",
                          icon: Icons.wc_outlined,
                        ),
                        ProfileInfoItem(
                          label: "Blood Group",
                          value: bloodGroup,
                          icon: Icons.bloodtype_outlined,
                        ),
                        ProfileInfoItem(
                          label: "Phone Number",
                          value: phone,
                          icon: Icons.phone_outlined,
                          isVerified: true,
                          isCopyable: true,
                        ),
                        ProfileInfoItem(
                          label: "Email Address",
                          value: email,
                          icon: Icons.email_outlined,
                          isVerified: true,
                          isCopyable: true,
                        ),
                        ProfileInfoItem(
                          label: "Residential Address",
                          value: address,
                          icon: Icons.location_on_outlined,
                          isCopyable: true,
                        ),
                      ],
                    ),

                    // 4. Emergency Contact Section
                    ProfileInfoCard(
                      icon: Icons.contact_phone_rounded,
                      iconColor: const Color(0xFFEF4444),
                      title: "Emergency Contact",
                      isTab: isTab,
                      items: [
                        ProfileInfoItem(
                          label: "Contact Person",
                          value: emergencyName,
                          icon: Icons.person_outline_rounded,
                          isCopyable: true,
                        ),
                        ProfileInfoItem(
                          label: "Relationship",
                          value: "Parent / Father",
                          icon: Icons.family_restroom_rounded,
                        ),
                        ProfileInfoItem(
                          label: "Primary Phone",
                          value: emergencyPhone,
                          icon: Icons.phone_in_talk_rounded,
                          isCopyable: true,
                        ),
                      ],
                    ),

                    // 5. Insurance Details Section
                    ProfileInfoCard(
                      icon: Icons.health_and_safety_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: "Insurance & Coverage Details",
                      isTab: isTab,
                      items: [
                        ProfileInfoItem(
                          label: "Provider",
                          value: policyName,
                          icon: Icons.apartment_rounded,
                          isCopyable: true,
                        ),
                        ProfileInfoItem(
                          label: "Policy Number",
                          value: policyNumber,
                          icon: Icons.tag_rounded,
                          isVerified: true,
                          isCopyable: true,
                        ),
                        ProfileInfoItem(
                          label: "Coverage Plan",
                          value: "Comprehensive Family Floater (₹10 Lakhs)",
                          icon: Icons.shield_outlined,
                        ),
                        ProfileInfoItem(
                          label: "Validity",
                          value: "Active until Dec 2027",
                          icon: Icons.event_available_rounded,
                        ),
                      ],
                    ),

                    // 6. Medical History & Allergies Section
                    ProfileInfoCard(
                      icon: Icons.medical_information_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: "Medical History & Allergies",
                      isTab: isTab,
                      items: [
                        ProfileInfoItem(
                          label: "Known Conditions",
                          value: condition,
                          icon: Icons.healing_rounded,
                        ),
                        ProfileInfoItem(
                          label: "Drug Allergies",
                          value: allergies,
                          icon: Icons.warning_amber_rounded,
                        ),
                        ProfileInfoItem(
                          label: "Food Allergies",
                          value: "Peanuts, Shellfish",
                          icon: Icons.restaurant_rounded,
                        ),
                        ProfileInfoItem(
                          label: "Past Surgeries",
                          value: "Appendectomy (2021)",
                          icon: Icons.local_hospital_outlined,
                        ),
                        ProfileInfoItem(
                          label: "Clinic Visits",
                          value: "$totalVisits Recorded Visits",
                          icon: Icons.history_rounded,
                        ),
                      ],
                    ),

                    // 7. Quick Settings & Navigation Menu
                    _buildSettingsMenu(context, isDark, primaryColor, isTab),
                    const SizedBox(height: 36),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIntegratedTopHeroCard({
    required BuildContext context,
    required DataEntity? data,
    required String patientName,
    required String mrnNumber,
    required String bloodGroup,
    required int totalVisits,
    required String policyName,
    required bool isDark,
    required Color primaryColor,
    required bool isTab,
  }) {
    final initials = _getInitials(patientName);

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
          // Top Part: Patient Profile Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              children: [
                // Avatar with Glowing Ring
                Center(
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
                      child: Text(
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
                const SizedBox(height: 14),

                // Name + Verified Check Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        patientName,
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

                // Patient Universal Health Pill
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
                    "Digital Health Passport • Universal Health ID",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 13 : 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // MRN Pill & Active Status
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
                            "Active Patient Account",
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
                        Clipboard.setData(ClipboardData(text: mrnNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("MRN Number copied"),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
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
                              mrnNumber,
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

                // Action Button (Patient Digital Passport Card)
                InkWell(
                  onTap: () => _showPatientDigitalCard(context, data, patientName, mrnNumber),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
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
                        Icon(Icons.badge_rounded, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "View Digital Health Passport",
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
                  // Stat 1: Blood Group
                  Expanded(
                    child: _buildTopCardStatColumn(
                      context: context,
                      label: "Blood Group",
                      value: bloodGroup,
                      icon: Icons.bloodtype_outlined,
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
                  // Stat 2: Visits
                  Expanded(
                    child: _buildTopCardStatColumn(
                      context: context,
                      label: "Clinic Visits",
                      value: "$totalVisits Visits",
                      icon: Icons.medical_services_outlined,
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
                  // Stat 3: Insurance
                  Expanded(
                    child: _buildTopCardStatColumn(
                      context: context,
                      label: "Insurance",
                      value: policyName.length > 9 ? "${policyName.substring(0, 9)}.." : policyName,
                      icon: Icons.health_and_safety_outlined,
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

    final activeRole = user?.data?.latestUserRole ?? "Patient";

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
                    "Profile Completeness",
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
          Text(
            "Complete your profile information for faster clinical check-ins",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 10.5,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu(
    BuildContext context,
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
      padding: const EdgeInsets.symmetric(
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
