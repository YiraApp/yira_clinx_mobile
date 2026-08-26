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
import 'request_access_duration_modal.dart';

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

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 10),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
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
                        color: Colors.white.withValues(alpha: 0.15),
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
                      onTap: (_isUpdating || isPatient) ? null : () => _showStatusPicker(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
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
                    if (!isPatient) ...[
                      const SizedBox(width: 8),
                      // Favorite Star Button
                      GestureDetector(
                        onTap: _toggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: _isFav
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isFav
                                  ? const Color(0xFFFDE68A)
                                  : Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            _isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: _isFav ? const Color(0xFFD97706) : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
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
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: widget.isTab ? 13 : 11,
                              ),
                            ),
                          if (widget.patient.gender.isNotEmpty) ...[
                            if (widget.patient.dob.isNotEmpty)
                              Text(
                                ' • ',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                              ),
                            Text(
                              widget.patient.gender,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: widget.isTab ? 13 : 11,
                              ),
                            ),
                          ],
                          if (widget.patient.bloodGroup.isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
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
            if (!isPatient && widget.consentBloc != null && (widget.appointmentId == null || widget.appointmentId!.isEmpty)) ...[
              const SizedBox(height: 10),
              _buildConsentAccessButton(context),
            ],
            const SizedBox(height: 8),
            if (widget.tabBar != null) widget.tabBar!,
          ],
        ),
      ),
    );
  }

  Widget _buildConsentAccessButton(BuildContext context) {
    final status = widget.accessStatus?.status.toUpperCase() ?? 'NO_REQUEST';
    final hasAccess = widget.accessStatus?.hasAccess ?? false;
    final isPending = status == 'PENDING';

    if (hasAccess) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 14),
            const SizedBox(width: 5),
            Text(
              "Access Granted • ${widget.accessStatus?.durationLabel ?? 'Active'}",
              style: const TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (isPending) {
      return InkWell(
        onTap: () {
          RequestAccessDurationModal.show(
            context: context,
            patient: widget.patient,
            patientId: widget.patientId ?? widget.patient.id,
            appointmentId: widget.appointmentId,
            hospitalId: widget.hospitalId,
            consentBloc: widget.consentBloc!,
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.hourglass_top_rounded, color: Colors.amberAccent, size: 13),
              SizedBox(width: 5),
              Text(
                "Access Request Pending (Tap to Change)",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        RequestAccessDurationModal.show(
          context: context,
          patient: widget.patient,
          patientId: widget.patientId ?? widget.patient.id,
          appointmentId: widget.appointmentId,
          hospitalId: widget.hospitalId,
          consentBloc: widget.consentBloc!,
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.vpn_key_rounded, color: primaryColor, size: 14),
            SizedBox(width: 6),
            Text(
              "Request Access to Patient Information",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}