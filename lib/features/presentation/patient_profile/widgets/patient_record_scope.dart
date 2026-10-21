import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/features/presentation/consent/bloc/patient_access_consent_state.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';

/// A thin strip saying the doctor is looking at the patient's full history,
/// shared through consent, and until when.
class ConsentHistoryBanner extends StatelessWidget {
  final DoctorAccessStatusLoaded? accessStatus;

  const ConsentHistoryBanner({super.key, required this.accessStatus});

  static String? expiryText(DoctorAccessStatusLoaded? status) {
    final expires = status?.expiresAt ?? status?.consent?.expiresAt;
    if (status?.consent?.durationMinutes == 0) return 'no end date';
    if (expires == null) return null;
    final local = expires.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;
    return 'until ${sameDay ? DateFormat('h:mm a').format(local) : DateFormat('d MMM, h:mm a').format(local)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final until = expiryText(accessStatus);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DietUi.green.withValues(alpha: isDark ? 0.15 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DietUi.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, size: 16, color: DietUi.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Full history from all hospitals · shared by the patient${until == null ? '' : ' $until'}',
              style: DietUi.text(11.5, FontWeight.w500, DietUi.body(isDark), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Puts a "This visit | Full history" switch above a record tab. The visit view
/// is what the doctor works on; the full history needs the patient's consent,
/// so the caller passes the access gate as [history] when there is none.
class PatientRecordScopeTab extends StatelessWidget {
  final bool showHistory;
  final ValueChanged<bool> onChanged;
  final String visitLabel;
  final bool hasAccess;
  final DoctorAccessStatusLoaded? accessStatus;
  final Widget Function() visit;
  final Widget Function() history;

  const PatientRecordScopeTab({
    super.key,
    required this.showHistory,
    required this.onChanged,
    required this.visitLabel,
    required this.hasAccess,
    required this.accessStatus,
    required this.visit,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _segment(isDark, label: visitLabel, icon: Icons.event_note_rounded, selected: !showHistory, onTap: () => onChanged(false)),
                _segment(
                  isDark,
                  label: 'Full history',
                  icon: hasAccess ? Icons.history_rounded : Icons.lock_outline_rounded,
                  selected: showHistory,
                  onTap: () => onChanged(true),
                ),
              ],
            ),
          ),
        ),
        if (showHistory && hasAccess) ConsentHistoryBanner(accessStatus: accessStatus),
        Expanded(child: showHistory ? history() : visit()),
      ],
    );
  }

  Widget _segment(bool isDark, {required String label, required IconData icon, required bool selected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 34,
          decoration: BoxDecoration(
            color: selected ? DietUi.card(isDark) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? DietUi.blue : DietUi.muted(isDark)),
              const SizedBox(width: 6),
              Text(
                label,
                style: DietUi.text(12, selected ? FontWeight.w700 : FontWeight.w500, selected ? DietUi.strong(isDark) : DietUi.muted(isDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
