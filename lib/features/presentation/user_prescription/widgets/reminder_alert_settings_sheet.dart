import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yiraclinics/core/services/medication_popup_service.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';

/// Lets the patient choose how medicine reminders appear: a normal
/// notification, or (Android only) a floating popup over other apps.
class ReminderAlertSettingsSheet extends StatefulWidget {
  const ReminderAlertSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReminderAlertSettingsSheet(),
    );
  }

  @override
  State<ReminderAlertSettingsSheet> createState() => _ReminderAlertSettingsSheetState();
}

class _ReminderAlertSettingsSheetState extends State<ReminderAlertSettingsSheet> with WidgetsBindingObserver {
  static const Color _blue = DietUi.blue;
  static const Color _green = DietUi.green;

  MedicationAlertStyle _style = MedicationAlertStyle.notification;
  bool _overlayAllowed = false;
  bool _notificationsAllowed = true;
  bool _loading = true;
  bool _busy = false;

  bool get _android => MedicationPopupService.isSupported;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back from the system settings page: show the new permission state.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final style = await MedicationPopupService.getStyle();
    final overlay = await MedicationPopupService.hasOverlayPermission();
    bool notifications = true;
    try {
      notifications = await Permission.notification.isGranted;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      // Without the permission the popup can't show, so fall back to notifications.
      _style = (style == MedicationAlertStyle.floatingPopup && overlay) ? style : MedicationAlertStyle.notification;
      _overlayAllowed = overlay;
      _notificationsAllowed = notifications;
      _loading = false;
    });
    if (style == MedicationAlertStyle.floatingPopup && !overlay) {
      await MedicationPopupService.setStyle(MedicationAlertStyle.notification);
    }
  }

  void _message(String text, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text, style: DietUi.text(12.5, FontWeight.w500, Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _choose(MedicationAlertStyle style) async {
    if (_busy || style == _style) return;
    if (style == MedicationAlertStyle.notification) {
      await MedicationPopupService.setStyle(style);
      setState(() => _style = style);
      return;
    }

    setState(() => _busy = true);
    var allowed = _overlayAllowed || await MedicationPopupService.requestOverlayPermission();
    allowed = allowed || await MedicationPopupService.hasOverlayPermission();
    if (!mounted) return;
    if (allowed) {
      await MedicationPopupService.setStyle(style);
      setState(() {
        _style = style;
        _overlayAllowed = true;
        _busy = false;
      });
      _message('Floating popup is on. Reminders will pop up over other apps.', color: _green);
    } else {
      setState(() => _busy = false);
      _message('Allow "Display over other apps" for Yira Health to use the floating popup.');
    }
  }

  Future<void> _testPopup() async {
    final shown = await MedicationPopupService.showTest();
    if (!mounted) return;
    if (shown) {
      _message('A sample popup is showing. Tap outside it or press Later to close.');
    } else {
      _message("Couldn't show the popup. Check that \"Display over other apps\" is allowed.", color: DietUi.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: DietUi.card(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: _loading
              ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(color: DietUi.line(isDark), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        DietUi.iconBadge(Icons.notifications_active_rounded, _blue, isDark, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Reminder alerts', style: DietUi.text(16, FontWeight.w700, DietUi.strong(isDark))),
                              Text(
                                'How your medicine reminders appear',
                                style: DietUi.text(12, FontWeight.w400, DietUi.muted(isDark)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!_notificationsAllowed) ...[
                      DietUi.notice(
                        'Notifications are off for Yira Health, so reminders cannot reach you.',
                        DietUi.amber,
                        Icons.notifications_off_rounded,
                        isDark,
                        action: TextButton(
                          onPressed: openAppSettings,
                          child: Text('Turn on', style: DietUi.text(12.5, FontWeight.w700, _blue)),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_android) ...[
                      _option(
                        isDark,
                        style: MedicationAlertStyle.notification,
                        icon: Icons.notifications_rounded,
                        title: 'Notification',
                        subtitle: 'A standard notification in your notification bar.',
                      ),
                      const SizedBox(height: 10),
                      _option(
                        isDark,
                        style: MedicationAlertStyle.floatingPopup,
                        icon: Icons.picture_in_picture_alt_rounded,
                        title: 'Floating popup',
                        subtitle: "A card pops up over any app you're using, so you don't miss a dose.",
                        badge: _overlayAllowed ? null : 'Needs permission',
                      ),
                      const SizedBox(height: 14),
                      _permissionRow(isDark),
                      if (_style == MedicationAlertStyle.floatingPopup) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: OutlinedButton.icon(
                            onPressed: _testPopup,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _blue,
                              side: BorderSide(color: _blue.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                            label: Text('Show a test popup', style: DietUi.text(13, FontWeight.w600, _blue)),
                          ),
                        ),
                      ],
                    ] else
                      DietUi.notice(
                        'On iPhone, reminders appear as notification banners. Floating popups over other apps are only available on Android.',
                        _blue,
                        Icons.info_outline_rounded,
                        isDark,
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _option(
    bool isDark, {
    required MedicationAlertStyle style,
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
  }) {
    final selected = _style == style;
    return InkWell(
      onTap: () => _choose(style),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? _blue.withValues(alpha: isDark ? 0.16 : 0.06) : DietUi.card(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _blue : DietUi.line(isDark), width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            DietUi.iconBadge(icon, selected ? _blue : DietUi.slate, isDark, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(title, style: DietUi.text(14, FontWeight.w700, DietUi.strong(isDark)))),
                      if (badge != null) ...[const SizedBox(width: 6), DietUi.pill(badge, DietUi.amber, isDark)],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: DietUi.text(12, FontWeight.w400, DietUi.muted(isDark), height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _busy && style == MedicationAlertStyle.floatingPopup
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    color: selected ? _blue : DietUi.hint(isDark),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _permissionRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: DietUi.sunken(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DietUi.line(isDark)),
      ),
      child: Row(
        children: [
          Icon(
            _overlayAllowed ? Icons.check_circle_rounded : Icons.layers_outlined,
            size: 18,
            color: _overlayAllowed ? _green : DietUi.muted(isDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display over other apps', style: DietUi.text(12.5, FontWeight.w600, DietUi.strong(isDark))),
                Text(
                  _overlayAllowed ? 'Allowed' : 'Needed for the floating popup',
                  style: DietUi.text(11, FontWeight.w400, DietUi.muted(isDark)),
                ),
              ],
            ),
          ),
          if (!_overlayAllowed)
            TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      await MedicationPopupService.requestOverlayPermission();
                      await _refresh();
                    },
              child: Text('Allow', style: DietUi.text(12.5, FontWeight.w700, _blue)),
            ),
        ],
      ),
    );
  }
}
