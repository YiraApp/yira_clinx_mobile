import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/domain/entities/patient_profile/patient_profile_entity.dart';
import 'package:yiraclinics/features/presentation/consent/bloc/patient_access_consent_bloc.dart';
import 'package:yiraclinics/features/presentation/consent/bloc/patient_access_consent_state.dart';
import 'request_access_duration_modal.dart';

class PatientRecordAccessGate extends StatelessWidget {
  final PatientProfileEntity patient;
  final String patientId;
  final String? appointmentId;
  final int? hospitalId;
  final PatientAccessConsentBloc consentBloc;
  final DoctorAccessStatusLoaded? accessStatus;
  final String recordType; // e.g. "Medical Records", "Clinical Notes", "Prescriptions", "Documents"

  const PatientRecordAccessGate({
    super.key,
    required this.patient,
    required this.patientId,
    this.appointmentId,
    this.hospitalId,
    required this.consentBloc,
    this.accessStatus,
    this.recordType = "Complete Medical Records",
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    final status = accessStatus?.status.toUpperCase() ?? 'NO_REQUEST';
    final isPending = status == 'PENDING';
    final isRejected = status == 'REJECTED';
    final isExpired = status == 'EXPIRED';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2234) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Security Shield Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isPending
                        ? [Colors.orange.shade400, Colors.amber.shade600]
                        : [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isPending ? Colors.orange : const Color(0xFF0284C7)).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isPending ? Icons.hourglass_top_rounded : Icons.lock_outline_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                "Patient Consent Required",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 20 : 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0A2540),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                "To protect patient confidentiality and comply with healthcare data privacy rules, doctors must obtain patient consent before accessing ${patient.name}'s $recordType.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 13.5 : 12.5,
                  height: 1.5,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 20),

              // Status Badge
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Access Request Pending Patient Approval",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isRejected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Text(
                    "Previous Request Declined by Patient",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                )
              else if (isExpired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: const Text(
                    "Previous Access Permission Expired",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Request Button
              ElevatedButton.icon(
                onPressed: () {
                  RequestAccessDurationModal.show(
                    context: context,
                    patient: patient,
                    patientId: patientId,
                    appointmentId: appointmentId,
                    hospitalId: hospitalId,
                    consentBloc: consentBloc,
                  );
                },
                icon: const Icon(Icons.vpn_key_rounded, size: 18),
                label: Text(
                  isPending ? "Update Access Duration" : "Request Access to Patient Information",
                  style: const TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                  shadowColor: primaryColor.withOpacity(0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
