import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/widgets/ios_icons.dart';

/// The patient's choice, while booking, to let the doctor see all their health
/// records for a while. On by default for 7 days; the patient can turn it off or
/// pick 1 day or 1 month instead.
class RecordShareConsentCard extends StatelessWidget {
  const RecordShareConsentCard({
    super.key,
    required this.value,
    required this.onChanged,
    required this.duration,
    required this.onDurationChanged,
    this.doctorName,
    this.isTab = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String duration;
  final ValueChanged<String> onDurationChanged;
  final String? doctorName;
  final bool isTab;

  static const String defaultDuration = '7_DAYS';
  static const List<(String, String)> durations = [('1_DAY', '1 day'), ('7_DAYS', '7 days'), ('1_MONTH', '1 month')];

  static String labelFor(String duration) =>
      durations.firstWhere((d) => d.$1 == duration, orElse: () => durations[1]).$2;

  static const Color _blue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);
    final name = (doctorName ?? '').trim();
    final who = name.isEmpty
        ? 'the doctor'
        : (name.toLowerCase().startsWith('dr') ? name : 'Dr. $name');

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 14),
      decoration: BoxDecoration(
        color: value ? _blue.withValues(alpha: isDark ? 0.12 : 0.06) : (isDark ? const Color(0xFF232323) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? _blue.withValues(alpha: 0.35) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => onChanged(!value),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: value,
                  activeColor: _blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (v) => onChanged(v ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(IosIcons.verified_user_rounded, size: 16, color: value ? _blue : muted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Give $who access to my profile',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 13.5 : 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF121212),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value
                              ? 'They can see your whole profile for ${labelFor(duration)}: visits, prescriptions, reports and documents from every hospital, plus your fitness and vitals. You can stop it anytime in Approvals.'
                              : 'They will only see their own consultations with you.',
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: isTab ? 12 : 11, height: 1.35, color: muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (value) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                children: [
                  Text(
                    'For',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: muted),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (key, label) in durations)
                          ChoiceChip(
                            label: Text(label),
                            selected: duration == key,
                            showCheckmark: false,
                            onSelected: (_) => onDurationChanged(key),
                            selectedColor: _blue,
                            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            side: BorderSide(color: duration == key ? _blue : (isDark ? Colors.white24 : const Color(0xFFCBD5E1))),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            visualDensity: VisualDensity.compact,
                            labelStyle: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: duration == key ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
