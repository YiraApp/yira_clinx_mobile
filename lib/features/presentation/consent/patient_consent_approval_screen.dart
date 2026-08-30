import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/consent/patient_access_consent_entity.dart';
import 'package:yiraclinics/core/tour/patient_tour_controller.dart';
import 'bloc/patient_access_consent_bloc.dart';
import 'bloc/patient_access_consent_event.dart';
import 'bloc/patient_access_consent_state.dart';

class PatientConsentApprovalScreen extends StatefulWidget {
  final String? patientId;
  final bool showBackButton;

  const PatientConsentApprovalScreen({
    super.key,
    this.patientId,
    this.showBackButton = true,
  });

  @override
  State<PatientConsentApprovalScreen> createState() => _PatientConsentApprovalScreenState();
}

class _PatientConsentApprovalScreenState extends State<PatientConsentApprovalScreen> {
  late PatientAccessConsentBloc _consentBloc;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Button-level loading indicator tracker
  int? _processingConsentId;
  String? _processingAction;

  @override
  void initState() {
    super.initState();
    final targetPatientId = widget.patientId ??
        GlobalSession.instance.userNotifier.value?.data?.id ??
        '';

    _consentBloc = sl<PatientAccessConsentBloc>()
      ..add(LoadPatientConsentsEvent(patientId: targetPatientId));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _consentBloc.close();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return "N/A";
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
  }

  String _getInitials(String name) {
    final clean = name.replaceAll(RegExp(r'^Dr\.\s*|^Dr\s*', caseSensitive: false), '').trim();
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'DR';
    if (parts.length > 1) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].length > 1 ? parts[0].substring(0, 2).toUpperCase() : parts[0].toUpperCase();
  }

  void _respondToConsent(int? consentId, String action, String patientId) {
    if (consentId == null) return;
    setState(() {
      _processingConsentId = consentId;
      _processingAction = action;
    });
    _consentBloc.add(RespondToConsentEvent(
      consentId: consentId,
      patientId: patientId,
      action: action,
    ));
  }

  void _showGrantConfirmationDialog(
    BuildContext context,
    PatientAccessConsentEntity item,
    String patientId,
  ) {
    final doctorName = item.doctorName ?? 'Doctor';
    final duration = item.durationLabel ?? '7 Days';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Grant Record Access",
                style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to authorize $doctorName to access your medical records?",
              style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: Color(0xFF059669)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Access Duration: $duration\nScope: Vitals, Prescriptions, Lab Records",
                      style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: const Text("Cancel", style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _respondToConsent(item.id, "APPROVE", patientId);
            },
            child: const Text("Grant Access", style: TextStyle(fontFamily: appPoppinFont, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDenyConfirmationDialog(
    BuildContext context,
    PatientAccessConsentEntity item,
    String patientId,
  ) {
    final doctorName = item.doctorName ?? 'Doctor';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.block_rounded, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Deny Access Request",
                style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to decline $doctorName's request to view your medical history? The doctor will not be able to view past records.",
          style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: const Text("Cancel", style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _respondToConsent(item.id, "REJECT", patientId);
            },
            child: const Text("Deny Request", style: TextStyle(fontFamily: appPoppinFont, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRevokeConfirmationDialog(
    BuildContext context,
    PatientAccessConsentEntity item,
    String patientId,
  ) {
    final doctorName = item.doctorName ?? 'this provider';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_reset_rounded, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Revoke Record Access",
                style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to revoke medical record access for $doctorName? They will immediately lose access to your past medical history.",
          style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
            child: const Text("Cancel", style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              _respondToConsent(item.id, "REVOKE", patientId);
            },
            child: const Text("Revoke Access", style: TextStyle(fontFamily: appPoppinFont, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    final currentPatientId = widget.patientId ??
        GlobalSession.instance.userNotifier.value?.data?.id ??
        '';

    return BlocProvider.value(
      value: _consentBloc,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: CommonAppBar(
          titleText: "Medical Record Consents",
          showBackButton: widget.showBackButton,
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: isDark ? Colors.white : Colors.black87,
              ),
              tooltip: "Refresh Consents",
              onPressed: () {
                _consentBloc.add(LoadPatientConsentsEvent(patientId: currentPatientId));
              },
            ),
          ],
        ),
        body: SafeArea(
          child: BlocConsumer<PatientAccessConsentBloc, PatientAccessConsentState>(
            listener: (context, state) {
              if (state is PatientAccessConsentError) {
                setState(() {
                  _processingConsentId = null;
                  _processingAction = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } else if (state is PatientConsentsListLoaded) {
                setState(() {
                  _processingConsentId = null;
                  _processingAction = null;
                });
              }
            },
            builder: (context, state) {
              if (state is PatientAccessConsentLoading && _processingConsentId == null) {
                return _buildLoadingShimmer(isDark, primaryColor);
              }

              List<PatientAccessConsentEntity> allConsents = [];
              if (state is PatientConsentsListLoaded) {
                allConsents = state.consents;
              }

              final pendingCount = allConsents.where((c) => (c.status ?? '').toUpperCase() == 'PENDING').length;
              final approvedCount = allConsents.where((c) => (c.status ?? '').toUpperCase() == 'APPROVED').length;

              List<PatientAccessConsentEntity> filteredConsents = allConsents.where((c) {
                final q = _searchQuery.toLowerCase();
                final matchesSearch = (c.doctorName ?? '').toLowerCase().contains(q) ||
                    (c.hospitalName ?? '').toLowerCase().contains(q) ||
                    (c.specialty ?? '').toLowerCase().contains(q);

                if (!matchesSearch) return false;

                final status = (c.status ?? '').toUpperCase();
                if (_selectedFilter == 'Pending') {
                  return status == 'PENDING';
                } else if (_selectedFilter == 'Approved') {
                  return status == 'APPROVED';
                } else if (_selectedFilter == 'History') {
                  return status != 'PENDING' && status != 'APPROVED';
                }
                return true;
              }).toList();

              return Column(
                children: [
                  // Search Field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(screenHorizontalSpacePadding, 10, screenHorizontalSpacePadding, 10),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'Search doctor, hospital, or specialty...',
                        hintStyle: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: isDark ? Colors.white38 : Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white54 : Colors.grey.shade500),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                  ),

                  // Filter Chips with Badge Counts
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
                      children: [
                        _buildFilterChip('All', allConsents.length, isDark, primaryColor),
                        _buildFilterChip('Pending', pendingCount, isDark, primaryColor, badgeColor: Colors.orange),
                        _buildFilterChip('Approved', approvedCount, isDark, primaryColor, badgeColor: const Color(0xFF059669)),
                        _buildFilterChip('History', allConsents.length - pendingCount - approvedCount, isDark, primaryColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Consent Cards List
                  Expanded(
                    key: PatientTourController().consentsListKey,
                    child: RefreshIndicator(
                      onRefresh: () async {
                        _consentBloc.add(LoadPatientConsentsEvent(patientId: currentPatientId));
                        await Future.delayed(const Duration(milliseconds: 600));
                      },
                      child: filteredConsents.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(22),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.verified_user_outlined,
                                          size: isTab ? 64 : 52,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        "No Consent Requests Found",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isTab ? 18 : 16,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'No requests matching "$_searchQuery"'
                                            : 'When doctors request access to view your medical history, they will appear here for your approval.',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: isTab ? 13.5 : 12.5,
                                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: screenHorizontalSpacePadding,
                                vertical: 6,
                              ),
                              itemCount: filteredConsents.length,
                              itemBuilder: (context, index) {
                                final item = filteredConsents[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14.0),
                                  child: _buildConsentCard(
                                    context: context,
                                    item: item,
                                    isDark: isDark,
                                    primaryColor: primaryColor,
                                    isTab: isTab,
                                    patientId: currentPatientId,
                                  ),
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
    );
  }

  Widget _buildFilterChip(
    String filter,
    int count,
    bool isDark,
    Color primaryColor, {
    Color? badgeColor,
  }) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filter,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (badgeColor ?? primaryColor).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (badgeColor ?? primaryColor),
                  ),
                ),
              ),
            ],
          ],
        ),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedFilter = filter),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        selectedColor: primaryColor,
        checkmarkColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected ? primaryColor : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildConsentCard({
    required BuildContext context,
    required PatientAccessConsentEntity item,
    required bool isDark,
    required Color primaryColor,
    required bool isTab,
    required String patientId,
  }) {
    final status = (item.status ?? 'PENDING').toUpperCase();
    final isPending = status == 'PENDING';
    final isApproved = status == 'APPROVED';
    final isRevoked = status == 'REVOKED';

    final Color statusColor = isPending
        ? Colors.orange
        : isApproved
            ? const Color(0xFF059669)
            : isRevoked
                ? Colors.redAccent
                : const Color(0xFF64748B);

    final statusBg = statusColor.withValues(alpha: isDark ? 0.18 : 0.1);
    final doctorName = item.doctorName ?? 'Healthcare Provider';
    final initials = _getInitials(doctorName);
    final isThisItemProcessing = _processingConsentId == item.id;

    return Container(
      padding: EdgeInsets.all(isTab ? 18 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPending
              ? Colors.orange.withValues(alpha: 0.45)
              : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isPending
                ? Colors.orange.withValues(alpha: isDark ? 0.08 : 0.05)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with initials
              Container(
                width: isTab ? 48 : 42,
                height: isTab ? 48 : 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withValues(alpha: 0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Specialty
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 15.5 : 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.specialty ?? 'Specialist Physician',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hospital / Facility & Duration Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.local_hospital_rounded, size: 15, color: primaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.hospitalName ?? 'Yira Clinx Medical Center',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.durationLabel ?? 'Duration: 7 Days',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Date Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 13, color: isDark ? Colors.white38 : Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Requested: ${_formatDate(item.requestedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (item.expiresAt != null && isApproved) ...[
                const SizedBox(width: 8),
                Text(
                  'Expires: ${DateFormat('MMM dd, yyyy').format(item.expiresAt!)}',
                  style: const TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ],
          ),

          if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Note: ${item.notes}',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11.5,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ),
          ],

          // Action Buttons with Confirmation Dialogs & Inside-Button Spinners
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                // Deny Button
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.7)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: isThisItemProcessing
                        ? null
                        : () => _showDenyConfirmationDialog(context, item, patientId),
                    child: (isThisItemProcessing && _processingAction == 'REJECT')
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                          )
                        : const Text(
                            'Deny Access',
                            style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                  ),
                ),
                const SizedBox(width: 10),

                // Grant Button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: isThisItemProcessing
                        ? null
                        : () => _showGrantConfirmationDialog(context, item, patientId),
                    child: (isThisItemProcessing && _processingAction == 'APPROVE')
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Grant Access',
                            style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12.5),
                          ),
                  ),
                ),
              ],
            ),
          ] else if (isApproved) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isThisItemProcessing
                    ? null
                    : () => _showRevokeConfirmationDialog(context, item, patientId),
                icon: (isThisItemProcessing && _processingAction == 'REVOKE')
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                      )
                    : const Icon(Icons.block_rounded, size: 16),
                label: Text(
                  (isThisItemProcessing && _processingAction == 'REVOKE') ? 'Revoking Access...' : 'Revoke Doctor Access',
                  style: const TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark, Color primaryColor) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 12),
      itemCount: 3,
      itemBuilder: (_, index) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 90,
                        height: 11,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 32,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
