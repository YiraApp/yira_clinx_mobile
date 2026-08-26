import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/features/domain/entities/patient_profile/patient_profile_entity.dart';
import 'package:yiraclinics/features/presentation/consent/bloc/patient_access_consent_bloc.dart';
import 'package:yiraclinics/features/presentation/consent/bloc/patient_access_consent_event.dart';
import 'package:yiraclinics/features/presentation/consent/bloc/patient_access_consent_state.dart';
import 'request_access_duration_modal.dart';

class PatientRecordAccessGate extends StatefulWidget {
  final PatientProfileEntity patient;
  final String patientId;
  final String? appointmentId;
  final int? hospitalId;
  final String? orgId;
  final PatientAccessConsentBloc consentBloc;
  final DoctorAccessStatusLoaded? accessStatus;
  final String recordType;

  const PatientRecordAccessGate({
    super.key,
    required this.patient,
    required this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
    required this.consentBloc,
    this.accessStatus,
    this.recordType = "records & documents",
  });

  @override
  State<PatientRecordAccessGate> createState() => _PatientRecordAccessGateState();
}

class _PatientRecordAccessGateState extends State<PatientRecordAccessGate> {
  bool _isRefreshing = false;

  void _refreshStatus() async {
    setState(() {
      _isRefreshing = true;
    });

    final currentDoctorId =
        GlobalSession.instance.userNotifier.value?.data?.id ?? '';
    widget.consentBloc.add(CheckAccessStatusEvent(
      patientId: widget.patientId,
      doctorId: currentDoctorId,
    ));

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("Access status updated"),
            ],
          ),
          backgroundColor: const Color(0xFF0284C7),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);

    final status = widget.accessStatus?.status.toUpperCase() ?? 'NO_REQUEST';
    final isPending = status == 'PENDING';
    final isRejected = status == 'REJECTED';
    final isExpired = status == 'EXPIRED';

    final Color statusColor = isPending
        ? Colors.amber.shade700
        : (isRejected
            ? Colors.redAccent
            : (isExpired ? Colors.grey.shade600 : const Color(0xFF0284C7)));

    final Color statusBg = isPending
        ? Colors.amber.withValues(alpha: 0.12)
        : (isRejected
            ? Colors.red.withValues(alpha: 0.12)
            : (isExpired
                ? Colors.grey.withValues(alpha: 0.12)
                : const Color(0xFF0284C7).withValues(alpha: 0.12)));

    final Color cardBg = isDark ? const Color(0xFF1E2638) : Colors.white;
    final Color borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isTab ? 48 : 24,
          vertical: 20,
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: EdgeInsets.symmetric(
            horizontal: isTab ? 32 : 24,
            vertical: isTab ? 32 : 26,
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lock Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusBg,
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    isPending
                        ? Icons.hourglass_top_rounded
                        : (isRejected
                            ? Icons.lock_person_outlined
                            : Icons.lock_outline_rounded),
                    size: 28,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                "Patient Consent Required",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 19 : 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),

              // Short Description
              Text(
                "Patient authorization is required to access medical records and documents.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 13 : 12,
                  height: 1.45,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),

              // Status Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPending) ...[
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Approval Pending",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ] else if (isRejected) ...[
                      Icon(Icons.cancel_outlined, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        "Request Declined",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ] else if (isExpired) ...[
                      Icon(Icons.history_toggle_off_rounded, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        "Access Expired",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ] else ...[
                      Icon(Icons.shield_outlined, size: 14, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        "Not Requested Yet",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Primary Action: Request Access Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    RequestAccessDurationModal.show(
                      context: context,
                      patient: widget.patient,
                      patientId: widget.patientId,
                      appointmentId: widget.appointmentId,
                      hospitalId: widget.hospitalId,
                      consentBloc: widget.consentBloc,
                    );
                  },
                  icon: const Icon(Icons.vpn_key_rounded, size: 16),
                  label: Text(
                    isPending ? "Update Access Duration" : "Request Access",
                    style: const TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                    shadowColor: primaryColor.withValues(alpha: 0.35),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Secondary Action: Refresh Status Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isRefreshing ? null : _refreshStatus,
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    _isRefreshing ? "Checking..." : "Check Status",
                    style: const TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
