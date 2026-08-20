import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/consent/patient_access_consent_entity.dart';
import 'bloc/patient_access_consent_bloc.dart';
import 'bloc/patient_access_consent_event.dart';
import 'bloc/patient_access_consent_state.dart';

class PatientConsentApprovalScreen extends StatefulWidget {
  final String? patientId;

  const PatientConsentApprovalScreen({
    super.key,
    this.patientId,
  });

  @override
  State<PatientConsentApprovalScreen> createState() => _PatientConsentApprovalScreenState();
}

class _PatientConsentApprovalScreenState extends State<PatientConsentApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PatientAccessConsentBloc _consentBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final targetPatientId = widget.patientId ??
        GlobalSession.instance.userNotifier.value?.data?.id ??
        '';

    _consentBloc = sl<PatientAccessConsentBloc>()
      ..add(LoadPatientConsentsEvent(patientId: targetPatientId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _consentBloc.close();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return "N/A";
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
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
          showBackButton: true,
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
          child: BlocBuilder<PatientAccessConsentBloc, PatientAccessConsentState>(
            builder: (context, state) {
              if (state is PatientAccessConsentLoading) {
                return const ListCardShimmer(itemCount: 4);
              }

              if (state is PatientAccessConsentError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                        const SizedBox(height: 12),
                        Text(
                          "Failed to load consent requests",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () {
                            _consentBloc.add(LoadPatientConsentsEvent(patientId: currentPatientId));
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text("Retry"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is PatientConsentsListLoaded) {
                final pending = state.pendingConsents;
                final active = state.activeConsents;
                final history = state.historyConsents;

                return Column(
                  children: [
                    // Segmented Tab Bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2538) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200,
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                        labelStyle: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 13.5 : 12,
                          fontWeight: FontWeight.w700,
                        ),
                        tabs: [
                          Tab(text: "Pending (${pending.length})"),
                          Tab(text: "Active (${active.length})"),
                          Tab(text: "History (${history.length})"),
                        ],
                      ),
                    ),

                    // Tab View
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // 1. Pending Tab
                          _buildPendingList(pending, isDark, primaryColor, isTab, currentPatientId),
                          // 2. Active Tab
                          _buildActiveList(active, isDark, primaryColor, isTab, currentPatientId),
                          // 3. History Tab
                          _buildHistoryList(history, isDark, primaryColor, isTab),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return const ListCardShimmer(itemCount: 4);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPendingList(
    List<PatientAccessConsentEntity> list,
    bool isDark,
    Color primaryColor,
    bool isTab,
    String currentPatientId,
  ) {
    if (list.isEmpty) {
      return _buildEmptyView(
        icon: Icons.check_circle_outline_rounded,
        title: "No Pending Consent Requests",
        subtitle: "When doctors request access to view your complete medical records, their requests will appear here for your approval.",
        isDark: isDark,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2234) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.orange.withOpacity(isDark ? 0.35 : 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Header Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: primaryColor.withOpacity(0.15),
                    child: Icon(Icons.medical_services_rounded, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.doctorName ?? "Dr. Healthcare Provider",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 16 : 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${item.specialty ?? 'General Medicine'} • ${item.hospitalName ?? 'Clinical Care'}",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 12.5 : 11.5,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Pending",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Request Details Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B2B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Requested Access Duration:",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          item.durationLabel ?? "1 Day",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Requested On:",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _formatDate(item.requestedAt),
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Approve / Reject Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (item.id != null) {
                          _consentBloc.add(RespondToConsentEvent(
                            consentId: item.id!,
                            patientId: currentPatientId,
                            action: 'REJECT',
                          ));
                        }
                      },
                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                      label: const Text(
                        "Reject",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.red.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (item.id != null) {
                          _consentBloc.add(RespondToConsentEvent(
                            consentId: item.id!,
                            patientId: currentPatientId,
                            action: 'APPROVE',
                          ));
                        }
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        "Approve",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveList(
    List<PatientAccessConsentEntity> list,
    bool isDark,
    Color primaryColor,
    bool isTab,
    String currentPatientId,
  ) {
    if (list.isEmpty) {
      return _buildEmptyView(
        icon: Icons.shield_outlined,
        title: "No Active Access Permissions",
        subtitle: "No doctors currently have approved access to your complete medical records.",
        isDark: isDark,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2234) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(isDark ? 0.35 : 0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.doctorName ?? "Dr. Healthcare Provider",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "${item.specialty ?? 'General Practice'} • ${item.hospitalName ?? 'Hospital'}",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Active",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Access Validity Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161B2B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Access Valid Until:",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      item.expiresAt != null ? _formatDate(item.expiresAt) : "Permanent (Until Revoked)",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Revoke Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    if (item.id != null) {
                      _consentBloc.add(RespondToConsentEvent(
                        consentId: item.id!,
                        patientId: currentPatientId,
                        action: 'REVOKE',
                      ));
                    }
                  },
                  icon: const Icon(Icons.block_rounded, size: 16, color: Colors.red),
                  label: const Text(
                    "Revoke Access Permission",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: Colors.red.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(
    List<PatientAccessConsentEntity> list,
    bool isDark,
    Color primaryColor,
    bool isTab,
  ) {
    if (list.isEmpty) {
      return _buildEmptyView(
        icon: Icons.history_rounded,
        title: "No Consent History",
        subtitle: "Past expired, declined, and revoked access logs will be archived here.",
        isDark: isDark,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = list[index];
        final isRejected = item.isRejected;
        final isExpired = item.isExpired;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2234) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: (isRejected ? Colors.red : Colors.grey).withOpacity(0.15),
                child: Icon(
                  isRejected ? Icons.cancel_outlined : Icons.timer_off_outlined,
                  color: isRejected ? Colors.red : Colors.grey,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.doctorName ?? "Doctor Access",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "${item.durationLabel ?? 'Duration'} • ${_formatDate(item.requestedAt)}",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isRejected ? Colors.red : Colors.grey).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status ?? (isExpired ? "Expired" : "Closed"),
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isRejected ? Colors.red : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyView({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: isDark ? Colors.white38 : Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0A2540),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12.5,
                height: 1.5,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
