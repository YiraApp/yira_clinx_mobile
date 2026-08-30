import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/services/liked_hospitals_service.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/presentation/appointments/add_new_appointment_screen.dart';
import 'package:yiraclinics/features/presentation/appointments/appointment_bloc/appointment_bloc.dart';
import 'package:yiraclinics/features/presentation/patient/doctors/widgets/scan_doctor_qr_sheet.dart';

class PatientHospitalDoctorsScreen extends StatefulWidget {
  final Map<String, dynamic> hospital;
  final VoidCallback? onAppointmentBooked;

  const PatientHospitalDoctorsScreen({
    super.key,
    required this.hospital,
    this.onAppointmentBooked,
  });

  @override
  State<PatientHospitalDoctorsScreen> createState() => _PatientHospitalDoctorsScreenState();
}

class _PatientHospitalDoctorsScreenState extends State<PatientHospitalDoctorsScreen> {
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  String _searchQuery = '';

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
    final hospName = widget.hospital['name'] ?? 'Hospital';
    final orgName = widget.hospital['orgName'] ?? 'Healthcare Network';

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
        title: Column(
          children: [
            Text(
              "Select Doctor",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.w700,
                fontSize: isTab ? 19 : 16.5,
              ),
            ),
            Text(
              "$hospName • $orgName",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.w500,
                fontSize: 11.5,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: primaryColor),
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
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
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
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search doctor by name, specialty, or qualification...",
                        hintStyle: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12.5,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: primaryColor),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Title Bar with Doctor Count Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Available Doctors",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 16 : 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${filteredDoctors.length}",
                              style: const TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () {
                          ScanDoctorQrSheet.show(
                            context,
                            onDoctorLinked: (_) => _loadDoctors(),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: primaryColor),
                        label: const Text(
                          "Scan QR",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildDoctorCard(BuildContext context, Map<String, dynamic> doc, bool isDark, bool isTab) {
    final docName = (doc['name'] ?? 'Doctor').toString();
    final specialty = (doc['specialty'] ?? 'General Physician').toString();
    final department = (doc['department'] ?? 'General').toString();
    final qualification = (doc['qualification'] ?? 'MBBS, MD').toString();
    final experience = (doc['experience'] ?? '5+ Years Exp.').toString();
    final regNo = (doc['registrationNumber'] ?? '').toString().trim();
    final imagePath = (doc['imagePath'] ?? doc['profileImage'] ?? '').toString().trim();
    final fee = doc['consultationFee'] ?? 0;

    final initial = docName.replaceFirst('Dr. ', '').trim().isNotEmpty
        ? docName.replaceFirst('Dr. ', '').trim()[0].toUpperCase()
        : 'D';

    final hospId = widget.hospital['id'] ?? widget.hospital['hospitalId'];
    final hospName = widget.hospital['name'] ?? 'Hospital';
    final orgId = widget.hospital['orgId'] ?? widget.hospital['organizationId'] ?? 1;

    final bool hasImage = imagePath.isNotEmpty && (imagePath.startsWith('http://') || imagePath.startsWith('https://'));

    return Container(
      padding: EdgeInsets.all(isTab ? 20 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
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
              // Doctor Photo or Avatar
              Container(
                width: isTab ? 64 : 56,
                height: isTab ? 64 : 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: hasImage
                      ? Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildInitialsAvatar(initial),
                        )
                      : _buildInitialsAvatar(initial),
                ),
              ),
              const SizedBox(width: 14),

              // Doctor Info Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            docName,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 16.5 : 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF2563EB)),
                      ],
                    ),
                    const SizedBox(height: 2),

                    // Qualification & Experience & Reg No
                    Text(
                      qualification.isNotEmpty
                          ? (regNo.isNotEmpty ? "$qualification • $experience • Reg: $regNo" : "$qualification • $experience")
                          : (regNo.isNotEmpty ? "$experience • Reg: $regNo" : experience),
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Specialty & Department Badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            specialty,
                            style: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        if (department.isNotEmpty && department != specialty && department != 'General')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              department,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Bottom Bar: Registration / Stats + Dynamic Consultation Fee + Book Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fee Tag
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Consultation Fee",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    fee == 0 ? "Free" : "₹$fee",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: fee == 0 ? const Color(0xFF059669) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),

              // Book Appointment Action Button (InkWell container for robust layout constraints)
              InkWell(
                onTap: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: sl<AppointmentBloc>(),
                        child: AddNewAppointmentScreen(
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

                  if (res == true && mounted) {
                    widget.onAppointmentBooked?.call();
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        "Book Appointment",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String initial) {
    return Container(
      color: primaryColor.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
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
          Icon(Icons.person_search_rounded, size: 48, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
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
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: Colors.white),
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
