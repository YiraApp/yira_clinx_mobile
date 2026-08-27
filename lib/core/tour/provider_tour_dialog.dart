import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/shared_preferences.dart';
import 'package:yiraclinics/di/dependency_injection.dart';

class ProviderTourDialog extends StatefulWidget {
  final VoidCallback? onComplete;

  const ProviderTourDialog({super.key, this.onComplete});

  static Future<void> show(BuildContext context, {bool force = false}) async {
    final prefs = sl<SharedPrefsService>();
    final isCompleted = prefs.getValue<bool>('doctor_tour_completed_v1') ?? false;
    final dontShowAgain = prefs.getValue<bool>('doctor_tour_dont_show_again') ?? false;

    if (!force && (isCompleted || dontShowAgain)) {
      return;
    }

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (ctx) => const ProviderTourDialog(),
    );
  }

  @override
  State<ProviderTourDialog> createState() => _ProviderTourDialogState();
}

class _ProviderTourDialogState extends State<ProviderTourDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;
  bool _isDemoFavStarred = true;

  final int _totalChapters = 7;

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

  void _finishTour() {
    final prefs = sl<SharedPrefsService>();
    prefs.setValue('doctor_tour_completed_v1', true);
    if (_dontShowAgain) {
      prefs.setValue('doctor_tour_dont_show_again', true);
    }
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    widget.onComplete?.call();
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
                  // 1. Top Header Bar with Step Badge & Skip Button
                  _buildTopBar(isDark, isTab),

                  // 2. Progress Indicator Strip
                  _buildProgressStrip(isDark),

                  // 3. Carousel PageView with Demo Content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (idx) {
                        setState(() => _currentPage = idx);
                      },
                      children: [
                        _buildChapter1Dashboard(isDark, isTab),
                        _buildChapter2Teleconsult(isDark, isTab),
                        _buildChapter3Patients(isDark, isTab),
                        _buildChapter4Slots(isDark, isTab),
                        _buildChapter5Scheduler(isDark, isTab),
                        _buildChapter6Clinical(isDark, isTab),
                        _buildChapter7Settings(isDark, isTab),
                      ],
                    ),
                  ),

                  // 4. Bottom Action Footer
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
                      "PROVIDER TOUR",
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
          // Don't Show Again Checkbox
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

          // Back Button (Custom Container Button - No Theme Constraint Conflicts)
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

          // Next / Finish Button (Custom Container Button)
          InkWell(
            onTap: _onNext,
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
                    isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isLast ? "Get Started" : "Next Feature",
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

  // -------------------------------------------------------------
  // CHAPTER 1: Provider Dashboard & Practice KPIs
  // -------------------------------------------------------------
  Widget _buildChapter1Dashboard(bool isDark, bool isTab) {
    return _buildChapterScaffold(
      icon: Icons.dashboard_customize_rounded,
      iconColor: const Color(0xFF3B82F6),
      title: "Provider Command Center",
      subtitle: "Your real-time practice dashboard with live operational metrics & patient inflow tracking.",
      isDark: isDark,
      isTab: isTab,
      demoWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Demo Hospital Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Yira Hospital • Branch 01",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 13 : 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "Dr. Rajesh Sharma • Cardiology • Active Duty",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 11.5 : 10.5,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "OPEN",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Demo KPI Grid
          Row(
            children: [
              _buildDemoKpiTile("Today's Visits", "18", "4 Teleconsult", const Color(0xFF3B82F6), isDark, isTab),
              const SizedBox(width: 8),
              _buildDemoKpiTile("Total Consulted", "42", "Past 7 Days", const Color(0xFF10B981), isDark, isTab),
              const SizedBox(width: 8),
              _buildDemoKpiTile("Completed", "12", "6 Pending", const Color(0xFF8B5CF6), isDark, isTab),
            ],
          ),
        ],
      ),
      bulletPoints: [
        "Live summary of today's scheduled consultations & walk-in arrivals.",
        "Quick switcher for multi-facility and cross-branch doctor postings.",
        "Weekly and monthly growth analytics charts at the bottom.",
      ],
    );
  }

  // -------------------------------------------------------------
  // CHAPTER 2: Teleconsultation & Live Video Calling
  // -------------------------------------------------------------
  Widget _buildChapter2Teleconsult(bool isDark, bool isTab) {
    return _buildChapterScaffold(
      icon: Icons.video_camera_front_rounded,
      iconColor: const Color(0xFFF59E0B),
      title: "Teleconsultation & Video Calling",
      subtitle: "Connect with remote patients securely via integrated 1-tap live HD video calls.",
      isDark: isDark,
      isTab: isTab,
      demoWidget: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  child: const Text("RK", style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Robert King (42 M)",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w700,
                          fontSize: isTab ? 13 : 12,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "10:30 AM • Follow-up Consultation",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 11 : 10,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "LIVE VIDEO",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Chief Complaint: Chest Tightness",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 11.5 : 10.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        "Join Call",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bulletPoints: [
        "Appointments marked 'LIVE VIDEO' feature an instant Zoom/WebRTC video link.",
        "In-clinic appointments are clearly tagged 'IN-CLINIC' with walk-in token status.",
        "Access clinical notes directly during the call without switching tabs.",
      ],
    );
  }

  // -------------------------------------------------------------
  // CHAPTER 3: Smart Patient Directory & Favorites
  // -------------------------------------------------------------
  Widget _buildChapter3Patients(bool isDark, bool isTab) {
    return _buildChapterScaffold(
      icon: Icons.people_alt_rounded,
      iconColor: const Color(0xFF10B981),
      title: "Smart Patient Directory & Favorites",
      subtitle: "Find patients by name, phone, or MRN with smooth continuous scrolling and 1-tap bookmarks.",
      isDark: isDark,
      isTab: isTab,
      demoWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips Demo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDemoFilterChip("All (48)", true, primaryColor, isDark),
                const SizedBox(width: 6),
                _buildDemoFilterChip("★ Favorites (12)", false, const Color(0xFFD97706), isDark),
                const SizedBox(width: 6),
                _buildDemoFilterChip("Recent (8)", false, primaryColor, isDark),
                const SizedBox(width: 6),
                _buildDemoFilterChip("Male (26)", false, primaryColor, isDark),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Interactive Demo Patient Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Text("EL", style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Emily Lawson (34 F)",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w700,
                          fontSize: isTab ? 13 : 12,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "MRN: YRA0042 • Last Visit: 2 Days Ago",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 11 : 10,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Interactive Star Button
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isDemoFavStarred = !_isDemoFavStarred);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      _isDemoFavStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: _isDemoFavStarred ? const Color(0xFFF59E0B) : Colors.grey,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bulletPoints: [
        "Tap the star (★) on any patient to bookmark them for fast access in your 'Favorites' tab.",
        "Smooth continuous scrolling lets you browse hundreds of patient files effortlessly.",
        "Displays uploaded profile photos automatically, with initials fallback.",
      ],
    );
  }

  // -------------------------------------------------------------
  // CHAPTER 4: Real-Time Slots & Protected Break Times
  // -------------------------------------------------------------
  Widget _buildChapter4Slots(bool isDark, bool isTab) {
    return _buildChapterScaffold(
      icon: Icons.calendar_month_rounded,
      iconColor: const Color(0xFF8B5CF6),
      title: "Real-Time Slots & Protected Breaks",
      subtitle: "Inspect daily capacity, available openings, booked visits, and protected break intervals.",
      isDark: isDark,
      isTab: isTab,
      demoWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Tabs Demo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDemoSlotTab("All (16)", true, primaryColor, isDark),
                const SizedBox(width: 6),
                _buildDemoSlotTab("Available (10)", false, Colors.green, isDark),
                const SizedBox(width: 6),
                _buildDemoSlotTab("Booked (4)", false, Colors.blue, isDark),
                const SizedBox(width: 6),
                _buildDemoSlotTab("Breaks (2)", false, Colors.orange, isDark),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Open Slot Card Demo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  "09:30 AM - 09:45 AM",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w700,
                    fontSize: isTab ? 12 : 11,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text("AVAILABLE", style: TextStyle(fontFamily: appPoppinFont, fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.green)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text("+ Book", style: TextStyle(fontFamily: appPoppinFont, fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Protected Break Card Demo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF292524) : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.coffee_rounded, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Text(
                  "01:00 PM - 02:00 PM • Lunch Break",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w700,
                    fontSize: isTab ? 12 : 11,
                    color: const Color(0xFFD97706),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text("PROTECTED", style: TextStyle(fontFamily: appPoppinFont, fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFD97706))),
                ),
              ],
            ),
          ),
        ],
      ),
      bulletPoints: [
        "Tap '+ Book' on any available slot to prefill timing and create walk-in appointments instantly.",
        "Protected breaks automatically prevent slot overlapping during lunch and tea hours.",
        "Past time slots for the current date are safely locked against accidental booking.",
      ],
    );
  }

  // -------------------------------------------------------------
  // CHAPTER 5: Smart Shift Scheduler (FAB '+')
  // -------------------------------------------------------------
  Widget _buildChapter5Scheduler(bool isDark, bool isTab) {
    return _buildChapterScaffold(
      icon: Icons.auto_awesome_rounded,
      iconColor: const Color(0xFFEC4899),
      title: "Smart Shift Scheduler (FAB '+')",
      subtitle: "Automate weeks of consultation schedules with customizable durations, buffers & shifts.",
      isDark: isDark,
      isTab: isTab,
      demoWidget: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: primaryColor),
                const SizedBox(width: 6),
                Text(
                  "Shift Hours: 09:00 AM - 05:00 PM",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w700,
                    fontSize: isTab ? 12 : 11,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDemoDurationChip("10m", false, isDark),
                const SizedBox(width: 6),
                _buildDemoDurationChip("15m", true, isDark),
                const SizedBox(width: 6),
                _buildDemoDurationChip("20m", false, isDark),
                const SizedBox(width: 6),
                _buildDemoDurationChip("30m", false, isDark),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Buffer Time: 5 Mins • 24 Slots Generated",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 11 : 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text("Deploy", style: TextStyle(fontFamily: appPoppinFont, fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bulletPoints: [
        "Tap the floating '+' button on the Slots tab to generate recurring multi-day clinic schedules.",
        "Configure consultation minutes (10, 15, 20, 30m) and optional buffer intervals.",
        "Review generated timeline previews before deploying to your live patient booking portal.",
      ],
    );
  }

  // -------------------------------------------------------------
  // CHAPTER 6: Clinical Notes, Medical Records & Vitals
  // -------------------------------------------------------------
  Widget _buildChapter6Clinical(bool isDark, bool isTab) {
    return _buildChapterScaffold(
      icon: Icons.assignment_rounded,
      iconColor: const Color(0xFF06B6D4),
      title: "Clinical Records & Patient Vitals",
      subtitle: "Access complete longitudinal patient health histories, vitals trends, and diagnoses.",
      isDark: isDark,
      isTab: isTab,
      demoWidget: Column(
        children: [
          Row(
            children: [
              _buildDemoVitalTile("BP", "120/80", "mmHg", Colors.red, isDark, isTab),
              const SizedBox(width: 6),
              _buildDemoVitalTile("Pulse", "72", "bpm", Colors.pink, isDark, isTab),
              const SizedBox(width: 6),
              _buildDemoVitalTile("SpO2", "98%", "Normal", Colors.blue, isDark, isTab),
              const SizedBox(width: 6),
              _buildDemoVitalTile("Temp", "98.6", "°F", Colors.amber, isDark, isTab),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.notes_rounded, size: 16, color: Color(0xFF06B6D4)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Latest Dx: Essential Hypertension • Prescribed Amlodipine 5mg",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 11.5 : 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bulletPoints: [
        "Inspect allergies, blood groups, and chronic conditions before writing prescriptions.",
        "Track vital sign progressions across consecutive clinic encounters.",
        "Issue digitally signed prescriptions and laboratory investigation requests.",
      ],
    );
  }

  // -------------------------------------------------------------
  // CHAPTER 7: Facility Switcher & Tour Restart
  // -------------------------------------------------------------
  Widget _buildChapter7Settings(bool isDark, bool isTab) {
    return _buildChapterScaffold(
      icon: Icons.check_circle_outline_rounded,
      iconColor: const Color(0xFF10B981),
      title: "You Are Ready to Practice!",
      subtitle: "You have completed the walkthrough. You can restart this tour anytime from Settings or Profile.",
      isDark: isDark,
      isTab: isTab,
      demoWidget: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withValues(alpha: 0.15),
              const Color(0xFF10B981).withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Onboarding Verified",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.w700,
                      fontSize: isTab ? 13.5 : 12.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    "Restart anytime from: Profile -> Interactive Product Tour",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 11 : 10,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bulletPoints: [
        "Switch clinical workspaces anytime from the top hospital dropdown.",
        "Manage push notifications, themes, and language in Settings.",
        "Tap 'Get Started' below to enter your live clinical workspace.",
      ],
    );
  }

  // -------------------------------------------------------------
  // REUSABLE CHAPTER LAYOUT
  // -------------------------------------------------------------
  Widget _buildChapterScaffold({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required bool isTab,
    required Widget demoWidget,
    required List<String> bulletPoints,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isTab ? 28 : 18,
        vertical: isTab ? 20 : 14,
      ),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title
          Row(
            children: [
              Container(
                width: isTab ? 44 : 38,
                height: isTab ? 44 : 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: isTab ? 24 : 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 18 : 15.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 12.5 : 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Live Interactive Demo Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "LIVE DEMO PREVIEW",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                demoWidget,
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Explanation / Bullet Points
          Column(
            children: bulletPoints.map((text) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 12.5 : 11.5,
                          height: 1.35,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // HELPER WIDGETS FOR DEMO PREVIEWS
  // -------------------------------------------------------------
  Widget _buildDemoKpiTile(String title, String value, String sub, Color color, bool isDark, bool isTab) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 16 : 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 10.5 : 9.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 9.5 : 8.5,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoFilterChip(String label, bool isSelected, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? color : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? color : (isDark ? Colors.white10 : const Color(0xFFCBD5E1))),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
        ),
      ),
    );
  }

  Widget _buildDemoSlotTab(String label, bool isSelected, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.15) : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSelected ? color : (isDark ? Colors.white10 : const Color(0xFFCBD5E1))),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: isSelected ? color : (isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
      ),
    );
  }

  Widget _buildDemoDurationChip(String label, bool isSelected, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor : (isDark ? const Color(0xFF334155) : Colors.white),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isSelected ? primaryColor : (isDark ? Colors.white10 : const Color(0xFFCBD5E1))),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
        ),
      ),
    );
  }

  Widget _buildDemoVitalTile(String title, String value, String unit, Color color, bool isDark, bool isTab) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontFamily: appPoppinFont, fontSize: 9.5, fontWeight: FontWeight.w700, color: color)),
            Text(value, style: TextStyle(fontFamily: appPoppinFont, fontSize: isTab ? 13 : 11.5, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
            Text(unit, style: TextStyle(fontFamily: appPoppinFont, fontSize: 8, color: isDark ? Colors.white54 : Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
