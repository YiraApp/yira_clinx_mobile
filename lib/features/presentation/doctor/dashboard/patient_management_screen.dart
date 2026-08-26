import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/app_bottom_nav_bar/app_bottom_nav_bar.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/services/favorite_patients_service.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/patient_dashboard_bloc/dashboard_bloc.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/patient_card.dart';
import '../../../../core/constants/constants.dart';

class PatientManagementScreen extends StatefulWidget {
  final bool isShellChild;
  const PatientManagementScreen({super.key, this.isShellChild = false});

  @override
  State<PatientManagementScreen> createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = "All";

  final List<String> _statusFilters = const [
    "All",
    "Favorites",
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    final primaryColor = Theme.of(context).primaryColor;

    return BlocProvider(
      create: (context) => DashboardBloc()..add(const GetDashboardData()),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          bottomNavigationBar: widget.isShellChild ? null : const AppBottomNavBar(currentIndex: 2),
          body: SafeArea(
            child: BlocConsumer<DashboardBloc, DashboardState>(
              buildWhen: (previous, state) => state is! ViewPatientDetailsState,
              listener: (context, state) {
                if (state is ViewPatientDetailsState) {
                  final currentUser = GlobalSession.instance.userNotifier.value;
                  final hospitalId = currentUser?.data?.latestHospitalId?.toString() ?? '';
                  final orgId = currentUser?.data?.latestOrgId?.toString() ?? '';
                  Navigator.pushNamed(
                    context,
                    AppRoutes.doctorPatientProfileScreen,
                    arguments: {
                      'patientId': state.patientId,
                      'patientName': state.patientName,
                      'hospitalId': hospitalId,
                      'orgId': orgId,
                      'initialTabIndex': 0,
                    },
                  );
                }
              },
              builder: (context, state) {
                final totalCount = state.allPatients.length;
                final filteredCount = state.patients.length;

                return Column(
                  children: [
                    // Clean Top Bar & Search Section
                    _buildTopHeader(context, isDark, primaryColor, isTab, totalCount, filteredCount),

                    // Filter Pills Bar
                    _buildStatusFilterRow(context, isDark, primaryColor, isTab, state.selectedStatus),

                    const SizedBox(height: 6),

                    // Patient List View or Empty State
                    Expanded(
                      child: state.status == DashboardStatus.loading
                          ? PatientCardListShimmer(itemCount: 5, isTab: isTab)
                          : RefreshIndicator(
                              color: primaryColor,
                              onRefresh: () async {
                                context.read<DashboardBloc>().add(const GetDashboardData());
                              },
                              child: state.patients.isEmpty
                                  ? _buildEmptyState(context, isDark, primaryColor, isTab)
                                  : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  screenHorizontalSpacePadding,
                                  8,
                                  screenHorizontalSpacePadding,
                                  24,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                itemCount: state.patients.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final patient = state.patients[index];
                                  return PatientCard(
                                    key: ValueKey(patient.id),
                                    isTab: isTab,
                                    patient: patient,
                                    onToggleFavorite: () async {
                                      final bloc = context.read<DashboardBloc>();
                                      await FavoritePatientsService().toggleFavorite(
                                        patientId: patient.userId,
                                        alternateId: patient.id,
                                      );
                                      try {
                                        bloc.add(
                                          ToggleFavoritePatientEvent(
                                            patientId: patient.userId,
                                            alternateId: patient.id,
                                          ),
                                        );
                                      } catch (_) {
                                        // Handled smoothly in-place by ValueListenableBuilder in PatientCard without any page reload
                                      }
                                    },
                                    onTap: () {
                                      context.read<DashboardBloc>().add(
                                        ViewPatientDetailsEvent(
                                          patientId: patient.userId,
                                          patientName: patient.name,
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Clean Top Header: Title + Count Badge + Search Bar
  Widget _buildTopHeader(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    bool isTab,
    int totalCount,
    int filteredCount,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        screenHorizontalSpacePadding,
        14,
        screenHorizontalSpacePadding,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "Patients",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 22 : 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$filteredCount${filteredCount != totalCount ? ' of $totalCount' : ''}",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 12 : 11,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      final bloc = context.read<DashboardBloc>();
                      Navigator.pushNamed(context, AppRoutes.favoritePatientsScreen).then((_) {
                        bloc.add(const GetDashboardData());
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFDE68A),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Favorites",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 13 : 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    tooltip: "Refresh List",
                    onPressed: () {
                      context.read<DashboardBloc>().add(const GetDashboardData());
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Search Field
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                context.read<DashboardBloc>().add(SearchPatients(val));
              },
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 14 : 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: "Search patient by name, ID, phone...",
                hintStyle: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? 13.5 : 12.5,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          context.read<DashboardBloc>().add(const SearchPatients(""));
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Status Filter Quick Chips Bar
  Widget _buildStatusFilterRow(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    bool isTab,
    String? selectedStatus,
  ) {
    final String currentSelected = (selectedStatus != null && selectedStatus.trim().isNotEmpty)
        ? selectedStatus.trim()
        : _selectedFilter;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _statusFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _statusFilters[index];
          final bool isSelected = currentSelected.toLowerCase() == filter.toLowerCase();
          final bool isFavPill = filter == "Favorites";

          return InkWell(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
              context.read<DashboardBloc>().add(
                FilterPatients(status: filter == "All" ? "All" : filter),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: isFavPill ? 12 : 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isFavPill ? const Color(0xFFD97706) : primaryColor)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? (isFavPill ? const Color(0xFFD97706) : primaryColor)
                      : (isFavPill
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (isFavPill ? const Color(0xFFD97706) : primaryColor).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFavPill) ...[
                      Icon(
                        Icons.star_rounded,
                        size: isTab ? 16 : 14,
                        color: isSelected ? Colors.white : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      filter,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 12.5 : 11.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isFavPill
                                ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Empty State Widget
  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    bool isTab,
  ) {
    final bool isFavFilter = _selectedFilter == "Favorites";

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isFavFilter
                    ? const Color(0xFFFEF3C7)
                    : primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFavFilter ? Icons.star_outline_rounded : Icons.people_outline_rounded,
                size: 44,
                color: isFavFilter ? const Color(0xFFD97706) : primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFavFilter ? "No Favorite Patients" : "No Patients Found",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 17 : 15.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isFavFilter
                  ? "Tap the star icon on any patient to add them to your favorites list for quick access."
                  : (_searchController.text.isNotEmpty || _selectedFilter != "All"
                      ? "Try adjusting your search query or status filter"
                      : "Patients assigned to your clinic will appear here"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 13 : 12,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            if (_searchController.text.isNotEmpty || _selectedFilter != "All") ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedFilter = "All";
                  });
                  context.read<DashboardBloc>().add(const SearchPatients(""));
                  context.read<DashboardBloc>().add(const FilterPatients(status: "All", gender: "All"));
                },
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text("Reset Filters"),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
