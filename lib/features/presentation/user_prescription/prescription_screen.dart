import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/services/medication_reminder_service.dart';
import 'package:yiraclinics/features/data/models/medication/medication_reminder_model.dart';
import 'package:yiraclinics/features/presentation/user_prescription/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/user_prescription/widgets/prescription_card.dart';
import '../../../core/colors/colors.dart';
import '../../../di/dependency_injection.dart';
import 'package:yiraclinics/core/widgets/notification_badge_icon.dart';
import 'package:yiraclinics/core/widgets/doctor_avatar_widget.dart';
import 'add_user_prescription_screen.dart';

class PrescriptionManagementScreen extends StatefulWidget {
  final int initialTabIndex;

  const PrescriptionManagementScreen({super.key, this.initialTabIndex = 0});

  @override
  State<PrescriptionManagementScreen> createState() => _PrescriptionManagementScreenState();
}

class _PrescriptionManagementScreenState extends State<PrescriptionManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    MedicationReminderService.instance.init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _navigateToAddPrescription(BuildContext ctx) async {
    final bloc = ctx.read<MedicationBloc>();
    final result = await Navigator.push<bool>(
      ctx,
      MaterialPageRoute(
        builder: (_) => AddUserPrescriptionScreen(bloc: bloc),
      ),
    );
    if (result == true) {
      bloc.add(LoadMedicationData());
      MedicationReminderService.instance.loadReminders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider(
      create: (context) => sl<MedicationBloc>()..add(LoadMedicationData()),
      child: Scaffold(
        backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Prescriptions & Medications",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          actions: [
            Builder(
              builder: (ctx) => TextButton.icon(
                onPressed: () => _navigateToAddPrescription(ctx),
                icon: const Icon(Icons.add_rounded, size: 18, color: primaryColor),
                label: const Text(
                  "Add",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
            const NotificationBadgeIcon(size: 22),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                labelStyle: const TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 16),
                        SizedBox(width: 6),
                        Text("Prescriptions"),
                      ],
                    ),
                  ),
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.alarm_on_rounded, size: 16),
                        SizedBox(width: 6),
                        Text("My Medications"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: Builder(
          builder: (ctx) => FloatingActionButton.extended(
            onPressed: () => _navigateToAddPrescription(ctx),
            backgroundColor: primaryColor,
            elevation: 3,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            label: const Text(
              "Add Prescription",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPrescriptionsTab(isDark),
            _buildMedicationsReminderTab(isDark),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: DOCTOR PRESCRIPTIONS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPrescriptionsTab(bool isDark) {
    return BlocConsumer<MedicationBloc, MedicationState>(
      listener: (context, state) {
        if (state.status == MedicationStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error ?? "Failed to load prescriptions"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == MedicationStatus.loading) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final allItems = state.filteredPrescriptions;
        final displayedItems = _searchQuery.trim().isEmpty
            ? allItems
            : allItems.where((p) {
                final title = (p['title'] ?? '').toString().toLowerCase();
                final doc = (p['doctor'] ?? '').toString().toLowerCase();
                final condition = (p['condition'] ?? '').toString().toLowerCase();
                final meds = (p['medications'] as List? ?? [])
                    .map((m) => (m is Map ? (m['name'] ?? '') : '').toString().toLowerCase())
                    .join(' ');
                final q = _searchQuery.trim().toLowerCase();
                return title.contains(q) || doc.contains(q) || condition.contains(q) || meds.contains(q);
              }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            context.read<MedicationBloc>().add(LoadMedicationData());
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Search Box & Helper banner
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Search Box
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.transparent : Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: "Search doctor, medicine or condition...",
                            hintStyle: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12.5,
                              color: isDark ? Colors.white38 : Colors.grey.shade400,
                            ),
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: primaryColor),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Info card explaining alarm setup
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/dashboard_icons/pill_prescriptions_thick.png',
                              width: 22,
                              height: 22,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.medication_rounded,
                                size: 18,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Tap any prescription to view medicines and schedule daily medication alarms.",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 11.5,
                                  color: isDark ? Colors.white70 : const Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Prescriptions List
              if (displayedItems.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_outlined,
                              size: 46,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty ? "No matching prescriptions" : "No Prescriptions Found",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty
                                ? "Try searching for a different medicine or doctor name."
                                : "Prescriptions issued by doctors during consultations will appear here.",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12.5,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToAddPrescription(context),
                            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                            label: const Text(
                              "Add External Prescription",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = displayedItems[index];
                        final meds = List<Map<String, dynamic>>.from(item['medications'] ?? []);
                        return PrescriptionCard(
                          id: item['id'] ?? '',
                          title: item['title'] ?? '',
                          condition: item['condition'] ?? 'General Consultation',
                          doctor: item['doctor'] ?? 'Doctor',
                          specialty: item['specialty'] ?? 'General Physician',
                          doctorPhoto: (item['doctorPhoto'] ?? '').toString(),
                          date: item['date'] ?? '',
                          status: item['status'] ?? 'Active',
                          pharmacy: item['pharmacy'] ?? 'Yira Clinx E-Pharmacy',
                          medications: meds,
                          pdfUrl: (item['pdfUrl'] ?? '').toString(),
                        );
                      },
                      childCount: displayedItems.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: MY MEDICATIONS & PILL REMINDERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMedicationsReminderTab(bool isDark) {
    return ValueListenableBuilder<List<MedicationReminder>>(
      valueListenable: MedicationReminderService.instance.remindersNotifier,
      builder: (context, reminders, _) {
        if (reminders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.alarm_add_rounded,
                      size: 48,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "No Active Medication Reminders",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Convert tablets from your doctor's prescriptions to receive daily reminders and track your dosage schedule.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text(
                      "View Prescriptions",
                      style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      _tabController.animateTo(0);
                    },
                  ),
                ],
              ),
            ),
          );
        }

        final todayDoses = MedicationReminderService.instance.getTodayDoses();
        final now = DateTime.now();
        final todayStr = DateFormat('EEEE, MMM d').format(now);
        final totalDosesCount = todayDoses.length;
        final takenDosesCount = todayDoses.where((d) => d.isTaken).length;
        final adherenceProgress = totalDosesCount > 0 ? (takenDosesCount / totalDosesCount) : 0.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TODAY'S ADHERENCE DASHBOARD CARD ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black26 : const Color(0xFF64748B).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.09),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.calendar_month_rounded,
                                size: 16,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Today's Schedule",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  todayStr,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            "$takenDosesCount/$totalDosesCount Taken",
                            style: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (totalDosesCount > 0) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: adherenceProgress,
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            adherenceProgress == 1.0 ? const Color(0xFF10B981) : primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        adherenceProgress == 1.0
                            ? "All doses taken for today! Excellent job 🎉"
                            : "${totalDosesCount - takenDosesCount} dose${(totalDosesCount - takenDosesCount) == 1 ? '' : 's'} remaining for today",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: adherenceProgress == 1.0
                              ? const Color(0xFF10B981)
                              : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── TODAY'S SCHEDULE DOSES LIST ──
              Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    "Scheduled Doses",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (todayDoses.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 28, color: Colors.grey.shade400),
                        const SizedBox(height: 6),
                        const Text(
                          "No doses scheduled for today.",
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...todayDoses.map((dose) => _buildTodayDoseCard(dose, isDark)),

              const SizedBox(height: 24),

              // ── ACTIVE MEDICATION COURSES ──
              Row(
                children: [
                  const Icon(Icons.medical_services_rounded, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    "Active Medication Courses (${reminders.length})",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ...reminders.map((reminder) => _buildActiveCourseCard(reminder, isDark)),

              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayDoseCard(TodayMedicationDose dose, bool isDark) {
    final r = dose.reminder;

    // Time-of-day Icon & Tint
    IconData timeIcon = Icons.access_time_rounded;
    Color timeColor = primaryColor;
    final lowerTime = dose.time.toLowerCase();
    if (lowerTime.contains('am')) {
      timeIcon = Icons.wb_sunny_rounded;
      timeColor = const Color(0xFFF59E0B);
    } else if (lowerTime.contains('pm')) {
      final hour = int.tryParse(dose.time.split(':').first.trim()) ?? 12;
      if (hour < 5 || hour == 12) {
        timeIcon = Icons.light_mode_rounded;
        timeColor = const Color(0xFFF97316);
      } else {
        timeIcon = Icons.bedtime_rounded;
        timeColor = const Color(0xFF8B5CF6);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dose.isTaken
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          width: dose.isTaken ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : const Color(0xFF64748B).withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time badge with smart time-of-day icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: dose.isTaken
                  ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1)
                  : timeColor.withValues(alpha: isDark ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: dose.isTaken
                    ? const Color(0xFF10B981).withValues(alpha: 0.25)
                    : timeColor.withValues(alpha: 0.2),
                width: 0.8,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  dose.isTaken ? Icons.check_rounded : timeIcon,
                  size: 15,
                  color: dose.isTaken ? const Color(0xFF10B981) : timeColor,
                ),
                const SizedBox(height: 2),
                Text(
                  dose.time,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: dose.isTaken ? const Color(0xFF10B981) : timeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Medicine Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.medicineName,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    decoration: dose.isTaken ? TextDecoration.lineThrough : null,
                    color: dose.isTaken
                        ? (isDark ? Colors.white38 : Colors.grey.shade400)
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
                if (r.mealRelation.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.restaurant_rounded, size: 10.5, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 3.5),
                      Text(
                        r.mealRelation,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
                if (r.doctorName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      DoctorAvatarWidget(
                        photoUrl: r.doctorPhoto,
                        doctorName: r.doctorName,
                        size: 18,
                        borderRadius: 5,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          r.doctorName.startsWith('Dr.') ? r.doctorName : "Dr. ${r.doctorName}",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : const Color(0xFF475569),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Action Button: Take / Taken
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              MedicationReminderService.instance.toggleDoseTaken(r.id, dose.time);
            },
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: dose.isTaken
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: dose.isTaken ? const Color(0xFF10B981) : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    dose.isTaken ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 14,
                    color: dose.isTaken ? Colors.white : (isDark ? Colors.white60 : Colors.grey.shade700),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dose.isTaken ? "Taken" : "Take",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: dose.isTaken ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCourseCard(MedicationReminder r, bool isDark) {
    final finishDateStr = DateFormat('MMM d, yyyy').format(r.endDate);
    final daysLeft = r.daysRemaining;
    final totalDays = r.durationDays > 0 ? r.durationDays : 1;
    final currentDay = r.currentDayNumber.clamp(0, totalDays);
    final courseProgress = r.isContinuous ? 1.0 : (currentDay / totalDays).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black12 : const Color(0xFF64748B).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pill icon container
              Container(
                width: 38,
                height: 38,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
                child: Image.asset(
                  'assets/images/dashboard_icons/pill_prescriptions_thick.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.medication_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.medicineName,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      r.isContinuous
                          ? "Continuous Medication • Daily alarms active"
                          : (daysLeft > 0
                              ? "Day $currentDay of $totalDays days • $daysLeft days left (until $finishDateStr)"
                              : "Course completed"),
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: r.isContinuous
                            ? primaryColor
                            : (isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(Icons.alarm_off_rounded, size: 18, color: Colors.redAccent),
                tooltip: "Stop Reminder",
                onPressed: () => _confirmDeleteReminder(r),
              ),
            ],
          ),

          if (!r.isContinuous && totalDays > 1) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: courseProgress,
                minHeight: 5,
                backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(
                  courseProgress == 1.0 ? const Color(0xFF10B981) : primaryColor,
                ),
              ),
            ),
          ],

          if (r.doctorName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DoctorAvatarWidget(
                  photoUrl: r.doctorPhoto,
                  doctorName: r.doctorName,
                  size: 18,
                  borderRadius: 5,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    "Prescribed by ${r.doctorName.startsWith('Dr.') ? r.doctorName : 'Dr. ${r.doctorName}'}",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // Timings tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: r.times.map((t) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.07),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.18),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 11, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      t,
                      style: const TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteReminder(MedicationReminder r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Reminder?"),
        content: Text("Are you sure you want to stop reminders for ${r.medicineName}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              MedicationReminderService.instance.deleteReminder(r.id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
