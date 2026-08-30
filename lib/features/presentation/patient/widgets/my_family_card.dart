import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'package:yiraclinics/features/use_cases/update_latest_org_details_use_case.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';

class MyFamilyCard extends StatefulWidget {
  final VoidCallback? onProfileSwitched;

  const MyFamilyCard({
    super.key,
    this.onProfileSwitched,
  });

  @override
  State<MyFamilyCard> createState() => _MyFamilyCardState();
}

class _MyFamilyCardState extends State<MyFamilyCard> {
  bool _isSwitching = false;
  String? _switchingProfileId;
  final Map<String, String> _memberImages = {};

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
          final path = prefs.getString('patient_profile_image_$pId');
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

      // Update backend session if possible
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
        latestRoleId: targetRoleId,
        latestOrgId: targetOrgId,
        latestHospitalId: targetHospitalId,
        latestUserRole: 'Patient',
        navigationId: '1',
        profiles: oldData.profiles,
      );

      await GlobalSession.instance.update(
        LoginEntity(
          status: true,
          message: 'Session switched',
          data: updatedData,
        ),
      );

      if (mounted) {
        final targetName = (targetProfile.name?.isNotEmpty ?? false)
            ? targetProfile.name!
            : '${targetProfile.firstName ?? ''} ${targetProfile.lastName ?? ''}'.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched profile to $targetName'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onProfileSwitched?.call();
        // Refresh configuration / dashboard
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.userConfiguration,
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error switching profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSwitching = false;
          _switchingProfileId = null;
        });
      }
    }
  }

  void _showAddMemberSheet(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final currentUser = GlobalSession.instance.userNotifier.value?.data;
    final primaryPhone = currentUser?.phoneNumber ?? '';
    final primaryUserId = GlobalSession.instance.rootPrimaryUserId ?? currentUser?.id ?? '';

    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController(text: primaryPhone);
    String selectedRelation = 'Spouse';
    String selectedGender = 'Female';
    DateTime selectedDob = DateTime(1995, 6, 15);
    bool isSaving = false;
    String? formError;

    final relations = const ['Spouse', 'Child', 'Son', 'Daughter', 'Father', 'Mother', 'Brother', 'Sister', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              top: 18,
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
                          color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.group_add_rounded, color: primaryColor, size: 22),
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Link a dependent under your primary account',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

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

                  // First & Last Name
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('First Name *', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: firstNameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: 'e.g. Rahul',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                            Text('Last Name', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: lastNameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                hintText: 'e.g. Kumar',
                                filled: true,
                                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Relationship Selection Chips
                  Text('Relationship to Primary Account *', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: relations.map((rel) {
                      final isSel = selectedRelation == rel;
                      return ChoiceChip(
                        label: Text(rel),
                        selected: isSel,
                        selectedColor: primaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        side: BorderSide(color: isSel ? primaryColor : (isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                        labelStyle: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? primaryColor : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
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
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Gender & DOB Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gender *', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedGender,
                                  isExpanded: true,
                                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13)))).toList(),
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
                            Text('Date of Birth', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF334155))),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDob,
                                  firstDate: DateTime(1920),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setSheetState(() => selectedDob = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.cake_outlined, size: 16, color: Color(0xFF64748B)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        DateFormat('dd MMM yyyy').format(selectedDob),
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 12.5,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                  const SizedBox(height: 22),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final fName = firstNameController.text.trim();
                              final lName = lastNameController.text.trim();
                              if (fName.isEmpty) {
                                setSheetState(() => formError = 'Please enter first name');
                                return;
                              }

                              setSheetState(() {
                                isSaving = true;
                                formError = null;
                              });

                              final fullName = '$fName $lName'.trim();
                              final dobStr = DateFormat('yyyy-MM-dd').format(selectedDob);
                              final cleanPhone = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');

                              try {
                                final token = currentUser?.accessToken ?? '';
                                final orgId = currentUser?.latestOrgId ?? 1;
                                final hospitalId = currentUser?.latestHospitalId ?? 1;

                                String newDepUserId = 'DEP-${DateTime.now().millisecondsSinceEpoch}';

                                final res = await sl<ApiClient>().account(showSuccessSnack: false).post(
                                  URLs.addDependentPatientUrl,
                                  data: {
                                    "primaryPhone": cleanPhone.isNotEmpty ? cleanPhone : primaryPhone,
                                    "parentUserId": primaryUserId,
                                    "name": fullName,
                                    "relation": selectedRelation,
                                    "gender": selectedGender,
                                    "dob": dobStr,
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

                                // Update local GlobalSession profiles list
                                final currentSession = GlobalSession.instance.userNotifier.value;
                                if (currentSession?.data != null) {
                                  final List<ProfileEntity> oldProfiles = [
                                    ...(currentSession!.data!.profiles ?? []),
                                  ];
                                  final newProfile = ProfileEntity(
                                    id: newDepUserId,
                                    firstName: fName,
                                    lastName: lName,
                                    name: fullName,
                                    phoneNumber: cleanPhone.isNotEmpty ? cleanPhone : primaryPhone,
                                    relation: selectedRelation,
                                    isPrimary: false,
                                    gender: selectedGender,
                                    dob: dobStr,
                                    accountType: 'Dependent',
                                  );

                                  oldProfiles.add(newProfile);

                                  final d = currentSession.data!;
                                  final updatedData = DataEntity(
                                    id: d.id,
                                    accessToken: d.accessToken,
                                    refreshToken: d.refreshToken,
                                    accessTokenExpiry: d.accessTokenExpiry,
                                    refreshTokenExpiry: d.refreshTokenExpiry,
                                    isMobileVerified: d.isMobileVerified,
                                    isEmailVerified: d.isEmailVerified,
                                    roleCount: d.roleCount,
                                    hospitalCount: d.hospitalCount,
                                    organizationCount: d.organizationCount,
                                    roles: d.roles,
                                    firstName: d.firstName,
                                    lastName: d.lastName,
                                    email: d.email,
                                    phoneNumber: d.phoneNumber,
                                    countryCode: d.countryCode,
                                    gender: d.gender,
                                    dob: d.dob,
                                    height: d.height,
                                    weight: d.weight,
                                    heightUnit: d.heightUnit,
                                    weightUnit: d.weightUnit,
                                    latestRoleId: d.latestRoleId,
                                    latestOrgId: d.latestOrgId,
                                    latestHospitalId: d.latestHospitalId,
                                    latestUserRole: d.latestUserRole,
                                    navigationId: d.navigationId,
                                    profiles: oldProfiles,
                                  );

                                  await GlobalSession.instance.update(
                                    LoginEntity(
                                      status: true,
                                      message: 'Family member added',
                                      data: updatedData,
                                    ),
                                  );
                                }

                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                }
                                if (mounted) {
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$fullName has been added to My Family!'),
                                      backgroundColor: const Color(0xFF10B981),
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
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final activeUserId = (currentUser?.data?.id ?? '').trim();
    final familyProfiles = _getFamilyProfiles();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTab ? 20 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF64748B).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Pill + Add Member Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.family_restroom_rounded, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'My Family',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 17 : 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${familyProfiles.length}',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Tap a member to switch active profile',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () => _showAddMemberSheet(context, isDark),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'Add',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 14),

          // Horizontal / Grid List of Family Members
          SizedBox(
            height: 106,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: familyProfiles.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                // Last item is "+ Add Member" quick action card
                if (index == familyProfiles.length) {
                  return InkWell(
                    onTap: () => _showAddMemberSheet(context, isDark),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 92,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add_rounded, color: primaryColor, size: 20),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add Member',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final profile = familyProfiles[index];
                final pId = (profile.id ?? '').trim();
                final isActive = (pId.isNotEmpty && pId == activeUserId) ||
                    (pId.isEmpty && profile.isPrimary == true && (activeUserId.isEmpty || activeUserId == currentUser?.data?.id));
                final isThisSwitching = _isSwitching && _switchingProfileId == pId;

                final rawRel = (profile.relation ?? '').trim();
                final bool isFam = rawRel.isNotEmpty &&
                    rawRel.toLowerCase() != 'self' &&
                    rawRel.toLowerCase() != 'primary' &&
                    rawRel.toLowerCase() != 'admin';
                final String relation = isFam ? rawRel : ((profile.isPrimary == true) ? 'Self' : 'Dependent');

                final pName = (profile.name?.isNotEmpty ?? false)
                    ? profile.name!
                    : '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim().isNotEmpty
                        ? '${profile.firstName ?? ''} ${profile.lastName ?? ''}'.trim()
                        : relation;

                final initials = pName.isNotEmpty
                    ? pName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
                    : (relation.isNotEmpty ? relation[0].toUpperCase() : 'M');

                final isPrimary = relation == 'Self' || profile.isPrimary == true;
                final badgeColor = isPrimary ? const Color(0xFF2563EB) : const Color(0xFF10B981);

                final cachedImg = _memberImages[pId];

                return InkWell(
                  onTap: isActive || _isSwitching ? null : () => _switchProfile(profile),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 104,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? primaryColor.withValues(alpha: isDark ? 0.2 : 0.08)
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Avatar + Active Indicator Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF2563EB),
                              ),
                              child: ClipOval(
                                child: isThisSwitching
                                    ? const Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        ),
                                      )
                                    : (cachedImg != null &&
                                            cachedImg.isNotEmpty &&
                                            (cachedImg.startsWith('http') || File(cachedImg).existsSync())
                                        ? (cachedImg.startsWith('http')
                                            ? Image.network(
                                                cachedImg,
                                                width: 38,
                                                height: 38,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Center(
                                                  child: Text(
                                                    initials,
                                                    style: const TextStyle(
                                                      fontFamily: appPoppinFont,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Image.file(
                                                File(cachedImg),
                                                width: 38,
                                                height: 38,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Center(
                                                  child: Text(
                                                    initials,
                                                    style: const TextStyle(
                                                      fontFamily: appPoppinFont,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ))
                                        : Center(
                                            child: Text(
                                              initials,
                                              style: const TextStyle(
                                                fontFamily: appPoppinFont,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          )),
                              ),
                            ),
                            if (isActive)
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Name
                        Text(
                          pName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),

                        // Relation / Status Pill
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.12)
                                : badgeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isActive ? 'Active' : relation,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isActive ? const Color(0xFF10B981) : badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
