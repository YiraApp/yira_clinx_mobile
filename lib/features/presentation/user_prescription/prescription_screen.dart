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
          actions: const [
            NotificationBadgeIcon(size: 22),
            SizedBox(width: 8),
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
                          date: item['date'] ?? '',
                          status: item['status'] ?? 'Active',
                          pharmacy: item['pharmacy'] ?? 'Yira Clinx E-Pharmacy',
                          medications: meds,
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

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TODAY'S SCHEDULE HEADER ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Medication Doses",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        todayStr,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${todayDoses.where((d) => d.isTaken).length}/${todayDoses.length} Taken",
                      style: const TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Today's Doses Cards
              if (todayDoses.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Text(
                      "No pills scheduled for today.",
                      style: TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                  ),
                )
              else
                ...todayDoses.map((dose) => _buildTodayDoseCard(dose, isDark)),

              const SizedBox(height: 24),

              // ── ACTIVE MEDICATION COURSES ──
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 18, color: primaryColor),
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
              const SizedBox(height: 12),

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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dose.isTaken
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: dose.isTaken
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 13,
                  color: dose.isTaken ? const Color(0xFF10B981) : primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  dose.time,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: dose.isTaken ? const Color(0xFF10B981) : primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Medicine Name & Meal timing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.medicineName,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                    decoration: dose.isTaken ? TextDecoration.lineThrough : null,
                    color: dose.isTaken
                        ? (isDark ? Colors.white38 : Colors.grey.shade400)
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
                if (r.mealRelation.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    r.mealRelation,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                ],
                if (r.doctorName.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    "Prescribed by: ${r.doctorName}",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 10.5,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: dose.isTaken
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(8),
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

    final String durationLabel = r.isContinuous
        ? "Continuous Medication • Daily reminders ongoing"
        : (daysLeft > 0
            ? "Day ${r.currentDayNumber} of ${r.durationDays} days • $daysLeft days left (until $finishDateStr)"
            : "Course completed");

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
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
                    Text(
                      r.medicineName,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      durationLabel,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: r.isContinuous
                            ? primaryColor
                            : (isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ),
                    if (r.doctorName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        "Prescribed by: ${r.doctorName}",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                tooltip: "Cancel Reminder",
                onPressed: () => _confirmDeleteReminder(r),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Timings tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: r.times.map((t) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.07),
                  borderRadius: BorderRadius.circular(6),
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
