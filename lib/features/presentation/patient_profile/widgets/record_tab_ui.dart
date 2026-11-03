import 'package:flutter/material.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/lab_test_entity.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';

/// Shared parts for the tabs of the doctor's patient screen, so Medical Record,
/// Prescribe, Notes and Documents read as one design: white cards, one brand
/// colour, and colour elsewhere only where it means something.
class RecordUi {
  RecordUi._();

  static Color ink(bool isDark) => isDark ? Colors.white : const Color(0xFF0F172A);
  static Color line(bool isDark) => isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0);
  static Color soft(bool isDark) => isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9);
  static const Color urgent = Color(0xFFD97706);
}

/// A white card. Tapping anywhere runs [onTap].
class RecordCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const RecordCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: DietUi.card(isDark),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: RecordUi.line(isDark)),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Icon, title, subtitle and an optional trailing widget, the top row of a card.
class RecordCardHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const RecordCardHeader({super.key, required this.icon, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DietUi.blue.withValues(alpha: isDark ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: DietUi.blue),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DietUi.text(14, FontWeight.w600, RecordUi.ink(isDark), height: 1.25)),
              if ((subtitle ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DietUi.text(11.5, FontWeight.w400, DietUi.muted(isDark))),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

/// Small status label. Green when done, amber when waiting, red when stopped,
/// grey for anything else.
class RecordStatusPill extends StatelessWidget {
  final String status;

  const RecordStatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = status.toLowerCase();
    final Color color;
    if (s.contains('cancel') || s.contains('reject') || s.contains('missed')) {
      color = const Color(0xFFDC2626);
    } else if (s.contains('pending') || s.contains('draft') || s.contains('progress')) {
      color = const Color(0xFFD97706);
    } else if (s.contains('complet') || s.contains('confirm') || s.contains('active') || s.contains('final')) {
      color = const Color(0xFF059669);
    } else {
      color = DietUi.muted(isDark);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status, style: DietUi.text(10.5, FontWeight.w600, color)),
    );
  }
}

/// A label above its value, for one piece of clinical text.
class RecordField extends StatelessWidget {
  final String label;
  final String value;

  const RecordField({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark))),
        const SizedBox(height: 2),
        Text(value, style: DietUi.text(13, FontWeight.w500, DietUi.body(isDark), height: 1.35)),
      ],
    );
  }
}

/// Vitals as tiles. Takes the server's "BP: 100/70, HR: 80, Temp: 98" summary.
class RecordVitalsRow extends StatelessWidget {
  final String summary;

  const RecordVitalsRow({super.key, required this.summary});

  static List<(String, String)> parse(String summary) => [
        for (final part in summary.split(','))
          if (part.contains(':') && part.split(':').last.trim().isNotEmpty)
            (part.split(':').first.trim(), part.split(':').skip(1).join(':').trim()),
      ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = parse(summary);
    if (items.isEmpty) return RecordField(label: 'Vitals', value: summary);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (label, value) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(color: RecordUi.soft(isDark), borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: DietUi.text(10.5, FontWeight.w500, DietUi.muted(isDark))),
                const SizedBox(height: 1),
                Text(value, style: DietUi.text(13.5, FontWeight.w600, RecordUi.ink(isDark))),
              ],
            ),
          ),
      ],
    );
  }
}

/// Quiet "View details" link for the bottom of a card.
class RecordCardLink extends StatelessWidget {
  final String label;

  const RecordCardLink({super.key, this.label = 'View details'});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(label, style: DietUi.text(12, FontWeight.w600, DietUi.blue)),
        const SizedBox(width: 2),
        const Icon(Icons.chevron_right_rounded, size: 17, color: DietUi.blue),
      ],
    );
  }
}

/// Grey icon button for edit; pass [danger] for delete.
class RecordIconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool danger;

  const RecordIconAction({super.key, required this.icon, required this.tooltip, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(icon, size: 18, color: danger ? const Color(0xFFDC2626) : DietUi.muted(isDark)),
    );
  }
}

/// Centred icon, title and message for a tab with nothing to show.
class RecordEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const RecordEmptyState({super.key, required this.icon, required this.title, this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: RecordUi.soft(isDark), shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: DietUi.muted(isDark)),
            ),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: DietUi.text(14, FontWeight.w600, RecordUi.ink(isDark))),
            if ((message ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(message!,
                  textAlign: TextAlign.center,
                  style: DietUi.text(12, FontWeight.w400, DietUi.muted(isDark), height: 1.35)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A pill whose colour the caller picks, for when the meaning is not one
/// [RecordStatusPill] reads from the words, such as a paused diet plan or a
/// record's scope. Grey without a [color], for plain tags like a diagnosis.
class RecordPill extends StatelessWidget {
  final String label;
  final Color? color;

  const RecordPill(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tone = color ?? DietUi.muted(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color == null ? RecordUi.soft(isDark) : tone.withValues(alpha: isDark ? 0.18 : 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: DietUi.text(10.5, FontWeight.w600, tone)),
    );
  }
}

/// Small grey icon and text, for a fact that needs no label: date, doctor, size.
class RecordMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const RecordMeta({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DietUi.muted(isDark)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DietUi.text(11.5, FontWeight.w400, DietUi.muted(isDark))),
        ),
      ],
    );
  }
}

/// Grey icon and title above a group of cards in a detail sheet.
class RecordSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const RecordSectionTitle({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: DietUi.muted(isDark)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DietUi.text(13, FontWeight.w600, RecordUi.ink(isDark))),
        ),
      ],
    );
  }
}

/// One medicine: a grey dot, its name, and dose and timing beneath.
class RecordMedicineLine extends StatelessWidget {
  final String name;
  final String detail;

  const RecordMedicineLine({super.key, required this.name, this.detail = ''});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(top: 7, right: 9),
          decoration: BoxDecoration(color: DietUi.hint(isDark), shape: BoxShape.circle),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: DietUi.text(13, FontWeight.w500, RecordUi.ink(isDark), height: 1.35)),
              if (detail.trim().isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(detail, style: DietUi.text(11.5, FontWeight.w400, DietUi.muted(isDark), height: 1.35)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One ordered lab test, in the shape of [RecordMedicineLine], with an amber
/// pill when it is urgent.
class RecordLabTestLine extends StatelessWidget {
  final PrescribedLabTest test;

  const RecordLabTestLine({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: RecordMedicineLine(name: test.testName, detail: test.detail)),
        if (test.isUrgent) ...[
          const SizedBox(width: 8),
          const RecordPill(PrescribedLabTest.urgent, color: RecordUi.urgent),
        ],
      ],
    );
  }
}

/// A prescription's lab tests, cut off after [limit] with a count of the rest.
class RecordLabTestLines extends StatelessWidget {
  final List<PrescribedLabTest> tests;
  final int? limit;

  const RecordLabTestLines({super.key, required this.tests, this.limit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shown = limit == null ? tests : tests.take(limit!).toList();
    final more = tests.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          RecordLabTestLine(test: shown[i]),
        ],
        if (more > 0) ...[
          const SizedBox(height: 8),
          Text(
            '+ $more more ${more == 1 ? 'test' : 'tests'}',
            style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
          ),
        ],
      ],
    );
  }
}

/// Hairline between rows in a card.
class RecordDivider extends StatelessWidget {
  final double indent;

  const RecordDivider({super.key, this.indent = 0});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(height: 25, thickness: 1, indent: indent, color: RecordUi.line(isDark));
  }
}

/// The one filled button of a sheet or tab. [compact] sizes it to fit a card's header.
class RecordPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool compact;

  const RecordPrimaryButton({super.key, required this.label, this.icon, required this.onPressed, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: DietUi.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: Size.zero,
        tapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: compact ? 9 : 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: icon == null ? null : Icon(icon, size: 17),
      label: Text(label, style: DietUi.text(13, FontWeight.w600, Colors.white)),
    );
  }
}

/// Quiet button beside a primary action: hairline border, brand text.
class RecordSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const RecordSecondaryButton({super.key, required this.label, this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: DietUi.blue,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: BorderSide(color: RecordUi.line(isDark)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: icon == null ? null : Icon(icon, size: 16, color: DietUi.blue),
      label: Text(label, style: DietUi.text(13, FontWeight.w600, DietUi.blue)),
    );
  }
}
