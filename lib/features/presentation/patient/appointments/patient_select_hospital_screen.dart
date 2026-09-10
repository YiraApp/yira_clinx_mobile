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
import 'patient_hospital_doctors_screen.dart';

class PatientSelectHospitalScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialHospitals;
  final VoidCallback? onAppointmentBooked;

  const PatientSelectHospitalScreen({
    super.key,
    this.initialHospitals,
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

  @override
  void initState() {
    super.initState();
    if (widget.initialHospitals != null && widget.initialHospitals!.isNotEmpty) {
      _hospitals = List.from(widget.initialHospitals!);
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

  Future<void> _loadHospitals() async {
    setState(() => _isLoading = true);
    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = (currentUser?.data?.id ?? '').trim();

    try {
      final list = await LikedHospitalsService.instance.getLikedAndLinkedHospitals(patientId: userId);
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
    return 'Location Details Available on Profile';
  }

  String _formatHospitalTimings(Map<String, dynamic> hosp) {
    final is24Hours = hosp['is24Hours'] == true;
    if (is24Hours) return 'Open 24/7 • Emergency Ready';

    final openTime = (hosp['openingTime'] ?? '').toString().trim();
    final closeTime = (hosp['closingTime'] ?? '').toString().trim();

    if (openTime.isNotEmpty && closeTime.isNotEmpty) {
      return 'OPD: $openTime - $closeTime';
    }
    return 'Regular Clinical & OPD Hours';
  }

  String _formatHospitalHelpline(Map<String, dynamic> hosp) {
    final helpline = (hosp['helplineNumber'] ?? '').toString().trim();
    final mobile = (hosp['mobileNumber'] ?? '').toString().trim();
    if (helpline.isNotEmpty) return helpline;
    if (mobile.isNotEmpty) return mobile;
    return '+91 8008123456';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);

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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        title: Column(
          children: [
            Text(
              "Select Hospital & Facility",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.w700,
                fontSize: isTab ? 19 : 16.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              "Choose where you want to consult doctors",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: primaryBlue, size: 20),
            ),
            tooltip: "Scan Doctor/Hospital QR",
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
          ? _buildHospitalsShimmer(isDark, isTab)
          : RefreshIndicator(
              color: primaryBlue,
              onRefresh: _loadHospitals,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: EdgeInsets.symmetric(
                  horizontal: isTab ? 32 : 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    _buildSearchBar(isDark),

                    const SizedBox(height: 14),

                    // My Doctors Quick Access Card
                    _buildMyDoctorsCard(isDark, isTab),

                    const SizedBox(height: 18),

                    // Section Title & Quick Info Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Linked Facilities",
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: primaryBlue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: primaryBlue.withValues(alpha: 0.25),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                "${filteredHospitals.length} ${filteredHospitals.length == 1 ? 'Hospital' : 'Hospitals'}",
                                style: const TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            ScanDoctorQrSheet.show(
                              context,
                              onDoctorLinked: (_) => _loadHospitals(),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.add_circle_outline_rounded, size: 15, color: primaryBlue),
                                SizedBox(width: 4),
                                Text(
                                  "Link Hospital",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Hospital Cards List or Empty State
                    if (filteredHospitals.isEmpty)
                      _buildEmptyState(isDark, isTab)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredHospitals.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _buildHospitalCard(
                            context,
                            filteredHospitals[index],
                            isDark,
                            isTab,
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
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
          hintText: "Search by hospital name, city, address, or code...",
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

  Widget _buildHospitalLogo(String? logoUrl, bool isDark, bool isTab) {
    final double size = isTab ? 56 : 48;
    final double iconSize = isTab ? 28 : 24;

    Widget fallbackIcon() {
      return Center(
        child: Icon(
          Icons.local_hospital_rounded,
          color: isDark ? const Color(0xFF93C5FD) : primaryBlue,
          size: iconSize,
        ),
      );
    }

    final trimmed = (logoUrl ?? '').trim();
    if (trimmed.isEmpty) {
      return fallbackIcon();
    }

    if (trimmed.endsWith('.svg')) {
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: SvgPicture.network(
              trimmed,
              width: size,
              height: size,
              fit: BoxFit.contain,
              placeholderBuilder: (context) => fallbackIcon(),
            ),
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: SvgPicture.asset(
              trimmed,
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
          ),
        );
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: trimmed,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? const Color(0xFF93C5FD) : primaryBlue,
              ),
            ),
          ),
          errorWidget: (context, url, error) => fallbackIcon(),
        ),
      );
    } else if (trimmed.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset(
            trimmed,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => fallbackIcon(),
          ),
        ),
      );
    }

    return fallbackIcon();
  }

  Widget _buildMyDoctorsCard(bool isDark, bool isTab) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            await Navigator.pushNamed(context, AppRoutes.patientMyDoctors);
            if (mounted) {
              _loadHospitals();
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTab ? 20 : 16,
              vertical: isTab ? 16 : 14,
            ),
            child: Row(
              children: [
                // Solid Doctor Icon Container (No Gradients)
                Container(
                  width: isTab ? 52 : 46,
                  height: isTab ? 52 : 46,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: isTab ? 24 : 21,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "My Doctors",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 16 : 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.3 : 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Quick Consult",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Consult your connected specialists & physicians",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Arrow CTA Button
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard(
    BuildContext context,
    Map<String, dynamic> hosp,
    bool isDark,
    bool isTab,
  ) {
    final hospName = (hosp['name'] ?? 'Hospital & Clinic').toString();
    final orgName = (hosp['orgName'] ?? 'Healthcare Facility Network').toString();
    final hospType = (hosp['hospitalType'] ?? 'Hospital Facility').toString();

    final locationStr = _formatHospitalLocation(hosp);
    final timingsStr = _formatHospitalTimings(hosp);
    final helplineStr = _formatHospitalHelpline(hosp);
    final totalBeds = hosp['totalBeds'];
    final is24Hours = hosp['is24Hours'] == true;
    final logoUrl = (hosp['logo'] ??
            hosp['logoUrl'] ??
            hosp['imageUrl'] ??
            hosp['hospitalLogo'] ??
            hosp['image'])
        ?.toString();

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientHospitalDoctorsScreen(
              hospital: hosp,
              onAppointmentBooked: widget.onAppointmentBooked,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : const Color(0xFF64748B).withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── CARD HEADER: ICON, NAME, ORG, TYPE & FAVORITE ────────
            Padding(
              padding: EdgeInsets.fromLTRB(isTab ? 20 : 16, isTab ? 18 : 16, isTab ? 20 : 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Facility Brand Container (Hospital Logo if available, otherwise Icon)
                  Container(
                    width: isTab ? 56 : 48,
                    height: isTab ? 56 : 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1.1,
                      ),
                    ),
                    child: _buildHospitalLogo(logoUrl, isDark, isTab),
                  ),
                  const SizedBox(width: 12),

                  // Hospital Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospName,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 16.5 : 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.apartment_rounded,
                              size: 13,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                orgName,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Hospital Type Pill from DB
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                hospType,
                                style: const TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                            ),
                            if (is24Hours) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "24/7",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                            if (totalBeds != null && totalBeds > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.2 : 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "$totalBeds Beds",
                                  style: const TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── DATABASE METADATA: LOCATION, TIMINGS, CONTACT ──────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTab ? 20 : 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEF4444)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            locationStr,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Timings & Helpline
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            timingsStr,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone_rounded, size: 12, color: primaryBlue),
                            const SizedBox(width: 4),
                            Text(
                              helplineStr,
                              style: const TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),

            // ─── FOOTER: VERIFIED STATUS & CTA BUTTON ────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(isTab ? 20 : 16, 11, isTab ? 20 : 16, isTab ? 14 : 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Verified Facility Trust Badge (No # HOSP- tag)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Verified Facility",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),

                  // Explore Doctors Primary CTA (Solid Primary Blue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.28),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "View Doctors",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, bool isTab) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
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
            child: const Icon(Icons.domain_disabled_rounded, size: 40, color: primaryBlue),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? "No Matching Hospitals" : "No Linked Hospitals Found",
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
                ? "Try searching for a different hospital name, city, or address."
                : "Scan your doctor's QR code to link their hospital and view available consultation slots.",
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
                setState(() => _searchQuery = '');
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
              _searchQuery.isNotEmpty ? "Clear Search" : "Scan Hospital / Doctor QR",
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

  Widget _buildHospitalsShimmer(bool isDark, bool isTab) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isTab ? 32 : 16, vertical: 16),
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
            const SizedBox(height: 16),
            ...List.generate(3, (index) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              width: double.infinity,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
