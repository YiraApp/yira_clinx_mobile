import 'package:yiraclinics/core/widgets/ios_icons.dart';
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
              Icon(IosIcons.check_circle_outline, color: Colors.white, size: 18),
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

  void _openRequest({bool otpFirst = false}) {
    RequestAccessDurationModal.show(
      context: context,
      patient: widget.patient,
      patientId: widget.patientId,
      appointmentId: widget.appointmentId,
      hospitalId: widget.hospitalId,
      consentBloc: widget.consentBloc,
      otpFirst: otpFirst,
    );
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
    final name = widget.patient.name.trim().isNotEmpty ? widget.patient.name.trim() : 'The patient';

    final ink = isDark ? Colors.white : const Color(0xFF121212);
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);
    final cardBg = isDark ? const Color(0xFF232323) : Colors.white;
    final line = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    // What happened to the last request, if anything
    final (Color, IconData, String)? banner = isPending
        ? (const Color(0xFFD97706), IosIcons.hourglass_top_rounded, 'Request sent. Waiting for $name to approve it in the Yira app.')
        : isRejected
            ? (const Color(0xFFDC2626), IosIcons.cancel_outlined, '$name declined your last request.')
            : isExpired
                ? (const Color(0xFF64748B), IosIcons.history_toggle_off_rounded, 'Your access has ended. Ask again to see the full history.')
                : null;

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(isTab ? 48 : 16, 16, isTab ? 48 : 16, 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heading
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(IosIcons.lock_outline_rounded, size: 22, color: primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Full history is locked',
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: isTab ? 17 : 15.5, fontWeight: FontWeight.w700, color: ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "You see your own consultations. $name's visits with other doctors and hospitals, fitness and vitals open once they allow it.",
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, height: 1.45, color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Status of the last request
              if (banner != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  decoration: BoxDecoration(
                    color: banner.$1.withValues(alpha: isDark ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: banner.$1.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(banner.$2, size: 16, color: banner.$1),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          banner.$3,
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.35, color: banner.$1),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isRefreshing ? null : _refreshStatus,
                        style: TextButton.styleFrom(
                          foregroundColor: banner.$1,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                        ),
                        icon: _isRefreshing
                            ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: banner.$1))
                            : const Icon(IosIcons.refresh_rounded, size: 15),
                        label: const Text('Check', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Text(
                'GET ACCESS',
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: muted),
              ),
              const SizedBox(height: 8),
              _option(
                isDark: isDark,
                icon: IosIcons.phone_iphone_rounded,
                color: const Color(0xFF059669),
                title: 'Verify with OTP',
                subtitle: '$name is with you: they read out the code sent to their phone.',
                onTap: () => _openRequest(otpFirst: true),
              ),
              const SizedBox(height: 8),
              _option(
                isDark: isDark,
                icon: IosIcons.notifications_none_rounded,
                color: primaryColor,
                title: isPending ? 'Send the request again' : 'Ask in their app',
                subtitle: '$name gets a notification and approves it in Yira. You choose for how long.',
                onTap: () => _openRequest(),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(IosIcons.info_outline_rounded, size: 14, color: muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'They can also share with you from Share Profile in their app.',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, height: 1.4, color: muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: color.withValues(alpha: isDark ? 0.2 : 0.1), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF121212))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, height: 1.35, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(IosIcons.arrow_forward_ios_rounded, size: 13, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
