import 'package:yiraclinics/core/custom_dialogue/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/services/medication_reminder_service.dart';
import 'package:yiraclinics/features/data/models/medication/medication_reminder_model.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/lab_test_entity.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';
import 'package:yiraclinics/features/presentation/user_prescription/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/user_prescription/widgets/prescription_card.dart';
import '../../../core/colors/colors.dart';
import '../../../di/dependency_injection.dart';
import 'package:yiraclinics/core/widgets/notification_badge_icon.dart';
import 'package:yiraclinics/core/widgets/doctor_avatar_widget.dart';
import 'add_user_prescription_screen.dart';
import 'widgets/reminder_alert_settings_sheet.dart';
import 'package:yiraclinics/core/widgets/phosphor_icons.dart';

/// Prescriptions from doctors (and ones the patient added), plus the daily
/// medication reminders made from them.
class PrescriptionManagementScreen extends StatefulWidget {
  final int initialTabIndex;

  /// For tests: a ready bloc, so no data is loaded from the API.
  @visibleForTesting
  final MedicationBloc? bloc;

  const PrescriptionManagementScreen({super.key, this.initialTabIndex = 0, this.bloc});

  @override
  State<PrescriptionManagementScreen> createState() => _PrescriptionManagementScreenState();
}

class _PrescriptionManagementScreenState extends State<PrescriptionManagementScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color _green = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) setState(() {});
    });
    if (widget.bloc == null) MedicationReminderService.instance.init();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // A dose may have been marked taken from the floating popup while away.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.bloc == null) {
      MedicationReminderService.instance.loadReminders();
    }
  }

  Future<void> _navigateToAddPrescription(BuildContext ctx) async {
    final bloc = ctx.read<MedicationBloc>();
    final result = await Navigator.push<bool>(
      ctx,
      MaterialPageRoute(builder: (_) => AddUserPrescriptionScreen(bloc: bloc)),
    );
    if (result == true) {
      bloc.add(LoadMedicationData());
      MedicationReminderService.instance.loadReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scaffold = Scaffold(
      backgroundColor: DietUi.background(isDark),
      appBar: DietUi.appBar(
        context,
        isDark,
        title: 'Prescriptions',
        subtitle: 'Your medicines & daily reminders',
        actions: [
          DietUi.actionIcon(
            PhosphorIconsBold.slidersHorizontal,
            isDark,
            () => ReminderAlertSettingsSheet.show(context),
            tooltip: 'Reminder settings',
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: NotificationBadgeIcon(size: 20, showCapsule: true)),
          ),
        ],
      ),
      // Adding a prescription belongs to the Prescriptions tab; on My Medicines it would cover the list.
      floatingActionButton: _tabController.index != 0 ? null : Builder(
        builder: (ctx) => FloatingActionButton.extended(
          onPressed: () => _navigateToAddPrescription(ctx),
          backgroundColor: primaryColor,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          icon: const PhosphorIcon(PhosphorIconsBold.plus, color: Colors.white, size: 20),
          label: Text('Add Prescription', style: DietUi.text(13, FontWeight.w700, Colors.white)),
        ),
      ),
      body: Column(
        children: [
          _buildTabStrip(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPrescriptionsTab(isDark),
                _buildMedicationsReminderTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.bloc != null) return BlocProvider.value(value: widget.bloc!, child: scaffold);
    return BlocProvider(
      create: (context) => sl<MedicationBloc>()..add(LoadMedicationData()),
      child: scaffold,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB SWITCHER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTabStrip(bool isDark) {
    // A clean text switcher with a count on each tab; very narrow phones drop the counts.
    final compact = MediaQuery.sizeOf(context).width < 360;

    Widget tab(IconData icon, String label, int count, bool selected) {
      return Tab(
        height: 40,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (count > 0 && !compact) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? primaryColor.withValues(alpha: 0.12) : DietUi.line(isDark),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: DietUi.text(10.5, FontWeight.w700, selected ? primaryColor : DietUi.muted(isDark)),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      color: DietUi.card(isDark),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DietUi.line(isDark)),
        ),
        child: BlocBuilder<MedicationBloc, MedicationState>(
          builder: (context, state) => ValueListenableBuilder<List<MedicationReminder>>(
            valueListenable: MedicationReminderService.instance.remindersNotifier,
            builder: (context, reminders, _) => TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: DietUi.card(isDark),
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1)),
                ],
              ),
              labelColor: primaryColor,
              unselectedLabelColor: DietUi.muted(isDark),
              labelStyle: DietUi.text(12.5, FontWeight.w700, primaryColor),
              unselectedLabelStyle: DietUi.text(12.5, FontWeight.w500, DietUi.muted(isDark)),
              tabs: [
                tab(PhosphorIconsDuotone.prescription, 'Prescriptions', state.allPrescriptions.length, _tabController.index == 0),
                tab(
                  PhosphorIconsDuotone.alarm,
                  'My Medicines',
                  reminders.where((r) => r.isActive).length,
                  _tabController.index == 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: DOCTOR PRESCRIPTIONS
  // ══════════════════════════════════════════════════════════════════════════
  List<PrescribedLabTest> _labTestsOf(Map<String, dynamic> prescription) =>
      (prescription['labTests'] as List? ?? const []).whereType<PrescribedLabTest>().toList();

  Widget _buildPrescriptionsTab(bool isDark) {
    return BlocConsumer<MedicationBloc, MedicationState>(
      listener: (context, state) {
        if (state.status == MedicationStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error ?? 'Failed to load prescriptions'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == MedicationStatus.loading) return _buildSkeleton(isDark);

        final allItems = state.filteredPrescriptions;
        final q = _searchQuery.trim().toLowerCase();
        final displayedItems = q.isEmpty
            ? allItems
            : allItems.where((p) {
                final title = (p['title'] ?? '').toString().toLowerCase();
                final doc = (p['doctor'] ?? '').toString().toLowerCase();
                final condition = (p['condition'] ?? '').toString().toLowerCase();
                final meds = (p['medications'] as List? ?? [])
                    .map((m) => (m is Map ? (m['name'] ?? '') : '').toString().toLowerCase())
                    .join(' ');
                final labs = _labTestsOf(p).map((t) => t.testName.toLowerCase()).join(' ');
                return title.contains(q) || doc.contains(q) || condition.contains(q) || meds.contains(q) || labs.contains(q);
              }).toList();

        // Group by month, keeping the list's order (newest first).
        final groups = <String, List<Map<String, dynamic>>>{};
        for (final item in displayedItems) {
          groups.putIfAbsent(_monthLabel((item['date'] ?? '').toString()), () => []).add(item);
        }

        return RefreshIndicator(
          color: primaryColor,
          onRefresh: () async => context.read<MedicationBloc>().add(LoadMedicationData()),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNextDoseBanner(isDark),
                      _buildSearchField(isDark),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
              if (displayedItems.isEmpty)
                SliverToBoxAdapter(child: _buildPrescriptionsEmpty(context, isDark))
              else
                for (final entry in groups.entries) ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: DietUi.sectionLabel(
                        entry.key.toUpperCase(),
                        isDark,
                        trailing: Text(
                          '${entry.value.length} prescription${entry.value.length == 1 ? '' : 's'}',
                          style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = entry.value[index];
                          final isSelf = item['isSelf'] == true;
                          final prescriptionId = item['id'] ?? '';
                          final title = (item['title'] ?? item['condition'] ?? 'Prescription').toString();

                          return PrescriptionCard(
                            id: prescriptionId,
                            title: item['title'] ?? '',
                            condition: item['condition'] ?? 'General Consultation',
                            doctor: item['doctor'] ?? 'Doctor',
                            specialty: item['specialty'] ?? 'General Physician',
                            doctorPhoto: (item['doctorPhoto'] ?? '').toString(),
                            date: item['date'] ?? '',
                            status: item['status'] ?? 'Active',
                            pharmacy: item['pharmacy'] ?? 'Yira Clinx E-Pharmacy',
                            medications: List<Map<String, dynamic>>.from(item['medications'] ?? []),
                            labTests: _labTestsOf(item),
                            pdfUrl: (item['pdfUrl'] ?? '').toString(),
                            isSelf: isSelf,
                            onDelete: isSelf
                                ? () => _confirmDeletePrescription(context, prescriptionId, title)
                                : null,
                          );
                        },
                        childCount: entry.value.length,
                      ),
                    ),
                  ),
                ],
              // Room for the floating Add button.
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeletePrescription(BuildContext ctx, String prescriptionId, String title) {
    showDialog(
      context: ctx,
      builder: (dialogContext) => AppDialog(
        title: "Remove Prescription?",
        message: "Are you sure you want to remove \"$title\"? This will permanently delete the prescription and any reminders created from it.",
        tone: AppDialogTone.danger,
        icon: PhosphorIconsDuotone.trash,
        primaryLabel: "Remove",
        onPrimary: () async {
          Navigator.pop(dialogContext);
          final bloc = ctx.read<MedicationBloc>();
          final success = await bloc.deletePrescription(prescriptionId);
          if (mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Prescription removed successfully'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Color(0xFF0F766E),
              ),
            );
          }
        },
        secondaryLabel: "Cancel",
        onSecondary: () => Navigator.pop(dialogContext),
      ),
    );
  }

  String _monthLabel(String raw) {
    final dt = DateTime.tryParse(raw.trim());
    if (dt == null) return 'Recent';
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month) return 'This month';
    return DateFormat('MMMM yyyy').format(dt);
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: DietUi.card(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DietUi.line(isDark)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: DietUi.text(13, FontWeight.w500, DietUi.strong(isDark)),
        decoration: InputDecoration(
          hintText: 'Search doctor, medicine or diagnosis',
          hintStyle: DietUi.text(12.5, FontWeight.w400, DietUi.hint(isDark)),
          prefixIcon: PhosphorIcon(PhosphorIconsBold.magnifyingGlass, size: 20, color: DietUi.muted(isDark)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: PhosphorIcon(PhosphorIconsBold.x, size: 18, color: DietUi.muted(isDark)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  /// Today's next dose, if any. Tapping it opens My Medicines.
  Widget _buildNextDoseBanner(bool isDark) {
    return ValueListenableBuilder<List<MedicationReminder>>(
      valueListenable: MedicationReminderService.instance.remindersNotifier,
      builder: (context, reminders, _) {
        if (reminders.isEmpty) return const SizedBox.shrink();
        final doses = [...MedicationReminderService.instance.getTodayDoses()]
          ..sort((a, b) => _minutes(a.time).compareTo(_minutes(b.time)));
        final total = doses.length;
        final taken = doses.where((d) => d.isTaken).length;
        final now = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
        TodayMedicationDose? next;
        for (final d in doses) {
          if (!d.isTaken && _minutes(d.time) >= now - 30) {
            next = d;
            break;
          }
        }
        final String headline = total == 0
            ? 'No doses scheduled today'
            : next != null
                ? 'Next: ${next.time} · ${next.reminder.medicineName}'
                : taken == total
                    ? 'All of today\'s doses are taken'
                    : '${total - taken} dose${total - taken == 1 ? '' : 's'} not marked today';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.06),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _tabController.animateTo(1),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const PhosphorIcon(PhosphorIconsDuotone.alarm, size: 20, color: primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DietUi.text(12.5, FontWeight.w700, DietUi.strong(isDark)),
                          ),
                          Text(
                            total == 0 ? 'Tap to open My Medicines' : '$taken of $total taken today',
                            style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark)),
                          ),
                        ],
                      ),
                    ),
                    const PhosphorIcon(PhosphorIconsBold.caretRight, color: primaryColor),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionsEmpty(BuildContext context, bool isDark) {
    final searching = _searchQuery.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        decoration: DietUi.cardDecoration(isDark),
        child: Column(
          children: [
            DietUi.iconBadge(
              searching ? PhosphorIconsDuotone.magnifyingGlass : PhosphorIconsDuotone.prescription,
              primaryColor,
              isDark,
              size: 60,
              iconSize: 28,
            ),
            const SizedBox(height: 14),
            Text(
              searching ? 'No matching prescriptions' : 'No prescriptions yet',
              style: DietUi.text(15.5, FontWeight.w700, DietUi.strong(isDark)),
            ),
            const SizedBox(height: 6),
            Text(
              searching
                  ? 'Try a different medicine or doctor name.'
                  : 'Prescriptions from your consultations appear here. You can also add one from another doctor.',
              textAlign: TextAlign.center,
              style: DietUi.text(12.5, FontWeight.w400, DietUi.muted(isDark), height: 1.45),
            ),
            if (!searching) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _navigateToAddPrescription(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const PhosphorIcon(PhosphorIconsBold.plus, size: 18),
                label: Text('Add a prescription', style: DietUi.text(13, FontWeight.w600, Colors.white)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    Widget block(double height) => Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: DietUi.card(isDark),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DietUi.line(isDark)),
          ),
        );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [block(46), block(96), const SizedBox(height: 8), block(170), block(170)],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: MY MEDICATIONS & PILL REMINDERS
  // ══════════════════════════════════════════════════════════════════════════
  int _minutes(String time) {
    final match = RegExp(r'^(\d{1,2})[:.](\d{2})\s*([AaPp][Mm])?$').firstMatch(time.trim());
    if (match == null) return 24 * 60;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)?.toUpperCase();
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  ({String label, IconData icon, Color color}) _period(String time) {
    final m = _minutes(time);
    if (m < 12 * 60) return (label: 'Morning', icon: PhosphorIconsFill.sunHorizon, color: const Color(0xFFF59E0B));
    if (m < 17 * 60) return (label: 'Afternoon', icon: PhosphorIconsFill.sun, color: const Color(0xFFF97316));
    return (label: 'Evening & Night', icon: PhosphorIconsFill.moonStars, color: const Color(0xFF8B5CF6));
  }

  Widget _buildMedicationsReminderTab(bool isDark) {
    return ValueListenableBuilder<List<MedicationReminder>>(
      valueListenable: MedicationReminderService.instance.remindersNotifier,
      builder: (context, reminders, _) {
        if (reminders.isEmpty) return _buildRemindersEmpty(isDark);

        final todayDoses = [...MedicationReminderService.instance.getTodayDoses()]
          ..sort((a, b) => _minutes(a.time).compareTo(_minutes(b.time)));
        final total = todayDoses.length;
        final taken = todayDoses.where((d) => d.isTaken).length;
        final progress = total > 0 ? taken / total : 0.0;

        final nowMinutes = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
        TodayMedicationDose? next;
        for (final d in todayDoses) {
          if (!d.isTaken && _minutes(d.time) >= nowMinutes - 30) {
            next = d;
            break;
          }
        }

        final byPeriod = <String, List<TodayMedicationDose>>{};
        for (final d in todayDoses) {
          byPeriod.putIfAbsent(_period(d.time).label, () => []).add(d);
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _buildTodaySummary(total, taken, progress, next, isDark),
            const SizedBox(height: 20),
            if (todayDoses.isEmpty) ...[
              DietUi.sectionLabel("TODAY'S DOSES", isDark),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: DietUi.cardDecoration(isDark),
                child: Row(
                  children: [
                    PhosphorIcon(PhosphorIconsBold.checkCircle, size: 22, color: DietUi.hint(isDark)),
                    const SizedBox(width: 10),
                    Text('No doses scheduled for today.', style: DietUi.text(12.5, FontWeight.w500, DietUi.muted(isDark))),
                  ],
                ),
              ),
            ] else
              for (final entry in byPeriod.entries) ...[
                DietUi.sectionLabel(
                  entry.key.toUpperCase(),
                  isDark,
                  trailing: Text(
                    '${entry.value.where((d) => d.isTaken).length}/${entry.value.length} taken',
                    style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
                  ),
                ),
                for (final dose in entry.value) _buildTodayDoseCard(dose, isDark),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 12),
            DietUi.sectionLabel('YOUR MEDICINES · ${reminders.length}', isDark),
            for (final reminder in reminders) _buildActiveCourseCard(reminder, isDark),
          ],
        );
      },
    );
  }

  Widget _buildTodaySummary(int total, int taken, double progress, TodayMedicationDose? next, bool isDark) {
    final done = total > 0 && taken == total;
    final ringColor = done ? _green : primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DietUi.cardDecoration(isDark),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: total == 0 ? 0 : progress,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                        backgroundColor: ringColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        color: ringColor,
                      ),
                    ),
                    Text('$taken/$total', style: DietUi.text(13.5, FontWeight.w700, DietUi.strong(isDark))),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's schedule", style: DietUi.text(15, FontWeight.w700, DietUi.strong(isDark))),
                    Text(
                      DateFormat('EEEE, d MMM').format(DateTime.now()),
                      style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'Nothing to take today'
                          : done
                              ? 'All doses taken today. Well done!'
                              : '${total - taken} dose${total - taken == 1 ? '' : 's'} left today',
                      style: DietUi.text(12, FontWeight.w600, done ? _green : DietUi.body(isDark)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const PhosphorIcon(PhosphorIconsFill.bellRinging, size: 17, color: primaryColor),
                  const SizedBox(width: 8),
                  Text('Next', style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${next.time} · ${next.reminder.medicineName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DietUi.text(12.5, FontWeight.w700, DietUi.strong(isDark)),
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

  Widget _buildRemindersEmpty(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: DietUi.cardDecoration(isDark),
          child: Column(
            children: [
              DietUi.iconBadge(PhosphorIconsDuotone.alarm, primaryColor, isDark, size: 60, iconSize: 28),
              const SizedBox(height: 14),
              Text('No medication reminders', style: DietUi.text(15.5, FontWeight.w700, DietUi.strong(isDark))),
              const SizedBox(height: 6),
              Text(
                'Open a prescription and set reminders for its medicines to get daily alerts and track your doses.',
                textAlign: TextAlign.center,
                style: DietUi.text(12.5, FontWeight.w400, DietUi.muted(isDark), height: 1.45),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const PhosphorIcon(PhosphorIconsBold.prescription, size: 18),
                label: Text('View prescriptions', style: DietUi.text(13, FontWeight.w600, Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _doctorLabel(String name) => name.startsWith('Dr.') ? name : 'Dr. $name';

  Widget _buildTodayDoseCard(TodayMedicationDose dose, bool isDark) {
    final r = dose.reminder;
    final period = _period(dose.time);
    final nowMinutes = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
    // More than an hour past its time and still not marked.
    final bool missed = !dose.isTaken && _minutes(dose.time) < nowMinutes - 60;
    const red = Color(0xFFEF4444);
    final color = dose.isTaken ? _green : (missed ? red : period.color);
    // "1 Dose - 1-0-1" -> "1 Dose": the daily pattern is already the time of this card.
    final dosageText = r.dosage.split(' - ').first.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: DietUi.cardDecoration(
        isDark,
        borderColor: dose.isTaken ? _green.withValues(alpha: 0.4) : (missed ? red.withValues(alpha: 0.35) : null),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        child: Row(
          children: [
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  PhosphorIcon(dose.isTaken ? PhosphorIconsBold.check : period.icon, size: 16, color: color),
                  const SizedBox(height: 2),
                  Text(
                    dose.time.replaceAll(' ', '\n'),
                    textAlign: TextAlign.center,
                    style: DietUi.text(10.5, FontWeight.w700, color, height: 1.15),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.medicineName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DietUi.text(
                      14,
                      FontWeight.w700,
                      dose.isTaken ? DietUi.hint(isDark) : DietUi.strong(isDark),
                      height: 1.25,
                    ).copyWith(decoration: dose.isTaken ? TextDecoration.lineThrough : null),
                  ),
                  if (missed) ...[
                    const SizedBox(height: 3),
                    Text('Missed this dose', style: DietUi.text(11, FontWeight.w600, red)),
                  ],
                  if (dosageText.isNotEmpty || r.mealRelation.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      [if (dosageText.isNotEmpty) dosageText, if (r.mealRelation.isNotEmpty) r.mealRelation]
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
                    ),
                  ],
                  if (r.doctorName.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        DoctorAvatarWidget(photoUrl: r.doctorPhoto, doctorName: r.doctorName, size: 18, borderRadius: 5),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _doctorLabel(r.doctorName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                MedicationReminderService.instance.toggleDoseTaken(r.id, dose.time);
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: dose.isTaken ? _green : DietUi.sunken(isDark),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: dose.isTaken ? _green : DietUi.line(isDark)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      dose.isTaken ? PhosphorIconsFill.checkCircle : PhosphorIconsBold.circle,
                      size: 15,
                      color: dose.isTaken ? Colors.white : DietUi.muted(isDark),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      dose.isTaken ? 'Taken' : 'Take',
                      style: DietUi.text(12, FontWeight.w700, dose.isTaken ? Colors.white : DietUi.body(isDark)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCourseCard(MedicationReminder r, bool isDark) {
    final finishDateStr = DateFormat('d MMM yyyy').format(r.endDate);
    final daysLeft = r.daysRemaining;
    final totalDays = r.durationDays > 0 ? r.durationDays : 1;
    final currentDay = r.currentDayNumber.clamp(0, totalDays);
    final courseProgress = r.isContinuous ? 1.0 : (currentDay / totalDays).clamp(0.0, 1.0);
    final completed = !r.isContinuous && daysLeft <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
      decoration: DietUi.cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DietUi.iconBadge(PhosphorIconsDuotone.pill, primaryColor, isDark, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.medicineName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DietUi.text(14.5, FontWeight.w700, DietUi.strong(isDark), height: 1.25),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      r.isContinuous
                          ? 'Ongoing · reminders every day'
                          : completed
                              ? 'Course completed'
                              : 'Day $currentDay of $totalDays · ends $finishDateStr',
                      style: DietUi.text(11.5, FontWeight.w500, r.isContinuous ? primaryColor : DietUi.muted(isDark)),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _confirmDeleteReminder(r),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const PhosphorIcon(PhosphorIconsBold.bellSimpleSlash, size: 16),
                label: Text('Stop', style: DietUi.text(12, FontWeight.w600, const Color(0xFFEF4444))),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!r.isContinuous && totalDays > 1) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: courseProgress,
                            minHeight: 6,
                            backgroundColor: DietUi.line(isDark),
                            color: courseProgress >= 1.0 ? _green : primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        completed ? 'Done' : '$daysLeft day${daysLeft == 1 ? '' : 's'} left',
                        style: DietUi.text(11, FontWeight.w600, DietUi.muted(isDark)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final t in r.times) DietUi.pill(t, primaryColor, isDark, icon: PhosphorIconsBold.clock)],
                ),
                if (r.doctorName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      DoctorAvatarWidget(photoUrl: r.doctorPhoto, doctorName: r.doctorName, size: 18, borderRadius: 5),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Prescribed by ${_doctorLabel(r.doctorName)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark)),
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
    );
  }

  void _confirmDeleteReminder(MedicationReminder r) {
    showDialog(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Stop reminders?',
        message: 'You will no longer get reminders for ${r.medicineName}.',
        tone: AppDialogTone.danger,
        icon: PhosphorIconsDuotone.bellSimpleSlash,
        primaryLabel: 'Stop',
        onPrimary: () {
          Navigator.pop(ctx);
          MedicationReminderService.instance.deleteReminder(r.id);
        },
        secondaryLabel: 'Keep',
        onSecondary: () => Navigator.pop(ctx),
      ),
    );
  }
}
