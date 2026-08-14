import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_contact_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_medical_card.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_summary_card.dart';

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
    final String pid = widget.patientId ?? widget.patient.id?.toString() ?? '';
    context.read<PatientOverViewBloc>().add(LoadPatientData(
          pid,
          orgId: widget.orgId,
          hospitalId: widget.hospitalId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<PatientOverViewBloc, PatientOverViewState>(
        listener: (context, state) {

        },
        builder: (context, state) {
          if (state is LoadingPatientViewDetails) {
            return const PatientOverviewShimmer();
          }

          if (state is LoadPatientDataFailureState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      state.error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadPatientData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
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
                child: Column(
                  children: [
                    // Safe parsing: Only display cards if the model data exists
                    if (fetchedData.contactInformation != null)
                      PatientContactCard(patient: fetchedData.contactInformation!, isTab: widget.isTab),

                    if (fetchedData.medicalInformation != null)
                      PatientMedicalCard(patient: fetchedData.medicalInformation!, isTab: widget.isTab),

                    if (fetchedData.summary != null && fetchedData.summary!.isNotEmpty)
                      PatientSummaryCard(summary: fetchedData.summary!, isTab: widget.isTab),

                    const SizedBox(height: 80),
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