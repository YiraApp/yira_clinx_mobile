import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/api/base_api_configuration.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/flutter_secure_storage.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/local/shared_preferences.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/core/utils/utils.dart';
import 'package:yiraclinics/di/dependency_injection.dart';

class DeleteAccountAlert {
  static Widget _deleteInfoRow(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white60 : Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  static Future<void> showCustomDialog(
    BuildContext context, {
    bool isDoctor = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    bool isDeleting = false;

    return showDialog<void>(
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
              _deleteInfoRow(
                Icons.person_off_rounded,
                isDoctor
                    ? 'Delete account and doctor credentials'
                    : 'Delete account and personal profile',
                isDark,
              ),
              const SizedBox(height: 6),
              _deleteInfoRow(
                isDoctor
                    ? Icons.medical_services_outlined
                    : Icons.family_restroom_rounded,
                isDoctor
                    ? 'Close active clinical slots & doctor schedule'
                    : 'Delete all linked dependents',
                isDark,
              ),
              const SizedBox(height: 6),
              _deleteInfoRow(
                Icons.block_rounded,
                'Revoke all active sessions & access tokens',
                isDark,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'This action cannot be undone. You can create a new account anytime.',
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
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() => isDeleting = true);
                      try {
                        final currentUser = GlobalSession.instance.userNotifier.value;
                        final userId = currentUser?.data?.id ?? '';
                        final token = currentUser?.data?.accessToken ?? '';

                        String targetUrl =
                            "${EnvironmentService.config.accountBaseUrl}${URLs.accountDeactivateUrl}";
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

                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.signIn,
                            (route) => false,
                          );
                          Utils.showSnackBar(
                            message: 'Your account has been deleted successfully.',
                            status: false,
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isDeleting = false);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to delete account: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e}',
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Delete Account',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
