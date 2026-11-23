import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/services/medication_popup_service.dart';
import 'package:yiraclinics/core/services/medication_reminder_service.dart';
import 'package:yiraclinics/core/widgets/phosphor_icons.dart';

/// The floating medicine reminder shown over other apps (Android). It runs in
/// its own Flutter engine, started from `overlayMain` in main.dart.
class MedicationPopupApp extends StatelessWidget {
  const MedicationPopupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins', useMaterial3: true),
      home: const MedicationPopupOverlay(),
    );
  }
}

class MedicationPopupOverlay extends StatefulWidget {
  /// For tests and previews; normally the dose is read from storage.
  final MedicationPopupData? initialData;

  /// Closes the popup; defaults to closing the overlay window.
  final Future<void> Function()? onClose;

  const MedicationPopupOverlay({super.key, this.initialData, this.onClose});

  @override
  State<MedicationPopupOverlay> createState() => _MedicationPopupOverlayState();
}

class _MedicationPopupOverlayState extends State<MedicationPopupOverlay> with WidgetsBindingObserver {
  static const Color _blue = Color(0xFF2563EB);
  static const Color _green = Color(0xFF10B981);
  static const Color _strong = Color(0xFF121212);
  static const Color _muted = Color(0xFF64748B);
  static const Color _line = Color(0xFFE2E8F0);

  MedicationPopupData? _data;
  _ScreenMetrics? _screen;
  bool _saving = false;
  bool _taken = false;
  StreamSubscription<dynamic>? _messages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _data = widget.initialData;
    if (widget.initialData == null) {
      _loadFromStorage();
      // A newer reminder while the popup is open replaces the dose shown.
      _messages = FlutterOverlayWindow.overlayListener.listen((event) {
        if (event is String && event.startsWith('{')) {
          try {
            _show(MedicationPopupData.fromJson(Map<String, dynamic>.from(jsonDecode(event))));
          } catch (_) {}
          // Also picks up a changed screen size, for example after rotation.
          _loadFromStorage();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messages?.cancel();
    super.dispose();
  }

  // The overlay engine keeps running between popups; each new popup resumes it.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.initialData == null) _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final rawScreen = prefs.getString(MedicationPopupService.screenMetricsKey);
      if (rawScreen != null && rawScreen.isNotEmpty && mounted) {
        final m = Map<String, dynamic>.from(jsonDecode(rawScreen));
        setState(() => _screen = _ScreenMetrics(
              height: (m['height'] as num?)?.toDouble() ?? 0,
              top: (m['top'] as num?)?.toDouble() ?? 0,
              bottom: (m['bottom'] as num?)?.toDouble() ?? 0,
            ));
      }
      final raw = prefs.getString(MedicationPopupService.payloadKey);
      if (raw == null || raw.isEmpty) return;
      _show(MedicationPopupData.fromJson(Map<String, dynamic>.from(jsonDecode(raw))));
    } catch (_) {}
  }

  void _show(MedicationPopupData data) {
    if (!mounted) return;
    setState(() {
      _data = data;
      _taken = false;
      _saving = false;
    });
  }

  Future<void> _close() async {
    if (widget.onClose != null) {
      await widget.onClose!();
    } else {
      await FlutterOverlayWindow.closeOverlay();
    }
    // The overlay engine is reused for the next popup, so it must not open
    // again in the "taken" state of this one.
    if (mounted) {
      setState(() {
        _taken = false;
        _saving = false;
      });
    }
  }

  Future<void> _markTaken() async {
    final data = _data;
    if (data == null || _saving) return;
    setState(() => _saving = true);
    if (data.reminderId.isNotEmpty && data.time.isNotEmpty) {
      await MedicationReminderService.instance.markDoseTaken(data.reminderId, data.time, date: data.date);
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _taken = true;
    });
    await Future.delayed(const Duration(milliseconds: 1200));
    await _close();
  }

  TextStyle _ts(double size, FontWeight weight, Color color, {double? height}) =>
      TextStyle(fontFamily: 'Poppins', fontSize: size, fontWeight: weight, color: color, height: height, decoration: TextDecoration.none);

  /// The overlay window spans the screen plus the status and navigation bar
  /// heights and is centred on the screen, so half of that extra height hangs
  /// below the bottom edge. Returns how far the card must sit from the
  /// window's bottom, in logical pixels, to clear that and the navigation bar.
  double _cardBottomGap(BuildContext context) {
    final view = View.of(context);
    final double dpr = view.devicePixelRatio;
    final screen = _screen;
    double extra;
    double navBar;
    if (screen != null && screen.height > 0) {
      extra = view.physicalSize.height - screen.height;
      navBar = screen.bottom;
    } else {
      // No saved size: estimate the bars from the top inset and a 48dp nav bar.
      navBar = 48 * dpr;
      extra = view.padding.top + navBar;
    }
    final double hidden = extra > 0 ? extra / 2 : 0;
    return (hidden + navBar) / dpr + 16;
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final double bottomGap = _cardBottomGap(context);
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // A light scrim keeps the reminder in focus; tapping it closes the popup.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _saving ? null : _close,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: data == null ? 0 : 1),
                duration: const Duration(milliseconds: 250),
                builder: (context, v, _) => ColoredBox(color: Colors.black.withValues(alpha: 0.32 * v)),
              ),
            ),
          ),
          if (data != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, bottomGap),
                  // Slides up into place.
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('${data.reminderId}_${data.time}_${data.medicineName}'),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(offset: Offset(0, (1 - v) * 40), child: child),
                    ),
                    child: _buildCard(data),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(13, FontWeight.w600, _strong)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(MedicationPopupData data) {
    // The sample from Reminder settings has no reminder behind it.
    final bool isPreview = data.reminderId.isEmpty;
    final String time = data.time.isEmpty ? 'Now' : data.time;

    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 32, offset: const Offset(0, 12)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand strip
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: SvgPicture.asset('assets/images/svgs/ic_apps_logo.svg', width: 26, height: 26),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Yira Health', style: _ts(13.5, FontWeight.w700, _strong)),
                      Text('Medicine reminder', style: _ts(11, FontWeight.w500, _muted)),
                    ],
                  ),
                ),
                if (isPreview)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Preview', style: _ts(10.5, FontWeight.w700, const Color(0xFFB45309))),
                  ),
                Semantics(
                  button: true,
                  label: 'Close',
                  child: InkWell(
                    onTap: _saving ? null : _close,
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(color: Color(0xFFEFF2F6), shape: BoxShape.circle),
                      child: const PhosphorIcon(PhosphorIconsBold.x, size: 18, color: _strong),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: _line),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medicine
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
                      ),
                      // A capsule with a clock badge: "medicine, now".
                      child: SvgPicture.asset('assets/images/svgs/ic_medicine_reminder.svg'),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time to take your medicine', style: _ts(12, FontWeight.w500, _muted)),
                          const SizedBox(height: 2),
                          Text(
                            data.medicineName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _ts(19, FontWeight.w700, _strong, height: 1.25),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // When and how
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(PhosphorIconsBold.clock, time, _blue),
                    if (data.dosage.isNotEmpty) _chip(PhosphorIconsBold.pill, data.dosage, const Color(0xFF7C3AED)),
                    if (data.mealRelation.isNotEmpty) _chip(PhosphorIconsBold.forkKnife, data.mealRelation, const Color(0xFFEA580C)),
                  ],
                ),
                const SizedBox(height: 18),

                // Actions
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _taken
                      ? Container(
                          key: const ValueKey('taken'),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _green.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const PhosphorIcon(PhosphorIconsFill.checkCircle, color: _green, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isPreview ? 'Looks good! Real reminders work the same way.' : 'Dose marked as taken. Well done!',
                                  textAlign: TextAlign.center,
                                  style: _ts(13.5, FontWeight.w700, const Color(0xFF047857)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          key: const ValueKey('actions'),
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _saving ? null : _close,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    foregroundColor: _strong,
                                    side: const BorderSide(color: _line, width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Not now', maxLines: 1, style: _ts(15, FontWeight.w600, _strong)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: _saving ? null : _markTaken,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    backgroundColor: _green,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: _green.withValues(alpha: 0.6),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  icon: _saving
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const PhosphorIcon(PhosphorIconsBold.check, size: 20),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Mark as taken', maxLines: 1, style: _ts(15, FontWeight.w600, Colors.white)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen height and system bar sizes saved by the app, in physical pixels.
class _ScreenMetrics {
  final double height;
  final double top;
  final double bottom;

  const _ScreenMetrics({required this.height, required this.top, required this.bottom});
}
