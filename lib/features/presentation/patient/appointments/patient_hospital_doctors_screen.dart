import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/services/liked_hospitals_service.dart';
import 'package:yiraclinics/core/widgets/entity_logo.dart';
import 'package:yiraclinics/core/widgets/phosphor_icons.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/presentation/appointments/add_new_appointment_screen.dart';
import 'package:yiraclinics/features/presentation/appointments/appointment_bloc/appointment_bloc.dart';
import 'package:yiraclinics/features/presentation/patient/doctors/widgets/scan_doctor_qr_sheet.dart';

import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';

class PatientHospitalDoctorsScreen extends StatefulWidget {
  final Map<String, dynamic> hospital;
  final ProfileEntity? targetProfile;
  final String? patientName;
  final String? patientPhone;
  final VoidCallback? onAppointmentBooked;

  const PatientHospitalDoctorsScreen({
    super.key,
    required this.hospital,
    this.targetProfile,
    this.patientName,
    this.patientPhone,
    this.onAppointmentBooked,
  });

  @override
  State<PatientHospitalDoctorsScreen> createState() => _PatientHospitalDoctorsScreenState();
}

class _PatientHospitalDoctorsScreenState extends State<PatientHospitalDoctorsScreen> {
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isBookingNavigating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    final hospId = widget.hospital['id'] ?? widget.hospital['hospitalId'];

    try {
      final list = await LikedHospitalsService.instance.getLinkedDoctorsForHospital(
        hospitalId: hospId,
      );
      if (mounted) {
        setState(() {
          _doctors = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTab = isTablet(context);

    final filteredDoctors = _doctors.where((doc) {
      final name = (doc['name'] ?? '').toString().toLowerCase();
      final specialty = (doc['specialty'] ?? '').toString().toLowerCase();
      final dept = (doc['department'] ?? '').toString().toLowerCase();
      final qual = (doc['qualification'] ?? '').toString().toLowerCase();

      // Exclude test/dummy doctors
      if (name.contains('test') ||
          name.contains('dummy') ||
          name.contains('sample') ||
          name.contains('demo') ||
          name.contains('fake') ||
          name.contains('sarah jenkins') ||
          name.contains('robert miller')) {
        return false;
      }

      final q = _searchQuery.trim().toLowerCase();
      return q.isEmpty || name.contains(q) || specialty.contains(q) || dept.contains(q) || qual.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
        title: Text(
          "Choose a doctor",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontWeight: FontWeight.w700,
            fontSize: isTab ? 18 : 16,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsBold.caretLeft, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsBold.qrCode, color: primaryColor, size: 22),
            tooltip: "Scan Doctor QR",
            onPressed: () {
              ScanDoctorQrSheet.show(
                context,
                onDoctorLinked: (_) => _loadDoctors(),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildDoctorsShimmer(isDark, isTab)
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isTab ? 32 : 16,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: "Search by name or specialty",
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
                  ),

                  const SizedBox(height: 18),

                  _buildHospitalHeader(isDark, isTab),
                  const SizedBox(height: 18),
                  Text(
                    filteredDoctors.length == 1 ? "1 doctor" : "${filteredDoctors.length} doctors",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (filteredDoctors.isEmpty)
                    _buildEmptyState(isDark, isTab)
                  else
                    Column(
                      children: [
                        for (int i = 0; i < filteredDoctors.length; i++) ...[
                          _buildDoctorCard(context, filteredDoctors[i], isDark, isTab),
                          if (i < filteredDoctors.length - 1) const SizedBox(height: 14),
                        ],
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  /// "6" → "6 yrs experience"; text values are shown as they are.
  static String _experienceLabel(dynamic raw) {
    final text = (raw ?? '').toString().trim();
    if (text.isEmpty || text == 'null' || text == '0') return '';
    final years = num.tryParse(text);
    if (years != null) return years == 1 ? '1 yr experience' : '${years.toString().replaceAll(RegExp(r'\.0$'), '')} yrs experience';
    return text;
  }

  Widget _buildHospitalHeader(bool isDark, bool isTab) {
    final hosp = widget.hospital;
    final name = (hosp['name'] ?? hosp['hospitalName'] ?? 'Hospital').toString().trim();
    final type = (hosp['hospitalType'] ?? '').toString().trim();
    final address = (hosp['address'] ?? '').toString().trim();
    final city = (hosp['city'] ?? '').toString().trim();
    final place = address.isNotEmpty ? address : city;
    final logo = (hosp['logo'] ?? hosp['logoUrl'] ?? hosp['imageUrl'] ?? hosp['hospitalLogo'])?.toString();
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          EntityLogo(imageUrl: logo, name: name, size: 46, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (type.isNotEmpty || place.isNotEmpty)
                  Text(
                    [if (type.isNotEmpty) type, if (place.isNotEmpty) place].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBooking(Map<String, dynamic> doc) async {
    if (_isBookingNavigating) return;
    _isBookingNavigating = true;
    final hospId = widget.hospital['id'] ?? widget.hospital['hospitalId'];
    final hospName = widget.hospital['name'] ?? 'Hospital';
    final orgId = widget.hospital['orgId'] ?? widget.hospital['organizationId'] ?? 1;
    final docName = (doc['name'] ?? 'Doctor').toString();
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: sl<AppointmentBloc>(),
          child: AddNewAppointmentScreen(
            initialPatientName: widget.patientName ??
                widget.targetProfile?.name ??
                (widget.targetProfile != null
                    ? '${widget.targetProfile!.firstName ?? ''} ${widget.targetProfile!.lastName ?? ''}'.trim()
                    : null),
            initialPatientPhone: widget.patientPhone ?? widget.targetProfile?.phoneNumber,
            initialDoctorId: (doc['doctorId'] ?? doc['userId'] ?? doc['id'])?.toString(),
            initialDoctorName: docName,
            initialHospitalId: hospId,
            initialDoctor: {
              ...doc,
              'hospitalId': hospId,
              'hospitalName': hospName,
              'orgId': orgId,
            },
          ),
        ),
      ),
    );
    _isBookingNavigating = false;
    if (res == true && mounted) {
      widget.onAppointmentBooked?.call();
    }
  }

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> doc, bool isDark, bool isTab) {
    final docName = (doc['name'] ?? 'Doctor').toString().trim();
    final specialty = (doc['specialty'] ?? '').toString().trim();
    final department = (doc['department'] ?? '').toString().trim();
    final qualification = (doc['qualification'] ?? '').toString().trim();
    final experience = _experienceLabel(doc['experience']);
    final imagePath = (doc['imagePath'] ?? doc['profileImage'] ?? '').toString().trim();
    final rawFee = doc['consultationFee'];
    final fee = rawFee == null ? 0 : (num.tryParse(rawFee.toString()) ?? 0);

    final strong = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);
    final showDepartment = department.isNotEmpty &&
        department.toLowerCase() != specialty.toLowerCase() &&
        department.toLowerCase() != 'general';

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openBooking(doc),
        child: Ink(
          padding: EdgeInsets.all(isTab ? 18 : 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EntityLogo(imageUrl: imagePath, name: docName, size: isTab ? 64 : 58, radius: 16, isLogo: false),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            text: docName,
                            children: const [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: PhosphorIcon(PhosphorIconsFill.sealCheck, size: 16, color: Color(0xFF2563EB)),
                                ),
                              ),
                            ],
                          ),
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
                        if (qualification.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            qualification,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w500, color: muted),
                          ),
                        ],
                        if (specialty.isNotEmpty || showDepartment || experience.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (specialty.isNotEmpty) _tag(PhosphorIconsBold.stethoscope, specialty, primaryColor, isDark),
                              if (showDepartment) _tag(PhosphorIconsBold.buildings, department, const Color(0xFF475569), isDark),
                              if (experience.isNotEmpty) _tag(PhosphorIconsBold.briefcase, experience, const Color(0xFF0D9488), isDark),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: fee == 0 ? "Free" : "₹${fee.toString().replaceAll(RegExp(r'\.0$'), '')}",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: fee == 0 ? const Color(0xFF059669) : strong,
                            ),
                          ),
                          TextSpan(
                            text: "  consultation",
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w500, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openBooking(doc),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const PhosphorIcon(PhosphorIconsBold.calendarPlus, size: 16, color: Colors.white),
                    label: const Text(
                      "Book",
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, bool isTab) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          PhosphorIcon(PhosphorIconsDuotone.stethoscope, size: 44, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            "No Doctors Found",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "No connected doctors found for this hospital. Scan your doctor's QR code to link them.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            ),
            onPressed: () {
              ScanDoctorQrSheet.show(
                context,
                onDoctorLinked: (_) => _loadDoctors(),
              );
            },
            icon: const PhosphorIcon(PhosphorIconsBold.qrCode, size: 18, color: Colors.white),
            label: const Text(
              "Scan Doctor QR",
              style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsShimmer(bool isDark, bool isTab) {
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
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 20),
            ...List.generate(3, (index) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              width: double.infinity,
              height: 140,
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
