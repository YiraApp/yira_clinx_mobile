import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'package:yiraclinics/features/use_cases/update_latest_org_details_use_case.dart';
import '../appointments/patient_book_appointment_sheet.dart';

class PatientMyFamilyScreen extends StatefulWidget {
  const PatientMyFamilyScreen({super.key});

  @override
  State<PatientMyFamilyScreen> createState() => _PatientMyFamilyScreenState();
}

class _PatientMyFamilyScreenState extends State<PatientMyFamilyScreen> {
  bool _isSwitching = false;
  String? _switchingProfileId;
  final Map<String, String> _memberImages = {};
  final ImagePicker _picker = ImagePicker();
  String _searchQuery = '';

  static const Color _primaryBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadMemberImages();
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

  Future<void> _switchProfile(ProfileEntity targetProfile) async {
    final currentSession = GlobalSession.instance.userNotifier.value;
    if (currentSession?.data == null) return;

    final targetId = targetProfile.id ?? '';
    if (targetId.isEmpty || targetId == currentSession!.data!.id) return;

    setState(() {
      _isSwitching = true;
      _switchingProfileId = targetId;
    });

    try {
      final oldData = currentSession.data!;
      final bool isDep = targetProfile.isPrimary == false ||
          targetProfile.accountType == 'Dependent' ||
          (targetProfile.relation != null &&
              targetProfile.relation!.toLowerCase() != 'self' &&
              targetProfile.relation!.toLowerCase() != 'primary' &&
              targetProfile.relation!.toLowerCase() != 'admin');

      final String targetRoleId = isDep
          ? '4FC67429-28AE-4106-93EF-436228282ED0'
          : (oldData.latestRoleId ?? '4FC67429-28AE-4106-93EF-436228282ED0');
      final dynamic targetOrgId = oldData.latestOrgId ?? 1;
      final dynamic targetHospitalId = oldData.latestHospitalId ?? 1;

      try {
        final updateUseCase = sl<UpdateLatestOrgDetailsUseCase>();
        await updateUseCase(UpdateLatestOrgDetailsModelParams(
          userId: targetId,
          latestRoleId: targetRoleId,
          latestOrgId: targetOrgId,
          latestHospitalId: targetHospitalId,
        ));
      } catch (_) {}

      final updatedData = DataEntity(
        id: targetId,
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
        firstName: targetProfile.firstName ?? oldData.firstName,
        lastName: targetProfile.lastName ?? oldData.lastName,
        email: oldData.email,
        phoneNumber: targetProfile.phoneNumber ?? oldData.phoneNumber,
        countryCode: oldData.countryCode,
        gender: targetProfile.gender ?? oldData.gender,
        dob: targetProfile.dob ?? oldData.dob,
        height: oldData.height,
        weight: oldData.weight,
        heightUnit: oldData.heightUnit,
        weightUnit: oldData.weightUnit,
        latestUserRole: isDep ? 'Dependent' : oldData.latestUserRole,
        latestOrgId: targetOrgId is int ? targetOrgId : int.tryParse(targetOrgId.toString()),
        latestHospitalId: targetHospitalId is int ? targetHospitalId : int.tryParse(targetHospitalId.toString()),
        latestRoleId: targetRoleId,
        navigationId: oldData.navigationId,
        profiles: oldData.profiles,
      );

      final updatedSession = LoginEntity(
        status: currentSession.status,
        message: 'Active profile switched to ${targetProfile.name ?? targetProfile.firstName ?? "User"}',
        data: updatedData,
      );

      await GlobalSession.instance.update(updatedSession);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Active profile switched to ${targetProfile.name ?? targetProfile.firstName ?? "User"}'),
              ],
            ),
            backgroundColor: _primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch profile: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSwitching = false;
          _switchingProfileId = null;
        });
      }
    }
  }

  Future<void> _pickAndSaveImage(String profileId, ImageSource source) async {
    try {
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
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final dobCtrl = TextEditingController();
    String selectedRelation = 'Spouse';
    String selectedGender = 'Female';
    bool isSaving = false;
    String? formError;

    final relations = ['Spouse', 'Child', 'Parent', 'Sibling', 'Other'];
    final genders = ['Male', 'Female', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Connect dependents to manage their medical care',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

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
                    const SizedBox(height: 12),
                  ],

                  // Full Name
                  Text(
                    'Full Name *',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
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

                  // Phone Number
                  Text(
                    'Phone Number (Optional)',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'e.g. +91 9876543210',
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

                  // Relation Selector
                  Text(
                    'Relationship',
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
                          if (val) setSheetState(() => selectedRelation = rel);
                        },
                        labelStyle: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
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

                  // Gender Selector
                  Text(
                    'Gender',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: genders.map((g) {
                      final isSelected = selectedGender == g;
                      return ChoiceChip(
                        label: Text(g),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setSheetState(() => selectedGender = g);
                        },
                        labelStyle: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
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
                  const SizedBox(height: 20),

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
                                  final newProfile = ProfileEntity(
                                    id: 'dep_${DateTime.now().millisecondsSinceEpoch}',
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
          );
        },
      ),
    );
  }

  // ─── DOCTOR/MEMBER AVATAR WIDGET (PHOTO OR INITIALS) ────────────────────────
  Widget _buildAvatar({
    required String? imagePath,
    required String initials,
    required bool isActive,
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
          // Active or Camera Badge
          if (isActive)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    width: 2,
                  ),
                ),
              ),
            )
          else
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFF64748B),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 8, color: Colors.white),
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

    final currentUser = GlobalSession.instance.userNotifier.value;
    final activeUserId = (currentUser?.data?.id ?? '').trim();
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
                  final isActive = (pId.isNotEmpty && pId == activeUserId) ||
                      (pId.isEmpty && profile.isPrimary == true && (activeUserId.isEmpty || activeUserId == currentUser?.data?.id));
                  final isThisSwitching = _isSwitching && _switchingProfileId == pId;

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
                              isActive: isActive,
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
                                      if (isActive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _primaryBlue.withValues(alpha: isDark ? 0.15 : 0.08),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: _primaryBlue.withValues(alpha: 0.25),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle_rounded, size: 10, color: _primaryBlue),
                                              SizedBox(width: 3.5),
                                              Text(
                                                'Active Account',
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
                                } else if (val == 'switch') {
                                  _switchProfile(profile);
                                } else if (val == 'book') {
                                  PatientBookAppointmentSheet.show(context);
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
                                if (!isActive)
                                  PopupMenuItem<String>(
                                    value: 'switch',
                                    child: Row(
                                      children: [
                                        Icon(Icons.switch_account_outlined, size: 16, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Switch Profile',
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
                                        'Book Visit',
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

                        // Action Buttons: Switch Profile & Book Visit
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _primaryBlue,
                                    side: BorderSide(
                                      color: isActive ? _primaryBlue : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                      width: 1.2,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: isActive || _isSwitching ? null : () => _switchProfile(profile),
                                  icon: isThisSwitching
                                      ? const SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBlue),
                                        )
                                      : Icon(
                                          isActive ? Icons.check_circle_rounded : Icons.switch_account_rounded,
                                          size: 14,
                                          color: isActive ? _primaryBlue : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                        ),
                                  label: Text(
                                    isActive ? 'Active' : 'Switch',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? _primaryBlue : (isDark ? Colors.white70 : const Color(0xFF475569)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => PatientBookAppointmentSheet.show(context),
                                  icon: const Icon(Icons.calendar_month_rounded, size: 14),
                                  label: const Text(
                                    'Book Visit',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
