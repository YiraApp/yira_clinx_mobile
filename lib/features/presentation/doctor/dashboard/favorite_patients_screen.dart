import 'package:flutter/material.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/services/favorite_patients_service.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/patient_entity.dart';
import 'package:yiraclinics/features/presentation/doctor/dashboard/widgets/patient_card.dart';

class FavoritePatientsScreen extends StatefulWidget {
  const FavoritePatientsScreen({super.key});

  @override
  State<FavoritePatientsScreen> createState() => _FavoritePatientsScreenState();
}

class _FavoritePatientsScreenState extends State<FavoritePatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PatientEntity> _allFavorites = [];
  List<PatientEntity> _filteredFavorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
    });

    final favs = await FavoritePatientsService().fetchFavoritePatients();

    if (mounted) {
      setState(() {
        _allFavorites = favs;
        _isLoading = false;
      });
      _applySearch();
    }
  }

  void _applySearch([String? query]) {
    final q = (query ?? _searchController.text).trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _filteredFavorites = List.from(_allFavorites);
      });
    } else {
      setState(() {
        _filteredFavorites = _allFavorites.where((p) {
          return p.name.toLowerCase().contains(q) ||
              p.id.toLowerCase().contains(q) ||
              p.condition.toLowerCase().contains(q);
        }).toList();
      });
    }
  }

  Future<void> _toggleFavorite(PatientEntity patient) async {
    await FavoritePatientsService().toggleFavorite(
      patientId: patient.userId,
      alternateId: patient.id,
    );

    setState(() {
      _allFavorites.removeWhere((p) =>
          (patient.userId.isNotEmpty && p.userId == patient.userId) ||
          (patient.id.isNotEmpty && p.id == patient.id));
    });
    _applySearch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);
    final primaryColor = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Text(
              "Favorite Patients",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 20 : 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
              ),
              child: Text(
                "${_filteredFavorites.length}",
                style: const TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD97706),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            color: isDark ? Colors.white70 : Colors.grey.shade700,
            tooltip: "Refresh Favorites",
            onPressed: _fetchFavorites,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                screenHorizontalSpacePadding,
                12,
                screenHorizontalSpacePadding,
                10,
              ),
              child: Container(
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
                  onChanged: (val) => _applySearch(val),
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 14 : 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: "Search in favorite patients...",
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
                              _applySearch("");
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ),

            // Content List
            Expanded(
              child: _isLoading
                  ? PatientCardListShimmer(itemCount: 5, isTab: isTab)
                  : RefreshIndicator(
                      color: primaryColor,
                      onRefresh: _fetchFavorites,
                      child: _filteredFavorites.isEmpty
                          ? _buildEmptyState(context, isDark, primaryColor, isTab)
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                screenHorizontalSpacePadding,
                                6,
                                screenHorizontalSpacePadding,
                                24,
                              ),
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              itemCount: _filteredFavorites.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final patient = _filteredFavorites[index];
                                return PatientCard(
                                  key: ValueKey(patient.id),
                                  isTab: isTab,
                                  patient: patient,
                                  onToggleFavorite: () => _toggleFavorite(patient),
                                  onTap: () {
                                    final currentUser = GlobalSession.instance.userNotifier.value;
                                    final hospitalId = currentUser?.data?.latestHospitalId?.toString() ?? '';
                                    final orgId = currentUser?.data?.latestOrgId?.toString() ?? '';
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.doctorPatientProfileScreen,
                                      arguments: {
                                        'patientId': patient.userId,
                                        'patientName': patient.name,
                                        'hospitalId': hospitalId,
                                        'orgId': orgId,
                                        'initialTabIndex': 0,
                                      },
                                    ).then((_) => _fetchFavorites());
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    bool isTab,
  ) {
    final bool hasSearch = _searchController.text.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                size: 48,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasSearch ? "No Matching Favorites" : "No Favorite Patients Yet",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 18 : 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasSearch
                  ? "Try adjusting your search terms"
                  : "Tap the star icon on any patient card in the Patients tab to add them to your favorites list for quick access.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 13.5 : 12.5,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            if (hasSearch)
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _applySearch("");
                },
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: const Text("Clear Search"),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.people_outline_rounded, size: 18),
                label: const Text("Browse Patients"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
