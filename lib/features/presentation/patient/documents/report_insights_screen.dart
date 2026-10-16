import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/services/medical_report_ai_service.dart';
import 'package:yiraclinics/core/utils/utils.dart';
import 'package:yiraclinics/features/domain/entities/medical_report/medical_report_analysis.dart';
import 'package:yiraclinics/features/presentation/patient/appointments/patient_book_appointment_sheet.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';

/// Plain-language AI reading of a medical document: overall status, urgent
/// alerts, whether to see a doctor, every result with its normal range, and
/// practical next steps.
class ReportInsightsScreen extends StatefulWidget {
  final String documentId;
  final String documentTitle;

  /// Shown straight away when the analysis is already known; otherwise the
  /// screen asks the server to analyse the document.
  final MedicalReportAnalysis? initialAnalysis;

  /// Opens the original file.
  final VoidCallback? onViewDocument;

  /// Called whenever a new analysis arrives, so lists can update their badge.
  final ValueChanged<MedicalReportAnalysis>? onAnalyzed;

  /// Doctors see the same insights read-only: no booking, no re-analysing.
  final bool forPatient;

  const ReportInsightsScreen({
    super.key,
    required this.documentId,
    required this.documentTitle,
    this.initialAnalysis,
    this.onViewDocument,
    this.onAnalyzed,
    this.forPatient = true,
  });

  @override
  State<ReportInsightsScreen> createState() => _ReportInsightsScreenState();
}

enum _Tab { overview, results, nextSteps }

enum _ResultFilter { all, flagged, normal }

class _ReportInsightsScreenState extends State<ReportInsightsScreen> {
  MedicalReportAnalysis? _analysis;
  String? _error;
  bool _loading = false;
  _Tab _tab = _Tab.overview;
  _ResultFilter _filter = _ResultFilter.all;
  final Set<String> _openTests = {};
  final ScrollController _scroll = ScrollController();
  final GlobalKey _heroKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _analysis = widget.initialAnalysis;
    if (_analysis == null) _analyze();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _analyze({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await MedicalReportAiService.analyzeDocument(widget.documentId, force: force);
      if (!mounted) return;
      setState(() {
        _analysis = result;
        _loading = false;
        _tab = _Tab.overview;
      });
      widget.onAnalyzed?.call(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _confirmReanalyze() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DietUi.card(isDark),
        title: Text('Analyse again?', style: DietUi.text(16, FontWeight.w700, DietUi.strong(isDark))),
        content: Text(
          'Yira AI will read the document again. Use this if the summary looks wrong.',
          style: DietUi.text(13, FontWeight.w400, DietUi.body(isDark), height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Analyse')),
        ],
      ),
    );
    if (yes == true) _analyze(force: true);
  }

  /// Switches tab and, if the hero has scrolled away, shows the new tab from its top.
  void _selectTab(_Tab tab, {_ResultFilter? filter}) {
    setState(() {
      _tab = tab;
      if (filter != null) _filter = filter;
    });
    final box = _heroKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !_scroll.hasClients) return;
    final heroBottom = box.size.height + 16;
    if (_scroll.offset > heroBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(heroBottom);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analysis = _analysis;
    final showContent = !_loading && analysis != null;

    return Scaffold(
      backgroundColor: DietUi.background(isDark),
      appBar: DietUi.appBar(
        context,
        isDark,
        title: 'Report insights',
        subtitle: analysis?.title.isNotEmpty == true ? analysis!.title : widget.documentTitle,
        actions: [
          if (widget.onViewDocument != null)
            DietUi.actionIcon(Icons.description_outlined, isDark, widget.onViewDocument!, tooltip: 'View document'),
          if (showContent && widget.forPatient)
            DietUi.actionIcon(Icons.refresh_rounded, isDark, _confirmReanalyze, tooltip: 'Analyse again'),
        ],
      ),
      bottomNavigationBar: showContent ? _bottomBar(analysis, isDark) : null,
      body: _loading
          ? _AnalyzingView(isDark: isDark)
          : _error != null && analysis == null
              ? _errorView(isDark)
              : analysis == null
                  ? const SizedBox.shrink()
                  : _content(analysis, isDark),
    );
  }

  Widget _errorView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DietUi.iconBadge(Icons.cloud_off_rounded, DietUi.amber, isDark, size: 64, iconSize: 30),
            const SizedBox(height: 16),
            Text("Couldn't analyse this document", style: DietUi.text(16, FontWeight.w700, DietUi.strong(isDark))),
            const SizedBox(height: 6),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: DietUi.text(12.5, FontWeight.w400, DietUi.muted(isDark), height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _analyze(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Try again', style: DietUi.text(13, FontWeight.w600, Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: DietUi.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(MedicalReportAnalysis a, bool isDark) {
    final children = switch (_tab) {
      _Tab.overview => _overview(a, isDark),
      _Tab.results => _results(a, isDark),
      _Tab.nextSteps => _nextSteps(a, isDark),
    };

    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          sliver: SliverToBoxAdapter(child: KeyedSubtree(key: _heroKey, child: _hero(a, isDark))),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _PinnedHeader(
            height: 64,
            color: DietUi.background(isDark),
            child: _tabs(a, isDark),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                children[i],
              ],
              const SizedBox(height: 18),
              _disclaimer(a, isDark),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────

  ({List<Color> gradient, Color color, IconData icon, String label, String tag}) _statusStyle(ReportStatus status) {
    switch (status) {
      case ReportStatus.normal:
        return (
          gradient: const [Color(0xFF10B981), Color(0xFF047857)],
          color: DietUi.green,
          icon: Icons.verified_rounded,
          label: 'All clear',
          tag: 'NORMAL',
        );
      case ReportStatus.attention:
        return (
          gradient: const [Color(0xFFF59E0B), Color(0xFFEA580C)],
          color: DietUi.amber,
          icon: Icons.error_outline_rounded,
          label: 'Needs attention',
          tag: 'ATTENTION',
        );
      case ReportStatus.critical:
        return (
          gradient: const [Color(0xFFEF4444), Color(0xFFB91C1C)],
          color: DietUi.red,
          icon: Icons.warning_amber_rounded,
          label: 'Critical - act now',
          tag: 'CRITICAL',
        );
      case ReportStatus.unknown:
        return (
          gradient: const [Color(0xFF64748B), Color(0xFF334155)],
          color: DietUi.slate,
          icon: Icons.help_outline_rounded,
          label: 'No health insights',
          tag: 'INFO',
        );
    }
  }

  Widget _hero(MedicalReportAnalysis a, bool isDark) {
    final style = _statusStyle(a.status);
    final date = _prettyDate(a.reportDate);
    final meta = [
      if (a.documentType.isNotEmpty) (Icons.description_outlined, a.documentType),
      if (date.isNotEmpty) (Icons.event_outlined, date),
      if (a.labName.isNotEmpty) (Icons.local_hospital_outlined, a.labName),
    ];

    return Container(
      decoration: BoxDecoration(
        color: DietUi.card(isDark),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07), blurRadius: 18, offset: const Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: style.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            ),
            child: Stack(
              children: [
                // Soft decorative rings.
                Positioned(right: -40, top: -50, child: _ring(170)),
                Positioned(right: 50, bottom: -70, child: _ring(120)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _glassChip(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(style.icon, size: 13, color: Colors.white),
                                const SizedBox(width: 5),
                                Text(style.tag, style: DietUi.text(10.5, FontWeight.w700, Colors.white, spacing: 0.8)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          _glassChip(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                                const SizedBox(width: 5),
                                Text('Yira AI', style: DietUi.text(10.5, FontWeight.w600, Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(style.label, style: DietUi.text(21, FontWeight.w700, Colors.white, height: 1.15, spacing: -0.3)),
                                if (a.headline.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    a.headline,
                                    style: DietUi.text(13, FontWeight.w500, Colors.white.withValues(alpha: 0.94), height: 1.45),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _scoreDisc(a, style.icon, style.color, isDark),
                        ],
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final m in meta)
                              _glassChip(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(m.$1, size: 12, color: Colors.white),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        m.$2,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: DietUi.text(10.5, FontWeight.w600, Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (a.hasNumericResults)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(
                children: [
                  _statTile(a.stats.normal, 'Normal', DietUi.green, isDark, () => _selectTab(_Tab.results, filter: _ResultFilter.normal)),
                  _statDivider(isDark),
                  _statTile(a.stats.outOfRange, 'Out of range', DietUi.amber, isDark, () => _selectTab(_Tab.results, filter: _ResultFilter.flagged)),
                  _statDivider(isDark),
                  _statTile(a.stats.critical, 'Critical', DietUi.red, isDark, () => _selectTab(_Tab.results, filter: _ResultFilter.flagged)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _ring(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 18),
        ),
      );

  Widget _glassChip(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: child,
      );

  /// A white disc with a donut of normal / out-of-range / critical results.
  Widget _scoreDisc(MedicalReportAnalysis a, IconData icon, Color color, bool isDark) {
    const size = 92.0;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: DietUi.card(isDark),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: a.hasNumericResults
          ? CustomPaint(
              painter: _DonutPainter(
                parts: [
                  (a.stats.normal.toDouble(), DietUi.green),
                  (a.stats.outOfRange.toDouble(), DietUi.amber),
                  (a.stats.critical.toDouble(), DietUi.red),
                ],
                track: DietUi.line(isDark),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${a.stats.total}', style: DietUi.text(20, FontWeight.w700, DietUi.strong(isDark), height: 1.05)),
                    Text(a.stats.total == 1 ? 'test' : 'tests', style: DietUi.text(10, FontWeight.w500, DietUi.muted(isDark))),
                  ],
                ),
              ),
            )
          : Center(child: Icon(icon, size: 38, color: color)),
    );
  }

  Widget _statTile(int value, String label, Color color, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('$value', style: DietUi.text(18, FontWeight.w700, DietUi.strong(isDark), height: 1.1)),
                ],
              ),
              const SizedBox(height: 2),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: DietUi.text(10.5, FontWeight.w500, DietUi.muted(isDark))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statDivider(bool isDark) => Container(width: 1, height: 30, color: DietUi.line(isDark));

  // ── Tabs ──────────────────────────────────────────────────────────────

  Widget _tabs(MedicalReportAnalysis a, bool isDark) {
    final flagged = a.flaggedTests.length;
    Widget tab(_Tab t, String label, IconData icon, {int? badge}) {
      final selected = _tab == t;
      return Expanded(
        child: GestureDetector(
          onTap: () => _selectTab(t),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 40,
            decoration: BoxDecoration(
              color: selected ? DietUi.card(isDark) : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: selected
                  ? [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07), blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: selected ? DietUi.blue : DietUi.muted(isDark)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DietUi.text(12, selected ? FontWeight.w700 : FontWeight.w500, selected ? DietUi.strong(isDark) : DietUi.muted(isDark)),
                  ),
                ),
                if (badge != null && badge > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: DietUi.amber, borderRadius: BorderRadius.circular(10)),
                    child: Text('$badge', style: DietUi.text(10, FontWeight.w700, Colors.white)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          tab(_Tab.overview, 'Overview', Icons.dashboard_outlined),
          tab(_Tab.results, 'Results', Icons.science_outlined, badge: flagged),
          tab(_Tab.nextSteps, 'Next steps', Icons.checklist_rounded),
        ],
      ),
    );
  }

  // ── Overview tab ──────────────────────────────────────────────────────

  List<Widget> _overview(MedicalReportAnalysis a, bool isDark) {
    final flagged = a.flaggedTests;
    return [
      if (!a.isMedicalDocument)
        DietUi.notice(
          "This doesn't look like a medical report, so there are no health insights. Upload a lab report, scan report or discharge summary.",
          DietUi.slate,
          Icons.info_outline_rounded,
          isDark,
        ),
      if (a.readability != 'good' && a.readabilityNote.isNotEmpty)
        DietUi.notice('Part of the document was hard to read: ${a.readabilityNote}', DietUi.amber, Icons.blur_on_rounded, isDark),
      if (a.criticalAlerts.isNotEmpty || a.consultation.isEmergency) _alertsCard(a, isDark),
      if (a.isMedicalDocument && a.consultation.needed) _consultCard(a, isDark),
      if (a.summary.isNotEmpty || a.keyFindings.isNotEmpty || a.impression.isNotEmpty) _summaryCard(a, isDark),
      if (a.hasNumericResults)
        flagged.isNotEmpty
            ? _flaggedPreview(flagged, a, isDark)
            : DietUi.notice('All ${a.stats.normal} results are within the normal range.', DietUi.green, Icons.verified_rounded, isDark),
    ];
  }

  Widget _alertsCard(MedicalReportAnalysis a, bool isDark) {
    const red = DietUi.red;
    return Container(
      decoration: BoxDecoration(
        color: DietUi.card(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: red.withValues(alpha: 0.45), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            color: red.withValues(alpha: isDark ? 0.22 : 0.09),
            child: Row(
              children: [
                const _Pulse(color: red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    a.consultation.isEmergency ? 'Get medical help today' : 'Needs urgent attention',
                    style: DietUi.text(14.5, FontWeight.w700, red),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final alert in a.criticalAlerts) ...[
                  const SizedBox(height: 10),
                  Text(alert.title, style: DietUi.text(13.5, FontWeight.w700, DietUi.strong(isDark))),
                  if (alert.detail.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(alert.detail, style: DietUi.text(12.5, FontWeight.w400, DietUi.body(isDark), height: 1.45)),
                  ],
                  if (alert.action.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: red.withValues(alpha: isDark ? 0.14 : 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.directions_run_rounded, size: 16, color: red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(alert.action, style: DietUi.text(12.5, FontWeight.w600, red, height: 1.4))),
                        ],
                      ),
                    ),
                  ],
                ],
                if (a.consultation.isEmergency) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () => Utils.launchURL('tel:108'),
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: Text('Call emergency (108)', style: DietUi.text(13.5, FontWeight.w700, Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color color, int level}) _urgencyStyle(String urgency) {
    switch (urgency) {
      case 'emergency':
        return (label: 'Emergency', color: DietUi.red, level: 4);
      case 'urgent':
        return (label: 'Within 1-2 days', color: DietUi.red, level: 3);
      case 'soon':
        return (label: 'Within 1-2 weeks', color: DietUi.amber, level: 2);
      case 'routine':
        return (label: 'Routine visit', color: DietUi.blue, level: 1);
      default:
        return (label: 'Optional', color: DietUi.slate, level: 0);
    }
  }

  Widget _consultCard(MedicalReportAnalysis a, bool isDark) {
    final c = a.consultation;
    final urgency = _urgencyStyle(c.urgency);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: DietUi.cardDecoration(isDark, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SUGGESTED CONSULTATION', style: DietUi.text(10.5, FontWeight.w700, DietUi.muted(isDark), spacing: 0.6)),
                    const SizedBox(height: 2),
                    Text(
                      'See a ${c.specialty.isNotEmpty ? c.specialty : 'doctor'}',
                      style: DietUi.text(15.5, FontWeight.w700, DietUi.strong(isDark), height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // How soon: a 4-step meter.
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 15, color: urgency.color),
              const SizedBox(width: 6),
              Text(urgency.label, style: DietUi.text(12.5, FontWeight.w700, urgency.color)),
              if (c.timeframe.isNotEmpty && c.timeframe.toLowerCase() != urgency.label.toLowerCase()) ...[
                Text('  ·  ', style: DietUi.text(12, FontWeight.w500, DietUi.hint(isDark))),
                Flexible(
                  child: Text(c.timeframe, maxLines: 1, overflow: TextOverflow.ellipsis, style: DietUi.text(12, FontWeight.w500, DietUi.muted(isDark))),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 1; i <= 4; i++) ...[
                if (i > 1) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= urgency.level ? urgency.color : DietUi.line(isDark),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (c.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(c.reason, style: DietUi.text(12.5, FontWeight.w400, DietUi.body(isDark), height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: DietUi.cardDecoration(isDark, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DietUi.iconBadge(icon, color, isDark, size: 34, iconSize: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: DietUi.text(14.5, FontWeight.w700, DietUi.strong(isDark)))),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _summaryCard(MedicalReportAnalysis a, bool isDark) {
    return _card(
      title: 'What your report says',
      icon: Icons.auto_awesome_rounded,
      color: DietUi.violet,
      isDark: isDark,
      children: [
        if (a.summary.isNotEmpty) Text(a.summary, style: DietUi.text(13, FontWeight.w400, DietUi.body(isDark), height: 1.6)),
        if (a.impression.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: DietUi.violet.withValues(alpha: isDark ? 0.14 : 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_quote_rounded, size: 16, color: DietUi.violet),
                    const SizedBox(width: 4),
                    Text('IMPRESSION', style: DietUi.text(10.5, FontWeight.w700, DietUi.violet, spacing: 0.6)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(a.impression, style: DietUi.text(12.5, FontWeight.w500, DietUi.strong(isDark), height: 1.5)),
              ],
            ),
          ),
        ],
        if (a.keyFindings.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('KEY FINDINGS', style: DietUi.text(10.5, FontWeight.w700, DietUi.muted(isDark), spacing: 0.6)),
          const SizedBox(height: 8),
          for (final f in a.keyFindings)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.5),
                    child: Icon(Icons.arrow_right_rounded, size: 20, color: DietUi.violet.withValues(alpha: 0.9)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: Text(f, style: DietUi.text(12.5, FontWeight.w500, DietUi.strong(isDark), height: 1.5))),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _flaggedPreview(List<ReportTest> flagged, MedicalReportAnalysis a, bool isDark) {
    final shown = flagged.take(3).toList();
    return _card(
      title: 'Results to look at',
      icon: Icons.flag_rounded,
      color: flagged.any((t) => t.isCritical) ? DietUi.red : DietUi.amber,
      isDark: isDark,
      trailing: DietUi.pill('${flagged.length} of ${a.stats.total}', DietUi.amber, isDark),
      children: [
        for (final t in shown) _resultTile(t, isDark, keyPrefix: 'preview', initiallyOpen: true),
        if (flagged.length > shown.length || a.stats.total > shown.length)
          InkWell(
            onTap: () => _selectTab(_Tab.results, filter: flagged.length > shown.length ? _ResultFilter.flagged : _ResultFilter.all),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    flagged.length > shown.length ? 'See all ${flagged.length} flagged results' : 'See all ${a.stats.total} results',
                    style: DietUi.text(12.5, FontWeight.w700, DietUi.blue),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: DietUi.blue),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Results tab ───────────────────────────────────────────────────────

  ({String label, Color color}) _flagStyle(String flag) {
    switch (flag) {
      case 'critical_high':
        return (label: 'Critical high', color: DietUi.red);
      case 'critical_low':
        return (label: 'Critical low', color: DietUi.red);
      case 'high':
        return (label: 'High', color: DietUi.amber);
      case 'low':
        return (label: 'Low', color: DietUi.amber);
      case 'abnormal':
        return (label: 'Abnormal', color: DietUi.amber);
      case 'normal':
        return (label: 'Normal', color: DietUi.green);
      default:
        return (label: '', color: DietUi.slate);
    }
  }

  bool _matchesFilter(ReportTest t) => switch (_filter) {
        _ResultFilter.all => true,
        _ResultFilter.flagged => t.needsAttention,
        _ResultFilter.normal => t.isNormal,
      };

  List<Widget> _results(MedicalReportAnalysis a, bool isDark) {
    final all = a.allTests;
    final counts = {
      _ResultFilter.all: all.length,
      _ResultFilter.flagged: all.where((t) => t.needsAttention).length,
      _ResultFilter.normal: all.where((t) => t.isNormal).length,
    };
    final sections = [
      for (final s in a.sections)
        if (s.tests.any(_matchesFilter)) s,
    ];

    return [
      if (a.hasNumericResults)
        Row(
          children: [
            _filterChip('All', counts[_ResultFilter.all]!, _ResultFilter.all, DietUi.blue, isDark),
            const SizedBox(width: 8),
            _filterChip('Flagged', counts[_ResultFilter.flagged]!, _ResultFilter.flagged, DietUi.amber, isDark),
            const SizedBox(width: 8),
            _filterChip('Normal', counts[_ResultFilter.normal]!, _ResultFilter.normal, DietUi.green, isDark),
          ],
        ),
      if (sections.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 36, color: DietUi.hint(isDark)),
              const SizedBox(height: 8),
              Text('No results in this filter', style: DietUi.text(13, FontWeight.w600, DietUi.muted(isDark))),
            ],
          ),
        ),
      for (final s in sections) _sectionCard(s, isDark),
    ];
  }

  Widget _filterChip(String label, int count, _ResultFilter filter, Color color, bool isDark) {
    final selected = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : DietUi.card(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : DietUi.line(isDark)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: DietUi.text(12, FontWeight.w600, selected ? Colors.white : DietUi.body(isDark))),
            const SizedBox(width: 6),
            Text('$count', style: DietUi.text(12, FontWeight.w700, selected ? Colors.white : color)),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(ReportSection s, bool isDark) {
    final tests = s.tests.where(_matchesFilter).toList();
    final flagged = s.tests.where((t) => t.needsAttention).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      decoration: DietUi.cardDecoration(isDark, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(s.name, style: DietUi.text(13.5, FontWeight.w700, DietUi.strong(isDark), height: 1.3)),
                ),
                const SizedBox(width: 8),
                if (flagged > 0)
                  DietUi.pill('$flagged flagged', DietUi.amber, isDark)
                else if (s.tests.any((t) => t.isNormal))
                  DietUi.pill('All normal', DietUi.green, isDark, icon: Icons.check_rounded),
              ],
            ),
          ),
          for (final t in tests) _resultTile(t, isDark, keyPrefix: s.name),
        ],
      ),
    );
  }

  /// One result. Numbers sit on the right with their flag; long text findings
  /// (scan reports) wrap under the name instead.
  Widget _resultTile(ReportTest t, bool isDark, {required String keyPrefix, bool initiallyOpen = false}) {
    final key = '$keyPrefix|${t.name}';
    final open = initiallyOpen || _openTests.contains(key);
    final flag = _flagStyle(t.flag);
    final accent = t.flag == 'unknown' ? DietUi.hint(isDark) : flag.color;
    // Scan findings ("normal in alignment") are words, not numbers: give them a full line.
    final isText = t.unit.isEmpty && !RegExp(r'^\s*[<>≤≥]?\s*-?\d').hasMatch(t.value);
    final hasMore = t.meaning.isNotEmpty || t.referenceRange.isNotEmpty;
    final tint = t.needsAttention ? flag.color.withValues(alpha: isDark ? 0.12 : 0.05) : DietUi.sunken(isDark);

    final value = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: t.value, style: DietUi.text(isText ? 12.5 : 15, isText ? FontWeight.w500 : FontWeight.w700, t.needsAttention ? flag.color : DietUi.strong(isDark), height: 1.4)),
          if (t.unit.isNotEmpty) TextSpan(text: ' ${t.unit}', style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark))),
        ],
      ),
      textAlign: isText ? TextAlign.left : TextAlign.right,
    );

    return GestureDetector(
      onTap: hasMore && !initiallyOpen ? () => setState(() => open ? _openTests.remove(key) : _openTests.add(key)) : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 34,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name, style: DietUi.text(13, FontWeight.w600, DietUi.strong(isDark), height: 1.3)),
                            if (t.referenceRange.isNotEmpty && !isText) ...[
                              const SizedBox(height: 2),
                              Text('Normal ${t.referenceRange}', style: DietUi.text(11, FontWeight.w500, DietUi.hint(isDark))),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (!isText)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 130),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              value,
                              if (flag.label.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(flag.label, style: DietUi.text(10.5, FontWeight.w700, flag.color)),
                              ],
                            ],
                          ),
                        )
                      else if (flag.label.isNotEmpty)
                        DietUi.pill(flag.label, flag.color, isDark),
                      if (hasMore && !initiallyOpen) ...[
                        const SizedBox(width: 2),
                        Icon(open ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18, color: DietUi.hint(isDark)),
                      ],
                    ],
                  ),
                  if (isText) ...[
                    const SizedBox(height: 5),
                    value,
                  ],
                  if (open) ...[
                    _RangeBar(test: t, color: flag.color, isDark: isDark),
                    if (t.meaning.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Icon(Icons.lightbulb_outline_rounded, size: 14, color: DietUi.muted(isDark)),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(t.meaning, style: DietUi.text(12, FontWeight.w400, DietUi.body(isDark), height: 1.45)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Next steps tab ────────────────────────────────────────────────────

  ({IconData icon, Color color, String label}) _recStyle(String category) {
    switch (category) {
      case 'diet':
        return (icon: Icons.restaurant_rounded, color: DietUi.green, label: 'Diet');
      case 'lifestyle':
        return (icon: Icons.directions_walk_rounded, color: DietUi.blue, label: 'Lifestyle');
      case 'monitoring':
        return (icon: Icons.monitor_heart_outlined, color: DietUi.red, label: 'Monitoring');
      case 'followUpTest':
        return (icon: Icons.biotech_outlined, color: DietUi.violet, label: 'Tests');
      case 'medication':
        return (icon: Icons.medication_outlined, color: DietUi.amber, label: 'Medicines');
      default:
        return (icon: Icons.tips_and_updates_outlined, color: DietUi.slate, label: 'General');
    }
  }

  List<Widget> _nextSteps(MedicalReportAnalysis a, bool isDark) {
    final steps = <({IconData icon, Color color, String label, String text})>[
      if (a.isMedicalDocument && a.consultation.needed)
        (
          icon: Icons.medical_services_rounded,
          color: _urgencyStyle(a.consultation.urgency).color,
          label: 'Doctor · ${_urgencyStyle(a.consultation.urgency).label}',
          text: 'See a ${a.consultation.specialty.isNotEmpty ? a.consultation.specialty : 'doctor'}'
              '${a.consultation.timeframe.isNotEmpty ? ' (${a.consultation.timeframe.toLowerCase()})' : ''}.',
        ),
      for (final r in a.recommendations)
        (icon: _recStyle(r.category).icon, color: _recStyle(r.category).color, label: _recStyle(r.category).label, text: r.text),
    ];

    return [
      if (steps.isNotEmpty)
        _card(
          title: 'Your action plan',
          icon: Icons.route_rounded,
          color: DietUi.green,
          isDark: isDark,
          children: [
            for (var i = 0; i < steps.length; i++) _timelineStep(i + 1, steps[i], isLast: i == steps.length - 1, isDark: isDark),
          ],
        ),
      if (a.followUpTests.isNotEmpty)
        _card(
          title: 'Tests your doctor may suggest',
          icon: Icons.event_repeat_rounded,
          color: DietUi.violet,
          isDark: isDark,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in a.followUpTests)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: DietUi.violet.withValues(alpha: isDark ? 0.16 : 0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DietUi.violet.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.biotech_outlined, size: 14, color: DietUi.violet),
                        const SizedBox(width: 6),
                        Flexible(child: Text(t, style: DietUi.text(12, FontWeight.w500, DietUi.strong(isDark), height: 1.35))),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      if (a.questionsForDoctor.isNotEmpty) _questionsCard(a, isDark),
      if (a.possibleConditions.isNotEmpty) _conditionsCard(a, isDark),
      _detailsCard(a, isDark),
    ];
  }

  Widget _timelineStep(int n, ({IconData icon, Color color, String label, String text}) step, {required bool isLast, required bool isDark}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: step.color.withValues(alpha: isDark ? 0.22 : 0.12), shape: BoxShape.circle),
                child: Icon(step.icon, size: 16, color: step.color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(color: DietUi.line(isDark), borderRadius: BorderRadius.circular(1)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STEP $n · ${step.label.toUpperCase()}', style: DietUi.text(10, FontWeight.w700, step.color, spacing: 0.5)),
                  const SizedBox(height: 3),
                  Text(step.text, style: DietUi.text(12.5, FontWeight.w500, DietUi.strong(isDark), height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionsCard(MedicalReportAnalysis a, bool isDark) {
    return _card(
      title: 'Questions to ask your doctor',
      icon: Icons.question_answer_outlined,
      color: DietUi.blue,
      isDark: isDark,
      trailing: InkWell(
        onTap: () {
          final text = [for (var i = 0; i < a.questionsForDoctor.length; i++) '${i + 1}. ${a.questionsForDoctor[i]}'].join('\n');
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Questions copied'), behavior: SnackBarBehavior.floating));
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: DietUi.blue.withValues(alpha: isDark ? 0.2 : 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.copy_rounded, size: 13, color: DietUi.blue),
              const SizedBox(width: 4),
              Text('Copy', style: DietUi.text(11.5, FontWeight.w700, DietUi.blue)),
            ],
          ),
        ),
      ),
      children: [
        for (var i = 0; i < a.questionsForDoctor.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: DietUi.sunken(isDark), borderRadius: BorderRadius.circular(12)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: DietUi.blue, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: DietUi.text(11, FontWeight.w700, Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(a.questionsForDoctor[i], style: DietUi.text(12.5, FontWeight.w500, DietUi.strong(isDark), height: 1.45)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _conditionsCard(MedicalReportAnalysis a, bool isDark) {
    return _card(
      title: 'What this may point to',
      icon: Icons.manage_search_rounded,
      color: DietUi.amber,
      isDark: isDark,
      children: [
        for (final c in a.possibleConditions)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: DietUi.sunken(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DietUi.line(isDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(c.name, style: DietUi.text(13, FontWeight.w700, DietUi.strong(isDark), height: 1.3))),
                    const SizedBox(width: 8),
                    DietUi.pill(
                      c.likelihood == 'likely' ? 'Likely' : 'Possible',
                      c.likelihood == 'likely' ? DietUi.amber : DietUi.slate,
                      isDark,
                    ),
                  ],
                ),
                if (c.explanation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(c.explanation, style: DietUi.text(12, FontWeight.w400, DietUi.body(isDark), height: 1.45)),
                ],
              ],
            ),
          ),
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 13, color: DietUi.hint(isDark)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Only a doctor can confirm a diagnosis.',
                style: DietUi.text(11.5, FontWeight.w500, DietUi.hint(isDark)).copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _detailsCard(MedicalReportAnalysis a, bool isDark) {
    final patient = [a.patientName, a.patientAge, a.patientGender].where((e) => e.isNotEmpty).join(' · ');
    final rows = <(IconData, String, String)>[
      if (a.labName.isNotEmpty) (Icons.local_hospital_outlined, 'Lab / hospital', a.labName),
      if (a.referringDoctor.isNotEmpty) (Icons.person_outline_rounded, 'Referred by', a.referringDoctor),
      if (a.reportDate.isNotEmpty) (Icons.event_outlined, 'Report date', _prettyDate(a.reportDate)),
      if (patient.isNotEmpty) (Icons.badge_outlined, 'Patient', patient),
      if (a.pagesAnalyzed != null) (Icons.layers_outlined, 'Pages read', '${a.pagesAnalyzed}'),
      if (a.analyzedAt != null) (Icons.schedule_rounded, 'Analysed on', DateFormat('d MMM yyyy, h:mm a').format(a.analyzedAt!)),
    ];

    return _card(
      title: 'Report details',
      icon: Icons.info_outline_rounded,
      color: DietUi.slate,
      isDark: isDark,
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(r.$1, size: 15, color: DietUi.muted(isDark)),
                const SizedBox(width: 8),
                SizedBox(width: 96, child: Text(r.$2, style: DietUi.text(12, FontWeight.w500, DietUi.muted(isDark)))),
                Expanded(child: Text(r.$3, style: DietUi.text(12.5, FontWeight.w600, DietUi.strong(isDark), height: 1.35))),
              ],
            ),
          ),
        if (a.confidence > 0) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 15, color: DietUi.muted(isDark)),
              const SizedBox(width: 8),
              SizedBox(width: 96, child: Text('AI confidence', style: DietUi.text(12, FontWeight.w500, DietUi.muted(isDark)))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: a.confidence / 100,
                    minHeight: 6,
                    backgroundColor: DietUi.line(isDark),
                    color: a.confidence >= 80 ? DietUi.green : (a.confidence >= 50 ? DietUi.amber : DietUi.red),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${a.confidence}%', style: DietUi.text(12.5, FontWeight.w700, DietUi.strong(isDark))),
            ],
          ),
        ],
      ],
    );
  }

  Widget _disclaimer(MedicalReportAnalysis a, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DietUi.card(isDark).withValues(alpha: isDark ? 0.6 : 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DietUi.line(isDark)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 16, color: DietUi.muted(isDark)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              a.disclaimer.isNotEmpty
                  ? a.disclaimer
                  : 'This summary was generated by AI to help you understand your report. It is not a diagnosis. Always confirm with a qualified doctor.',
              style: DietUi.text(11, FontWeight.w400, DietUi.muted(isDark), height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────

  Widget? _bottomBar(MedicalReportAnalysis a, bool isDark) {
    final canBook = widget.forPatient && a.isMedicalDocument && a.consultation.needed;
    if (!canBook && widget.onViewDocument == null) return null;
    final bookColor = a.consultation.isUrgent ? DietUi.red : DietUi.blue;

    return Container(
      decoration: BoxDecoration(
        color: DietUi.card(isDark),
        border: Border(top: BorderSide(color: DietUi.line(isDark))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              if (widget.onViewDocument != null)
                canBook
                    ? (MediaQuery.sizeOf(context).width < 360
                        ? _viewReportIconButton(isDark)
                        : SizedBox(width: 112, child: _viewReportButton('Report')))
                    : Expanded(child: _viewReportButton('View original report')),
              if (canBook && widget.onViewDocument != null) const SizedBox(width: 10),
              if (canBook)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => PatientBookAppointmentSheet.show(context),
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text('Book appointment', maxLines: 1, overflow: TextOverflow.ellipsis, style: DietUi.text(13, FontWeight.w700, Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bookColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _viewReportIconButton(bool isDark) {
    return SizedBox(
      width: 48,
      height: 48,
      child: OutlinedButton(
        onPressed: widget.onViewDocument,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: DietUi.blue,
          side: BorderSide(color: DietUi.blue.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Icon(Icons.description_outlined, size: 20),
      ),
    );
  }

  Widget _viewReportButton(String label) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: widget.onViewDocument,
        icon: const Icon(Icons.description_outlined, size: 18),
        label: Text(label, style: DietUi.text(13, FontWeight.w600, DietUi.blue)),
        style: OutlinedButton.styleFrom(
          foregroundColor: DietUi.blue,
          side: BorderSide(color: DietUi.blue.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  String _prettyDate(String raw) {
    final d = DateTime.tryParse(raw);
    return d == null ? raw : DateFormat('d MMM yyyy').format(d);
  }
}

class _PinnedHeader extends SliverPersistentHeaderDelegate {
  final double height;
  final Color color;
  final Widget child;

  _PinnedHeader({required this.height, required this.color, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: color,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeader oldDelegate) => true;
}

/// Donut of result counts, drawn with small gaps between segments.
class _DonutPainter extends CustomPainter {
  final List<(double, Color)> parts;
  final Color track;

  _DonutPainter({required this.parts, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    final total = parts.fold<double>(0, (sum, p) => sum + p.$1);
    if (total <= 0) return;

    final visible = parts.where((p) => p.$1 > 0).length;
    final gap = visible > 1 ? 0.28 : 0.0;
    var start = -math.pi / 2;
    for (final p in parts) {
      if (p.$1 <= 0) continue;
      final sweep = math.pi * 2 * p.$1 / total;
      canvas.drawArc(rect, start + gap / 2, math.max(0.01, sweep - gap), false, paint..color = p.$2);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.parts != parts || old.track != track;
}

/// A gently pulsing dot for urgent alerts.
class _Pulse extends StatefulWidget {
  final Color color;

  const _Pulse({required this.color});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 10 + 12 * _c.value,
              height: 10 + 12 * _c.value,
              decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.35 * (1 - _c.value)), shape: BoxShape.circle),
            ),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}

/// A thin bar showing where a value falls against its normal range, drawn
/// only when both are plain numbers (e.g. 10.2 against 13.0 - 17.0).
class _RangeBar extends StatelessWidget {
  final ReportTest test;
  final Color color;
  final bool isDark;

  const _RangeBar({required this.test, required this.color, required this.isDark});

  static final _number = RegExp(r'-?\d+(?:\.\d+)?');
  static final _range = RegExp(r'^\s*(\d+(?:\.\d+)?)\s*(?:-|–|to)\s*(\d+(?:\.\d+)?)\s*$');

  @override
  Widget build(BuildContext context) {
    final value = double.tryParse(_number.firstMatch(test.value.replaceAll(',', ''))?.group(0) ?? '');
    final match = _range.firstMatch(test.referenceRange.replaceAll(',', '').replaceAll(RegExp(r'[a-zA-Z/%µ]+'), ' ').trim());
    if (value == null || match == null) return const SizedBox.shrink();
    final low = double.parse(match.group(1)!);
    final high = double.parse(match.group(2)!);
    if (high <= low) return const SizedBox.shrink();

    // The normal band sits in the middle third; values outside spill into the sides.
    final pos = ((value - low) / (high - low) / 3 + 1 / 3).clamp(0.02, 0.98);
    final labelStyle = DietUi.text(9.5, FontWeight.w600, DietUi.hint(isDark));

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        return SizedBox(
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 5,
                child: Row(
                  children: [
                    Expanded(child: Container(height: 6, decoration: BoxDecoration(color: DietUi.amber.withValues(alpha: 0.35), borderRadius: const BorderRadius.horizontal(left: Radius.circular(3))))),
                    Expanded(child: Container(height: 6, color: DietUi.green.withValues(alpha: 0.65))),
                    Expanded(child: Container(height: 6, decoration: BoxDecoration(color: DietUi.red.withValues(alpha: 0.3), borderRadius: const BorderRadius.horizontal(right: Radius.circular(3))))),
                  ],
                ),
              ),
              Positioned(left: w / 3 - 12, top: 15, child: SizedBox(width: 24, child: Text(_fmt(low), textAlign: TextAlign.center, style: labelStyle))),
              Positioned(left: w * 2 / 3 - 12, top: 15, child: SizedBox(width: 24, child: Text(_fmt(high), textAlign: TextAlign.center, style: labelStyle))),
              Positioned(
                left: w * pos - 7,
                top: 1,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: test.isNormal ? DietUi.green : color,
                    shape: BoxShape.circle,
                    border: Border.all(color: DietUi.card(isDark), width: 2.5),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}

/// Shown while the server reads the document; steps through what the AI is
/// doing so a 10-20 second wait doesn't feel stuck.
class _AnalyzingView extends StatefulWidget {
  final bool isDark;

  const _AnalyzingView({required this.isDark});

  @override
  State<_AnalyzingView> createState() => _AnalyzingViewState();
}

class _AnalyzingViewState extends State<_AnalyzingView> {
  static const _steps = [
    'Reading every page',
    'Finding each test result',
    'Comparing with normal ranges',
    'Checking for anything urgent',
    'Writing your summary',
  ];
  int _step = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (_step < _steps.length - 1) setState(() => _step++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(width: 76, height: 76, child: CircularProgressIndicator(strokeWidth: 3, color: DietUi.violet)),
                DietUi.iconBadge(Icons.auto_awesome_rounded, DietUi.violet, isDark, size: 56, iconSize: 26),
              ],
            ),
            const SizedBox(height: 20),
            Text('Yira AI is reading your report', style: DietUi.text(16, FontWeight.w700, DietUi.strong(isDark))),
            const SizedBox(height: 4),
            Text('This usually takes 10-30 seconds', style: DietUi.text(12, FontWeight.w400, DietUi.muted(isDark))),
            const SizedBox(height: 22),
            for (var i = 0; i < _steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: i < _step
                          ? const Icon(Icons.check_circle_rounded, size: 18, color: DietUi.green)
                          : i == _step
                              ? const Padding(padding: EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2, color: DietUi.violet))
                              : Icon(Icons.radio_button_unchecked_rounded, size: 18, color: DietUi.hint(isDark)),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 220,
                      child: Text(
                        _steps[i],
                        style: DietUi.text(12.5, i <= _step ? FontWeight.w600 : FontWeight.w400, i <= _step ? DietUi.strong(isDark) : DietUi.hint(isDark)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
