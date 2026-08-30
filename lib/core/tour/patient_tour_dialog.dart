import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'patient_tour_controller.dart';

class PatientTourDialog extends StatefulWidget {
  final VoidCallback? onComplete;

  const PatientTourDialog({super.key, this.onComplete});

  static Future<void> show(BuildContext context, {bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final isCompleted = prefs.getBool('patient_tour_has_completed_v1') ?? false;

    if (!force && isCompleted) {
      return;
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (ctx) => const PatientTourDialog(),
    );
  }

  @override
  State<PatientTourDialog> createState() => _PatientTourDialogState();
}

class _PatientTourDialogState extends State<PatientTourDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  final int _totalChapters = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    HapticFeedback.lightImpact();
    if (_currentPage < _totalChapters - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishTour();
    }
  }

  void _onBack() {
    HapticFeedback.selectionClick();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _onSkip() {
    HapticFeedback.lightImpact();
    _finishTour();
  }

  Future<void> _finishTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('patient_tour_has_completed_v1', true);
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    widget.onComplete?.call();
  }

  void _launchLiveSpotlight() {
    Navigator.of(context, rootNavigator: true).pop();
    PatientTourController().restartTour(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);
    final size = MediaQuery.of(context).size;

    final dialogWidth = isTab ? size.width * 0.72 : size.width * 0.92;
    final dialogHeight = isTab ? size.height * 0.82 : size.height * 0.84;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTab ? 40 : 16,
        vertical: isTab ? 40 : 20,
      ),
      child: Center(
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  // 1. Top Header Bar
                  _buildTopBar(isDark, isTab),

                  // 2. Progress Strip
                  _buildProgressStrip(isDark),

                  // 3. Carousel PageView
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (idx) {
                        setState(() => _currentPage = idx);
                      },
                      children: [
                        _buildChapter1Dashboard(isDark, isTab),
                        _buildChapter2Appointments(isDark, isTab),
                        _buildChapter3Consents(isDark, isTab),
                        _buildChapter4Passport(isDark, isTab),
                      ],
                    ),
                  ),

                  // 4. Bottom Footer
                  _buildBottomFooter(isDark, isTab),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark, bool isTab) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tour_rounded, size: 14, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      "PATIENT GUIDE",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 12 : 11,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${_currentPage + 1} of $_totalChapters",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 12 : 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          InkWell(
            onTap: _onSkip,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStrip(bool isDark) {
    final progress = (_currentPage + 1) / _totalChapters;
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
      valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
      minHeight: 3.5,
    );
  }

  Widget _buildBottomFooter(bool isDark, bool isTab) {
    final isLast = _currentPage == _totalChapters - 1;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTab ? 24 : 16,
        vertical: isTab ? 16 : 14,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          // Don't show again checkbox
          InkWell(
            onTap: () {
              setState(() => _dontShowAgain = !_dontShowAgain);
            },
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: Checkbox(
                    value: _dontShowAgain,
                    onChanged: (val) {
                      setState(() => _dontShowAgain = val ?? false);
                    },
                    activeColor: primaryColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Don't show again",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 12 : 11,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          if (_currentPage > 0) ...[
            InkWell(
              onTap: _onBack,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTab ? 18 : 14,
                  vertical: isTab ? 10 : 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  "Back",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 13 : 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          InkWell(
            onTap: isLast ? _launchLiveSpotlight : _onNext,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTab ? 20 : 16,
                vertical: isTab ? 11 : 9,
              ),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLast ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isLast ? "Start Spotlight Tour" : "Next",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 13 : 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

  Widget _buildChapterScaffold({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget demoWidget,
    required List<String> bulletPoints,
    required bool isDark,
    required bool isTab,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTab ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: isTab ? 28 : 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 18 : 15.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 12.5 : 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          demoWidget,

          const SizedBox(height: 16),

          ...bulletPoints.map((bp) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5.0, right: 8.0),
                      child: Icon(Icons.check_circle_rounded, color: primaryColor, size: 14),
                    ),
                    Expanded(
                      child: Text(
                        bp,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 13 : 12,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildChapter1Dashboard(bool isDark, bool isTab) {
    return _buildChapterScaffold(
      icon: Icons.monitor_heart_rounded,
      iconColor: const Color(0xFF3B82F6),
      title: "Health Vitals & Daily Check",
      subtitle: "Track blood pressure, heart rate, SpO2, and weight continuously.",
      isDark: isDark,
      isTab: isTab,
      demoWidget: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildVitalsItem("Blood Pressure", "120/80", "mmHg", Colors.red, isDark),
            _buildVitalsItem("Pulse Rate", "72", "bpm", Colors.pink, isDark),
            _buildVitalsItem("Blood Oxygen", "98%", "SpO2", Colors.blue, isDark),
          ],
        ),
      ),
      bulletPoints: [
        "Log and monitor your daily vital metrics with instant feedback.",
        "Quick switcher lets you switch between family member health profiles.",
        "Direct access to active prescriptions and digital medical reports.",
      ],
    );
  }

  Widget _buildChapter2Appointments(bool isDark, bool isTab) {
    return _buildChapterScaffold(
      icon: Icons.video_camera_front_rounded,
      iconColor: const Color(0xFF10B981),
      title: "Doctor Consultations & Video Visits",
      subtitle: "Book verified doctor visits and join HD live video calls with 1 tap.",
      isDark: isDark,
      isTab: isTab,
      demoWidget: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.videocam_rounded, color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Dr. Rajesh Sharma • Cardiology",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.bold,
                      fontSize: isTab ? 13 : 12,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    "Today at 04:30 PM • Apollo Hospital",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 11.5 : 10.5,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bulletPoints: [
        "Instant Zoom/WebRTC video connection for online consultations.",
        "Tokens and real-time clinic arrival status for in-person visits.",
        "Filter and download past appointment summaries anytime.",
      ],
    );
  }

  Widget _buildChapter3Consents(bool isDark, bool isTab) {
    return _buildChapterScaffold(
      icon: Icons.security_rounded,
      iconColor: const Color(0xFF8B5CF6),
      title: "Consents & Medical Privacy",
      subtitle: "Control exactly which doctors and hospitals can view your records.",
      isDark: isDark,
      isTab: isTab,
      demoWidget: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Color(0xFF8B5CF6), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Apollo Hospital requested access to Lab Records",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w600,
                  fontSize: isTab ? 12.5 : 11.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
      bulletPoints: [
        "Approve or revoke medical record access with a single tap.",
        "Granular consent permissions for specific consultations or clinics.",
        "Complete audit trail of who viewed your medical documents.",
      ],
    );
  }

  Widget _buildChapter4Passport(bool isDark, bool isTab) {
    return _buildChapterScaffold(
      icon: Icons.badge_rounded,
      iconColor: const Color(0xFFF59E0B),
      title: "Digital Health Passport & ABHA",
      subtitle: "Your universal digital health passport with emergency QR scan.",
      isDark: isDark,
      isTab: isTab,
      demoWidget: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.qr_code_rounded, color: Color(0xFFF59E0B), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Digital Health Passport • Rahul Verma",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.bold,
                      fontSize: isTab ? 13 : 12,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    "ABHA Linked • Blood Group: O+ • Emergency Ready",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 11.5 : 10.5,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bulletPoints: [
        "Show your QR code for 1-second check-in at partner hospitals.",
        "Store verified emergency contact details and blood group.",
        "Restart this interactive tour anytime from your Profile settings.",
      ],
    );
  }

  Widget _buildVitalsItem(String label, String value, String unit, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
