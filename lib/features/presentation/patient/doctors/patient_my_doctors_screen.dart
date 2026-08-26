import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'widgets/scan_doctor_qr_sheet.dart';

class PatientMyDoctorsScreen extends StatefulWidget {
  const PatientMyDoctorsScreen({super.key});

  @override
  State<PatientMyDoctorsScreen> createState() => _PatientMyDoctorsScreenState();
}

class _PatientMyDoctorsScreenState extends State<PatientMyDoctorsScreen> {
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
    });

    final currentUser = GlobalSession.instance.userNotifier.value;
    final patientId = (currentUser?.data?.id ?? '').toString().trim();
    final token = currentUser?.data?.accessToken ?? '';
    final orgId = currentUser?.data?.latestOrgId ?? 9;
    final hospitalId = currentUser?.data?.latestHospitalId ?? 11;

    if (patientId.isEmpty) {
      if (mounted) {
        setState(() {
          _doctors = [];
          _isLoading = false;
        });
      }
      return;
    }

    final linkedStorageKey = 'patient_linked_doctors_$patientId';
    final unlinkedStorageKey = 'patient_unlinked_doctors_$patientId';

    List<Map<String, dynamic>> fetchedDoctors = [];

    // Get list of removed / unlinked doctors for THIS specific patient
    Set<String> unlinkedKeys = {};
    try {
      final prefs = await SharedPreferences.getInstance();
      final unlinkedList = prefs.getStringList(unlinkedStorageKey) ?? [];
      unlinkedKeys = unlinkedList.map((e) => e.toLowerCase().trim()).toSet();
    } catch (_) {}

    // 1. FIRST: Load locally stored verified scanned / newly added doctors for THIS patient
    try {
      final prefs = await SharedPreferences.getInstance();
      final localStr = prefs.getString(linkedStorageKey);
      if (localStr != null) {
        final List<dynamic> localList = jsonDecode(localStr);
        for (final item in localList) {
          final map = Map<String, dynamic>.from(item);
          final name = (map['name'] ?? '').toString().trim();
          final docId = (map['doctorId'] ?? map['id'] ?? '').toString().trim();

          // Filter out dummy or previously unlinked
          if (name.toLowerCase().contains('sarah jenkins') ||
              name.toLowerCase().contains('robert miller') ||
              unlinkedKeys.contains(name.toLowerCase()) ||
              unlinkedKeys.contains(docId.toLowerCase())) {
            continue;
          }
          if (!fetchedDoctors.any((d) =>
              (d['doctorId'] != null && d['doctorId'] == map['doctorId']) ||
              (d['id'] != null && d['id'] == map['id']) ||
              (d['name'] != null && d['name'].toString().toLowerCase() == name.toLowerCase()))) {
            fetchedDoctors.add(map);
          }
        }
      }
    } catch (_) {}

    // 2. SECOND: Load real doctors from THIS patient's appointment records & append
    try {
      final apptsRes = await sl<ApiClient>().account(showSuccessSnack: false).post(
        '/v1/api/auth/patient-appointments',
        data: {
          "userId": patientId,
          "orgId": orgId,
          "hospitalId": hospitalId,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (apptsRes.statusCode == 200 && apptsRes.data != null) {
        final data = apptsRes.data;
        final list = (data is Map && data['data'] is List) ? data['data'] as List : [];

        for (final appt in list) {
          final docName = (appt['doctorName'] ?? '').toString().trim();
          final docId = (appt['doctorId'] ?? appt['id'] ?? docName).toString().trim();
          
          if (docName.isNotEmpty &&
              docName.toLowerCase() != 'doctor' &&
              !unlinkedKeys.contains(docId.toLowerCase()) &&
              !unlinkedKeys.contains(docName.toLowerCase())) {
            if (!fetchedDoctors.any((d) =>
                (d['name'] != null && d['name'].toString().toLowerCase() == docName.toLowerCase()) ||
                (d['doctorId'] != null && d['doctorId'] == docId) ||
                (d['id'] != null && d['id'] == docId))) {
              fetchedDoctors.add({
                'id': docId,
                'doctorId': docId,
                'name': docName,
                'specialty': (appt['appointmentType'] != null && appt['appointmentType'].toString().isNotEmpty) ? appt['appointmentType'].toString() : 'Consulting Specialist',
                'department': 'General Consultation',
                'hospitalName': (appt['hospitalName'] != null && appt['hospitalName'].toString().isNotEmpty) ? appt['hospitalName'].toString() : 'Yira Clinx Medical Center',
                'qualification': 'Verified Healthcare Provider',
                'experience': '',
                'consultationFee': 500,
                'phoneNumber': '',
                'isLinked': true,
              });
            }
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _doctors = fetchedDoctors;
        _isLoading = false;
      });
    }
  }

  Future<void> _unlinkDoctor(Map<String, dynamic> doctor) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final patientId = (currentUser?.data?.id ?? '').toString().trim();
    final linkedStorageKey = 'patient_linked_doctors_$patientId';
    final unlinkedStorageKey = 'patient_unlinked_doctors_$patientId';

    final docId = (doctor['doctorId'] ?? doctor['id'] ?? '').toString().trim();
    final docName = (doctor['name'] ?? '').toString().trim();

    setState(() {
      _doctors.removeWhere((d) {
        final dId = (d['doctorId'] ?? d['id'] ?? '').toString().trim();
        final dName = (d['name'] ?? '').toString().trim();
        return (docId.isNotEmpty && dId == docId) || (docName.isNotEmpty && dName.toLowerCase() == docName.toLowerCase());
      });
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Remove from user's linked list
      final localStr = prefs.getString(linkedStorageKey);
      if (localStr != null) {
        final List<dynamic> localList = jsonDecode(localStr);
        localList.removeWhere((d) {
          final dId = (d['doctorId'] ?? d['id'] ?? '').toString().trim();
          final dName = (d['name'] ?? '').toString().trim();
          return (docId.isNotEmpty && dId == docId) || (docName.isNotEmpty && dName.toLowerCase() == docName.toLowerCase());
        });
        await prefs.setString(linkedStorageKey, jsonEncode(localList));
      }

      // 2. Add to user's unlinked blacklist so it never gets auto re-added from appointments
      final unlinkedList = prefs.getStringList(unlinkedStorageKey) ?? [];
      if (docId.isNotEmpty && !unlinkedList.contains(docId)) {
        unlinkedList.add(docId);
      }
      if (docName.isNotEmpty && !unlinkedList.contains(docName)) {
        unlinkedList.add(docName);
      }
      await prefs.setStringList(unlinkedStorageKey, unlinkedList);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${docName.isNotEmpty ? docName : 'Doctor'} removed from My Doctors'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _confirmRemoveDoctor(BuildContext context, Map<String, dynamic> doctor) {
    final name = (doctor['name'] ?? 'Doctor').toString();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.person_remove_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Remove Doctor',
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove $name from My Doctors?',
          style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _unlinkDoctor(doctor);
            },
            child: const Text('Remove', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

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
    final isTab = isTablet(context);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final filteredDoctors = _doctors.where((d) {
      final name = (d['name'] ?? '').toString().toLowerCase();
      final specialty = (d['specialty'] ?? '').toString().toLowerCase();
      final hospital = (d['hospitalName'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || specialty.contains(q) || hospital.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          'My Doctors',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: isTab ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.qr_code_scanner_rounded, color: primaryColor, size: 20),
            ),
            tooltip: 'Scan Doctor QR Code',
            onPressed: () => ScanDoctorQrSheet.show(
              context,
              onDoctorLinked: (newDoc) {
                setState(() {
                  _doctors.removeWhere((d) =>
                      (d['doctorId'] != null && d['doctorId'] == newDoc['doctorId']) ||
                      (d['id'] != null && d['id'] == newDoc['id']) ||
                      (d['name'] != null && d['name'] == newDoc['name']));
                  _doctors.insert(0, newDoc);
                });
                _loadDoctors();
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDoctors,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Search by doctor name or specialty...',
                        hintStyle: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                        ),
                        prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.grey.shade500),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Connected Doctors',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? 16 : 15,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${filteredDoctors.length}',
                                style: TextStyle(
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
            onPressed: () => ScanDoctorQrSheet.show(
              context,
              onDoctorLinked: (newDoc) {
                setState(() {
                  _doctors.removeWhere((d) =>
                      (d['doctorId'] != null && d['doctorId'] == newDoc['doctorId']) ||
                      (d['id'] != null && d['id'] == newDoc['id']) ||
                      (d['name'] != null && d['name'] == newDoc['name']));
                  _doctors.insert(0, newDoc);
                });
                _loadDoctors();
              },
            ),
                          icon: Icon(Icons.add_circle_outline_rounded, size: 16, color: primaryColor),
                          label: Text(
                            'Add Doctor',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Doctor Cards List
                    if (filteredDoctors.isEmpty)
                      _buildEmptyState(context, isDark, primaryColor)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredDoctors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          return _buildDoctorCard(context, filteredDoctors[index], isDark, primaryColor, isTab);
                        },
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDoctorCard(
    BuildContext context,
    Map<String, dynamic> doctor,
    bool isDark,
    Color primaryColor,
    bool isTab,
  ) {
    final name = (doctor['name'] ?? 'Dr. Medical Specialist').toString();
    final initials = _getInitials(name);
    final specialty = (doctor['specialty'] ?? 'General Physician').toString();
    final hospital = (doctor['hospitalName'] ?? 'Yira Clinx Medical Center').toString();
    final experience = (doctor['experience'] ?? '10+ Years Exp.').toString();
    final fee = doctor['consultationFee'] != null ? '₹${doctor['consultationFee']}' : '₹500';
    final docId = (doctor['doctorId'] ?? doctor['id'] ?? '').toString();

    return Container(
      padding: EdgeInsets.all(isTab ? 18 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
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
              // Doctor Avatar
              Container(
                width: isTab ? 58 : 50,
                height: isTab ? 58 : 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.8),
                      primaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Doctor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 16 : 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.more_vert_rounded, size: 18, color: isDark ? Colors.white54 : Colors.grey.shade600),
                          onSelected: (val) {
                            if (val == 'unlink') {
                              _confirmRemoveDoctor(context, doctor);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'unlink',
                              child: Row(
                                children: [
                                  Icon(Icons.person_remove_outlined, size: 18, color: Colors.redAccent),
                                  SizedBox(width: 8),
                                  Text('Remove Doctor', style: TextStyle(fontFamily: appPoppinFont, color: Colors.redAccent, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_hospital_rounded, size: 13, color: isDark ? Colors.white38 : Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hospital,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

          // Badges Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 12, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                    const SizedBox(width: 4),
                    Text(
                      experience,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments_rounded, size: 12, color: Color(0xFF059669)),
                    const SizedBox(width: 4),
                    Text(
                      fee,
                      style: const TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF0284C7)),
                    SizedBox(width: 4),
                    Text(
                      'Connected',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.addAppointmentScreen);
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 15, color: Colors.white),
                  label: const Text(
                    'Book Appointment',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medical_services_outlined, size: 48, color: primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'No Connected Doctors',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan your doctor\'s QR code or enter their profile link to connect and easily book appointments!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: () => ScanDoctorQrSheet.show(
              context,
              onDoctorLinked: (newDoc) {
                setState(() {
                  _doctors.removeWhere((d) =>
                      (d['doctorId'] != null && d['doctorId'] == newDoc['doctorId']) ||
                      (d['id'] != null && d['id'] == newDoc['id']) ||
                      (d['name'] != null && d['name'] == newDoc['name']));
                  _doctors.insert(0, newDoc);
                });
                _loadDoctors();
              },
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
            label: const Text(
              'Scan Doctor QR Code',
              style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
