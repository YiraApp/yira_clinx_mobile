import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../config/app_route/app_routes.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/services/fitness/fitness_service.dart';
import '../../../../core/services/fitness/fitness_sync_service.dart';

class PatientConnectFitnessScreen extends StatefulWidget {
  const PatientConnectFitnessScreen({super.key});

  @override
  State<PatientConnectFitnessScreen> createState() => _PatientConnectFitnessScreenState();
}

class _PatientConnectFitnessScreenState extends State<PatientConnectFitnessScreen> {
  bool _isConnecting = false;

  Future<void> _handleConnect() async {
    setState(() => _isConnecting = true);
    final result = await FitnessSyncService.instance.connectFitness();
    if (!mounted) return;

    setState(() => _isConnecting = false);
    if (result.isSuccess) {
      // Automatically navigate to the full fitness data screen
      Navigator.pushReplacementNamed(context, AppRoutes.patientFitnessTracking);
    } else {
      _showConnectErrorDialog(result);
    }
  }

  /// Modern popup modal displaying connection errors, missing plugin guidance, or permission prompts
  void _showConnectErrorDialog(FitnessConnectResult result) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    final isMissingPlugin = result.status == FitnessConnectStatus.missingPlugin;
    final isPermissionDenied = result.status == FitnessConnectStatus.permissionDenied;
    final isHealthConnectRequired = result.status == FitnessConnectStatus.healthConnectRequired;

    final Color accentColor = isMissingPlugin
        ? const Color(0xFFF59E0B) // Amber
        : isPermissionDenied
            ? const Color(0xFFEF4444) // Red
            : const Color(0xFF3B82F6); // Blue

    final IconData icon = isMissingPlugin
        ? Icons.restart_alt_rounded
        : isPermissionDenied
            ? Icons.security_rounded
            : Icons.download_rounded;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Badge
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 30),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              result.title,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message Body
            Text(
              result.message,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),

            if (isMissingPlugin) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.terminal_rounded, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Text(
                      'flutter run',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              if (isPermissionDenied) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 13,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      openAppSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Settings',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ] else if (isHealthConnectRequired) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      FitnessService.instance.promptInstallHealthConnect();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Install',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Understood',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    final isIos = Platform.isIOS;
    final platformName = isIos ? 'Apple Health' : 'Google Health Connect';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Connect Fitness',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, size: 14, color: primaryColor),
                const SizedBox(width: 4),
                Text(
                  '30 Days Sync',
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
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Hero Ecosystem Bridge Card
                    _buildHeroBridgeCard(
                      isIos: isIos,
                      platformName: platformName,
                      primaryColor: primaryColor,
                      isDark: isDark,
                      isTab: isTab,
                    ),
                    const SizedBox(height: 16),

                    // 2. 3 Key Sync Specs Badges
                    _buildSpecsRow(isDark: isDark, primaryColor: primaryColor),
                    const SizedBox(height: 20),

                    // 3. Section Title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'What Will Be Synchronized',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4. 4 Rich Health Pillars
                    _buildFeatureCard(
                      icon: Icons.directions_run_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Steps & Daily Distance',
                      subtitle: 'Pedometer tracking, walking/running mileage, and active movement towards your targets.',
                      tag: 'Past 30 Days',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureCard(
                      icon: Icons.favorite_rounded,
                      iconColor: const Color(0xFFEF4444),
                      title: 'Heart Rate & Blood Oxygen',
                      subtitle: 'Continuous pulse monitoring, resting heart rate averages, and SpO2 oxygen saturation.',
                      tag: 'Live Sensors',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureCard(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFF97316),
                      title: 'Active Caloric Burn',
                      subtitle: 'Energy burned throughout the day, workouts, and active metabolic energy expenditure.',
                      tag: 'Daily Kcal',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureCard(
                      icon: Icons.bedtime_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'Sleep Duration & Cycles',
                      subtitle: 'Nightly sleep duration, deep/REM restorative recovery cycles, and sleep trends.',
                      tag: 'Rest Analysis',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 18),

                    // 5. Privacy & Security Trust Banner
                    _buildPrivacyBanner(isDark: isDark),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 6. Bottom Sticky Connect Button Container
            _buildBottomConnectBar(
              isIos: isIos,
              platformName: platformName,
              primaryColor: primaryColor,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBridgeCard({
    required bool isIos,
    required String platformName,
    required Color primaryColor,
    required bool isDark,
    required bool isTab,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Visual Bridge: Health App <---> Yira Clinics
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left: Platform Health Logo Box
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isIos
                        ? const [Color(0xFFFF2D55), Color(0xFFFF5E3A)]
                        : const [Color(0xFF34A853), Color(0xFF4285F4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (isIos ? const Color(0xFFFF2D55) : const Color(0xFF4285F4))
                          .withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isIos ? Icons.favorite_rounded : Icons.health_and_safety_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),

              // Center: Animated Sync Connector Pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync_alt_rounded, size: 16, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Sync',
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
              ),

              // Right: Yira Health Cloud Box
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.82),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            'Connect $platformName',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isTab ? 22 : 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            'Seamlessly synchronizes the past 30 days of daily activity and keeps your vitals, steps, and sleep continuously up to date.',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsRow({required bool isDark, required Color primaryColor}) {
    return Row(
      children: [
        Expanded(
          child: _buildSpecItem(
            icon: Icons.calendar_today_rounded,
            title: '30-Day Sync',
            subtitle: 'Full month history',
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSpecItem(
            icon: Icons.bolt_rounded,
            title: 'Auto Sync',
            subtitle: 'On app launch',
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSpecItem(
            icon: Icons.lock_outline_rounded,
            title: 'Private',
            subtitle: 'AES-256 encrypted',
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.30 : 0.20),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.22 : 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 9.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String tag,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: isDark ? 0.20 : 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyBanner({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.shield_outlined, size: 18, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your health records are encrypted and confidential. Yira Clinics only reads metrics with your explicit permission and never shares or alters your Apple Health records.',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomConnectBar({
    required bool isIos,
    required String platformName,
    required Color primaryColor,
    required bool isDark,
  }) {
    final gradientColors = isIos
        ? const [Color(0xFFFF2D55), Color(0xFFFF5268)]
        : [primaryColor, primaryColor.withValues(alpha: 0.88)];
    final shadowColor = isIos ? const Color(0xFFFF2D55) : primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _isConnecting ? null : _handleConnect,
                child: Center(
                  child: _isConnecting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isIos ? Icons.favorite_rounded : Icons.sync_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Connect $platformName',
                              style: const TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 13,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 5),
              Text(
                'Instant 1-tap setup • Synchronizes past 30 days',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
