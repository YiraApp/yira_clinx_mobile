import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/services/medication_popup_service.dart';
import 'package:yiraclinics/core/services/medication_reminder_service.dart';

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
  static const Color _strong = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _line = Color(0xFFE2E8F0);

  MedicationPopupData? _data;
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

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Tapping anywhere outside the card closes it.
          Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _close)),
          if (data != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  child: _buildCard(data),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(MedicationPopupData data) {
    final details = [
      if (data.dosage.isNotEmpty) data.dosage,
      if (data.mealRelation.isNotEmpty) data.mealRelation,
    ].join(' · ');

    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand and close
          Row(
            children: [
              SvgPicture.asset('assets/images/ic_splash_logo.svg', width: 26, height: 26),
              const SizedBox(width: 8),
              Expanded(child: Text('Yira Health', style: _ts(16, FontWeight.w700, _blue))),
              InkWell(
                onTap: _close,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 18, color: _strong),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Medicine
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.medication_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time for your medicine', style: _ts(12, FontWeight.w500, _muted)),
                    const SizedBox(height: 2),
                    Text(
                      data.medicineName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(18, FontWeight.w700, _strong, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Time and how to take it
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 18, color: _blue),
                const SizedBox(width: 8),
                Text(data.time.isEmpty ? 'Now' : data.time, style: _ts(14, FontWeight.w700, _strong)),
                if (details.isNotEmpty) ...[
                  Container(width: 1, height: 18, margin: const EdgeInsets.symmetric(horizontal: 12), color: _line),
                  Expanded(
                    child: Text(details, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(13, FontWeight.w500, _muted)),
                  ),
                ] else
                  const Spacer(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          if (_taken)
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: _green, size: 20),
                  const SizedBox(width: 8),
                  Text('Dose logged. Well done!', style: _ts(14, FontWeight.w700, _green)),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _saving ? null : _close,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _blue,
                        side: const BorderSide(color: _blue, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Later', style: _ts(15, FontWeight.w600, _blue)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _markTaken,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _blue.withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Mark as Taken', style: _ts(15, FontWeight.w600, Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
