import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';

class PatientProfileHeader extends StatefulWidget {
  final PatientProfileEntity patient;
  final bool isTab;
  final VoidCallback? onBack;
  final Widget? tabBar;
  final String? appointmentId;

  const PatientProfileHeader({
    super.key,
    required this.patient,
    required this.isTab,
    this.onBack,
    this.tabBar,
    this.appointmentId,
  });

  @override
  State<PatientProfileHeader> createState() => _PatientProfileHeaderState();
}

class _PatientProfileHeaderState extends State<PatientProfileHeader> {
  String _currentStatus = 'CONFIRMED';
  bool _isUpdating = false;

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) {
        final statuses = [
          'Scheduled',
          'Confirmed',
          'In Progress',
          'Completed',
          'Cancelled',
        ];
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Update Appointment Status",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ...statuses.map((s) {
                final isCurrent = _currentStatus.toLowerCase() == s.toLowerCase();
                return ListTile(
                  title: Text(
                    s,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Theme.of(context).primaryColor : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                  trailing: isCurrent ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor) : null,
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _updateStatus(s);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    final aptId = widget.appointmentId;
    if (aptId == null || aptId.isEmpty) {
      setState(() {
        _currentStatus = newStatus.toUpperCase();
      });
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
      final response = await sl<ApiClient>().account(showSuccessSnack: true).post(
        URLs.updateAppointmentStatusUrl,
        data: {
          'appointmentId': aptId,
          'status': newStatus,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _currentStatus = newStatus.toUpperCase();
        });
      }
    } catch (e) {
      // Handled by ApiClient or fallback silently
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.patient.name.trim().isNotEmpty
        ? widget.patient.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'PT';

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation & Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.onBack != null)
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.addAppointmentScreen,
                          arguments: {
                            'patientName': widget.patient.name,
                            'patientPhone': widget.patient.phone,
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.add_rounded, size: 14, color: primaryColor),
                            SizedBox(width: 4),
                            Text(
                              'Book Appt',
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _isUpdating ? null : () => _showStatusPicker(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isUpdating)
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            else ...[
                              Text(
                                _currentStatus,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontFamily: appPoppinFont,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_drop_down_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Patient details row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Patient Avatar (White Circle, Blue Initials)
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontFamily: appPoppinFont,
                        color: primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.name,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          color: Colors.white,
                          fontSize: widget.isTab ? 20 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (widget.patient.dob.isNotEmpty)
                            Text(
                              widget.patient.dob,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                color: Colors.white.withOpacity(0.9),
                                fontSize: widget.isTab ? 13 : 11,
                              ),
                            ),
                          if (widget.patient.gender.isNotEmpty) ...[
                            if (widget.patient.dob.isNotEmpty)
                              Text(
                                ' • ',
                                style: TextStyle(color: Colors.white.withOpacity(0.7)),
                              ),
                            Text(
                              widget.patient.gender,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                color: Colors.white.withOpacity(0.9),
                                fontSize: widget.isTab ? 13 : 11,
                              ),
                            ),
                          ],
                          if (widget.patient.bloodGroup.isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: TextStyle(color: Colors.white.withOpacity(0.7)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.patient.bloodGroup,
                                style: const TextStyle(
                                  fontFamily: appPoppinFont,
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.tabBar != null) widget.tabBar!,
          ],
        ),
      ),
    );
  }
}