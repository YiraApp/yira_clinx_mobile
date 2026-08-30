import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/core/urls/urls.dart';
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
  String _selectedSpecialty = 'All';

  static const Color _primaryBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final patientId = (currentUser?.data?.id ?? '').toString().trim();

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
    Set<String> unlinkedIds = {};

    try {
      final prefs = await SharedPreferences.getInstance();
      unlinkedIds = (prefs.getStringList(unlinkedStorageKey) ?? []).toSet();

      // 1. Load explicitly linked / scanned doctors from local storage
      final localStr = prefs.getString(linkedStorageKey);
      if (localStr != null) {
        final List<dynamic> localList = jsonDecode(localStr);
        for (final item in localList) {
          final map = Map<String, dynamic>.from(item);
          final name = (map['name'] ?? '').toString().trim();
          final docId = (map['doctorId'] ?? map['id'] ?? '').toString().trim();

          if (_isTestDoctor(name)) continue;
          if (docId.isNotEmpty && unlinkedIds.contains(docId)) continue;
          if (name.isNotEmpty && unlinkedIds.contains(name.toLowerCase())) continue;

          if (!fetchedDoctors.any((d) =>
              (docId.isNotEmpty && (d['doctorId'] == docId || d['id'] == docId)) ||
              (d['name'] != null && d['name'].toString().toLowerCase() == name.toLowerCase()))) {
            fetchedDoctors.add(map);
          }
        }
      }

      // 2. Fetch doctors from hospital backend if available
      final token = currentUser?.data?.accessToken ?? '';
      final hospId = currentUser?.data?.latestHospitalId?.toString() ?? '1';
      if (token.isNotEmpty) {
        try {
          final res = await sl<ApiClient>().account(showSuccessSnack: false).get(
            URLs.hospitalDoctorsUrl,
            queryParameters: {'hospitalId': hospId},
            options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
          );

          if (res.data != null && res.data['data'] is List) {
            final List<dynamic> apiList = res.data['data'] as List;
            for (final item in apiList) {
              if (item is Map<String, dynamic>) {
                final map = Map<String, dynamic>.from(item);
                final name = (map['name'] ?? map['displayName'] ?? '').toString().trim();
                final docId = (map['doctorId'] ?? map['id'] ?? map['userId'] ?? '').toString().trim();

                if (_isTestDoctor(name)) continue;
                if (docId.isNotEmpty && unlinkedIds.contains(docId)) continue;
                if (name.isNotEmpty && unlinkedIds.contains(name.toLowerCase())) continue;

                if (!fetchedDoctors.any((d) =>
                    (docId.isNotEmpty && (d['doctorId'] == docId || d['id'] == docId)) ||
                    (d['name'] != null && d['name'].toString().toLowerCase() == name.toLowerCase()))) {
                  fetchedDoctors.add(map);
                }
              }
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _doctors = fetchedDoctors;
        _isLoading = false;
      });
    }
  }

  bool _isTestDoctor(String name) {
    final lower = name.toLowerCase();
    return lower.contains('test') ||
        lower.contains('dummy') ||
        lower.contains('sample') ||
        lower.contains('demo') ||
        lower.contains('fake') ||
        lower.contains('sarah jenkins') ||
        lower.contains('robert miller');
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

      // 2. Add to user's unlinked blacklist
      final unlinkedList = prefs.getStringList(unlinkedStorageKey) ?? [];
      if (docId.isNotEmpty && !unlinkedList.contains(docId)) {
        unlinkedList.add(docId);
      }
      if (docName.isNotEmpty && !unlinkedList.contains(docName.toLowerCase())) {
        unlinkedList.add(docName.toLowerCase());
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
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 10),
            Text(
              'Remove Doctor',
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove $name from My Doctors?',
          style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // ─── EXTRACT DOCTOR PHOTO URL / BASE64 ─────────────────────────────────────
  String _extractDoctorPhoto(Map<String, dynamic> doc) {
    final raw = (doc['imagePath'] ??
            doc['ImagePath'] ??
            doc['photo'] ??
            doc['Photo'] ??
            doc['photoUrl'] ??
            doc['PhotoUrl'] ??
            doc['profilePhoto'] ??
            doc['ProfilePhoto'] ??
            doc['profilePicture'] ??
            doc['ProfilePicture'] ??
            doc['avatarUrl'] ??
            doc['avatar'] ??
            doc['image'] ??
            '')
        .toString()
        .trim();

    return raw;
  }

  // ─── DOCTOR AVATAR WIDGET (PHOTO OR INITIALS) ──────────────────────────────
  Widget _buildDoctorAvatar(Map<String, dynamic> doctor, bool isDark, bool isTab) {
    final name = (doctor['name'] ?? doctor['displayName'] ?? 'Doctor').toString();
    final initials = _getInitials(name);
    final photoUrl = _extractDoctorPhoto(doctor);
    final size = isTab ? 58.0 : 50.0;

    Widget avatarContent;

    if (photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('data:image')) {
        // Base64 Data URI
        try {
          final commaIdx = photoUrl.indexOf(',');
          final base64Data = commaIdx != -1 ? photoUrl.substring(commaIdx + 1) : photoUrl;
          final Uint8List bytes = base64Decode(base64Data);
          avatarContent = Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitialsFallback(initials, size, isDark),
          );
        } catch (_) {
          avatarContent = _buildInitialsFallback(initials, size, isDark);
        }
      } else {
        // HTTP/HTTPS Network URL
        String effectiveUrl = photoUrl;
        if (!effectiveUrl.startsWith('http://') && !effectiveUrl.startsWith('https://')) {
          effectiveUrl = 'https://$effectiveUrl';
        }
        avatarContent = Image.network(
          effectiveUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialsFallback(initials, size, isDark),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildInitialsFallback(initials, size, isDark);
          },
        );
      }
    } else {
      avatarContent = _buildInitialsFallback(initials, size, isDark);
    }

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: avatarContent,
          ),
        ),
        // Connected Dot Indicator
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsFallback(String initials, double size, bool isDark) {
    return Container(
      width: size,
      height: size,
      color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: size * 0.36,
          fontWeight: FontWeight.bold,
          color: _primaryBlue,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    // Filter doctors by search query and category
    final filteredDoctors = _doctors.where((d) {
      final name = (d['name'] ?? d['displayName'] ?? '').toString().toLowerCase();
      final specialty = (d['specialty'] ?? '').toString().toLowerCase();
      final hospital = (d['hospitalName'] ?? '').toString().toLowerCase();
      final dept = (d['department'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase().trim();

      if (_selectedSpecialty != 'All') {
        if (!specialty.contains(_selectedSpecialty.toLowerCase()) && !dept.contains(_selectedSpecialty.toLowerCase())) {
          return false;
        }
      }

      if (q.isNotEmpty) {
        return name.contains(q) || specialty.contains(q) || hospital.contains(q) || dept.contains(q);
      }
      return true;
    }).toList();

    // Extract dynamic unique specialties for filter chips
    final Set<String> specialtiesSet = {'All'};
    for (final d in _doctors) {
      final sp = (d['specialty'] ?? '').toString().trim();
      if (sp.isNotEmpty && sp.length > 2) {
        specialtiesSet.add(sp);
      }
    }
    final List<String> specialtyList = specialtiesSet.toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'My Doctors',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: isTab ? 19 : 17.5,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: _primaryBlue, size: 18),
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
      floatingActionButton: FloatingActionButton.extended(
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
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
        label: const Text(
          'Add Doctor',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDoctors,
        child: _isLoading
            ? _buildShimmerList(isDark)
            : SafeArea(
                child: Column(
                  children: [
                    // 1. Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 4),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Search by doctor name, specialty, hospital...',
                          hintStyle: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12.5,
                            color: isDark ? Colors.white38 : Colors.grey[400],
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ),

                    // 2. Specialty Filter Chips (if more than 1 specialty)
                    if (specialtyList.length > 2)
                      Container(
                        height: 38,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
                          itemCount: specialtyList.length,
                          itemBuilder: (context, index) {
                            final sp = specialtyList[index];
                            final isSelected = _selectedSpecialty.toLowerCase() == sp.toLowerCase();

                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(sp),
                                selected: isSelected,
                                onSelected: (val) {
                                  if (val) setState(() => _selectedSpecialty = sp);
                                },
                                labelStyle: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                ),
                                selectedColor: _primaryBlue,
                                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? _primaryBlue
                                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                  ),
                                ),
                                showCheckmark: false,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              ),
                            );
                          },
                        ),
                      ),

                    // 3. Doctors List / Empty State
                    Expanded(
                      child: filteredDoctors.isEmpty
                          ? _buildEmptyState(context, isDark)
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: screenHorizontalSpacePadding,
                                vertical: 6,
                              ),
                              itemCount: filteredDoctors.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildDoctorCard(context, filteredDoctors[index], isDark, isTab),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── CLEAN & MODERN DOCTOR CARD ────────────────────────────────────────────
  Widget _buildDoctorCard(
    BuildContext context,
    Map<String, dynamic> doctor,
    bool isDark,
    bool isTab,
  ) {
    final name = (doctor['name'] ?? doctor['displayName'] ?? 'Dr. Specialist').toString();
    final specialty = (doctor['specialty'] ?? 'General Physician').toString();
    final hospital = (doctor['hospitalName'] ?? 'Healthcare Network').toString();
    final qualification = (doctor['qualification'] ?? '').toString().trim();
    final experience = (doctor['experience'] ?? '').toString().trim();
    final fee = doctor['consultationFee'] != null ? '₹${doctor['consultationFee']}' : '';
    final docId = (doctor['doctorId'] ?? doctor['id'] ?? doctor['userId'] ?? '').toString();

    return Container(
      padding: EdgeInsets.all(isTab ? 16 : 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF64748B).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Doctor Avatar + Name/Specialty/Hospital + 3-Dots Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Avatar with profile pic if available
              _buildDoctorAvatar(doctor, isDark, isTab),
              const SizedBox(width: 12),

              // Doctor Info Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 15 : 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      style: const TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _primaryBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.local_hospital_rounded,
                          size: 12,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hospital,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
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

              // 3-Dots Popup Menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Options',
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                elevation: 6,
                onSelected: (val) {
                  if (val == 'book') {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.addAppointmentScreen,
                      arguments: {
                        'doctorId': docId,
                        'doctorName': name,
                        'hospitalId': doctor['hospitalId'],
                        'hospitalName': doctor['hospitalName'],
                        'orgId': doctor['orgId'],
                        'doctor': doctor,
                      },
                    );
                  } else if (val == 'remove') {
                    _confirmRemoveDoctor(context, doctor);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: 'book',
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: _primaryBlue),
                        const SizedBox(width: 10),
                        Text(
                          'Book Appointment',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove_outlined, size: 16, color: Color(0xFFEF4444)),
                        SizedBox(width: 10),
                        Text(
                          'Remove Doctor',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Metadata Chips Row (Qualification / Exp / Fee)
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (qualification.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    qualification,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ),
              if (experience.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    experience.contains('Exp') ? experience : '$experience Exp',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ),
              if (fee.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    fee,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ),
            ],
          ),

          // Action Button: Book Appointment
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.addAppointmentScreen,
                  arguments: {
                    'doctorId': docId,
                    'doctorName': name,
                    'hospitalId': doctor['hospitalId'],
                    'hospitalName': doctor['hospitalName'],
                    'orgId': doctor['orgId'],
                    'doctor': doctor,
                  },
                );
              },
              icon: const Icon(Icons.calendar_today_rounded, size: 14),
              label: const Text(
                'Book Appointment',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.person_search_rounded, size: 38, color: _primaryBlue),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty ? "No Matching Doctors" : "No Connected Doctors",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No doctors match "$_searchQuery". Try clearing your search.'
                    : 'Scan your doctor\'s QR code or search to easily book appointments anytime.',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text(
                  'Scan Doctor QR Code',
                  style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 10),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: BaseShimmer(
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
