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
import 'package:yiraclinics/core/widgets/huge_icons.dart';
import 'package:yiraclinics/core/widgets/medical_loader.dart';

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
    // Shows the stored list at once and refreshes it from the server in the background.
    if (widget.bloc == null) MedicationReminderService.instance.init(force: true);
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

  /// Reloads prescriptions and medicines, and keeps the pull-to-refresh spinner
  /// up until both are back.
  Future<void> _refreshAll(BuildContext ctx) async {
    final bloc = ctx.read<MedicationBloc>();
    bloc.add(LoadMedicationData());
    await Future.wait([
      bloc.stream.firstWhere((s) => s.status != MedicationStatus.loading).timeout(const Duration(seconds: 20), onTimeout: () => bloc.state),
      MedicationReminderService.instance.fetchRemoteReminders(),
    ]);
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
      // One Add action at a time: the floating button only once there is a list.
      // With no prescriptions the empty page carries the single Add button.
      // On My Medicines it would cover the list, so it is hidden there.
      floatingActionButton: _tabController.index != 0
          ? null
          : BlocBuilder<MedicationBloc, MedicationState>(
              buildWhen: (a, b) =>
                  a.status != b.status || a.allPrescriptions.isEmpty != b.allPrescriptions.isEmpty,
              builder: (ctx, state) {
                if (state.allPrescriptions.isEmpty) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  onPressed: () => _navigateToAddPrescription(ctx),
                  backgroundColor: primaryColor,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  icon: const Icon(HugeIcons.add01, color: Colors.white, size: 20),
                  label: Text('Add prescription', style: DietUi.text(13, FontWeight.w600, Colors.white)),
                );
              },
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

            Flexible(child: Text(label)),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFEDEFF3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: BlocBuilder<MedicationBloc, MedicationState>(
          builder: (context, state) => ValueListenableBuilder<List<MedicationReminder>>(
            valueListenable: MedicationReminderService.instance.remindersNotifier,
            builder: (context, reminders, _) => TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: isDark ? const Color(0xFF2E2E30) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08), blurRadius: 6, offset: const Offset(0, 2)),
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
                  reminders.where((r) => r.isActive && !r.hasEnded).length,
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
        // A refresh keeps the list on screen; the skeleton is only for the first load.
        if (state.status == MedicationStatus.loading && state.allPrescriptions.isEmpty) return _buildSkeleton(isDark);

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
          onRefresh: () => _refreshAll(context),
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
                      if (state.allPrescriptions.isNotEmpty) ...[
                        _buildSearchField(isDark),
                        const SizedBox(height: 18),
                      ],
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
              SliverToBoxAdapter(child: SizedBox(height: displayedItems.isEmpty ? 24 : 96)),
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
          hintText: 'Search doctor, medicine, diagnosis',
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
    if (_searchQuery.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
        child: Column(
          children: [
            Icon(HugeIcons.search01, size: 30, color: DietUi.hint(isDark)),
            const SizedBox(height: 10),
            Text('No matching prescriptions', style: DietUi.text(15, FontWeight.w700, DietUi.strong(isDark))),
            const SizedBox(height: 4),
            Text(
              'Try a different medicine, doctor or diagnosis.',
              textAlign: TextAlign.center,
              style: DietUi.text(12.5, FontWeight.w400, DietUi.muted(isDark)),
            ),
          ],
        ),
      );
    }

    Widget source(IconData icon, String title, String body) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: isDark ? accentBlueDark : primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: DietUi.text(13.5, FontWeight.w600, DietUi.strong(isDark))),
                  const SizedBox(height: 2),
                  Text(body, style: DietUi.text(12, FontWeight.w400, DietUi.muted(isDark), height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark ? const [Color(0xFF2C2F36), Color(0xFF1F2126)] : const [Colors.white, Color(0xFFF6F7FA)],
              ),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.07) : const Color(0xFFECEDF2)),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFF4F5B93).withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(HugeIcons.prescription, size: 34, color: isDark ? accentBlueDark : primaryColor),
          ),
          const SizedBox(height: 18),
          Text('No prescriptions yet', style: DietUi.text(17, FontWeight.w700, DietUi.strong(isDark))),
          const SizedBox(height: 6),
          Text(
            'Keep every prescription in one place and get reminders for your medicines.',
            textAlign: TextAlign.center,
            style: DietUi.text(12.5, FontWeight.w400, DietUi.muted(isDark), height: 1.45),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: DietUi.cardDecoration(isDark),
            child: Column(
              children: [
                source(
                  HugeIcons.stethoscope,
                  'From your Yira doctor',
                  'Added here automatically after your consultation.',
                ),
                Divider(height: 1, color: DietUi.line(isDark)),
                source(
                  HugeIcons.scanImage,
                  'From any other doctor',
                  'Upload a photo or PDF. AI fills in the details for you to check.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToAddPrescription(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(HugeIcons.add01, size: 20),
              label: Text('Add a prescription', style: DietUi.text(14, FontWeight.w600, Colors.white)),
            ),
          ),
        ],
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
    return ValueListenableBuilder<bool>(
      valueListenable: MedicationReminderService.instance.isLoading,
      builder: (context, loading, _) => ValueListenableBuilder<List<MedicationReminder>>(
      valueListenable: MedicationReminderService.instance.remindersNotifier,
      builder: (context, reminders, _) {
        if (reminders.isEmpty && loading) return _buildMedicinesSkeleton(isDark);
        if (reminders.isEmpty) {
          return RefreshIndicator(
            color: primaryColor,
            onRefresh: () => MedicationReminderService.instance.fetchRemoteReminders(),
            child: _buildRemindersEmpty(isDark),
          );
        }
        final current = reminders.where((r) => !r.hasEnded).toList();
        final finished = reminders.where((r) => r.hasEnded).toList()
          ..sort((a, b) => b.endDate.compareTo(a.endDate));

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

        return RefreshIndicator(
          color: primaryColor,
          onRefresh: () => MedicationReminderService.instance.fetchRemoteReminders(),
          child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
            if (current.isNotEmpty) ...[
              DietUi.sectionLabel('CURRENT MEDICINES · ${current.length}', isDark),
              for (final reminder in current) _buildActiveCourseCard(reminder, isDark),
            ],
            if (finished.isNotEmpty) ...[
              const SizedBox(height: 8),
              DietUi.sectionLabel(
                'FINISHED · ${finished.length}',
                isDark,
                trailing: Text('No reminders', style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark))),
              ),
              for (final reminder in finished) _buildFinishedCourseCard(reminder, isDark),
            ],
          ],
        ),
        );
      },
      ),
    );
  }

  Widget _buildMedicinesSkeleton(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        Container(
          height: 150,
          decoration: DietUi.cardDecoration(isDark),
          child: const Center(child: MedicalLoader(message: 'Loading your medicines…', size: 0.8)),
        ),
        for (var i = 0; i < 3; i++)
          Container(
            height: 92,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: DietUi.card(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DietUi.line(isDark)),
            ),
          ),
      ],
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

  /// The dose text without its daily pattern: "1 Tablet - 1-0-1" -> "1 Tablet".
  String _doseText(MedicationReminder r) => r.dosage.split(' - ').first.trim();

  Widget _buildActiveCourseCard(MedicationReminder r, bool isDark) {
    final finishDateStr = DateFormat('d MMM').format(r.endDate);
    final daysLeft = r.daysRemaining;
    final totalDays = r.durationDays > 0 ? r.durationDays : 1;
    final currentDay = r.currentDayNumber.clamp(1, totalDays);
    final notStarted = DateTime(r.startDate.year, r.startDate.month, r.startDate.day).isAfter(DateTime.now());
    final courseProgress = r.isContinuous ? 1.0 : (currentDay / totalDays).clamp(0.0, 1.0);
    final endsToday = !r.isContinuous && daysLeft == 0;
    final accent = r.isContinuous ? const Color(0xFF8B5CF6) : primaryColor;
    final details = [
      if (_doseText(r).isNotEmpty) _doseText(r),
      if (r.mealRelation.isNotEmpty) r.mealRelation,
      '${r.times.length}× a day',
    ].join(' · ');

    final String status;
    if (r.isContinuous) {
      status = 'Ongoing';
    } else if (notStarted) {
      status = 'Starts ${DateFormat('d MMM').format(r.startDate)}';
    } else if (endsToday) {
      status = 'Last day today';
    } else {
      status = 'Day $currentDay of $totalDays';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: DietUi.cardDecoration(isDark),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DietUi.iconBadge(PhosphorIconsDuotone.pill, accent, isDark, size: 42, iconSize: 21),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.medicineName,
                                style: DietUi.text(15, FontWeight.w700, DietUi.strong(isDark), height: 1.25),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                details,
                                style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark), height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        DietUi.pill(status, endsToday ? const Color(0xFFF59E0B) : accent, isDark),
                      ],
                    ),
                    if (!r.isContinuous && totalDays > 1 && !notStarted) ...[
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
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            endsToday ? 'Ends today' : '$daysLeft day${daysLeft == 1 ? '' : 's'} left · ends $finishDateStr',
                            style: DietUi.text(11, FontWeight.w600, DietUi.muted(isDark)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [for (final t in r.times) DietUi.pill(t, accent, isDark, icon: PhosphorIconsBold.clock)],
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: DietUi.line(isDark)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (r.doctorName.isNotEmpty) ...[
                          DoctorAvatarWidget(photoUrl: r.doctorPhoto, doctorName: r.doctorName, size: 20, borderRadius: 6),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _doctorLabel(r.doctorName),
                              style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
                            ),
                          ),
                        ] else
                          const Spacer(),
                        TextButton.icon(
                          onPressed: () => _confirmDeleteReminder(r),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          icon: const PhosphorIcon(PhosphorIconsBold.bellSimpleSlash, size: 15),
                          label: Text('Stop reminders', style: DietUi.text(12, FontWeight.w600, const Color(0xFFEF4444))),
                        ),
                      ],
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

  /// A course whose last day has passed: no reminders are sent for it any more.
  Widget _buildFinishedCourseCard(MedicationReminder r, bool isDark) {
    final details = [
      if (_doseText(r).isNotEmpty) _doseText(r),
      'Finished ${DateFormat('d MMM yyyy').format(r.endDate)}',
    ].join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: DietUi.sunken(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DietUi.line(isDark)),
      ),
      child: Row(
        children: [
          DietUi.iconBadge(PhosphorIconsBold.checkCircle, _green, isDark, size: 34, iconSize: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.medicineName,
                  style: DietUi.text(13.5, FontWeight.w600, DietUi.body(isDark)),
                ),
                const SizedBox(height: 2),
                Text(details, style: DietUi.text(11, FontWeight.w500, DietUi.muted(isDark))),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
            icon: Icon(HugeIcons.delete02, size: 18, color: DietUi.hint(isDark)),
            onPressed: () => MedicationReminderService.instance.deleteReminder(r.id),
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
