import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/consent/patient_access_consent_entity.dart';
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

  void _respondToConsent(int? consentId, String action, String patientId) {
    if (consentId == null) return;
    _consentBloc.add(RespondToConsentEvent(
      consentId: consentId,
      patientId: patientId,
      action: action,
    ));
  }

  void _showRevokeConfirmationDialog(
    BuildContext context,
    PatientAccessConsentEntity item,
    String patientId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Revoke Record Access?",
          style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to revoke medical record access for ${item.doctorName ?? 'this provider'}? They will no longer be able to view your past medical history.",
          style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _respondToConsent(item.id, "REVOKE", patientId);
            },
            child: const Text("Revoke", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        backgroundColor: theme.scaffoldBackgroundColor,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                );
              }
            },
            builder: (context, state) {
              if (state is PatientAccessConsentLoading) {
                return _buildLoadingShimmer(isDark);
              }

              List<PatientAccessConsentEntity> allConsents = [];
              if (state is PatientConsentsListLoaded) {
                allConsents = state.consents;
              }

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
                    padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search doctor, hospital, or specialty...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Filter Chips
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
                      children: ['All', 'Pending', 'Approved', 'History'].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedFilter = filter),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            selectedColor: primaryColor,
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? primaryColor : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Consent Cards List
                  Expanded(
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
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.verified_user_outlined,
                                        size: isTab ? 80 : 64,
                                        color: theme.hintColor.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "No Consent Requests Found",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isTab ? 18 : 15,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'When doctors request access to your records, they will appear here.',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: isTab ? 14 : 12,
                                          color: theme.hintColor,
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
                                  padding: const EdgeInsets.only(bottom: 12.0),
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
                ? Colors.red
                : const Color(0xFF64748B);

    final statusBg = statusColor.withValues(alpha: isDark ? 0.2 : 0.12);

    return Container(
      padding: EdgeInsets.all(isTab ? 18 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending
              ? Colors.orange.withValues(alpha: 0.4)
              : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doctor Info & Status Badge Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: isTab ? 26 : 22,
                backgroundColor: primaryColor.withValues(alpha: 0.12),
                child: Icon(Icons.medical_services_rounded, color: primaryColor, size: isTab ? 22 : 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.doctorName ?? 'Healthcare Provider',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 16 : 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hospital / Facility Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.local_hospital_rounded, size: 14, color: primaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.hospitalName ?? 'Yira Hospitals',
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
                const SizedBox(width: 6),
                Text(
                  item.durationLabel ?? 'Duration: 7 Days',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Requested: ${_formatDate(item.requestedAt)}',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
              ),
              if (item.expiresAt != null && isApproved)
                Text(
                  'Expires: ${DateFormat('MMM dd, yyyy').format(item.expiresAt!)}',
                  style: const TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF059669),
                  ),
                ),
            ],
          ),

          if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: ${item.notes}',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11.5,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ],

          // Inline Action Buttons
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _respondToConsent(item.id, "REJECT", patientId),
                    child: const Text('Deny Access', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    onPressed: () => _respondToConsent(item.id, "APPROVE", patientId),
                    child: const Text('Grant Access', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
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
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showRevokeConfirmationDialog(context, item, patientId),
                icon: const Icon(Icons.block_rounded, size: 16),
                label: const Text('Revoke Doctor Access', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(screenHorizontalSpacePadding),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 140,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
