import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yiraclinics/core/custom_dialogue/app_dialog.dart';
import '../../../../config/app_route/app_routes.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/services/fitness/fitness_service.dart';
import '../../../../core/services/fitness/fitness_sync_service.dart';
import '../../../../core/widgets/phosphor_icons.dart';

class PatientConnectFitnessScreen extends StatefulWidget {
  const PatientConnectFitnessScreen({super.key});

  @override
  State<PatientConnectFitnessScreen> createState() => _PatientConnectFitnessScreenState();
}

class _PatientConnectFitnessScreenState extends State<PatientConnectFitnessScreen> with WidgetsBindingObserver {
  final _sync = FitnessSyncService.instance;
  bool _isConnecting = false;
  late final String _profileId;

  bool get _isFamilyProfile => !GlobalSession.instance.isCurrentProfilePrimary;

  String get _firstName {
    final name = (GlobalSession.instance.userNotifier.value?.data?.firstName ?? '').trim();
    return name.isEmpty ? 'this person' : name;
  }

  @override
  void initState() {
    super.initState();
    _profileId = GlobalSession.instance.userNotifier.value?.data?.id ?? '';
    WidgetsBinding.instance.addObserver(this);
    GlobalSession.instance.userNotifier.addListener(_onProfileChanged);
    _openDashboardIfConnected();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GlobalSession.instance.userNotifier.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    final id = GlobalSession.instance.userNotifier.value?.data?.id ?? '';
    if (mounted && id != _profileId) Navigator.of(context).maybePop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _openDashboardIfConnected();
  }

  /// Only a profile that chose to connect on this phone skips this screen.
  /// OS permission alone isn't enough, since it's shared by every profile.
  Future<void> _openDashboardIfConnected() async {
    if (await _sync.checkIsConnected() && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.patientFitnessTracking);
    }
  }

  Future<void> _handleConnect({bool moveLink = false}) async {
    setState(() => _isConnecting = true);
    final result = await _sync.connectFitness(moveLink: moveLink);
    if (!mounted) return;
    setState(() => _isConnecting = false);

    if (result.isSuccess) {
      Navigator.pushReplacementNamed(context, AppRoutes.patientFitnessTracking);
    } else if (result.status == FitnessConnectStatus.linkedToAnotherProfile) {
      _confirmMoveLink(result);
    } else {
      _showConnectError(result);
    }
  }

  void _confirmMoveLink(FitnessConnectResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: result.title,
        message: result.message,
        icon: PhosphorIconsBold.deviceMobile,
        primaryLabel: 'Link to $_firstName',
        onPrimary: () {
          Navigator.pop(ctx);
          _handleConnect(moveLink: true);
        },
        secondaryLabel: 'Cancel',
        onSecondary: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showConnectError(FitnessConnectResult result) {
    final needsInstall = result.status == FitnessConnectStatus.healthConnectRequired;
    final denied = result.status == FitnessConnectStatus.permissionDenied;
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: result.title,
        message: result.message,
        tone: denied ? AppDialogTone.danger : AppDialogTone.info,
        icon: needsInstall ? PhosphorIconsBold.downloadSimple : PhosphorIconsBold.shieldWarning,
        primaryLabel: needsInstall ? 'Install' : (denied ? 'Open settings' : 'OK'),
        onPrimary: () async {
          Navigator.pop(ctx);
          if (needsInstall) await FitnessService.instance.promptInstallHealthConnect();
          if (denied) await openAppSettings();
        },
        secondaryLabel: needsInstall || denied ? 'Not now' : null,
        onSecondary: needsInstall || denied ? () => Navigator.pop(ctx) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).primaryColor;
    final fg = isDark ? Colors.white : const Color(0xFF121212);
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final platform = Platform.isIOS ? 'Apple Health' : 'Health Connect';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6FA),
        leading: IconButton(icon: Icon(PhosphorIconsBold.caretLeft, color: fg), onPressed: () => Navigator.pop(context)),
        title: Text('Fitness',
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 19, fontWeight: FontWeight.w700, color: fg)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _hero(isDark, primary, platform, fg, muted),
                  if (_isFamilyProfile) ...[
                    const SizedBox(height: 14),
                    _familyNote(isDark),
                  ],
                  const SizedBox(height: 22),
                  Text('What we read',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
                  const SizedBox(height: 10),
                  _readRow(PhosphorIconsFill.footprints, const Color(0xFF16A34A), 'Steps, distance and active energy',
                      'Daily totals, counted once even when your phone and watch both record a walk.', isDark, fg, muted),
                  _readRow(PhosphorIconsFill.moonStars, const Color(0xFF6366F1), 'Sleep',
                      'Each night with deep, REM and light stages when your watch records them.', isDark, fg, muted),
                  _readRow(PhosphorIconsFill.heartbeat, const Color(0xFFE11D48), 'Heart rate',
                      'Daily average and range, plus resting heart rate.', isDark, fg, muted),
                  _readRow(PhosphorIconsFill.drop, const Color(0xFF06B6D4), 'Blood oxygen and weight',
                      'Your latest readings, so your doctor sees them at your next visit.', isDark, fg, muted),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF232323) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(PhosphorIconsFill.lockSimple, size: 18, color: Color(0xFF10B981)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Read-only. We never write to $platform or share your data without your consent. '
                            'You can disconnect at any time.',
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, height: 1.45, color: muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121212) : Colors.white,
                border: Border(top: BorderSide(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE8ECF2))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isConnecting ? null : () => _handleConnect(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isConnecting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(PhosphorIconsBold.link, size: 18),
                      label: Text(_isConnecting ? 'Connecting…' : 'Connect $platform',
                          style: const TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Brings in your last ${FitnessSyncService.backfillDays} days, then keeps it up to date',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(bool isDark, Color primary, String platform, Color fg, Color muted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF14532D), const Color(0xFF121212)]
              : [const Color(0xFFDCFCE7), const Color(0xFFE0F2FE)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _badge(Platform.isIOS ? PhosphorIconsFill.heart : PhosphorIconsFill.heartbeat,
                  Platform.isIOS ? const Color(0xFFEF4444) : const Color(0xFF2563EB)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(PhosphorIconsBold.arrowsLeftRight, color: muted, size: 18),
              ),
              _badge(PhosphorIconsFill.footprints, const Color(0xFF16A34A)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _isFamilyProfile ? 'Track $_firstName\'s activity' : 'Your activity, sleep and heart in one place',
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 20, fontWeight: FontWeight.w800, height: 1.25, color: fg),
          ),
          const SizedBox(height: 6),
          Text(
            'Connect $platform to bring in readings from this phone and any watch or app that writes to it, '
            'like ${Platform.isIOS ? 'Apple Watch, Fitbit or Garmin' : 'Samsung Health, Fitbit, Mi Fitness or NoiseFit'}.',
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, height: 1.45, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, Color color) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: color, size: 22),
      );

  Widget _familyNote(bool isDark) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232323) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(PhosphorIconsFill.deviceMobile, size: 18, color: Color(0xFFD97706)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Connect on $_firstName\'s own phone. Health data on a phone belongs to whoever carries it, '
                'so connecting here saves this phone\'s steps and sleep to $_firstName\'s profile. '
                'A phone syncs to one profile at a time.',
                style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E)),
              ),
            ),
          ],
        ),
      );

  Widget _readRow(IconData icon, Color color, String title, String body, bool isDark, Color fg, Color muted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE8ECF2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, fontWeight: FontWeight.w700, color: fg)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, height: 1.4, color: muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
