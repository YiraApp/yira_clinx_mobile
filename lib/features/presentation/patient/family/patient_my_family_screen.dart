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
import 'package:yiraclinics/core/widgets/phosphor_icons.dart';
import 'package:yiraclinics/core/widgets/profile_visuals.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/core/services/permission_helper.dart';
import 'package:yiraclinics/features/data/models/login/login_model.dart';
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
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const Color _primaryBlue = Color(0xFF2563EB);
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadMemberImages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFamilyData();
    });
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
                imagePath: oldData.imagePath,
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
      final currentUser = GlobalSession.instance.userNotifier.value;
      final currentUserId = (currentUser?.data?.id ?? '').trim().toLowerCase();
      final primaryImagePath = (currentUser?.data?.imagePath ?? '').trim();

      final Map<String, String> loaded = {};
      for (final p in profiles) {
        final pId = (p.id ?? '').trim();
        if (pId.isNotEmpty) {
          final isPrimary = (p.id?.toLowerCase() == currentUserId) || (p.isPrimary == true);
          final bool isRemoved = (prefs.getBool('patient_profile_removed_$pId') ?? false) ||
              (prefs.getBool('patient_profile_removed_${pId.toLowerCase()}') ?? false) ||
              (prefs.getBool('patient_profile_removed_${pId.toUpperCase()}') ?? false);
          if (isRemoved) continue;

          final path = prefs.getString('patient_profile_network_image_$pId') ??
              prefs.getString('patient_profile_image_$pId') ??
              prefs.getString('profile_image_$pId') ??
              p.imagePath;

          // Guard: If this is a dependent member, but their imagePath erroneously matches the primary user's image,
          // ignore the corrupted bleed-through from GlobalSession unless explicitly saved for this dependent!
          if (!isPrimary &&
              path != null &&
              path.trim().isNotEmpty &&
              primaryImagePath.isNotEmpty &&
              path.trim() == primaryImagePath &&
              prefs.getString('patient_profile_network_image_$pId') == null &&
              prefs.getString('patient_profile_image_$pId') == null) {
            continue;
          }

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

    // Deduplicate profiles by unique ID
    final Map<String, ProfileEntity> map = {};
    for (final p in raw) {
      if (p.id != null && p.id!.isNotEmpty) {
        map[p.id!] = p;
      }
    }
    List<ProfileEntity> unique = map.values.toList();

    // Identify the true root primary user ID
    final rootPrimaryGuid = GlobalSession.instance.rootPrimaryUserId;

    int primaryIdx = -1;
    if (rootPrimaryGuid != null && rootPrimaryGuid.isNotEmpty) {
      primaryIdx = unique.indexWhere((p) => p.id == rootPrimaryGuid);
    }
    if (primaryIdx == -1) {
      primaryIdx = unique.indexWhere((p) {
        final r = (p.relation ?? '').trim().toLowerCase();
        final isFam = r.isNotEmpty && r != 'self' && r != 'primary' && r != 'admin';
        return p.isPrimary == true && !isFam;
      });
    }
    if (primaryIdx == -1 && unique.isNotEmpty) {
      primaryIdx = 0;
    }

    if (primaryIdx > 0) {
      final primary = unique.removeAt(primaryIdx);
      unique.insert(0, primary);
    }

    // Ensure ONLY index 0 is marked isPrimary == true, all others are strictly isPrimary == false
    final List<ProfileEntity> sanitized = [];
    for (int i = 0; i < unique.length; i++) {
      final p = unique[i];
      final bool isRootPrimary = (i == 0);
      final rawRel = (p.relation ?? '').trim();
      final bool hasFamilyRel = rawRel.isNotEmpty &&
          rawRel.toLowerCase() != 'self' &&
          rawRel.toLowerCase() != 'primary' &&
          rawRel.toLowerCase() != 'admin';

      sanitized.add(ProfileEntity(
        id: p.id,
        firstName: p.firstName,
        lastName: p.lastName,
        name: p.name,
        phoneNumber: p.phoneNumber,
        relation: isRootPrimary ? 'Self' : (hasFamilyRel ? rawRel : 'Dependent'),
        isPrimary: isRootPrimary,
        gender: p.gender,
        dob: p.dob,
        accountType: isRootPrimary ? 'Independent' : 'Dependent',
        imagePath: p.imagePath,
      ));
    }

    return sanitized;
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
        final file = File(picked.path);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('patient_profile_image_$profileId', picked.path);
        await prefs.setString('profile_image_$profileId', picked.path);

        setState(() {
          _memberImages[profileId] = picked.path;
        });

        // Upload photo to backend database
        bool uploaded = false;
        try {
          final currentUser = GlobalSession.instance.userNotifier.value;
          final token = currentUser?.data?.accessToken ?? '';
          final fileName = file.path.split(RegExp(r'[/\\]')).last;

          final formData = FormData.fromMap({
            "userId": profileId,
            "patientId": profileId,
            "doctorId": profileId,
            "photo": await MultipartFile.fromFile(
              file.path,
              filename: fileName,
            ),
          });

          final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
            URLs.providerProfileUploadPhotoUrl,
            data: formData,
            options: Options(
              headers: {
                if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
                'x-user-id': profileId,
              },
            ),
          );

          if (response.data != null && response.data['data'] != null) {
            final data = response.data['data'];
            final photoUrl = data['photoUrl']?.toString() ??
                data['imagePath']?.toString() ??
                data['profileImageUrl']?.toString() ??
                '';
            if (photoUrl.isNotEmpty) {
              uploaded = true;
              await prefs.setString('patient_profile_network_image_$profileId', photoUrl);
              if (mounted) {
                setState(() {
                  _memberImages[profileId] = photoUrl;
                });
              }

              // Also update GlobalSession profiles list
              final currentSession = GlobalSession.instance.userNotifier.value;
              if (currentSession?.data != null) {
                final isPrimary = profileId == currentSession!.data!.id;
                final updatedProfiles = (currentSession.data!.profiles ?? []).map((p) {
                  if (p.id == profileId) {
                    return ProfileModel(
                      id: p.id,
                      firstName: p.firstName,
                      lastName: p.lastName,
                      name: p.name,
                      phoneNumber: p.phoneNumber,
                      relation: p.relation,
                      isPrimary: p.isPrimary,
                      gender: p.gender,
                      dob: p.dob,
                      accountType: p.accountType,
                      imagePath: photoUrl,
                    );
                  }
                  return p is ProfileModel ? p : ProfileModel.fromEntity(p);
                }).toList();

                final currentData = currentSession.data!;
                final updatedData = DataModel(
                  accessToken: currentData.accessToken,
                  refreshToken: currentData.refreshToken,
                  accessTokenExpiry: currentData.accessTokenExpiry,
                  refreshTokenExpiry: currentData.refreshTokenExpiry,
                  id: currentData.id,
                  isMobileVerified: currentData.isMobileVerified,
                  isEmailVerified: currentData.isEmailVerified,
                  roleCount: currentData.roleCount,
                  hospitalCount: currentData.hospitalCount,
                  organizationCount: currentData.organizationCount,
                  roles: (currentData.roles ?? []).map((r) => r is RoleModel ? r : RoleModel.fromEntity(r)).toList(),
                  profiles: updatedProfiles,
                  firstName: currentData.firstName,
                  lastName: currentData.lastName,
                  email: currentData.email,
                  phoneNumber: currentData.phoneNumber,
                  countryCode: currentData.countryCode,
                  gender: currentData.gender,
                  dob: currentData.dob,
                  height: currentData.height,
                  weight: currentData.weight,
                  heightUnit: currentData.heightUnit,
                  weightUnit: currentData.weightUnit,
                  latestUserRole: currentData.latestUserRole,
                  latestHospitalId: currentData.latestHospitalId,
                  latestOrgId: currentData.latestOrgId,
                  latestRoleId: currentData.latestRoleId,
                  navigationId: currentData.navigationId,
                  imagePath: isPrimary ? photoUrl : currentData.imagePath,
                );

                final newModel = LoginModel(
                  status: currentSession.status,
                  message: currentSession.message,
                  data: updatedData,
                );
                await GlobalSession.instance.update(newModel);
              }
            }
          }
        } catch (uploadErr) {
          debugPrint("Backend member photo upload error: $uploadErr");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(uploaded
                  ? 'Photo updated'
                  : 'Photo saved on this phone only. It could not be uploaded, so it will not show on other devices.'),
              backgroundColor: uploaded ? _primaryBlue : const Color(0xFFD97706),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: uploaded ? 2 : 4),
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
              'Change photo · $name',
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
                                      'Add family member',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    Text(
                                      'Book visits and keep their records in your account',
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
                              'Relationship to you *',
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
                                        'Date of Birth *',
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

                            // Dependents live under the account holder's number.
                            Row(
                              children: [
                                PhosphorIcon(PhosphorIconsBold.phone, size: 14, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    primaryMobileNumber.isNotEmpty
                                        ? 'They will be linked to your number $primaryMobileNumber.'
                                        : 'They will be linked to your account.',
                                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                                  ),
                                ),
                              ],
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
                                        final fullName = nameCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
                                        if (fullName.length < 2) {
                                          setSheetState(() => formError = 'Please enter their full name');
                                          return;
                                        }
                                        if (!RegExp(r"^[A-Za-z][A-Za-z .'-]*$").hasMatch(fullName)) {
                                          setSheetState(() => formError = 'Use letters only in the name');
                                          return;
                                        }
                                        if (selectedDob == null) {
                                          setSheetState(() => formError = 'Please add their date of birth so doctors see the right age');
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

                                            String? serverError;
                                            String? serverId;
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
                                                  final id = (data['id'] ?? data['userId'] ?? '').toString().trim();
                                                  if (id.isNotEmpty) serverId = id;
                                                }
                                                if (serverId == null && rawData['message'] != null) {
                                                  serverError = rawData['message'].toString();
                                                }
                                              }
                                            } on DioException catch (apiErr) {
                                              final body = apiErr.response?.data;
                                              serverError = (body is Map && body['message'] != null)
                                                  ? body['message'].toString()
                                                  : 'Could not reach the server. Check your connection and try again.';
                                            } catch (apiErr) {
                                              serverError = 'Could not add this member. Please try again.';
                                            }

                                            // Without a saved record there is nothing to book for, so
                                            // never add a member that exists only on this phone.
                                            if (serverId == null) {
                                              setSheetState(() {
                                                isSaving = false;
                                                formError = serverError ?? 'Could not add this member. Please try again.';
                                              });
                                              return;
                                            }
                                            newDepUserId = serverId;

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
                                              imagePath: oldData.imagePath,
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
                                            'Add member',
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
            errorBuilder: (_, _, _) => _buildInitialsChild(initials, size, isDark),
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
          errorBuilder: (_, _, _) => _buildInitialsChild(initials, size, isDark),
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
          errorBuilder: (_, _, _) => _buildInitialsChild(initials, size, isDark),
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

  /// The backend allows six family members besides the account holder.
  static const int _maxFamilyMembers = 6;

  String _profileName(ProfileEntity p, String fallback) {
    if ((p.name ?? '').trim().isNotEmpty) return p.name!.trim();
    final full = '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim();
    return full.isNotEmpty ? full : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);

    final familyProfiles = _getFamilyProfiles();
    final int dependents = familyProfiles.isEmpty ? 0 : familyProfiles.length - 1;
    final bool canAdd = dependents < _maxFamilyMembers;
    final String primaryPhone = (GlobalSession.instance.userNotifier.value?.data?.phoneNumber ?? '').replaceAll(RegExp(r'\D'), '');

    final q = _searchQuery.toLowerCase().trim();
    final filteredProfiles = q.isEmpty
        ? familyProfiles
        : familyProfiles.where((p) {
            final name = _profileName(p, '').toLowerCase();
            final relation = (p.relation ?? '').toLowerCase();
            return name.contains(q) || relation.contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIconsBold.caretLeft, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Family',
          style: TextStyle(fontFamily: appPoppinFont, fontSize: isTab ? 19 : 17, fontWeight: FontWeight.w700, color: textColor),
        ),
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMemberSheet(context, isDark),
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const PhosphorIcon(PhosphorIconsBold.userPlus, size: 18, color: Colors.white),
              label: const Text('Add member', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700, fontSize: 13.5)),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refreshFamilyData,
        color: _primaryBlue,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.fromLTRB(isTab ? 28 : 16, 14, isTab ? 28 : 16, 96),
          children: [
            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
                    alignment: Alignment.center,
                    child: const PhosphorIcon(PhosphorIconsDuotone.usersThree, size: 26, color: Colors.white, duotoneSecondaryOpacity: 0.35),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dependents == 0 ? 'Just you so far' : '$dependents family ${dependents == 1 ? 'member' : 'members'}',
                          style: const TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          canAdd
                              ? 'Book visits and keep health records for everyone in one place. You can add ${_maxFamilyMembers - dependents} more.'
                              : 'You have added the maximum of $_maxFamilyMembers family members.',
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, height: 1.4, color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isRefreshing && familyProfiles.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator(color: _primaryBlue)),
              ),
            if (familyProfiles.length > 5) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search by name or relation',
                  hintStyle: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(12),
                    child: PhosphorIcon(PhosphorIconsBold.magnifyingGlass, size: 18, color: Color(0xFF64748B)),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const PhosphorIcon(PhosphorIconsBold.x, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE6EAF0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE6EAF0))),
                ),
              ),
            ],
            const SizedBox(height: 18),
            for (int i = 0; i < filteredProfiles.length; i++) ...[
              if (i == 0 && filteredProfiles[0].isPrimary == true) ...[
                _sectionLabel('YOU', muted),
              ] else if (i == 0 || (i == 1 && filteredProfiles[0].isPrimary == true)) ...[
                const SizedBox(height: 8),
                _sectionLabel('FAMILY MEMBERS', muted),
              ],
              _buildMemberCard(filteredProfiles[i], isDark, isTab, primaryPhone),
              const SizedBox(height: 10),
            ],
            if (dependents == 0 && !_isRefreshing) ...[
              const SizedBox(height: 8),
              _buildEmptyFamily(isDark, isTab),
            ],
            if (q.isNotEmpty && filteredProfiles.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Center(child: Text('No one matches "$_searchQuery"', style: TextStyle(fontFamily: appPoppinFont, color: muted))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(text, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: color)),
    );
  }

  Widget _buildEmptyFamily(bool isDark, bool isTab) {
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE6EAF0)),
      ),
      child: Column(
        children: [
          const PhosphorIcon(PhosphorIconsDuotone.usersThree, size: 40, color: _primaryBlue),
          const SizedBox(height: 10),
          Text('Add your family', style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(
            'Add parents, children or a spouse to book appointments and track their health from your account.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, height: 1.4, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(ProfileEntity profile, bool isDark, bool isTab, String primaryPhone) {
    final pId = (profile.id ?? '').trim();
    final bool isPrimary = profile.isPrimary == true;
    final rawRel = (profile.relation ?? '').trim();
    final String relation = isPrimary ? 'You' : (rawRel.isNotEmpty ? rawRel : 'Family member');
    final pName = _profileName(profile, relation);
    final initials = profileInitials(pName);
    final gender = (profile.gender ?? '').trim();
    final age = profileAgeLabel(profile.dob);
    final phone = (profile.phoneNumber ?? '').replaceAll(RegExp(r'\D'), '');
    final relColor = profileRelationColor(rawRel, isPrimary: isPrimary);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final currentUserId = (currentUser?.data?.id ?? '').trim().toLowerCase();
    final bool isPrimaryMember = isPrimary || (profile.id?.toLowerCase() == currentUserId);
    final img = _memberImages[pId] ??
        (isPrimaryMember
            ? profile.imagePath
            : ((profile.imagePath != null && profile.imagePath != currentUser?.data?.imagePath) ? profile.imagePath : null));

    final meta = <String>[
      if (!isPrimary) relation,
      if (gender.isNotEmpty && gender.toLowerCase() != 'other') gender,
      if (age != null) age,
    ];
    // Dependents usually share the account number; only show a number of their own.
    final bool showPhone = phone.isNotEmpty && (isPrimary || phone != primaryPhone);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Container(
      padding: EdgeInsets.all(isTab ? 16 : 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPrimary ? _primaryBlue.withValues(alpha: 0.35) : (isDark ? const Color(0xFF334155) : const Color(0xFFE6EAF0))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Change photo of $pName',
            button: true,
            child: _buildAvatar(
              imagePath: img,
              initials: initials,
              onTap: () => _showImagePickerSheet(context, pId, pName),
              isDark: isDark,
              isTab: isTab,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        pName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: isTab ? 15.5 : 14.5, fontWeight: FontWeight.w700, color: textColor),
                      ),
                    ),
                    if (isPrimary) ...[
                      const SizedBox(width: 6),
                      ProfileTag(label: 'You', color: relColor, isDark: isDark),
                    ],
                  ],
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(meta.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: muted)),
                ],
                if (showPhone) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      PhosphorIcon(PhosphorIconsBold.phone, size: 12, color: muted),
                      const SizedBox(width: 4),
                      Text(profile.phoneNumber!.trim(), style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: muted)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: () => PatientBookAppointmentSheet.show(
              context,
              targetProfile: profile,
              patientName: pName,
              patientPhone: profile.phoneNumber,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _primaryBlue.withValues(alpha: isDark ? 0.22 : 0.1),
              foregroundColor: _primaryBlue,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const PhosphorIcon(PhosphorIconsBold.calendarPlus, size: 16, color: _primaryBlue),
            label: const Text('Book', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
