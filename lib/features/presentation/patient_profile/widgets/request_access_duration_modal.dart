import 'package:yiraclinics/core/widgets/ios_icons.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
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

  /// Open straight at the OTP step (the code is sent as the sheet opens), for "Verify with OTP".
  final bool otpFirst;

  const RequestAccessDurationModal({
    super.key,
    required this.patient,
    required this.patientId,
    this.appointmentId,
    this.hospitalId,
    required this.consentBloc,
    this.otpFirst = false,
  });

  static Future<void> show({
    required BuildContext context,
    required PatientProfileEntity patient,
    required String patientId,
    String? appointmentId,
    int? hospitalId,
    required PatientAccessConsentBloc consentBloc,
    bool otpFirst = false,
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
        otpFirst: otpFirst,
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
      icon: IosIcons.timer_outlined,
    ),
    DurationOption(
      key: "5_HOURS",
      title: "5 Hours",
      subtitle: "Half-day clinical observation",
      icon: IosIcons.timelapse_rounded,
    ),
    DurationOption(
      key: "1_DAY",
      title: "1 Day",
      subtitle: "Full-day consultation & diagnosis",
      icon: IosIcons.today_rounded,
    ),
    DurationOption(
      key: "3_DAYS",
      title: "3 Days",
      subtitle: "Short-term treatment & follow-up",
      icon: IosIcons.date_range_rounded,
    ),
    DurationOption(
      key: "7_DAYS",
      title: "7 Days",
      subtitle: "Standard 1-week treatment course",
      icon: IosIcons.calendar_view_week_rounded,
    ),
    DurationOption(
      key: "1_MONTH",
      title: "1 Month",
      subtitle: "Long-term ongoing clinical management",
      icon: IosIcons.calendar_month_rounded,
    ),
    DurationOption(
      key: "NEVER",
      title: "Permanent",
      subtitle: "Active care until revoked by patient",
      icon: IosIcons.all_inclusive_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.otpFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sendOtp();
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;

  // ── Access by OTP: the patient is with the doctor and reads out the code sent to their phone ──
  String? _otpSessionId;
  String? _otpSentTo;
  String? _otpError;
  bool _otpBusy = false;
  final TextEditingController _otpController = TextEditingController();

  int? get _hospitalId => widget.hospitalId ?? GlobalSession.instance.userNotifier.value?.data?.latestHospitalId;

  static String _messageOf(Object e, String fallback) {
    if (e is DioException && e.response?.data is Map) {
      final m = ((e.response!.data as Map)['message'] ?? '').toString().trim();
      if (m.isNotEmpty) return m;
    }
    return fallback;
  }

  Future<void> _sendOtp() async {
    if (_otpBusy) return;
    setState(() {
      _otpBusy = true;
      _otpError = null;
    });
    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).post(
            URLs.patientAccessOtpSendUrl,
            data: {'patientId': widget.patientId, if (_hospitalId != null) 'hospitalId': _hospitalId},
            options: Options(extra: const {'showSuccessSnack': false, 'suppressErrorSnack': true}),
          );
      final data = (res.data is Map) ? (res.data as Map)['data'] : null;
      if (!mounted) return;
      setState(() {
        _otpSessionId = (data is Map ? data['sessionId'] : null)?.toString();
        _otpSentTo = (data is Map ? data['sentTo'] : null)?.toString();
        _otpController.clear();
        if ((_otpSessionId ?? '').isEmpty) _otpError = "Couldn't send the OTP. Please try again.";
      });
    } catch (e) {
      if (mounted) setState(() => _otpError = _messageOf(e, "Couldn't send the OTP. Please try again."));
    } finally {
      if (mounted) setState(() => _otpBusy = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (_otpBusy || (_otpSessionId ?? '').isEmpty) return;
    if (otp.length < 4) {
      setState(() => _otpError = 'Enter the OTP the patient received.');
      return;
    }
    setState(() {
      _otpBusy = true;
      _otpError = null;
    });
    try {
      await sl<ApiClient>().account(showSuccessSnack: false).post(
            URLs.patientAccessOtpVerifyUrl,
            data: {
              'patientId': widget.patientId,
              'sessionId': _otpSessionId,
              'otp': otp,
              'duration': _selectedDuration,
              if (_hospitalId != null) 'hospitalId': _hospitalId,
            },
            options: Options(extra: const {'showSuccessSnack': false, 'suppressErrorSnack': true}),
          );
      if (!mounted) return;
      final doctorId = GlobalSession.instance.userNotifier.value?.data?.id ?? '';
      widget.consentBloc.add(CheckAccessStatusEvent(patientId: widget.patientId, doctorId: doctorId));
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Access granted. You can now see all of this patient\'s records, fitness and vitals.'),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _otpError = _messageOf(e, "That OTP is not right. Please check and try again."));
    } finally {
      if (mounted) setState(() => _otpBusy = false);
    }
  }

  /// Set when the doctor taps Back on the OTP step, so an OTP-first sheet can show the options.
  bool _leftOtpStep = false;

  /// The code step: once a code is sent, or straight away for "Verify with OTP" while it is sending.
  bool get _inOtpStep =>
      (_otpSessionId ?? '').isNotEmpty || (widget.otpFirst && !_leftOtpStep && _otpError == null);

  String get _selectedDurationLabel =>
      _options.firstWhere((o) => o.key == _selectedDuration, orElse: () => _options.first).title;

  /// Below the request button: start the OTP step (sends the code to the patient's phone).
  Widget _buildOtpSection(bool isDark, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _otpBusy ? null : _sendOtp,
          icon: _otpBusy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(IosIcons.phone_iphone_rounded, size: 18),
          label: const Text(
            'Patient is with me: verify by OTP',
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (_otpError != null) ...[
          const SizedBox(height: 6),
          Text(_otpError!, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: Color(0xFFDC2626))),
        ],
      ],
    );
  }

  /// The OTP step: the code box first, so it is never hidden below the options or the keyboard.
  List<Widget> _buildOtpStep(bool isDark, Color primaryColor) {
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);
    return [
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(IosIcons.timer_outlined, size: 16, color: primaryColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Access for $_selectedDurationLabel once verified',
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        autofocus: true,
        textAlign: TextAlign.center,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 10,
          color: isDark ? Colors.white : const Color(0xFF151515),
        ),
        decoration: InputDecoration(
          hintText: 'Enter OTP',
          hintStyle: TextStyle(fontFamily: appPoppinFont, fontSize: 16, letterSpacing: 1, color: muted),
          errorText: _otpError,
          errorMaxLines: 3,
          filled: true,
          fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primaryColor, width: 1.6),
          ),
        ),
        onSubmitted: (_) => _verifyOtp(),
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _otpBusy ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _otpBusy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Verify and get access', style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          TextButton(
            onPressed: _otpBusy
                ? null
                : () => setState(() {
                      _otpSessionId = null;
                      _otpError = null;
                      _leftOtpStep = true;
                      _otpController.clear();
                    }),
            child: const Text('Back', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13)),
          ),
          const Spacer(),
          TextButton(
            onPressed: _otpBusy ? null : _sendOtp,
            child: const Text('Send the OTP again', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13)),
          ),
        ],
      ),
    ];
  }

  void _submitRequest() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

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

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(IosIcons.hourglass_top_rounded, color: Colors.white, size: 20),
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
        color: isDark ? const Color(0xFF222222) : Colors.white,
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
                  IosIcons.vpn_key_rounded,
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
                      _inOtpStep ? "Enter the patient's OTP" : "Request Patient Access",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 19 : 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF151515),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _inOtpStep
                          ? ((_otpSessionId ?? '').isEmpty
                              ? "Sending a code to ${widget.patient.name.isNotEmpty ? widget.patient.name : 'the patient'}'s phone"
                              : "Sent to ${_otpSentTo ?? "the patient's phone"}. Ask ${widget.patient.name.isNotEmpty ? widget.patient.name : 'the patient'} for the code.")
                          : "Select access duration for ${widget.patient.name.isNotEmpty ? widget.patient.name : 'this patient'}'s records.",
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
                icon: const Icon(IosIcons.close_rounded),
                onPressed: () => Navigator.pop(context),
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_inOtpStep)
            ..._buildOtpStep(isDark, primaryColor)
          else ...[
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
                          : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC)),
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
                                : (isDark ? Colors.white70 : const Color(0xFF4A4A4A)),
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
                                  color: isDark ? Colors.white : const Color(0xFF121212),
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
              hintText: "Optional note to the patient",
              hintStyle: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF8FAFC),
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
              onPressed: _isSubmitting ? null : _submitRequest,
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
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(IosIcons.send_rounded, size: 18),
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
          const SizedBox(height: 10),
          // Or the patient approves the request in their app (they get a notification)
          _buildOtpSection(isDark, primaryColor),
          ],
        ],
      ),
    );
  }
}
