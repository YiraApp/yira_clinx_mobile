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
import 'package:yiraclinics/core/services/favorite_patients_service.dart';

import 'package:yiraclinics/features/presentation/consent/bloc/patient_access_consent_bloc.dart';
import 'package:yiraclinics/features/presentation/consent/bloc/patient_access_consent_state.dart';

class PatientProfileHeader extends StatefulWidget {
  final PatientProfileEntity patient;
  final bool isTab;
  final VoidCallback? onBack;
  final Widget? tabBar;
  final String? appointmentId;
  final String? patientId;
  final String? initialStatus;
  final int? hospitalId;
  final PatientAccessConsentBloc? consentBloc;
  final DoctorAccessStatusLoaded? accessStatus;
  final bool showStatus;

  const PatientProfileHeader({
    super.key,
    required this.patient,
    required this.isTab,
    this.onBack,
    this.tabBar,
    this.appointmentId,
    this.patientId,
    this.initialStatus,
    this.hospitalId,
    this.consentBloc,
    this.accessStatus,
    this.showStatus = true,
  });

  @override
  State<PatientProfileHeader> createState() => _PatientProfileHeaderState();
}

class _PatientProfileHeaderState extends State<PatientProfileHeader> {
  late String _currentStatus;
  bool _isUpdating = false;
  bool _isFav = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = (widget.initialStatus != null && widget.initialStatus!.trim().isNotEmpty)
        ? widget.initialStatus!.trim().toUpperCase()
        : 'CONFIRMED';
    _checkFavorite();
  }

  void _checkFavorite() {
    final pId = widget.patientId ?? '';
    final altId = widget.patient.id;
    _isFav = FavoritePatientsService().isFavorite(pId.isNotEmpty ? pId : altId, altId);
  }

  Future<void> _toggleFavorite() async {
    final pId = widget.patientId ?? widget.patient.id;
    final altId = widget.patient.id;
    final isNowFav = await FavoritePatientsService().toggleFavorite(
      patientId: pId,
      alternateId: altId,
    );
    if (mounted) {
      setState(() {
        _isFav = isNowFav;
      });
    }
  }

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
    setState(() {
      _isUpdating = true;
    });

    try {
      final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
      final doctorId = GlobalSession.instance.userNotifier.value?.data?.id ?? '';
      final aptId = widget.appointmentId;
      final patientId = widget.patientId ?? widget.patient.id;

      final response = await sl<ApiClient>().account(showSuccessSnack: true).post(
        URLs.updateAppointmentStatusUrl,
        data: {
          if (aptId != null && aptId.isNotEmpty) 'appointmentId': aptId,
          'patientId': patientId,
          if (doctorId.isNotEmpty) 'doctorId': doctorId,
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
      setState(() {
        _currentStatus = newStatus.toUpperCase();
      });
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
    final bool isPatient = GlobalSession.instance.userNotifier.value?.data?.navigationId == "1";
    final initials = widget.patient.name.trim().isNotEmpty
        ? widget.patient.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'PT';

    final String rawPhone = widget.patient.phone.trim();
    final String phone = (rawPhone.isEmpty || rawPhone.toLowerCase() == 'none' || rawPhone.toLowerCase() == 'null')
        ? ''
        : rawPhone;

    final String rawDob = widget.patient.dob.trim();
    final String dob = (rawDob.isEmpty || rawDob.toLowerCase() == 'none' || rawDob.toLowerCase() == 'null')
        ? ''
        : rawDob;

    final String rawGender = widget.patient.gender.trim();
    final String gender = (rawGender.isEmpty || rawGender.toLowerCase() == 'none' || rawGender.toLowerCase() == 'null')
        ? ''
        : rawGender;

    final String rawBlood = widget.patient.bloodGroup.trim();
    final String bloodGroup = (rawBlood.isEmpty || rawBlood.toLowerCase() == 'none' || rawBlood.toLowerCase() == 'null')
        ? ''
        : rawBlood;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.onBack != null)
                  GestureDetector(
                    onTap: widget.onBack,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
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
                    // Book Appointment Button
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.add_rounded, size: 15, color: primaryColor),
                            SizedBox(width: 4),
                            Text(
                              'Book Appointment',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Appointment status badge (only shown on appointment screen when showStatus == true)
                    if (widget.showStatus && widget.appointmentId != null && widget.appointmentId!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: (_isUpdating || isPatient) ? null : () => _showStatusPicker(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
                                if (!isPatient) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (!isPatient) ...[
                      const SizedBox(width: 8),
                      // Favorite Star Button
                      GestureDetector(
                        onTap: _toggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _isFav
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isFav
                                  ? const Color(0xFFFDE68A)
                                  : Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Icon(
                            _isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: _isFav ? const Color(0xFFD97706) : Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Patient details card layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Patient Avatar (White Circle with Blue Initials & shadow)
                Container(
                  width: widget.isTab ? 58 : 50,
                  height: widget.isTab ? 58 : 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        color: primaryColor,
                        fontSize: widget.isTab ? 20 : 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Name
                      Text(
                        widget.patient.name,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          color: Colors.white,
                          fontSize: widget.isTab ? 20 : 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Mobile Phone Number Row
                      if (phone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              Icon(
                                Icons.phone_android_rounded,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                phone,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: widget.isTab ? 13 : 11.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Demographics row (DOB, Gender, Blood Group)
                      Row(
                        children: [
                          if (dob.isNotEmpty)
                            Text(
                              dob,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: widget.isTab ? 12.5 : 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (gender.isNotEmpty) ...[
                            if (dob.isNotEmpty)
                              Text(
                                ' • ',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                              ),
                            Text(
                              gender,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: widget.isTab ? 12.5 : 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (bloodGroup.isNotEmpty) ...[
                            if (dob.isNotEmpty || gender.isNotEmpty)
                              Text(
                                ' • ',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                bloodGroup,
                                style: const TextStyle(
                                  fontFamily: appPoppinFont,
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
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
            const SizedBox(height: 10),
            if (widget.tabBar != null) widget.tabBar!,
          ],
        ),
      ),
    );
  }
}