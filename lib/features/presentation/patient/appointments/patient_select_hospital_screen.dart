import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/services/liked_hospitals_service.dart';
import 'package:yiraclinics/core/widgets/entity_logo.dart';
import 'package:yiraclinics/core/widgets/phosphor_icons.dart';
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
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF232323) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsBold.caretLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Book an appointment",
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
              child: const PhosphorIcon(PhosphorIconsBold.qrCode, color: primaryBlue, size: 18),
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
                              "Hospitals & clinics",
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
                                "${filteredHospitals.length}",
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
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0),
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
          hintText: "Search hospital, clinic or area",
          hintStyle: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 12.5,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
          prefixIcon: const PhosphorIcon(PhosphorIconsBold.magnifyingGlass, size: 19, color: Color(0xFF64748B)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const PhosphorIcon(PhosphorIconsBold.x, size: 16),
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
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0),
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
                    color: primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const PhosphorIcon(PhosphorIconsDuotone.stethoscope, size: 22, color: primaryBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your connected doctors",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "Book again with doctors you have visited",
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
                      PhosphorIcon(PhosphorIconsBold.caretRight, size: 11, color: primaryBlue),
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

  // ─── 3. HOSPITAL CARD ─────────────────────────────────────────────────
  Widget _buildMediBuddyHospitalCard({
    required BuildContext context,
    required Map<String, dynamic> hosp,
    required bool isDark,
    required bool isTab,
  }) {
    final hospName = (hosp['name'] ?? hosp['hospitalName'] ?? 'Hospital').toString().trim();
    final orgName = (hosp['orgName'] ?? hosp['organizationName'] ?? '').toString().trim();
    final hospType = (hosp['hospitalType'] ?? '').toString().trim();
    final locationStr = _formatHospitalLocation(hosp);
    final helplineStr = _formatHospitalHelpline(hosp);
    final logoUrl = (hosp['logo'] ?? hosp['logoUrl'] ?? hosp['imageUrl'] ?? hosp['hospitalLogo'] ?? hosp['image'])?.toString();
    final isDefault = _isDefaultHospital(hosp);

    // "General · YIRA" adds nothing when the organisation is the hospital itself.
    final subtitleParts = <String>[
      if (hospType.isNotEmpty) hospType,
      if (orgName.isNotEmpty && orgName.toLowerCase() != hospName.toLowerCase()) orgName,
    ];

    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final strong = isDark ? Colors.white : const Color(0xFF0F172A);

    Future<void> open() async {
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
    }

    return Material(
      color: isDark ? const Color(0xFF232323) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: open,
        child: Ink(
          decoration: BoxDecoration(
            // Solid fill so the shadow stays behind the card.
            color: isDark ? const Color(0xFF232323) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDefault
                  ? primaryBlue.withValues(alpha: isDark ? 0.55 : 0.35)
                  : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0)),
              width: isDefault ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.all(isTab ? 18 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EntityLogo(imageUrl: logoUrl, name: hospName, size: isTab ? 64 : 56, radius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isDefault)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryBlue.withValues(alpha: isDark ? 0.22 : 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  PhosphorIcon(PhosphorIconsFill.sealCheck, size: 11, color: primaryBlue),
                                  SizedBox(width: 4),
                                  Text(
                                    "Your default clinic",
                                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 10, fontWeight: FontWeight.w700, color: primaryBlue),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Text(
                          hospName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 16 : 15,
                            fontWeight: FontWeight.w700,
                            color: strong,
                            height: 1.25,
                          ),
                        ),
                        if (subtitleParts.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitleParts.join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w500, color: muted),
                          ),
                        ],
                        if (locationStr.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: PhosphorIcon(PhosphorIconsFill.mapPin, size: 13, color: muted),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  locationStr,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11.5,
                                    height: 1.35,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  ),
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
              const SizedBox(height: 12),
              Divider(height: 1, color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (helplineStr.isNotEmpty)
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: helplineStr));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Helpline number copied'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              PhosphorIcon(PhosphorIconsBold.phone, size: 14, color: muted),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  helplineStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: muted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "View doctors",
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w700, color: primaryBlue),
                      ),
                      SizedBox(width: 4),
                      PhosphorIcon(PhosphorIconsBold.arrowRight, size: 14, color: primaryBlue),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0),
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
            child: const PhosphorIcon(PhosphorIconsDuotone.hospital, size: 38, color: primaryBlue),
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
              _searchQuery.isNotEmpty ? PhosphorIconsBold.x : PhosphorIconsBold.qrCode,
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
      baseColor: isDark ? const Color(0xFF232323) : const Color(0xFFE2E8F0),
      highlightColor: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF8FAFC),
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
