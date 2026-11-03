import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/shimmer_widgets/patient_appointments_shimmer.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import '../patient_over_view_bloc/patient_over_view_bloc.dart';
import '../../patient/diet/diet_ui.dart';
import '../widgets/patient_appointments_card.dart';
import '../widgets/record_tab_ui.dart';
import '../../../../core/utils/display_format.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  final PatientProfileEntity patient;
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;
  final VoidCallback onPrescribeTap;
  final VoidCallback onNoteTap;
  final bool isTab;
  final bool hasAccess;

  const PatientAppointmentsScreen({
    super.key,
    required this.patient,
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
    required this.onPrescribeTap,
    required this.onNoteTap,
    required this.isTab,
    this.hasAccess = true,
  });

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  String _activeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    final String pid = widget.patientId ?? widget.patient.id.toString();
    context.read<PatientOverViewBloc>().add(LoadPatientData(
          pid,
          orgId: widget.orgId,
          hospitalId: widget.hospitalId,
        ));
  }

  List<PatientAppointmentEntity> _getBaseAppointments(List<PatientAppointmentEntity> all) {
    if (widget.hasAccess) {
      return all;
    }
    // Without consent: only show treated / completed appointments or appointments belonging to this doctor
    final currentDoctorId =
        GlobalSession.instance.userNotifier.value?.data?.id?.toString().trim() ?? '';

    return all.where((a) {
      final s = a.status.toLowerCase().trim();
      final isTreated = s == 'completed' || s == 'treated';
      final isThisDoctor = currentDoctorId.isNotEmpty && a.doctorId.trim() == currentDoctorId;
      final hasClinicalRecords = a.prescriptions.isNotEmpty ||
          a.medicalRecords.isNotEmpty ||
          a.clinicalNotes.isNotEmpty;
      return isTreated || isThisDoctor || hasClinicalRecords;
    }).toList();
  }

  List<PatientAppointmentEntity> _filterAppointments(List<PatientAppointmentEntity> baseList) {
    if (_activeFilter == 'All') return baseList;
    final target = statusKey(_activeFilter);
    return baseList.where((a) => statusKey(a.status) == target).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primaryColor = DietUi.blue;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocConsumer<PatientOverViewBloc, PatientOverViewState>(
        listener: (context, state) {},
        builder: (context, state) {
          if (state is LoadingPatientViewDetails) {
            return PatientAppointmentsShimmer(
              isTab: widget.isTab,
              itemCount: 4,
            );
          }

          if (state is LoadPatientDataFailureState) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RecordEmptyState(icon: Icons.wifi_off_rounded, title: "Unable to Load", message: state.error),
                  const SizedBox(height: 16),
                  RecordPrimaryButton(label: 'Retry', icon: Icons.refresh_rounded, compact: true, onPressed: _loadAppointments),
                ],
              ),
            );
          }

          final List<PatientAppointmentEntity> allAppointments = (state is LoadPatientDataState)
              ? (state.patientOverViewEntity.data?.appointments ?? <PatientAppointmentEntity>[])
              : <PatientAppointmentEntity>[];

          final baseAppointments = _getBaseAppointments(allAppointments);
          final filteredAppointments = _filterAppointments(baseAppointments);

          // Build dynamic filter chip data
          final Map<String, int> statusCounts = {};
          final Map<String, String> statusLabels = {};
          for (final a in baseAppointments) {
            final key = statusKey(a.status);
            statusCounts[key] = (statusCounts[key] ?? 0) + 1;
            statusLabels.putIfAbsent(key, () => humanizeStatus(a.status));
          }

          return RefreshIndicator.adaptive(
            onRefresh: () async => _loadAppointments(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(
                horizontal: screenHorizontalSpacePadding,
                vertical: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Consent Restricted Notice Banner
                  if (!widget.hasAccess)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: RecordUi.soft(isDark), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 18, color: Color(0xFFD97706)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Showing treated appointments only. Patient consent is required to view complete appointment history.",
                              style: DietUi.text(11.5, FontWeight.w500, DietUi.body(isDark), height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Filter Chips Row ──
                  if (baseAppointments.isNotEmpty) ...[
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildFilterChip(
                            label: "All",
                            count: baseAppointments.length,
                            isActive: _activeFilter == 'All',
                            primaryColor: primaryColor,
                            isDark: isDark,
                            onTap: () => setState(() => _activeFilter = 'All'),
                          ),
                          ...statusCounts.entries.map((entry) {
                            final statusLabel = statusLabels[entry.key] ?? entry.key;
                            return _buildFilterChip(
                              label: statusLabel,
                              count: entry.value,
                              isActive: statusKey(_activeFilter) == entry.key,
                              primaryColor: primaryColor,
                              isDark: isDark,
                              onTap: () => setState(() => _activeFilter = statusLabel),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // ── Results Count ──
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 4),
                      child: Text(
                        "${filteredAppointments.length} ${filteredAppointments.length == 1 ? 'appointment' : 'appointments'}",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],

                  // ── Empty State when no treated appointments ──
                  if (filteredAppointments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: RecordEmptyState(
                        icon: Icons.event_busy_outlined,
                        title: !widget.hasAccess ? "No Treated Appointments Found" : "No Appointments Found",
                        message: !widget.hasAccess
                            ? "No treated records available for this patient. Patient consent is required to access full appointment history."
                            : "There are no appointments registered for this patient.",
                      ),
                    )
                  else
                    // ── Appointment Cards ──
                    PatientAppointmentsCard(
                      appointments: filteredAppointments,
                      isTab: widget.isTab,
                      patient: widget.patient,
                      onPrescribeTap: widget.onPrescribeTap,
                      onNoteTap: widget.onNoteTap,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isActive,
    required Color primaryColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? primaryColor.withValues(alpha: isDark ? 0.2 : 0.1)
                : (isDark ? const Color(0xFF232323) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? primaryColor
                  : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0)),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? primaryColor
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.15)
                      : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "$count",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? primaryColor
                        : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
