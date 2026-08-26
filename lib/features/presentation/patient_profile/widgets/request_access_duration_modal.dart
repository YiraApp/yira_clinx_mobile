import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/features/domain/entities/patient_profile/patient_profile_entity.dart';
import 'package:yiraclinics/features/presentation/consent/bloc/patient_access_consent_bloc.dart';
import 'package:yiraclinics/features/presentation/consent/bloc/patient_access_consent_event.dart';

class DurationOption {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;

  const DurationOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class RequestAccessDurationModal extends StatefulWidget {
  final PatientProfileEntity patient;
  final String patientId;
  final String? appointmentId;
  final int? hospitalId;
  final PatientAccessConsentBloc consentBloc;

  const RequestAccessDurationModal({
    super.key,
    required this.patient,
    required this.patientId,
    this.appointmentId,
    this.hospitalId,
    required this.consentBloc,
  });

  static Future<void> show({
    required BuildContext context,
    required PatientProfileEntity patient,
    required String patientId,
    String? appointmentId,
    int? hospitalId,
    required PatientAccessConsentBloc consentBloc,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RequestAccessDurationModal(
        patient: patient,
        patientId: patientId,
        appointmentId: appointmentId,
        hospitalId: hospitalId,
        consentBloc: consentBloc,
      ),
    );
  }

  @override
  State<RequestAccessDurationModal> createState() => _RequestAccessDurationModalState();
}

class _RequestAccessDurationModalState extends State<RequestAccessDurationModal> {
  String _selectedDuration = "7_DAYS";
  final TextEditingController _notesController = TextEditingController();

  final List<DurationOption> _options = const [
    DurationOption(
      key: "1_HOUR",
      title: "1 Hour",
      subtitle: "Instant consultation & quick check",
      icon: Icons.timer_outlined,
    ),
    DurationOption(
      key: "5_HOURS",
      title: "5 Hours",
      subtitle: "Half-day clinical observation",
      icon: Icons.timelapse_rounded,
    ),
    DurationOption(
      key: "1_DAY",
      title: "1 Day",
      subtitle: "Full-day consultation & diagnosis",
      icon: Icons.today_rounded,
    ),
    DurationOption(
      key: "3_DAYS",
      title: "3 Days",
      subtitle: "Short-term treatment & follow-up",
      icon: Icons.date_range_rounded,
    ),
    DurationOption(
      key: "7_DAYS",
      title: "7 Days",
      subtitle: "Standard 1-week treatment course",
      icon: Icons.calendar_view_week_rounded,
    ),
    DurationOption(
      key: "1_MONTH",
      title: "1 Month",
      subtitle: "Long-term ongoing clinical management",
      icon: Icons.calendar_month_rounded,
    ),
    DurationOption(
      key: "NEVER",
      title: "Permanent",
      subtitle: "Active care until revoked by patient",
      icon: Icons.all_inclusive_rounded,
    ),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    final doctorId = GlobalSession.instance.userNotifier.value?.data?.id ?? '';
    final hospitalId = widget.hospitalId ??
        GlobalSession.instance.userNotifier.value?.data?.latestHospitalId;

    widget.consentBloc.add(RequestPatientAccessEvent(
      patientId: widget.patientId,
      doctorId: doctorId,
      hospitalId: hospitalId,
      duration: _selectedDuration,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    ));

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text("Access request sent to patient for approval!"),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2234) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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

          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: Color(0xFF0284C7),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Request Patient Access",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 19 : 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0A2540),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Select access duration for ${widget.patient.name.isNotEmpty ? widget.patient.name : 'this patient'}'s records.",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 12.5 : 11.5,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Duration options list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: _options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 7),
              itemBuilder: (context, index) {
                final opt = _options[index];
                final isSelected = _selectedDuration == opt.key;

                return InkWell(
                  onTap: () => setState(() => _selectedDuration = opt.key),
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: isDark ? 0.2 : 0.08)
                          : (isDark ? const Color(0xFF232B40) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : (isDark ? Colors.white12 : Colors.grey.shade200),
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor
                                : (isDark ? Colors.white10 : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            opt.icon,
                            size: 18,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt.title,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 14.5 : 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                opt.subtitle,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 12 : 11,
                                  color: isSelected
                                      ? primaryColor
                                      : (isDark ? Colors.white54 : Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark ? Colors.white30 : Colors.grey.shade400),
                              width: isSelected ? 5.5 : 1.5,
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
          const SizedBox(height: 14),

          // Clinical Purpose / Notes field (Optional)
          TextField(
            controller: _notesController,
            maxLines: 2,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: "Optional clinical purpose or note to patient...",
              hintStyle: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF232B40) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Submit Request Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 3,
                shadowColor: primaryColor.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "Submit Access Request",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
