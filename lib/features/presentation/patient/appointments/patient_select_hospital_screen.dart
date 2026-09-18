import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/services/liked_hospitals_service.dart';
import 'package:yiraclinics/features/presentation/patient/doctors/widgets/scan_doctor_qr_sheet.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'patient_hospital_doctors_screen.dart';

class PatientSelectHospitalScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialHospitals;
  final ProfileEntity? targetProfile;
  final String? patientName;
  final String? patientPhone;
  final VoidCallback? onAppointmentBooked;

  const PatientSelectHospitalScreen({
    super.key,
    this.initialHospitals,
    this.targetProfile,
    this.patientName,
    this.patientPhone,
    this.onAppointmentBooked,
  });

  @override
  State<PatientSelectHospitalScreen> createState() => _PatientSelectHospitalScreenState();
}

class _PatientSelectHospitalScreenState extends State<PatientSelectHospitalScreen> {
  List<Map<String, dynamic>> _hospitals = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const Color primaryBlue = Color(0xFF2563EB);
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialHospitals != null && widget.initialHospitals!.isNotEmpty) {
      _hospitals = List.from(widget.initialHospitals!);
      _prioritizeDefaultHospital(_hospitals);
      _isLoading = false;
    } else {
      _loadHospitals();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isDefaultHospital(Map<String, dynamic> h) {
    return LikedHospitalsService.isDefaultHospital(h);
  }

  void _prioritizeDefaultHospital(List<Map<String, dynamic>> list) {
    final bool hasDefault = list.any(_isDefaultHospital);
    if (!hasDefault) {
      list.insert(0, {
        'id': 19,
        'name': 'Yira Hospitals',
        'orgId': 1,
        'orgName': 'yira',
        'hospitalCode': 'Hosp11',
        'hospitalType': 'General',
        'city': 'K.V.Rangareddy',
        'state': 'Telangana',
        'country': 'India',
        'address': '6-123, kota , andhra pradesh',
        'mobileNumber': '9908875796',
        'is24Hours': true,
        'isDefault': true,
        'isLinked': true,
        'logo': 'https://yiraappdev.blob.core.windows.net/adminuploadedfiles/yiraai.svg',
        'logoUrl': 'https://yiraappdev.blob.core.windows.net/adminuploadedfiles/yiraai.svg',
      });
    }

    for (final h in list) {
      if (_isDefaultHospital(h)) {
        h['isDefault'] = true;
      }
    }

    list.sort((a, b) {
      final aIsDef = _isDefaultHospital(a);
      final bIsDef = _isDefaultHospital(b);
      if (aIsDef && !bIsDef) return -1;
      if (!aIsDef && bIsDef) return 1;
      return 0;
    });
  }

  Future<void> _loadHospitals() async {
    setState(() => _isLoading = true);
    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = (currentUser?.data?.id ?? '').trim();

    try {
      final list = await LikedHospitalsService.instance.getLikedAndLinkedHospitals(patientId: userId);
      _prioritizeDefaultHospital(list);
      if (mounted) {
        setState(() {
          _hospitals = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatHospitalLocation(Map<String, dynamic> hosp) {
    final address = (hosp['address'] ?? '').toString().trim();
    final city = (hosp['city'] ?? '').toString().trim();
    final state = (hosp['state'] ?? '').toString().trim();

    if (address.isNotEmpty) return address;
    if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
    if (city.isNotEmpty) return city;
    return '';
  }

  String _formatHospitalHelpline(Map<String, dynamic> hosp) {
    final helpline = (hosp['helplineNumber'] ?? '').toString().trim();
    final mobile = (hosp['mobileNumber'] ?? '').toString().trim();
    if (helpline.isNotEmpty) return helpline;
    if (mobile.isNotEmpty) return mobile;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);

    // Filter by search query directly from database fields
    final filteredHospitals = _hospitals.where((h) {
      final name = (h['name'] ?? '').toString().toLowerCase();
      final org = (h['orgName'] ?? '').toString().toLowerCase();
      final code = (h['hospitalCode'] ?? '').toString().toLowerCase();
      final city = (h['city'] ?? '').toString().toLowerCase();
      final addr = (h['address'] ?? '').toString().toLowerCase();
      final type = (h['hospitalType'] ?? '').toString().toLowerCase();
      final q = _searchQuery.trim().toLowerCase();

      return q.isEmpty ||
          name.contains(q) ||
          org.contains(q) ||
          code.contains(q) ||
          city.contains(q) ||
          addr.contains(q) ||
          type.contains(q);
    }).toList();

    // Default hospital (Yira Hospitals) always stays at top
    filteredHospitals.sort((a, b) {
      final aIsDef = _isDefaultHospital(a);
      final bIsDef = _isDefaultHospital(b);
      if (aIsDef && !bIsDef) return -1;
      if (!aIsDef && bIsDef) return 1;
      return 0;
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Select Hospital & Facility",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontWeight: FontWeight.w700,
            fontSize: isTab ? 17.5 : 15.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Scan Doctor / Hospital QR",
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: primaryBlue.withValues(alpha: isDark ? 0.35 : 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: primaryBlue, size: 18),
            ),
            onPressed: () {
              ScanDoctorQrSheet.show(
                context,
                onDoctorLinked: (_) => _loadHospitals(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? _buildMediBuddyShimmer(isDark, isTab)
          : RefreshIndicator(
              color: primaryBlue,
              onRefresh: _loadHospitals,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: EdgeInsets.symmetric(
                  horizontal: isTab ? 28 : 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Search Bar
                    _buildSearchBar(isDark),

                    const SizedBox(height: 12),

                    // 2. MediBuddy "My Doctors" Quick Consult Deck
                    _buildMyDoctorsQuickDeck(isDark, isTab),

                    const SizedBox(height: 16),

                    // 3. Section Counter Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Hospitals & Clinics",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? 16 : 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${filteredHospitals.length} Found",
                                style: const TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            child: const Text(
                              "Clear Search",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 4. MediBuddy Hospital Cards List
                    if (filteredHospitals.isEmpty)
                      _buildEmptyState(isDark, isTab)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredHospitals.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _buildMediBuddyHospitalCard(
                            context: context,
                            hosp: filteredHospitals[index],
                            isDark: isDark,
                            isTab: isTab,
                          );
                        },
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── 1. SEARCH BAR ───────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 13.5,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: "Search by hospital, clinic, specialty, or area...",
          hintStyle: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 12.5,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: primaryBlue),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
      ),
    );
  }

  // ─── 2. MEDIBUDDY QUICK "MY DOCTORS" TRAY ─────────────────────────────
  Widget _buildMyDoctorsQuickDeck(bool isDark, bool isTab) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.025),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (_isNavigating) return;
            _isNavigating = true;
            HapticFeedback.lightImpact();
            await Navigator.pushNamed(context, AppRoutes.patientMyDoctors);
            if (mounted) _loadHospitals();
            _isNavigating = false;
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.asset(
                      'assets/images/dashboard_icons/connected_doctors_thick.png',
                      width: 42,
                      height: 42,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Consult Your Connected Doctors",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "Direct appointment booking with specialists you've visited",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "View",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded, size: 9, color: primaryBlue),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 3. SIGNATURE MEDIBUDDY HOSPITAL CARD (CLEAN: NO STAR / NO FILTERS) ───
  Widget _buildMediBuddyHospitalCard({
    required BuildContext context,
    required Map<String, dynamic> hosp,
    required bool isDark,
    required bool isTab,
  }) {
    // Pure Database fields
    final hospName = (hosp['name'] ?? hosp['hospitalName'] ?? 'Hospital').toString().trim();
    final orgName = (hosp['orgName'] ?? hosp['organizationName'] ?? '').toString().trim();
    final hospType = (hosp['hospitalType'] ?? '').toString().trim();
    final locationStr = _formatHospitalLocation(hosp);
    final helplineStr = _formatHospitalHelpline(hosp);
    final logoUrl = (hosp['logo'] ??
            hosp['logoUrl'] ??
            hosp['imageUrl'] ??
            hosp['hospitalLogo'] ??
            hosp['image'])
        ?.toString();

    String subtitle = '';
    if (hospType.isNotEmpty && orgName.isNotEmpty) {
      subtitle = "$hospType • $orgName";
    } else if (hospType.isNotEmpty) {
      subtitle = hospType;
    } else if (orgName.isNotEmpty) {
      subtitle = orgName;
    }

    final hasAmenities = helplineStr.isNotEmpty;
    final isDefault = _isDefaultHospital(hosp);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDefault
              ? primaryBlue.withValues(alpha: isDark ? 0.6 : 0.4)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isDefault ? 1.4 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDefault
                ? primaryBlue.withValues(alpha: isDark ? 0.15 : 0.08)
                : Colors.black.withValues(alpha: isDark ? 0.25 : 0.035),
            blurRadius: 10,
            offset: const Offset(0, 2.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            if (_isNavigating) return;
            _isNavigating = true;
            HapticFeedback.selectionClick();
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientHospitalDoctorsScreen(
                  hospital: hosp,
                  targetProfile: widget.targetProfile,
                  patientName: widget.patientName,
                  patientPhone: widget.patientPhone,
                  onAppointmentBooked: widget.onAppointmentBooked,
                ),
              ),
            );
            _isNavigating = false;
          },
          child: Padding(
            padding: EdgeInsets.all(isTab ? 18 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── MEDIBUDDY TOP ROW: LEFT LOGO (68x68) + RIGHT DETAILS ───
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Hospital Image / Logo Showcase (From DB)
                    _buildHospitalLogo(
                      logoUrl: logoUrl,
                      size: isTab ? 78 : 68,
                      isDark: isDark,
                      radius: 14,
                    ),
                    const SizedBox(width: 12),

                    // Right Info Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hospital Name with Default Badge if applicable
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  hospName,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: isTab ? 16 : 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: primaryBlue.withValues(alpha: isDark ? 0.25 : 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: primaryBlue.withValues(alpha: isDark ? 0.45 : 0.25),
                                      width: 0.9,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.check_circle_rounded, size: 10.5, color: primaryBlue),
                                      SizedBox(width: 3.5),
                                      Text(
                                        "Default",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),

                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          if (locationStr.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFFEF4444)),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    locationStr,
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // ─── MEDIBUDDY AMENITIES STRIP (DATABASE DRIVEN ONLY) ─────────
                if (hasAmenities) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      if (helplineStr.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: helplineStr));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Helpline copied to clipboard'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: _buildPillChip(
                            label: "Helpline: $helplineStr",
                            icon: Icons.phone_rounded,
                            color: primaryBlue,
                            isDark: isDark,
                          ),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                const SizedBox(height: 9),

                // ─── MEDIBUDDY BOTTOM ACTION BAR ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Right MediBuddy Primary CTA Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            "View Doctors",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── 4. PILL CHIP HELPER ──────────────────────────────────────────────
  Widget _buildPillChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.35 : 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5. HOSPITAL LOGO BADGE ENGINE (DATA FROM DATABASE) ───────────────
  Widget _buildHospitalLogo({
    required String? logoUrl,
    required double size,
    required bool isDark,
    double radius = 12,
  }) {
    Widget fallbackIcon() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.local_hospital_rounded,
            size: size * 0.44,
            color: primaryBlue,
          ),
        ),
      );
    }

    final trimmed = (logoUrl ?? '').trim();
    if (trimmed.isEmpty) {
      return fallbackIcon();
    }

    Widget content;
    if (trimmed.endsWith('.svg')) {
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        content = SvgPicture.network(
          trimmed,
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => fallbackIcon(),
        );
      } else {
        content = SvgPicture.asset(
          trimmed,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      content = CachedNetworkImage(
        imageUrl: trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Center(
          child: SizedBox(
            width: size * 0.35,
            height: size * 0.35,
            child: const CircularProgressIndicator(
              strokeWidth: 1.5,
              color: primaryBlue,
            ),
          ),
        ),
        errorWidget: (context, url, error) => fallbackIcon(),
      );
    } else {
      content = Image.asset(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallbackIcon(),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: content,
        ),
      ),
    );
  }

  // ─── 6. EMPTY STATE ───────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark, bool isTab) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.domain_disabled_rounded, size: 38, color: primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? "No Matching Facilities" : "No Facilities Available",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? "Try searching for a different keyword or clearing your search."
                : "Scan a hospital or doctor QR to connect and view consultation slots.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            onPressed: () {
              if (_searchQuery.isNotEmpty) {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              } else {
                ScanDoctorQrSheet.show(
                  context,
                  onDoctorLinked: (_) => _loadHospitals(),
                );
              }
            },
            icon: Icon(
              _searchQuery.isNotEmpty ? Icons.clear_all_rounded : Icons.qr_code_scanner_rounded,
              size: 18,
            ),
            label: Text(
              _searchQuery.isNotEmpty ? "Clear Search" : "Scan Facility QR",
              style: const TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 7. MEDIBUDDY SHIMMER ─────────────────────────────────────────────
  Widget _buildMediBuddyShimmer(bool isDark, bool isTab) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTab ? 28 : 16, vertical: 16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(3, (index) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
