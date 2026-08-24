import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/shimmer_widgets/patient_appointments_shimmer.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import '../patient_over_view_bloc/patient_over_view_bloc.dart';
import '../widgets/patient_appointments_card.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  final PatientProfileEntity patient;
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;
  final VoidCallback onPrescribeTap;
  final VoidCallback onNoteTap;
  final bool isTab;

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

  List<PatientAppointmentEntity> _filterAppointments(List<PatientAppointmentEntity> all) {
    if (_activeFilter == 'All') return all;
    return all.where((a) => a.status.toUpperCase() == _activeFilter.toUpperCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

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
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.red.shade400.withValues(alpha: 0.15),
                            Colors.red.shade600.withValues(alpha: 0.08),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.wifi_off_rounded,
                        size: 32,
                        color: Colors.red.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Unable to Load",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          elevation: 0,
                        ),
                        onPressed: _loadAppointments,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text(
                          'Retry',
                          style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<PatientAppointmentEntity> allAppointments = (state is LoadPatientDataState)
              ? (state.patientOverViewEntity.data?.appointments ?? <PatientAppointmentEntity>[])
              : <PatientAppointmentEntity>[];

          final filteredAppointments = _filterAppointments(allAppointments);

          // Build dynamic filter chip data
          final Map<String, int> statusCounts = {};
          for (final a in allAppointments) {
            final key = a.status.toUpperCase();
            statusCounts[key] = (statusCounts[key] ?? 0) + 1;
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
                  // ── Filter Chips Row ──
                  if (allAppointments.isNotEmpty) ...[
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildFilterChip(
                            label: "All",
                            count: allAppointments.length,
                            isActive: _activeFilter == 'All',
                            primaryColor: primaryColor,
                            isDark: isDark,
                            onTap: () => setState(() => _activeFilter = 'All'),
                          ),
                          ...statusCounts.entries.map((entry) {
                            final statusLabel = _capitalizeStatus(entry.key);
                            return _buildFilterChip(
                              label: statusLabel,
                              count: entry.value,
                              isActive: _activeFilter.toUpperCase() == entry.key,
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

  String _capitalizeStatus(String status) {
    if (status.isEmpty) return status;
    final words = status.split(RegExp(r'[_ ]'));
    return words.map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
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
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? primaryColor
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
