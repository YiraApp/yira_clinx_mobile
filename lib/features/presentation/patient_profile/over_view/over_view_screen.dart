import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_contact_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_medical_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_summary_card.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/shimmer_widgets/over_view_shimmer_card.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import '../patient_over_view_bloc/patient_over_view_bloc.dart';

class OverviewScreen extends StatefulWidget {
  final PatientProfileEntity patient;
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;
  final VoidCallback onPrescribeTap;
  final VoidCallback onNoteTap;
  final VoidCallback onScheduleTap;
  final bool isTab;

  const OverviewScreen({
    super.key,
    required this.patient,
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
    required this.onPrescribeTap,
    required this.onNoteTap,
    required this.onScheduleTap,
    required this.isTab,
  });

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  void _loadPatientData() {
    final patientId = widget.patientId ?? widget.patient.id;
    if (patientId.isNotEmpty) {
      context.read<PatientOverViewBloc>().add(
            LoadPatientData(
              patientId,
              hospitalId: widget.hospitalId,
              orgId: widget.orgId,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<PatientOverViewBloc, PatientOverViewState>(
        builder: (context, state) {
          if (state is LoadingPatientViewDetails) {
            return const PatientOverviewShimmer();
          }

          if (state is LoadPatientDataFailureState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 12),
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        color: Colors.red.shade400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadPatientData,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text("Retry"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is LoadPatientDataState) {
            final fetchedData = state.patientOverViewEntity.data;

            if (fetchedData == null) {
              return const Center(child: Text("No data details found."));
            }

            return RefreshIndicator.adaptive(
              onRefresh: () async => _loadPatientData(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: screenHorizontalSpacePadding,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // 1. Contact Information
                    if (fetchedData.contactInformation != null)
                      PatientContactCard(patient: fetchedData.contactInformation!, isTab: widget.isTab),

                    // 2. Medical Information (Allergies, Blood Group, Visits)
                    if (fetchedData.medicalInformation != null)
                      PatientMedicalCard(patient: fetchedData.medicalInformation!, isTab: widget.isTab),

                    // 3. Clinical Summary (if present)
                    if (fetchedData.summary != null && fetchedData.summary!.isNotEmpty)
                      PatientSummaryCard(summary: fetchedData.summary!, isTab: widget.isTab),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}