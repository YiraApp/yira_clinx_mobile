import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/user_prescription/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/user_prescription/widgets/prescription_card.dart';
import '../../../core/colors/colors.dart';
import '../../../di/dependency_injection.dart';
import '../../domain/entities/medication/medication_entity.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';

class PrescriptionManagementScreen extends StatefulWidget {
  const PrescriptionManagementScreen({super.key});

  @override
  State<PrescriptionManagementScreen> createState() => _PrescriptionManagementScreenState();
}

class _PrescriptionManagementScreenState extends State<PrescriptionManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
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
            "Prescriptions",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.recentNotifications);
              },
              icon: Icon(
                Icons.notifications_none_rounded,
                size: 22,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: BlocConsumer<MedicationBloc, MedicationState>(
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

            final selectedStatus = state.selectedStatus ?? 'All';

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Interactive Summary Cards Grid ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildSummaryGrid(context, state.summary, selectedStatus, isDark),
                  ),
                ),

                // ── Search & Filter Tabs ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // Search Box
                        Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E2430) : Colors.white,
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
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: isDark ? Colors.white54 : Colors.grey.shade500,
                              ),
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

                        const SizedBox(height: 12),

                        // Status Filter Chips
                        _buildFilterChips(context, selectedStatus, isDark),
                      ],
                    ),
                  ),
                ),

                // ── Prescriptions List ──
                if (displayedItems.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
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
                                Icons.medication_outlined,
                                size: 48,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty ? "No matching prescriptions" : "No Prescriptions in '$selectedStatus'",
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
                                  : "Prescriptions issued by your doctor will appear here.",
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

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, String currentStatus, bool isDark) {
    final statuses = ['All', 'Active', 'Need Refill', 'Completed'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: statuses.map((status) {
          final isSelected = currentStatus.toLowerCase() == status.toLowerCase() ||
              (currentStatus.toLowerCase() == 'refill' && status.toLowerCase() == 'need refill');
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                status,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF475569)),
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              backgroundColor: isDark ? const Color(0xFF1E2430) : Colors.white,
              selectedColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? primaryColor
                      : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              onSelected: (_) {
                context.read<MedicationBloc>().add(FilterByStatus(status == 'Need Refill' ? 'Refill' : status));
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    MedicationEntity? summary,
    String selectedStatus,
    bool isDark,
  ) {
    final bool isAllSelected = selectedStatus.toLowerCase() == 'all';
    final bool isActiveSelected = selectedStatus.toLowerCase() == 'active';
    final bool isRefillSelected = selectedStatus.toLowerCase() == 'refill' || selectedStatus.toLowerCase() == 'need refill';

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _statCard(
              context: context,
              title: "Prescriptions",
              value: summary?.totalPrescriptions ?? 0,
              accentColor: const Color(0xFF0284C7),
              icon: Icons.description_outlined,
              isSelected: isAllSelected,
              isDark: isDark,
              onTap: () => context.read<MedicationBloc>().add(const FilterByStatus("All")),
            ),
            _statCard(
              context: context,
              title: "Active Meds",
              value: summary?.activeMeds ?? 0,
              accentColor: const Color(0xFF10B981),
              icon: Icons.medication_rounded,
              isSelected: isActiveSelected,
              isDark: isDark,
              onTap: () => context.read<MedicationBloc>().add(const FilterByStatus("Active")),
            ),
            _statCard(
              context: context,
              title: "Total Medicines",
              value: summary?.totalMedications ?? 0,
              accentColor: const Color(0xFF8B5CF6),
              icon: Icons.vaccines_outlined,
              isSelected: false,
              isDark: isDark,
              onTap: () => context.read<MedicationBloc>().add(const FilterByStatus("All")),
            ),
            _statCard(
              context: context,
              title: "Need Refill",
              value: summary?.needRefill ?? 0,
              accentColor: const Color(0xFFF59E0B),
              icon: Icons.replay_circle_filled_rounded,
              isSelected: isRefillSelected,
              isDark: isDark,
              onTap: () => context.read<MedicationBloc>().add(const FilterByStatus("Refill")),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required BuildContext context,
    required String title,
    required int value,
    required Color accentColor,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2430) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEEF2F6)),
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.12)
                    : (isDark ? Colors.transparent : const Color(0xFF1E293B).withValues(alpha: 0.03)),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? accentColor
                            : (isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
