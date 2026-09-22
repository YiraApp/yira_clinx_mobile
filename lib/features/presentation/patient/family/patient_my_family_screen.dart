import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/core/services/permission_helper.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'package:yiraclinics/features/use_cases/config_use_case.dart';
import '../appointments/patient_book_appointment_sheet.dart';

class PatientMyFamilyScreen extends StatefulWidget {
  const PatientMyFamilyScreen({super.key});

  @override
  State<PatientMyFamilyScreen> createState() => _PatientMyFamilyScreenState();
}

class _PatientMyFamilyScreenState extends State<PatientMyFamilyScreen> {
  final Map<String, String> _memberImages = {};
  final ImagePicker _picker = ImagePicker();
  String _searchQuery = '';

  static const Color _primaryBlue = Color(0xFF2563EB);
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadMemberImages();
    _refreshFamilyData();
  }

  Future<void> _refreshFamilyData() async {
    if (_isRefreshing) return;
    if (mounted) setState(() => _isRefreshing = true);

    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';
      final primaryPhone = (currentUser?.data?.phoneNumber ?? '').replaceAll(RegExp(r'\D'), '');

      // 1. Fetch fresh user data from ConfigUseCase (getUserData endpoint)
      if (sl.isRegistered<ConfigUseCase>()) {
        final freshLogin = await sl<ConfigUseCase>().call(null);
        if (freshLogin != null && freshLogin.data != null) {
          await GlobalSession.instance.update(freshLogin);
        }
      }

      // 2. Query all matching accounts/dependents by primary phone from backend
      if (primaryPhone.isNotEmpty && token.isNotEmpty) {
        try {
          final res = await sl<ApiClient>().account(showSuccessSnack: false).post(
            URLs.patientAccountsByPhoneUrl,
            data: {"phone": primaryPhone},
            options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
          );

          if (res.data != null && res.data['data'] is List) {
            final list = res.data['data'] as List;
            final currentSession = GlobalSession.instance.userNotifier.value;
            final currentProfiles = List<ProfileEntity>.from(currentSession?.data?.profiles ?? []);

            bool hasNewProfiles = false;
            for (final item in list) {
              final itemUserId = (item['id'] ?? item['userId'] ?? '').toString().trim();
              if (itemUserId.isNotEmpty && !currentProfiles.any((p) => (p.id ?? '').trim() == itemUserId)) {
                final fName = (item['firstName'] ?? '').toString().trim();
                final lName = (item['lastName'] ?? '').toString().trim();
                final depName = '$fName $lName'.trim();
                final rel = (item['relation'] ?? 'Dependent').toString().trim();

                currentProfiles.add(
                  ProfileEntity(
                    id: itemUserId,
                    name: depName.isNotEmpty ? depName : 'Family Member',
                    firstName: fName,
                    lastName: lName,
                    phoneNumber: (item['phoneNumber'] ?? primaryPhone).toString(),
                    relation: rel.isNotEmpty ? rel : 'Dependent',
                    gender: (item['gender'] ?? 'Other').toString(),
                    dob: item['dob']?.toString(),
                    isPrimary: item['isPrimary'] == true,
                    accountType: 'Dependent',
                  ),
                );
                hasNewProfiles = true;
              }
            }

            if (hasNewProfiles && currentSession?.data != null) {
              final oldData = currentSession!.data!;
              final updatedData = DataEntity(
                id: oldData.id,
                accessToken: oldData.accessToken,
                refreshToken: oldData.refreshToken,
                accessTokenExpiry: oldData.accessTokenExpiry,
                refreshTokenExpiry: oldData.refreshTokenExpiry,
                isMobileVerified: oldData.isMobileVerified,
                isEmailVerified: oldData.isEmailVerified,
                roleCount: oldData.roleCount,
                hospitalCount: oldData.hospitalCount,
                organizationCount: oldData.organizationCount,
                roles: oldData.roles,
                firstName: oldData.firstName,
                lastName: oldData.lastName,
                email: oldData.email,
                phoneNumber: oldData.phoneNumber,
                countryCode: oldData.countryCode,
                gender: oldData.gender,
                dob: oldData.dob,
                height: oldData.height,
                weight: oldData.weight,
                heightUnit: oldData.heightUnit,
                weightUnit: oldData.weightUnit,
                latestUserRole: oldData.latestUserRole,
                latestOrgId: oldData.latestOrgId,
                latestHospitalId: oldData.latestHospitalId,
                latestRoleId: oldData.latestRoleId,
                navigationId: oldData.navigationId,
                profiles: currentProfiles,
              );
              await GlobalSession.instance.update(
                LoginEntity(
                  status: currentSession.status,
                  message: currentSession.message,
                  data: updatedData,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint("[PatientMyFamily] Error syncing patient accounts by phone: $e");
        }
      }

      await _loadMemberImages();
    } catch (e) {
      debugPrint("[PatientMyFamily] Error refreshing family: $e");
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _loadMemberImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profiles = _getFamilyProfiles();
      final Map<String, String> loaded = {};
      for (final p in profiles) {
        final pId = (p.id ?? '').trim();
        if (pId.isNotEmpty) {
          final path = prefs.getString('patient_profile_image_$pId') ??
              prefs.getString('profile_image_$pId') ??
              p.imagePath;
          if (path != null && path.isNotEmpty) {
            loaded[pId] = path;
          }
        }
      }
      if (mounted) {
        setState(() {
          _memberImages.clear();
          _memberImages.addAll(loaded);
        });
      }
    } catch (_) {}
  }

  List<ProfileEntity> _getFamilyProfiles() {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final List<ProfileEntity> raw = [...(currentUser?.data?.profiles ?? [])];

    if (raw.isEmpty && currentUser?.data != null) {
      final d = currentUser!.data!;
      raw.add(
        ProfileEntity(
          id: d.id,
          firstName: d.firstName,
          lastName: d.lastName,
          name: '${d.firstName ?? ''} ${d.lastName ?? ''}'.trim().isNotEmpty
              ? '${d.firstName ?? ''} ${d.lastName ?? ''}'.trim()
              : 'Primary Account',
          phoneNumber: d.phoneNumber,
          relation: 'Self',
          isPrimary: true,
          gender: d.gender,
          dob: d.dob,
          accountType: 'Independent',
        ),
      );
    }

    // Ensure primary profile is first
    int primaryIdx = raw.indexWhere((p) {
      final r = (p.relation ?? '').trim().toLowerCase();
      final isFam = r.isNotEmpty && r != 'self' && r != 'primary' && r != 'admin';
      return p.isPrimary == true && !isFam;
    });
    if (primaryIdx > 0) {
      final primary = raw.removeAt(primaryIdx);
      raw.insert(0, primary);
    }

    return raw;
  }



  Future<void> _pickAndSaveImage(String profileId, ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final hasPerm = await PermissionHelper.ensureCameraPermission(context);
        if (!hasPerm) return;
      } else {
        final hasPerm = await PermissionHelper.ensurePhotosPermission(context);
        if (!hasPerm) return;
      }
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('patient_profile_image_$profileId', picked.path);
        await prefs.setString('profile_image_$profileId', picked.path);

        setState(() {
          _memberImages[profileId] = picked.path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: _primaryBlue,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not update photo: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showImagePickerSheet(BuildContext context, String profileId, String name) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Profile Photo: $name',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: _primaryBlue, size: 20),
              ),
              title: Text(
                'Take a Photo',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickAndSaveImage(profileId, ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_outlined, color: _primaryBlue, size: 20),
              ),
              title: Text(
                'Choose from Gallery',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickAndSaveImage(profileId, ImageSource.gallery);
              },
            ),
            if (_memberImages.containsKey(profileId))
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                ),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.redAccent,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('patient_profile_image_$profileId');
                  await prefs.remove('profile_image_$profileId');
                  setState(() {
                    _memberImages.remove(profileId);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddMemberSheet(BuildContext context, bool isDark) {
    final currentSession = GlobalSession.instance.userNotifier.value;
    final primaryMobileNumber = (currentSession?.data?.phoneNumber ?? '').trim();

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: primaryMobileNumber);
    final dobCtrl = TextEditingController();
    String selectedRelation = 'Spouse';
    String selectedGender = 'Female';
    DateTime? selectedDob;
    bool isSaving = false;
    String? formError;

    final relations = ['Spouse', 'Child', 'Son', 'Daughter', 'Father', 'Mother', 'Brother', 'Sister', 'Other'];
    final genders = ['Male', 'Female', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pinned Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 14, 12),
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white24 : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.person_add_alt_1_rounded, color: _primaryBlue, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add Family Member',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      'Connect dependents to manage their medical care',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 20),
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                onPressed: () => Navigator.pop(sheetCtx),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),

                    // Scrollable Form Content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (formError != null) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        formError!,
                                        style: const TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 12,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // Full Name
                            Text(
                              'Full Name *',
                              style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: nameCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: 'e.g. John Doe',
                                hintStyle: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: isDark ? Colors.white38 : Colors.grey[400]),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Relationship
                            Text(
                              'Relationship to Primary Account *',
                              style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: relations.map((rel) {
                                final isSelected = selectedRelation == rel;
                                return ChoiceChip(
                                  label: Text(rel),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) {
                                      setSheetState(() {
                                        selectedRelation = rel;
                                        if (rel == 'Father' || rel == 'Brother' || rel == 'Son') {
                                          selectedGender = 'Male';
                                        } else if (rel == 'Mother' || rel == 'Sister' || rel == 'Daughter') {
                                          selectedGender = 'Female';
                                        }
                                      });
                                    }
                                  },
                                  labelStyle: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                  ),
                                  selectedColor: _primaryBlue,
                                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: isSelected ? _primaryBlue : (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                                  ),
                                  showCheckmark: false,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),

                            // Gender & Date of Birth
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Gender *',
                                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: selectedGender,
                                            isExpanded: true,
                                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                            items: genders
                                                .map((g) => DropdownMenuItem(
                                                      value: g,
                                                      child: Text(g, style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: textColor)),
                                                    ))
                                                .toList(),
                                            onChanged: (val) {
                                              if (val != null) setSheetState(() => selectedGender = val);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Date of Birth',
                                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                                      ),
                                      const SizedBox(height: 6),
                                      InkWell(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: selectedDob ?? DateTime(2000, 1, 1),
                                            firstDate: DateTime(1920),
                                            lastDate: DateTime.now(),
                                          );
                                          if (picked != null) {
                                            setSheetState(() {
                                              selectedDob = picked;
                                              dobCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                                            });
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.cake_outlined, size: 16, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  selectedDob != null
                                                      ? DateFormat('dd MMM yyyy').format(selectedDob!)
                                                      : 'Select DOB',
                                                  style: TextStyle(
                                                    fontFamily: appPoppinFont,
                                                    fontSize: 12,
                                                    color: selectedDob != null ? textColor : (isDark ? Colors.white38 : Colors.grey[400]),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Primary Mobile Number (Autofilled & Blocked)
                            Row(
                              children: [
                                Text(
                                  'Primary Mobile Number',
                                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.lock_rounded, size: 10, color: _primaryBlue),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Autofilled & Blocked',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: phoneCtrl,
                              readOnly: true,
                              enabled: false,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.phone_android_rounded, size: 18, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                suffixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dependents are automatically linked under your primary registered mobile number.',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        final fullName = nameCtrl.text.trim();
                                        if (fullName.isEmpty) {
                                          setSheetState(() => formError = 'Please enter member name');
                                          return;
                                        }

                                        setSheetState(() {
                                          isSaving = true;
                                          formError = null;
                                        });

                                        try {
                                          final currentSession = GlobalSession.instance.userNotifier.value;
                                          final oldData = currentSession?.data;
                                          if (oldData != null) {
                                            final token = oldData.accessToken ?? '';
                                            final orgId = oldData.latestOrgId ?? 1;
                                            final hospitalId = oldData.latestHospitalId ?? 1;
                                            final cleanPhone = phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
                                            final primaryPhone = (oldData.phoneNumber ?? '').replaceAll(RegExp(r'\D'), '');

                                            String newDepUserId = 'DEP-${DateTime.now().millisecondsSinceEpoch}';

                                            final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
                                            String? validParentGuid;
                                            if (GlobalSession.instance.rootPrimaryUserId != null &&
                                                uuidRegex.hasMatch(GlobalSession.instance.rootPrimaryUserId!)) {
                                              validParentGuid = GlobalSession.instance.rootPrimaryUserId;
                                            } else if (oldData.id != null && uuidRegex.hasMatch(oldData.id!)) {
                                              validParentGuid = oldData.id;
                                            }

                                            try {
                                              final res = await sl<ApiClient>().account(showSuccessSnack: false).post(
                                                URLs.addDependentPatientUrl,
                                                data: {
                                                  "primaryPhone": cleanPhone.isNotEmpty ? cleanPhone : primaryPhone,
                                                  if (validParentGuid != null) "parentUserId": validParentGuid,
                                                  "name": fullName,
                                                  "relation": selectedRelation,
                                                  "gender": selectedGender,
                                                  "dob": dobCtrl.text.trim().isNotEmpty ? dobCtrl.text.trim() : null,
                                                  "orgId": orgId,
                                                  "hospitalId": hospitalId,
                                                },
                                                options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
                                              );

                                              if (res.data != null && res.data is Map<String, dynamic>) {
                                                final rawData = res.data as Map<String, dynamic>;
                                                final data = rawData['data'];
                                                if (data is Map<String, dynamic>) {
                                                  newDepUserId = (data['id'] ?? data['userId'] ?? newDepUserId).toString();
                                                }
                                              }
                                            } catch (apiErr) {
                                              debugPrint('API add-dependent notice: $apiErr');
                                            }

                                            final newProfile = ProfileEntity(
                                              id: newDepUserId,
                                              name: fullName,
                                              firstName: fullName.split(' ').first,
                                              lastName: fullName.contains(' ') ? fullName.substring(fullName.indexOf(' ') + 1) : '',
                                              phoneNumber: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                                              relation: selectedRelation,
                                              gender: selectedGender,
                                              dob: dobCtrl.text.trim().isNotEmpty ? dobCtrl.text.trim() : null,
                                              isPrimary: false,
                                              accountType: 'Dependent',
                                            );

                                            final updatedProfiles = [...(oldData.profiles ?? []), newProfile];
                                            final updatedData = DataEntity(
                                              id: oldData.id,
                                              accessToken: oldData.accessToken,
                                              refreshToken: oldData.refreshToken,
                                              accessTokenExpiry: oldData.accessTokenExpiry,
                                              refreshTokenExpiry: oldData.refreshTokenExpiry,
                                              isMobileVerified: oldData.isMobileVerified,
                                              isEmailVerified: oldData.isEmailVerified,
                                              roleCount: oldData.roleCount,
                                              hospitalCount: oldData.hospitalCount,
                                              organizationCount: oldData.organizationCount,
                                              roles: oldData.roles,
                                              firstName: oldData.firstName,
                                              lastName: oldData.lastName,
                                              email: oldData.email,
                                              phoneNumber: oldData.phoneNumber,
                                              countryCode: oldData.countryCode,
                                              gender: oldData.gender,
                                              dob: oldData.dob,
                                              height: oldData.height,
                                              weight: oldData.weight,
                                              heightUnit: oldData.heightUnit,
                                              weightUnit: oldData.weightUnit,
                                              latestUserRole: oldData.latestUserRole,
                                              latestOrgId: oldData.latestOrgId,
                                              latestHospitalId: oldData.latestHospitalId,
                                              latestRoleId: oldData.latestRoleId,
                                              navigationId: oldData.navigationId,
                                              profiles: List<ProfileEntity>.from(updatedProfiles),
                                            );

                                            final updatedSession = LoginEntity(
                                              status: currentSession?.status,
                                              message: currentSession?.message,
                                              data: updatedData,
                                            );

                                            await GlobalSession.instance.update(updatedSession);
                                          }

                                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                          if (mounted) {
                                            setState(() {});
                                            _refreshFamilyData();
                                            ScaffoldMessenger.of(this.context).showSnackBar(
                                              SnackBar(
                                                content: Text('$fullName has been added to My Family!'),
                                                backgroundColor: _primaryBlue,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          setSheetState(() {
                                            isSaving = false;
                                            formError = 'Failed to add dependent: $e';
                                          });
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.person_add_alt_1_rounded, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            'Save Family Member',
                                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── DOCTOR/MEMBER AVATAR WIDGET (PHOTO OR INITIALS) ────────────────────────
  Widget _buildAvatar({
    required String? imagePath,
    required String initials,
    required VoidCallback onTap,
    required bool isDark,
    required bool isTab,
  }) {
    final size = isTab ? 56.0 : 48.0;
    final bool hasImage = imagePath != null &&
        imagePath.isNotEmpty &&
        (imagePath.startsWith('http') || imagePath.startsWith('data:image') || File(imagePath).existsSync());

    Widget avatarContent;

    if (hasImage) {
      if (imagePath.startsWith('data:image')) {
        try {
          final commaIdx = imagePath.indexOf(',');
          final base64Data = commaIdx != -1 ? imagePath.substring(commaIdx + 1) : imagePath;
          final Uint8List bytes = base64Decode(base64Data);
          avatarContent = Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildInitialsChild(initials, size, isDark),
          );
        } catch (_) {
          avatarContent = _buildInitialsChild(initials, size, isDark);
        }
      } else if (imagePath.startsWith('http')) {
        avatarContent = Image.network(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialsChild(initials, size, isDark),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildInitialsChild(initials, size, isDark);
          },
        );
      } else {
        avatarContent = Image.file(
          File(imagePath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialsChild(initials, size, isDark),
        );
      }
    } else {
      avatarContent = _buildInitialsChild(initials, size, isDark);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Stack(
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
          // Camera Badge for Updating Photo
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 9, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsChild(String initials, double size, bool isDark) {
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

    final familyProfiles = _getFamilyProfiles();

    final filteredProfiles = familyProfiles.where((p) {
      final name = (p.name ?? '${p.firstName ?? ''} ${p.lastName ?? ''}').toLowerCase();
      final relation = (p.relation ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase().trim();
      if (q.isNotEmpty) {
        return name.contains(q) || relation.contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Family & Dependents',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: isTab ? 19 : 17.5,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Family',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBlue),
                    )
                  : const Icon(Icons.refresh_rounded, color: _primaryBlue, size: 18),
            ),
            onPressed: _isRefreshing ? null : _refreshFamilyData,
          ),
          IconButton(
            tooltip: 'Add Family Member',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: _primaryBlue, size: 18),
            ),
            onPressed: () => _showAddMemberSheet(context, isDark),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberSheet(context, isDark),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text(
          'Add Member',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar (if more than 2 members)
            if (familyProfiles.length > 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 4),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Search family members by name or relation...',
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

            // 2. Members List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshFamilyData,
                color: _primaryBlue,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: screenHorizontalSpacePadding,
                    vertical: 8,
                  ),
                  itemCount: filteredProfiles.length,
                  itemBuilder: (context, index) {
                  final profile = filteredProfiles[index];
                  final pId = (profile.id ?? '').trim();

                  final rawRel = (profile.relation ?? '').trim();
                  final bool isFam = rawRel.isNotEmpty &&
                      rawRel.toLowerCase() != 'self' &&
                      rawRel.toLowerCase() != 'primary' &&
                      rawRel.toLowerCase() != 'admin';
                  final String relation = isFam ? rawRel : ((profile.isPrimary == true) ? 'Primary (Self)' : 'Dependent');

                  final pName = (profile.name?.isNotEmpty ?? false)
                      ? profile.name!
                      : '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim().isNotEmpty
                          ? '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim()
                          : relation;

                  final initials = pName.isNotEmpty
                      ? pName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
                      : (relation.isNotEmpty ? relation[0].toUpperCase() : 'M');

                  final cachedImg = _memberImages[pId] ?? profile.imagePath;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : const Color(0xFF64748B).withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Avatar + Name/Relation + 3-Dots Menu
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Member Avatar
                            _buildAvatar(
                              imagePath: cachedImg,
                              initials: initials,
                              onTap: () => _showImagePickerSheet(context, pId, pName),
                              isDark: isDark,
                              isTab: isTab,
                            ),
                            const SizedBox(width: 12),

                            // Member Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          pName,
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: isTab ? 15 : 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          relation,
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                      if (profile.isPrimary == true || !isFam)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.verified_user_rounded, size: 10, color: Color(0xFF10B981)),
                                              SizedBox(width: 3.5),
                                              Text(
                                                'Primary User',
                                                style: TextStyle(
                                                  fontFamily: appPoppinFont,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF10B981),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.phone_outlined, size: 11, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                        const SizedBox(width: 4),
                                        Text(
                                          profile.phoneNumber!,
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 11,
                                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
                                if (val == 'photo') {
                                  _showImagePickerSheet(context, pId, pName);
                                } else if (val == 'book') {
                                  PatientBookAppointmentSheet.show(
                                    context,
                                    targetProfile: profile,
                                    patientName: pName,
                                    patientPhone: profile.phoneNumber,
                                  );
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem<String>(
                                  value: 'photo',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.camera_alt_outlined, size: 16, color: _primaryBlue),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Update Photo',
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
                              ],
                            ),
                          ],
                        ),

                        // Action Button: Full-width Book Appointment
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => PatientBookAppointmentSheet.show(
                              context,
                              targetProfile: profile,
                              patientName: pName,
                              patientPhone: profile.phoneNumber,
                            ),
                            icon: const Icon(Icons.calendar_month_rounded, size: 15),
                            label: const Text(
                              'Book Appointment',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
