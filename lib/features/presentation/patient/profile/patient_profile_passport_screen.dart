import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/base_api_configuration.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/custom_dialogue/custom_dialogue.dart';
import '../../../../core/custom_dialogue/sign_out_alert.dart';
import '../../../../config/app_route/app_routes.dart';
import '../../../../core/local/flutter_secure_storage.dart';
import '../../../../core/local/shared_preferences.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/services/liked_hospitals_service.dart';
import '../../../../core/services/permission_helper.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';
import '../../../../core/urls/urls.dart';
import '../../../../di/dependency_injection.dart';
import '../../../data/models/login/login_model.dart';
import '../../../domain/entities/login/login_entity.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../doctor/profile/widgets/doctor_profile_section_card.dart';
import '../../doctor/profile/widgets/profile_switcher_sheet.dart';
import '../../patient_profile/patient_over_view_bloc/patient_over_view_bloc.dart';
import '../../../../core/tour/patient_tour_controller.dart';

class PatientProfilePassportScreen extends StatefulWidget {
  const PatientProfilePassportScreen({super.key});

  @override
  State<PatientProfilePassportScreen> createState() => _PatientProfilePassportScreenState();
}

class _PatientProfilePassportScreenState extends State<PatientProfilePassportScreen> {
  File? _localProfileImage;
  String? _networkProfileImageUrl;
  bool _photoRemovedExplicitly = false;
  bool _isUploadingPhoto = false;
  final ImagePicker _picker = ImagePicker();
  String? _cachedBloodGroup;
  String? _cachedEmergencyName;
  String? _cachedEmergencyRelation;
  String? _cachedEmergencyPhone;

  static String _cleanValue(String? val, [String fallback = '-']) {
    if (val == null) return fallback;
    final trimmed = val.trim();
    if (trimmed.isEmpty ||
        trimmed.toLowerCase() == 'none' ||
        trimmed.toLowerCase() == 'null') {
      return fallback;
    }
    return trimmed;
  }

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
    _loadCachedEmergencyContact();
  }

  Future<void> _loadCachedEmergencyContact() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';
      if (userId.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final n = prefs.getString('patient_emergency_name_$userId');
      final r = prefs.getString('patient_emergency_relation_$userId');
      final p = prefs.getString('patient_emergency_phone_$userId');
      if (mounted) {
        setState(() {
          if (n != null && n.isNotEmpty) _cachedEmergencyName = n;
          if (r != null && r.isNotEmpty) _cachedEmergencyRelation = r;
          if (p != null && p.isNotEmpty) _cachedEmergencyPhone = p;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final userId = currentUser?.data?.id ?? '';
      if (userId.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final bool wasExplicitlyRemoved = prefs.getBool('patient_profile_removed_$userId') ?? false;

      if (wasExplicitlyRemoved) {
        if (mounted) {
          setState(() {
            _photoRemovedExplicitly = true;
            _localProfileImage = null;
            _networkProfileImageUrl = '';
          });
        }
        return;
      }

      final savedPath = prefs.getString('patient_profile_image_$userId');
      final savedNetworkUrl = prefs.getString('patient_profile_network_image_$userId');

      final activeProfile = currentUser?.data?.profiles?.isNotEmpty == true
          ? currentUser!.data!.profiles!.first
          : null;
      final sessionImage = (currentUser?.data?.imagePath?.isNotEmpty == true)
          ? currentUser!.data!.imagePath
          : activeProfile?.imagePath;

      if (mounted) {
        setState(() {
          _photoRemovedExplicitly = false;
          if (savedPath != null && savedPath.isNotEmpty && File(savedPath).existsSync()) {
            _localProfileImage = File(savedPath);
          }
          _networkProfileImageUrl = (savedNetworkUrl != null && savedNetworkUrl.isNotEmpty)
              ? savedNetworkUrl
              : sessionImage;
        });
      }
    } catch (_) {}
  }

  Future<void> _updateSessionImagePath(String newImagePath) async {
    try {
      final current = GlobalSession.instance.userNotifier.value;
      if (current == null) return;

      final updatedProfiles = (current.data?.profiles ?? []).map((p) {
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
          imagePath: newImagePath,
        );
      }).toList();

      final updatedData = DataModel(
        accessToken: current.data?.accessToken,
        refreshToken: current.data?.refreshToken,
        accessTokenExpiry: current.data?.accessTokenExpiry,
        refreshTokenExpiry: current.data?.refreshTokenExpiry,
        id: current.data?.id,
        isMobileVerified: current.data?.isMobileVerified,
        isEmailVerified: current.data?.isEmailVerified,
        roleCount: current.data?.roleCount,
        hospitalCount: current.data?.hospitalCount,
        organizationCount: current.data?.organizationCount,
        roles: (current.data?.roles ?? []).map((r) => RoleModel.fromEntity(r)).toList(),
        profiles: updatedProfiles,
        firstName: current.data?.firstName,
        lastName: current.data?.lastName,
        email: current.data?.email,
        phoneNumber: current.data?.phoneNumber,
        countryCode: current.data?.countryCode,
        gender: current.data?.gender,
        dob: current.data?.dob,
        height: current.data?.height,
        weight: current.data?.weight,
        heightUnit: current.data?.heightUnit,
        weightUnit: current.data?.weightUnit,
        latestUserRole: current.data?.latestUserRole,
        latestHospitalId: current.data?.latestHospitalId,
        latestOrgId: current.data?.latestOrgId,
        latestRoleId: current.data?.latestRoleId,
        navigationId: current.data?.navigationId,
        imagePath: newImagePath,
      );

      final updatedLogin = LoginModel(
        status: current.status,
        message: current.message,
        data: updatedData,
      );

      await GlobalSession.instance.update(updatedLogin);
    } catch (e) {
      debugPrint("Error updating session image path: $e");
    }
  }

  Future<void> _uploadProfilePhoto(XFile picked) async {
    final file = File(picked.path);
    setState(() {
      _photoRemovedExplicitly = false;
      _localProfileImage = file;
      _isUploadingPhoto = true;
    });

    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final token = currentUser?.data?.accessToken ?? '';
    final hospitalId = currentUser?.data?.latestHospitalId;
    final orgId = currentUser?.data?.latestOrgId;

    if (userId.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('patient_profile_image_$userId', picked.path);
      await prefs.remove('patient_profile_removed_$userId');
    }

    try {
      final fileName = file.path.split(RegExp(r'[/\\]')).last;
      final formData = FormData.fromMap({
        "userId": userId,
        "doctorId": userId,
        "patientId": userId,
        "hospitalId": hospitalId,
        "orgId": orgId,
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
            'x-user-id': userId,
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
          try {
            await CachedNetworkImage.evictFromCache(photoUrl);
            PaintingBinding.instance.imageCache.clear();
            PaintingBinding.instance.imageCache.clearLiveImages();
          } catch (_) {}

          if (mounted) {
            setState(() {
              _photoRemovedExplicitly = false;
              _networkProfileImageUrl = photoUrl;
            });
          }
          if (userId.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('patient_profile_network_image_$userId', photoUrl);
            await prefs.remove('patient_profile_removed_$userId');
          }
          await _updateSessionImagePath(photoUrl);
          if (mounted) {
            _showSuccessSnackBar(context, 'Profile photo updated successfully!');
          }
          return;
        }
      }
      throw Exception('Server did not return a valid photo URL');
    } catch (e) {
      debugPrint("Error uploading patient photo: $e");
      if (mounted) {
        _showErrorSnackBar(context, 'Failed to save photo to database: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(BuildContext ctx, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981), // Emerald Green
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext ctx, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444), // Alert Red
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _openPhotoPickerSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    String currentPhotoUrl = '';
    if (_localProfileImage != null) {
      currentPhotoUrl = _localProfileImage!.path;
    } else if (!_photoRemovedExplicitly) {
      if (_networkProfileImageUrl != null && _networkProfileImageUrl!.isNotEmpty) {
        currentPhotoUrl = _networkProfileImageUrl!;
      } else {
        currentPhotoUrl = (currentUser?.data?.imagePath ?? '').trim();
      }
    }
    final bool canRemove = currentPhotoUrl.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Profile Photo",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Choose how you want to update your profile photo",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12.5,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPickerOption(
                    icon: Icons.camera_alt_rounded,
                    label: "Camera",
                    color: primaryColor,
                    isDark: isDark,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final hasPerm = await PermissionHelper.ensureCameraPermission(context);
                      if (!hasPerm) return;
                      final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                      if (picked != null) {
                        await _uploadProfilePhoto(picked);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildPickerOption(
                    icon: Icons.photo_library_rounded,
                    label: "Gallery",
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final hasPerm = await PermissionHelper.ensurePhotosPermission(context);
                      if (!hasPerm) return;
                      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                      if (picked != null) {
                        await _uploadProfilePhoto(picked);
                      }
                    },
                  ),
                ),
              ],
            ),
            if (canRemove) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text(
                    "Remove Photo",
                    style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    setState(() {
                      _photoRemovedExplicitly = true;
                      _localProfileImage = null;
                      _networkProfileImageUrl = '';
                    });

                    PaintingBinding.instance.imageCache.clear();
                    PaintingBinding.instance.imageCache.clearLiveImages();

                    if (userId.isNotEmpty) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('patient_profile_image_$userId');
                      await prefs.remove('patient_profile_network_image_$userId');
                      await prefs.setBool('patient_profile_removed_$userId', true);
                    }

                    await _updateSessionImagePath('');

                    // Send removal request to backend
                    try {
                      final token = currentUser?.data?.accessToken ?? '';
                      final platFormData = GlobalSession.instance.platformNotifier.value ?? GlobalSession.instance.cachedPlatformInfo;
                      String deviceId = platFormData?.deviceId ?? '';
                      if (deviceId.isEmpty || deviceId == 'unknown_id') {
                        deviceId = (userId.trim().isNotEmpty) ? "dev_${userId.trim()}" : 'fallback_production_id';
                      }

                      await sl<ApiClient>().account(showSuccessSnack: false).post(
                        URLs.providerProfileUpdateUrl,
                        data: {
                          'userId': userId,
                          'patientId': userId,
                          'doctorId': userId,
                          'deviceId': deviceId,
                          'imagePath': '',
                          'profileImageUrl': '',
                        },
                        options: Options(
                          headers: {
                            if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
                            'x-user-id': userId,
                            'x-device-id': deviceId,
                            'Content-Type': 'application/json',
                          },
                        ),
                      );
                    } catch (e) {
                      debugPrint("Backend photo removal error: $e");
                    }

                    if (mounted && context.mounted) {
                      _showSuccessSnackBar(context, 'Profile photo removed successfully!');
                      try {
                        final currentOrgId = currentUser?.data?.latestOrgId ?? 0;
                        final currentHospId = currentUser?.data?.latestHospitalId ?? 0;
                        context.read<PatientOverViewBloc>().add(
                          LoadPatientData(
                            userId,
                            orgId: currentOrgId.toString(),
                            hospitalId: currentHospId.toString(),
                          ),
                        );
                      } catch (_) {}
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.35 : 0.25),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProfileSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileSwitcherSheet(),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context, Color primaryColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'Delete Account',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete your account? This action will:',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13.5,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              _deleteInfoRow(Icons.person_off_rounded, 'Deactivate your account', isDark),
              const SizedBox(height: 6),
              _deleteInfoRow(Icons.family_restroom_rounded, 'Deactivate all linked dependents', isDark),
              const SizedBox(height: 6),
              _deleteInfoRow(Icons.block_rounded, 'Revoke all active sessions', isDark),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'This action cannot be undone. Contact support to reactivate.',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: isDeleting ? null : () async {
                setDialogState(() => isDeleting = true);
                try {
                  final currentUser = GlobalSession.instance.userNotifier.value;
                  final userId = currentUser?.data?.id ?? '';
                  final token = currentUser?.data?.accessToken ?? '';

                  String targetUrl = "${EnvironmentService.config.accountBaseUrl}${URLs.accountDeactivateUrl}";
                  if (!targetUrl.startsWith("http://") && !targetUrl.startsWith("https://")) {
                    targetUrl = "http://$targetUrl";
                  }

                  final dio = Dio(BaseOptions(
                    connectTimeout: const Duration(seconds: 15),
                    receiveTimeout: const Duration(seconds: 15),
                  ));
                  await dio.post(
                    targetUrl,
                    data: {'userId': userId},
                    options: Options(headers: {
                      HttpHeaders.authorizationHeader: 'Bearer $token',
                      'Content-Type': 'application/json',
                    }),
                  );

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  await sl<SecureStorageService>().clearAllSecureData();
                  await sl<SharedPrefsService>().clearAll();
                  if (mounted && context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.signIn,
                      (route) => false,
                    );
                    Utils.showSnackBar(
                      message: 'Your account was deactivated. Contact administrator.',
                      status: false,
                    );
                  }
                } catch (e) {
                  setDialogState(() => isDeleting = false);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (mounted && context.mounted) {
                    _showErrorSnackBar(context, 'Failed to delete account: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}');
                  }
                }
              },
              child: isDeleting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Delete Account', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deleteInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.red.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  DateTime? _parseFlexibleDate(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim();
    if (clean.isEmpty || clean == '0' || clean.toLowerCase() == 'none' || clean.toLowerCase() == 'null') {
      return null;
    }

    // Try standard ISO-8601 (e.g. 1995-09-24 or 1995-09-24T00:00:00.000Z)
    try {
      final dt = DateTime.parse(clean);
      if (dt.year > 1900 && dt.year < 2100) return dt;
    } catch (_) {}

    // Regex check for DD-MM-YYYY or DD/MM/YYYY
    final dmyMatch = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$').firstMatch(clean);
    if (dmyMatch != null) {
      final d = int.tryParse(dmyMatch.group(1)!) ?? 1;
      final m = int.tryParse(dmyMatch.group(2)!) ?? 1;
      final y = int.tryParse(dmyMatch.group(3)!) ?? 1990;
      try {
        return DateTime(y, m, d);
      } catch (_) {}
    }

    // Regex check for YYYY-MM-DD or YYYY/MM/DD
    final ymdMatch = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$').firstMatch(clean);
    if (ymdMatch != null) {
      final y = int.tryParse(ymdMatch.group(1)!) ?? 1990;
      final m = int.tryParse(ymdMatch.group(2)!) ?? 1;
      final d = int.tryParse(ymdMatch.group(3)!) ?? 1;
      try {
        return DateTime(y, m, d);
      } catch (_) {}
    }

    final formats = [
      'dd-MM-yyyy',
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'yyyy/MM/dd',
      'dd MMM yyyy',
      'MMM dd, yyyy',
      'd MMM yyyy',
      'MMMM d, yyyy',
    ];
    for (final fmt in formats) {
      try {
        return DateFormat(fmt).parse(clean);
      } catch (_) {}
    }
    return null;
  }

  String _formatDisplayDob(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final parsed = _parseFlexibleDate(raw);
    if (parsed != null) {
      return DateFormat('dd MMM yyyy').format(parsed);
    }
    return raw.trim();
  }

  void _openEditProfileDialog(BuildContext context, [String? currentBloodGroup]) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final profiles = currentUser?.data?.profiles ?? [];
    final activeProfile = profiles.isNotEmpty ? profiles.first : null;
    final nameController = TextEditingController(text: '${currentUser?.data?.firstName ?? ''} ${currentUser?.data?.lastName ?? ''}'.trim());

    final existingPhone = (currentUser?.data?.phoneNumber ?? '').trim();
    final bool isPhoneAvailable = existingPhone.isNotEmpty;
    final phoneController = TextEditingController(text: existingPhone);

    final existingEmail = (currentUser?.data?.email ?? '').trim();
    final bool isEmailAvailable = existingEmail.isNotEmpty;
    final emailController = TextEditingController(text: existingEmail);

    final existingDob = (currentUser?.data?.dob ?? activeProfile?.dob ?? '').trim();
    final parsedExistingDob = _parseFlexibleDate(existingDob);
    final initialDobText = parsedExistingDob != null
        ? DateFormat('yyyy-MM-dd').format(parsedExistingDob)
        : '';
    final dobController = TextEditingController(text: initialDobText);

    final existingGender = (currentUser?.data?.gender ?? activeProfile?.gender ?? '').trim();
    final genders = ['Male', 'Female', 'Other'];
    String selectedGender = '';
    for (final g in genders) {
      if (g.toLowerCase() == existingGender.toLowerCase()) {
        selectedGender = g;
        break;
      }
    }

    // Resolve existing blood group from argument, cached variable, or current overview state
    String existingBloodGroup = (currentBloodGroup ?? _cachedBloodGroup ?? '').trim();
    if (existingBloodGroup.isEmpty || existingBloodGroup.toLowerCase() == 'none' || existingBloodGroup.toLowerCase() == 'null') {
      try {
        final overViewState = context.read<PatientOverViewBloc>().state;
        if (overViewState is LoadPatientDataState) {
          final bg = overViewState.patientOverViewEntity.data?.medicalInformation?.bloodGroup?.trim();
          if (bg != null && bg.isNotEmpty && bg.toLowerCase() != 'none' && bg.toLowerCase() != 'null') {
            existingBloodGroup = bg;
          }
        }
      } catch (_) {}
    }

    final bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    String selectedBloodGroup = '';
    if (existingBloodGroup.isNotEmpty) {
      final raw = existingBloodGroup.replaceAll(' ', '').toUpperCase();
      for (final bg in bloodGroups) {
        if (bg.toUpperCase() == raw ||
            '${bg}VE'.toUpperCase() == raw ||
            (raw.startsWith(bg) && (raw.contains('POS') || raw.contains('NEG')))) {
          selectedBloodGroup = bg;
          break;
        }
      }
      if (selectedBloodGroup.isEmpty && existingBloodGroup.toLowerCase() != 'none' && existingBloodGroup.toLowerCase() != 'null') {
        bloodGroups.add(existingBloodGroup);
        selectedBloodGroup = existingBloodGroup;
      }
    }

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> pickDateFromCalendar() async {
            FocusScope.of(ctx).unfocus();
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final minDate = DateTime(1920, 1, 1);
            DateTime initialDate = _parseFlexibleDate(dobController.text.trim()) ??
                parsedExistingDob ??
                DateTime(1995, 1, 1);
            final initDateOnly = DateTime(initialDate.year, initialDate.month, initialDate.day);
            DateTime safeInitial = initDateOnly;
            if (safeInitial.isAfter(today)) safeInitial = today;
            if (safeInitial.isBefore(minDate)) safeInitial = minDate;

            final picked = await showDatePicker(
              context: ctx,
              initialDate: safeInitial,
              firstDate: minDate,
              lastDate: today,
              useRootNavigator: true,
              builder: (dateCtx, child) {
                return Theme(
                  data: isDark
                      ? ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: primaryColor,
                            onPrimary: Colors.white,
                            surface: const Color(0xFF1E293B),
                            onSurface: Colors.white,
                          ),
                          dialogTheme: const DialogThemeData(
                            backgroundColor: Color(0xFF1E293B),
                          ),
                        )
                      : ThemeData.light().copyWith(
                          colorScheme: ColorScheme.light(
                            primary: primaryColor,
                            onPrimary: Colors.white,
                            surface: Colors.white,
                            onSurface: const Color(0xFF0F172A),
                          ),
                          dialogTheme: const DialogThemeData(
                            backgroundColor: Colors.white,
                          ),
                        ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
            if (picked != null) {
              setModalState(() {
                dobController.text = DateFormat('yyyy-MM-dd').format(picked);
              });
            }
          }

          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return AnimatedPadding(
            padding: EdgeInsets.only(bottom: bottomInset),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Edit Profile Details',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            FocusScope.of(ctx).unfocus();
                            Navigator.pop(ctx);
                            _openPhotoPickerSheet();
                          },
                          icon: const Icon(Icons.camera_alt_rounded, size: 16),
                          label: const Text("Photo", style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                            padding: const EdgeInsets.all(6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white70 : Colors.grey.shade700),
                          tooltip: 'Close',
                          onPressed: () {
                            FocusScope.of(ctx).unfocus();
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                // Full Name
                Text('Full Name', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  style: TextStyle(fontFamily: appPoppinFont, color: textColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    hintText: 'Enter your full name',
                  ),
                ),
                const SizedBox(height: 14),

                // Date of Birth
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Date of Birth',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    InkWell(
                      onTap: pickDateFromCalendar,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_month_rounded, size: 14, color: primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Open Calendar',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: dobController,
                  keyboardType: TextInputType.datetime,
                  style: TextStyle(fontFamily: appPoppinFont, color: textColor),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    hintText: 'YYYY-MM-DD or DD-MM-YYYY',
                    hintStyle: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.grey,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_month_rounded, size: 20, color: primaryColor),
                      tooltip: 'Select date from calendar',
                      onPressed: pickDateFromCalendar,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Gender
                Text('Gender', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedGender.isEmpty ? null : selectedGender,
                      hint: Text('Select gender', style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, color: isDark ? Colors.white38 : Colors.grey)),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, color: textColor),
                      items: genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedGender = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Blood Group
                Text('Blood Group', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedBloodGroup.isEmpty ? null : selectedBloodGroup,
                      hint: Text('Select blood group', style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, color: isDark ? Colors.white38 : Colors.grey)),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, color: textColor),
                      items: bloodGroups.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedBloodGroup = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Phone Number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Phone Number', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                    if (isPhoneAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              "Locked",
                              style: TextStyle(fontFamily: appPoppinFont, fontSize: 10, color: isDark ? Colors.white60 : Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: phoneController,
                  readOnly: isPhoneAvailable,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    color: isPhoneAvailable
                        ? (isDark ? Colors.white60 : Colors.grey[600])
                        : textColor,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isPhoneAvailable
                        ? (isDark ? const Color(0xFF161F30) : Colors.grey[200])
                        : (isDark ? const Color(0xFF0F172A) : Colors.grey[100]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    hintText: isPhoneAvailable ? null : "Add your mobile number",
                    suffixIcon: isPhoneAvailable
                        ? Icon(Icons.lock_rounded, size: 16, color: isDark ? Colors.white38 : Colors.grey[500])
                        : null,
                  ),
                ),
                const SizedBox(height: 14),

                // Email Address
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Email Address', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                    if (isEmailAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              "Locked",
                              style: TextStyle(fontFamily: appPoppinFont, fontSize: 10, color: isDark ? Colors.white60 : Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: emailController,
                  readOnly: isEmailAvailable,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    color: isEmailAvailable
                        ? (isDark ? Colors.white60 : Colors.grey[600])
                        : textColor,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isEmailAvailable
                        ? (isDark ? const Color(0xFF161F30) : Colors.grey[200])
                        : (isDark ? const Color(0xFF0F172A) : Colors.grey[100]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    hintText: isEmailAvailable ? null : "Add your email address",
                    suffixIcon: isEmailAvailable
                        ? Icon(Icons.lock_rounded, size: 16, color: isDark ? Colors.white38 : Colors.grey[500])
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons: Cancel and Save
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                        ),
                        onPressed: isSaving
                            ? null
                            : () {
                                FocusScope.of(ctx).unfocus();
                                Navigator.pop(ctx);
                              },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSaving ? null : () async {
                          setModalState(() => isSaving = true);
                          try {
                            final userId = currentUser?.data?.id ?? '';
                            final token = currentUser?.data?.accessToken ?? '';
                            final nameParts = nameController.text.trim().split(' ');
                            final firstName = nameParts.isNotEmpty ? nameParts.first : '';
                            final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

                            // Resolve deviceId to satisfy authMiddleware and backend device telemetry
                            final platFormData = GlobalSession.instance.platformNotifier.value ?? GlobalSession.instance.cachedPlatformInfo;
                            String deviceId = platFormData?.deviceId ?? '';
                            if (deviceId.isEmpty || deviceId == 'unknown_id') {
                              deviceId = (userId.trim().isNotEmpty)
                                  ? "dev_${userId.trim()}"
                                  : 'fallback_production_id';
                            }

                            final rawDobText = dobController.text.trim();
                            final parsedDob = _parseFlexibleDate(rawDobText);
                            if (rawDobText.isNotEmpty && parsedDob == null) {
                              setModalState(() => isSaving = false);
                              _showErrorSnackBar(ctx, 'Please enter a valid date of birth (e.g. YYYY-MM-DD or DD-MM-YYYY)');
                              return;
                            }
                            final body = <String, dynamic>{
                              'userId': userId,
                              'patientId': userId,
                              'doctorId': userId,
                              'deviceId': deviceId,
                              'firstName': firstName,
                              'lastName': lastName,
                            };
                            if (parsedDob != null) {
                              final isoDate = DateFormat('yyyy-MM-dd').format(parsedDob);
                              body['dob'] = isoDate;
                              body['dateOfBirth'] = isoDate;
                            }
                            if (selectedGender.isNotEmpty) body['gender'] = selectedGender;
                            if (selectedBloodGroup.isNotEmpty) body['bloodGroup'] = selectedBloodGroup;
                            if (!isPhoneAvailable && phoneController.text.trim().isNotEmpty) {
                              body['phoneNumber'] = phoneController.text.trim();
                            }
                            if (!isEmailAvailable && emailController.text.trim().isNotEmpty) {
                              body['email'] = emailController.text.trim();
                            }
                            final hospId = currentUser?.data?.latestHospitalId;
                            if (hospId != null && hospId > 0) body['hospitalId'] = hospId;
                            final orgId = currentUser?.data?.latestOrgId;
                            if (orgId != null && orgId > 0) body['orgId'] = orgId;

                            // Use sl<ApiClient>().account which handles HTTPS base URL, timeouts, and transparent token refresh
                            await sl<ApiClient>().account(showSuccessSnack: false).post(
                              URLs.providerProfileUpdateUrl,
                              data: body,
                              options: Options(
                                headers: {
                                  if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
                                  'x-user-id': userId,
                                  'x-device-id': deviceId,
                                  'Content-Type': 'application/json',
                                },
                              ),
                            );

                            final resolvedDob = parsedDob != null
                                ? DateFormat('yyyy-MM-dd').format(parsedDob)
                                : (currentUser?.data?.dob ?? activeProfile?.dob);

                            // Update GlobalSession locally
                            final updatedProfiles = (currentUser?.data?.profiles ?? []).map((p) {
                              return ProfileModel(
                                id: p.id,
                                firstName: firstName,
                                lastName: lastName,
                                name: '$firstName $lastName'.trim(),
                                phoneNumber: p.phoneNumber,
                                relation: p.relation,
                                isPrimary: p.isPrimary,
                                gender: selectedGender.isNotEmpty ? selectedGender : p.gender,
                                dob: resolvedDob ?? p.dob,
                                accountType: p.accountType,
                                imagePath: p.imagePath,
                              );
                            }).toList();

                            final updatedData = DataModel(
                              accessToken: currentUser?.data?.accessToken,
                              refreshToken: currentUser?.data?.refreshToken,
                              accessTokenExpiry: currentUser?.data?.accessTokenExpiry,
                              refreshTokenExpiry: currentUser?.data?.refreshTokenExpiry,
                              id: currentUser?.data?.id,
                              isMobileVerified: currentUser?.data?.isMobileVerified,
                              isEmailVerified: currentUser?.data?.isEmailVerified,
                              roleCount: currentUser?.data?.roleCount,
                              hospitalCount: currentUser?.data?.hospitalCount,
                              organizationCount: currentUser?.data?.organizationCount,
                              roles: (currentUser?.data?.roles ?? []).map((r) => RoleModel.fromEntity(r)).toList(),
                              profiles: updatedProfiles,
                              firstName: firstName,
                              lastName: lastName,
                              email: (!isEmailAvailable && emailController.text.trim().isNotEmpty) ? emailController.text.trim() : currentUser?.data?.email,
                              phoneNumber: (!isPhoneAvailable && phoneController.text.trim().isNotEmpty) ? phoneController.text.trim() : currentUser?.data?.phoneNumber,
                              countryCode: currentUser?.data?.countryCode,
                              gender: selectedGender.isNotEmpty ? selectedGender : currentUser?.data?.gender,
                              dob: resolvedDob ?? currentUser?.data?.dob,
                              height: currentUser?.data?.height,
                              weight: currentUser?.data?.weight,
                              heightUnit: currentUser?.data?.heightUnit,
                              weightUnit: currentUser?.data?.weightUnit,
                              latestUserRole: currentUser?.data?.latestUserRole,
                              latestHospitalId: currentUser?.data?.latestHospitalId,
                              latestOrgId: currentUser?.data?.latestOrgId,
                              latestRoleId: currentUser?.data?.latestRoleId,
                              navigationId: currentUser?.data?.navigationId,
                              imagePath: currentUser?.data?.imagePath ?? activeProfile?.imagePath ?? _networkProfileImageUrl,
                            );

                            final updatedLogin = LoginModel(
                              status: currentUser?.status,
                              message: currentUser?.message,
                              data: updatedData,
                            );
                            await GlobalSession.instance.update(updatedLogin);

                            if (selectedBloodGroup.isNotEmpty) {
                              _cachedBloodGroup = selectedBloodGroup;
                            }

                            // Dismiss keyboard and close modal smoothly first
                            if (ctx.mounted) {
                              FocusScope.of(ctx).unfocus();
                              Navigator.pop(ctx);
                            }

                            // Trigger UI update and background reload after smooth dismissal
                            if (mounted && context.mounted) {
                              setState(() {});
                              _showSuccessSnackBar(context, 'Profile updated successfully!');

                              try {
                                final currentUserId = currentUser?.data?.id ?? '';
                                final currentOrgId = currentUser?.data?.latestOrgId ?? 0;
                                final currentHospId = currentUser?.data?.latestHospitalId ?? 0;
                                if (currentUserId.isNotEmpty && mounted && context.mounted) {
                                  context.read<PatientOverViewBloc>().add(
                                    LoadPatientData(
                                      currentUserId,
                                      orgId: currentOrgId.toString(),
                                      hospitalId: currentHospId.toString(),
                                    ),
                                  );
                                }
                              } catch (_) {}
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            if (mounted && context.mounted) {
                              String errorMsg = 'Failed to update profile';
                              if (e is DioException) {
                                final respData = e.response?.data;
                                if (respData is Map && respData['message'] != null) {
                                  errorMsg = respData['message'].toString();
                                } else if (e.message != null && e.message!.isNotEmpty) {
                                  errorMsg = e.message!;
                                }
                              } else {
                                errorMsg = e.toString();
                              }
                              if (errorMsg.length > 90) {
                                errorMsg = '${errorMsg.substring(0, 90)}...';
                              }
                              _showErrorSnackBar(context, errorMsg);
                            }
                          }
                        },
                        child: isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
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

  void _openEditEmergencyContactDialog(BuildContext context, EmergencyContactEntity? emergency) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final initialName = _cleanValue(_cachedEmergencyName ?? emergency?.name, '');
    final initialPhone = _cleanValue(_cachedEmergencyPhone ?? emergency?.phone, '');
    final initialRelation = _cleanValue(_cachedEmergencyRelation ?? emergency?.relationship, '');

    final nameController = TextEditingController(text: initialName);
    final phoneController = TextEditingController(text: initialPhone);

    final relationshipOptions = [
      'Father',
      'Mother',
      'Spouse',
      'Brother',
      'Sister',
      'Son',
      'Daughter',
      'Guardian',
      'Friend',
      'Other',
    ];

    String selectedRelation = '';
    String otherRelationText = '';
    if (initialRelation.isNotEmpty) {
      for (final opt in relationshipOptions) {
        if (opt.toLowerCase() == initialRelation.toLowerCase()) {
          selectedRelation = opt;
          break;
        }
      }
      if (selectedRelation.isEmpty) {
        selectedRelation = 'Other';
        otherRelationText = initialRelation;
      }
    }

    final otherRelationController = TextEditingController(text: otherRelationText);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return AnimatedPadding(
            padding: EdgeInsets.only(bottom: bottomInset),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.only(
                top: 16,
                left: 20,
                right: 20,
                bottom: 24,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Edit Emergency Contact',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
                            padding: const EdgeInsets.all(6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white70 : Colors.grey.shade700),
                          tooltip: 'Close',
                          onPressed: () {
                            FocusScope.of(ctx).unfocus();
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Contact Name', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: TextStyle(fontFamily: appPoppinFont, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Enter contact name',
                        hintStyle: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: isDark ? Colors.white38 : Colors.grey),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Relationship', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedRelation.isEmpty ? null : selectedRelation,
                          hint: Text(
                            'Select relationship',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 14,
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                          ),
                          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, color: textColor),
                          items: relationshipOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() {
                                selectedRelation = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    if (selectedRelation == 'Other') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: otherRelationController,
                        style: TextStyle(fontFamily: appPoppinFont, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Enter relationship (e.g. Uncle, Colleague, Neighbor)',
                          hintStyle: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: isDark ? Colors.white38 : Colors.grey),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text('Emergency Phone Number', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(fontFamily: appPoppinFont, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'e.g. +91 91234 56789',
                        hintStyle: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: isDark ? Colors.white38 : Colors.grey),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                            ),
                            onPressed: isSaving
                                ? null
                                : () {
                                    FocusScope.of(ctx).unfocus();
                                    Navigator.pop(ctx);
                                  },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    setModalState(() => isSaving = true);
                                    try {
                                      final finalName = nameController.text.trim();
                                      final finalRelation = selectedRelation == 'Other'
                                          ? otherRelationController.text.trim()
                                          : selectedRelation;
                                      final finalPhone = phoneController.text.trim();

                                      final currentUser = GlobalSession.instance.userNotifier.value;
                                      final userId = currentUser?.data?.id ?? '';
                                      final token = currentUser?.data?.accessToken ?? '';

                                      // 1. Cache values locally immediately
                                      _cachedEmergencyName = finalName;
                                      _cachedEmergencyRelation = finalRelation;
                                      _cachedEmergencyPhone = finalPhone;

                                      if (userId.isNotEmpty) {
                                        final prefs = await SharedPreferences.getInstance();
                                        await prefs.setString('patient_emergency_name_$userId', finalName);
                                        await prefs.setString('patient_emergency_relation_$userId', finalRelation);
                                        await prefs.setString('patient_emergency_phone_$userId', finalPhone);
                                      }

                                      // 2. Call backend updatePatientProfile API (/api/users/patient/profile)
                                      try {
                                        final platFormData = GlobalSession.instance.platformNotifier.value ?? GlobalSession.instance.cachedPlatformInfo;
                                        String deviceId = platFormData?.deviceId ?? '';
                                        if (deviceId.isEmpty || deviceId == 'unknown_id') {
                                          deviceId = (userId.trim().isNotEmpty) ? "dev_${userId.trim()}" : 'fallback_production_id';
                                        }

                                        await sl<ApiClient>().account(showSuccessSnack: false).post(
                                          '/api/users/patient/profile',
                                          data: {
                                            'personalInfo': {
                                              'emergencyContact': {
                                                'name': finalName,
                                                'relationship': finalRelation,
                                                'phone': finalPhone,
                                              },
                                            },
                                          },
                                          options: Options(
                                            headers: {
                                              if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
                                              'x-user-id': userId,
                                              'x-device-id': deviceId,
                                              'Content-Type': 'application/json',
                                            },
                                          ),
                                        );
                                      } catch (e) {
                                        debugPrint("Backend emergency contact update error: $e");
                                      }

                                      // 3. Smooth dismissal
                                      if (ctx.mounted) {
                                        FocusScope.of(ctx).unfocus();
                                        Navigator.pop(ctx);
                                      }

                                      // 4. Update UI & reload overview
                                      if (mounted && context.mounted) {
                                        setState(() {});
                                        _showSuccessSnackBar(context, 'Emergency contact updated successfully!');
                                        try {
                                          final currentOrgId = currentUser?.data?.latestOrgId ?? 0;
                                          final currentHospId = currentUser?.data?.latestHospitalId ?? 0;
                                          context.read<PatientOverViewBloc>().add(
                                            LoadPatientData(
                                              userId,
                                              orgId: currentOrgId.toString(),
                                              hospitalId: currentHospId.toString(),
                                            ),
                                          );
                                        } catch (_) {}
                                      }
                                    } catch (e) {
                                      setModalState(() => isSaving = false);
                                      if (mounted && context.mounted) {
                                        _showErrorSnackBar(context, 'Failed to update emergency contact: $e');
                                      }
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Save Changes', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final hospitalId = currentUser?.data?.latestHospitalId?.toString() ?? '1';
    final orgId = currentUser?.data?.latestOrgId?.toString() ?? '1';

    return BlocProvider<PatientOverViewBloc>(
      create: (_) => sl<PatientOverViewBloc>()..add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId)),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          title: const Text(
            'My Profile',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Switch Member',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.switch_account_rounded, size: 18, color: primaryColor),
              ),
              onPressed: () => _openProfileSwitcher(context),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: BlocBuilder<PatientOverViewBloc, PatientOverViewState>(
            builder: (context, state) {
              if (state is LoadingPatientViewDetails) {
                return _buildProfileShimmer(context, isDark, isTab);
              }

              PatientOverViewEntity? overViewEntity;
              if (state is LoadPatientDataState) {
                overViewEntity = state.patientOverViewEntity;
              }

              final data = overViewEntity?.data;
              final contact = data?.contactInformation;
              final medical = data?.medicalInformation;
              final emergency = contact?.emergencyContact;

              // Determine active member
              final List<ProfileEntity> profiles = currentUser?.data?.profiles ?? [];
              final activeProfile = profiles.isNotEmpty ? profiles.first : null;

              final firstName = currentUser?.data?.firstName ?? '';
              final lastName = currentUser?.data?.lastName ?? '';
              final patientName = '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName'.trim() : 'Patient';

              final initials = patientName.isNotEmpty
                  ? patientName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
                  : 'P';

              final rawRel = (activeProfile?.relation ?? '').trim();
              final bool hasFamilyRelation = rawRel.isNotEmpty &&
                  rawRel.toLowerCase() != 'self' &&
                  rawRel.toLowerCase() != 'primary' &&
                  rawRel.toLowerCase() != 'admin';

              final String relation = hasFamilyRelation
                  ? rawRel
                  : ((activeProfile?.isPrimary == true) ? 'Primary' : 'Dependent');
              final bool isPrimary = (relation == 'Primary');
              final mrn = userId.isNotEmpty
                  ? 'MRN-${userId.length > 5 ? userId.substring(0, 5).toUpperCase() : userId}'
                  : 'MRN-90214';
              final phone = contact?.phone ?? currentUser?.data?.phoneNumber ?? '';
              final email = contact?.emailAddress ?? currentUser?.data?.email ?? '';
              final gender = currentUser?.data?.gender ?? activeProfile?.gender ?? '';
              final dob = currentUser?.data?.dob ?? activeProfile?.dob ?? '';
              final bloodGroup = medical?.bloodGroup ?? '';
              if (bloodGroup.isNotEmpty && bloodGroup.toLowerCase() != 'none' && bloodGroup.toLowerCase() != 'null') {
                _cachedBloodGroup = bloodGroup;
              }
              final hospital = data?.hospital?.name ?? data?.nextAppointment?.hospitalName ?? '';
              final hospitalLogo = data?.hospital?.logo ??
                  data?.hospital?.imageUrl ??
                  data?.nextAppointment?.hospitalLogo ??
                  LikedHospitalsService.instance.getHospitalLogo(
                    data?.hospital?.id ?? currentUser?.data?.latestHospitalId ?? 19,
                    hospital,
                  );

              final displayEmergencyName = _cleanValue(_cachedEmergencyName ?? emergency?.name, '-');
              final displayEmergencyRelation = _cleanValue(_cachedEmergencyRelation ?? emergency?.relationship, '-');
              final displayEmergencyPhone = _cleanValue(_cachedEmergencyPhone ?? emergency?.phone, '-');

              return RefreshIndicator(
                color: primaryColor,
                onRefresh: () async {
                  context.read<PatientOverViewBloc>().add(LoadPatientData(userId, orgId: orgId, hospitalId: hospitalId));
                  await Future.delayed(const Duration(milliseconds: 600));
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: screenHorizontalSpacePadding,
                    vertical: 12,
                  ),
                  children: [
                    // 1. Executive Hero Header with Profile Picture Upload & Hospital Logo
                    _buildPatientHeroHeader(
                      context: context,
                      name: patientName,
                      initials: initials,
                      relation: relation,
                      isPrimary: isPrimary,
                      mrn: mrn,
                      hospital: hospital,
                      hospitalLogo: hospitalLogo,
                      isDark: isDark,
                      primaryColor: primaryColor,
                      isTab: isTab,
                      bloodGroup: bloodGroup,
                    ),
                    const SizedBox(height: 16),

                    // 2. Personal Information Card
                    DoctorProfileSectionCard(
                      title: "Personal & Demographics",
                      icon: Icons.person_rounded,
                      iconColor: primaryColor,
                      isTab: isTab,
                      onEdit: () => _openEditProfileDialog(context, bloodGroup),
                      fields: [
                        DoctorProfileFieldItem(
                          label: "Full Name",
                          value: patientName,
                          icon: Icons.badge_outlined,
                          isCopyable: true,
                        ),
                        DoctorProfileFieldItem(
                          label: "Medical Record Number (MRN)",
                          value: mrn,
                          icon: Icons.fingerprint_rounded,
                          isCopyable: true,
                          isVerified: true,
                        ),
                        DoctorProfileFieldItem(
                          label: "Date of Birth",
                          value: _formatDisplayDob(dob),
                          icon: Icons.cake_outlined,
                        ),
                        DoctorProfileFieldItem(
                          label: "Gender",
                          value: gender.isNotEmpty ? gender : '-',
                          icon: Icons.wc_outlined,
                        ),
                        DoctorProfileFieldItem(
                          label: "Blood Group",
                          value: bloodGroup.isNotEmpty
                              ? bloodGroup
                              : (_cachedBloodGroup?.isNotEmpty == true ? _cachedBloodGroup! : '-'),
                          icon: Icons.bloodtype_outlined,
                          customValueColor: (bloodGroup.isNotEmpty || _cachedBloodGroup?.isNotEmpty == true)
                              ? Colors.redAccent
                              : null,
                        ),
                        DoctorProfileFieldItem(
                          label: "Phone Number",
                          value: phone.isNotEmpty ? phone : '-',
                          icon: Icons.phone_outlined,
                          isCopyable: phone.isNotEmpty,
                        ),
                        DoctorProfileFieldItem(
                          label: "Email Address",
                          value: email.isNotEmpty ? email : '-',
                          icon: Icons.email_outlined,
                          isCopyable: email.isNotEmpty,
                          isVerified: email.isNotEmpty,
                        ),
                      ],
                    ),

                    // 3. Emergency Contact Card
                    DoctorProfileSectionCard(
                      title: "Emergency Contact",
                      icon: Icons.contact_phone_rounded,
                      iconColor: const Color(0xFF10B981),
                      isTab: isTab,
                      onEdit: () => _openEditEmergencyContactDialog(context, emergency),
                      fields: [
                        DoctorProfileFieldItem(
                          label: "Contact Name",
                          value: displayEmergencyName,
                          icon: Icons.person_outline_rounded,
                        ),
                        DoctorProfileFieldItem(
                          label: "Relationship",
                          value: displayEmergencyRelation,
                          icon: Icons.family_restroom_rounded,
                        ),
                        DoctorProfileFieldItem(
                          label: "Phone Number",
                          value: displayEmergencyPhone,
                          icon: Icons.phone_forwarded_rounded,
                          isCopyable: displayEmergencyPhone != '-',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. Spotlight Product Tour Tile
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.4 : 0.25),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.08 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.lightbulb_circle_rounded, color: Color(0xFF2563EB), size: 20),
                        ),
                        title: Text(
                          "Spotlight Product Tour",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          "Start live interactive spotlight tour across all tabs",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          PatientTourController().restartTour(context: context);
                        },
                      ),
                    ),

                    // 5. Legal & Policies Card
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // 1. Terms & Conditions
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.description_outlined, color: Color(0xFF0284C7), size: 20),
                            ),
                            title: Text(
                              "Terms & Conditions",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              "Usage terms & service policies",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () {
                              CustomUrlDialog.customLauncherDialogue(
                                context,
                                'Terms & Conditions',
                                'Review our terms and conditions, user agreement, and operational policies governing your access and usage of Yira Clinx platform.',
                                primaryColor,
                                'https://yira.ai/terms-and-conditions/',
                                'More',
                                'assets/images/ic_read_abt_us.png',
                              );
                            },
                          ),
                          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

                          // 2. Privacy Policy (below Terms & Conditions)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.privacy_tip_outlined, color: Color(0xFFF59E0B), size: 20),
                            ),
                            title: Text(
                              "Privacy Policy",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              "Data privacy & personal health record protection",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () {
                              CustomUrlDialog.customLauncherDialogue(
                                context,
                                'Privacy Policy',
                                'We prioritize your privacy and data security. Read our privacy policy to understand how your medical and personal data is collected, protected, and processed.',
                                primaryColor,
                                'https://yira.ai/privacy-policy/',
                                'More',
                                'assets/images/ic_privacy_plc.png',
                              );
                            },
                          ),
                          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

                          // 3. Cancellation & Refund Policy
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF10B981), size: 20),
                            ),
                            title: Text(
                              "Cancellation & Refund Policy",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              "Appointment cancellation & refund guidelines",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            onTap: () {
                              CustomUrlDialog.customLauncherDialogue(
                                context,
                                'Cancellation & Refund Policy',
                                'Learn about our policies regarding appointment cancellations, rescheduled consultations, payment reversals, and refund processing.',
                                primaryColor,
                                'https://yira.ai/cancellation-and-refund-policy/',
                                'More',
                                'assets/images/ic_read_abt_us.png',
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Delete Account Tile
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_forever_rounded, color: Colors.deepOrange, size: 20),
                        ),
                        title: const Text(
                          "Delete Account",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          "Permanently deactivate your account",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.deepOrange, size: 14),
                        onTap: () => _showDeleteAccountConfirmation(context, primaryColor),
                      ),
                    ),

                    // 9. Sign Out Tile
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                        ),
                        title: const Text(
                          "Sign Out",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.red, size: 14),
                        onTap: () async {
                          await SignOutAlert.showSignCustomDialog(context, primaryColor);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalLogoBadge({
    required String? logoUrl,
    required double size,
    required bool isDark,
    double radius = 8,
  }) {
    Widget fallbackIcon() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.local_hospital_rounded,
            size: size * 0.52,
            color: const Color(0xFF0284C7),
          ),
        ),
      );
    }

    final trimmed = (logoUrl ?? '').trim();
    if (trimmed.isEmpty) {
      return fallbackIcon();
    }

    Widget content;
    if (trimmed.endsWith('.svg')) {
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        content = SvgPicture.network(
          trimmed,
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholderBuilder: (_) => fallbackIcon(),
        );
      } else {
        content = SvgPicture.asset(
          trimmed,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      }
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      content = CachedNetworkImage(
        imageUrl: trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Center(
          child: SizedBox(
            width: size * 0.4,
            height: size * 0.4,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF0284C7),
            ),
          ),
        ),
        errorWidget: (context, url, error) => fallbackIcon(),
      );
    } else {
      content = Image.asset(
        trimmed,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallbackIcon(),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: content,
        ),
      ),
    );
  }


  Widget _buildPatientHeroHeader({
    required BuildContext context,
    required String name,
    required String initials,
    required String relation,
    required bool isPrimary,
    required String mrn,
    required String hospital,
    String? hospitalLogo,
    required bool isDark,
    required Color primaryColor,
    required bool isTab,
    String? bloodGroup,
  }) {
    return Container(
      key: PatientTourController().passportProfileCardKey,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Surface Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              isTab ? 28 : 20,
              isTab ? 26 : 22,
              isTab ? 28 : 20,
              isTab ? 22 : 18,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Builder(
              builder: (context) {
                final currentUser = GlobalSession.instance.userNotifier.value;
                final List<ProfileEntity> profiles = currentUser?.data?.profiles ?? [];
                final activeProfile = profiles.isNotEmpty ? profiles.first : null;

                final bool hasLocalImage = !_photoRemovedExplicitly && _localProfileImage != null && _localProfileImage!.existsSync();
                final String activeSessionImage = !_photoRemovedExplicitly
                    ? (currentUser?.data?.imagePath?.isNotEmpty == true
                        ? currentUser!.data!.imagePath!.trim()
                        : (activeProfile?.imagePath ?? '').trim())
                    : '';
                final String resolvedNetworkUrl = !_photoRemovedExplicitly
                    ? ((_networkProfileImageUrl != null)
                        ? _networkProfileImageUrl!.trim()
                        : activeSessionImage)
                    : '';
                final bool hasNetworkImage = resolvedNetworkUrl.isNotEmpty;
                final bool hasPhoto = hasLocalImage || hasNetworkImage;

                return Column(
                  children: [
                    // Avatar with Camera Icon Overlay for Photo Upload
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: _openPhotoPickerSheet,
                          child: Container(
                            width: isTab ? 96 : 84,
                            height: isTab ? 96 : 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.4),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _isUploadingPhoto
                                  ? Center(
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: primaryColor,
                                        ),
                                      ),
                                    )
                                  : hasLocalImage
                                      ? Image.file(
                                          _localProfileImage!,
                                          width: isTab ? 96 : 84,
                                          height: isTab ? 96 : 84,
                                          fit: BoxFit.cover,
                                        )
                                      : hasNetworkImage
                                          ? _buildNetworkAvatar(resolvedNetworkUrl, initials, isTab, primaryColor)
                                          : _buildInitialsAvatar(initials, isTab, primaryColor),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: _openPhotoPickerSheet,
                            child: Container(
                              padding: const EdgeInsets.all(4.5),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Tap to change photo subtitle button
                    GestureDetector(
                      onTap: _openPhotoPickerSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(hasPhoto ? Icons.edit_outlined : Icons.add_a_photo_outlined, size: 13, color: primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              hasPhoto ? "Change Photo" : "Add Photo",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                const SizedBox(height: 10),

                // Name & Verified Badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 20 : 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.verified_rounded, size: 18, color: primaryColor),
                  ],
                ),
                const SizedBox(height: 6),

                // Relation Badge + MRN Badge
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isPrimary ? const Color(0xFF10B981) : const Color(0xFF0284C7)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPrimary ? Icons.star_rounded : Icons.people_rounded,
                            size: 14,
                            color: isPrimary ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            relation,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isPrimary ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        mrn,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Hospital Tag with Database Logo (only if hospital is available)
                if (hospital.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHospitalLogoBadge(
                          logoUrl: hospitalLogo,
                          size: 18,
                          isDark: isDark,
                          radius: 5,
                        ),
                        const SizedBox(width: 7),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isTab ? 260 : 180),
                          child: Text(
                            hospital,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),

          // Compact Edit Profile Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: SizedBox(
                height: 34,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    foregroundColor: primaryColor,
                  ),
                  onPressed: () => _openEditProfileDialog(context, bloodGroup),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit Profile', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkAvatar(String url, String initials, bool isTab, Color primaryColor) {
    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Str = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: isTab ? 96 : 84,
          height: isTab ? 96 : 84,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(initials, isTab, primaryColor),
        );
      } catch (_) {
        return _buildInitialsAvatar(initials, isTab, primaryColor);
      }
    }

    String fullUrl = url;
    if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
      final baseUrl = EnvironmentService.config.accountBaseUrl;
      final formattedBase = baseUrl.startsWith('http') ? baseUrl : 'http://$baseUrl';
      final cleanBase = formattedBase.endsWith('/') ? formattedBase.substring(0, formattedBase.length - 1) : formattedBase;
      final cleanPath = fullUrl.startsWith('/') ? fullUrl : '/$fullUrl';
      fullUrl = '$cleanBase$cleanPath';
    }

    return CachedNetworkImage(
      key: ValueKey(fullUrl),
      imageUrl: fullUrl,
      width: isTab ? 96 : 84,
      height: isTab ? 96 : 84,
      fit: BoxFit.cover,
      placeholder: (context, url) => Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: primaryColor,
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildInitialsAvatar(initials, isTab, primaryColor),
    );
  }

  Widget _buildInitialsAvatar(String initials, bool isTab, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: isTab ? 30 : 26,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }


  Widget _buildProfileShimmer(BuildContext context, bool isDark, bool isTab) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(screenHorizontalSpacePadding),
      child: Column(
        children: [
          BaseShimmer(
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const SizedBox(height: 16),
          BaseShimmer(
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
