import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/single_prescription_card.dart';
import 'package:yiraclinics/features/presentation/prescriptions/add_prescription_screen.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import 'package:yiraclinics/features/domain/entities/patient_profile/patient_profile_entity.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/prescription_item.dart';

class PrescriptionListScreen extends StatelessWidget {
  final PatientProfileEntity? patient;
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;

  const PrescriptionListScreen({
    super.key,
    this.patient,
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isTab = isTablet(context);
    final String effectivePatientId = patientId ?? patient?.id ?? '';

    return BlocConsumer<PrescriptionBloc, PrescriptionState>(
        buildWhen: (previous, current) =>
        current is! AddPrescriptionRecordNavState &&
            current is! SinglePrescriptionDetailsNavState,
        listenWhen: (previous, current) =>
        current is AddPrescriptionRecordNavState ||
            current is SinglePrescriptionDetailsNavState,
        listener: (context, state) {
          debugPrint("[PrescriptionListScreen] Listener triggered with state: ${state.runtimeType}");
          if (state is AddPrescriptionRecordNavState) {
            debugPrint("[PrescriptionListScreen] Detected AddPrescriptionRecordNavState, showing modal bottom sheet...");
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => FractionallySizedBox(
                heightFactor: 0.9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AddPrescriptionRecordScreen(
                    patient: patient,
                    patientId: effectivePatientId,
                    appointmentId: appointmentId,
                    hospitalId: hospitalId,
                    orgId: orgId,
                  ),
                ),
              ),
            ).then((_) {
              debugPrint("[PrescriptionListScreen] Modal bottom sheet closed, reloading prescription data...");
              if (context.mounted) {
                context.read<PrescriptionBloc>().add(LoadPrescriptionData(
                  patientId: effectivePatientId,
                  appointmentId: appointmentId,
                  hospitalId: hospitalId,
                  orgId: orgId,
                ));
              }
            });
          } else if (state is SinglePrescriptionDetailsNavState) {
            Navigator.pushNamed(
              context,
              AppRoutes.prescriptionViewDetailsScreen,
              arguments: {
                'patientId': effectivePatientId,
                'appointmentId': appointmentId,
                'hospitalId': hospitalId,
                'orgId': orgId,
              },
            );
          }
        },
        builder: (context, state) {
          final validMeds = state.medications
              .where((m) => m.name.trim().isNotEmpty)
              .toList();
          final bool hasPrescription = validMeds.isNotEmpty;

          Widget bodyWidget;

          if (state.status == PrescriptionStatus.loading) {
            bodyWidget = PrescriptionListShimmer(itemCount: 4, isTab: isTab);
          } else {
            if (validMeds.isEmpty) {
              bodyWidget = Center(
                child: CommonText(
                  'No prescriptions records found.',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.035,
                    color: Colors.grey,
                  ),
                ),
              );
            } else {
              final firstMed = validMeds.first;
              final String cardTitle = validMeds.length > 1
                  ? '${firstMed.name} (+${validMeds.length - 1} more)'
                  : firstMed.name;
              final String cardSubtitle = validMeds.map((m) => m.name).join(', ');

              bodyWidget = ListView(
                padding: EdgeInsets.zero,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SinglePrescriptionCard(
                    title: cardTitle,
                    subtitle: cardSubtitle,
                    date: 'Today',
                    onEdit: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => FractionallySizedBox(
                          heightFactor: 0.9,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: AddPrescriptionRecordScreen(
                              patient: patient,
                              patientId: effectivePatientId,
                              appointmentId: appointmentId,
                              hospitalId: hospitalId,
                              orgId: orgId,
                            ),
                          ),
                        ),
                      ).then((_) {
                        if (context.mounted) {
                          context.read<PrescriptionBloc>().add(LoadPrescriptionData(
                            patientId: effectivePatientId,
                            appointmentId: appointmentId,
                            hospitalId: hospitalId,
                            orgId: orgId,
                          ));
                        }
                      });
                    },
                    onDelete: () {
                      _confirmDeletePrescription(context, validMeds);
                    },
                    onView: () {
                      context.read<PrescriptionBloc>().add(
                            SinglePrescriptionDetailsNavEvent(
                                prescriptionId: firstMed.id),
                          );
                    },
                    isTab: isTab,
                  ),
                ],
              );
            }
          }

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            floatingActionButton: hasPrescription
                ? null
                : FloatingActionButton(
                    backgroundColor: primaryColor,
                    child: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      debugPrint("[PrescriptionListScreen] FAB clicked, dispatching AddPrescriptionRecordNavEvent...");
                      context.read<PrescriptionBloc>().add(
                        AddPrescriptionRecordNavEvent(),
                      );
                    },
                  ),
            body: bodyWidget,
          );
        },
    );
  }

  void _confirmDeletePrescription(BuildContext context, List<MedicationItem> meds) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        backgroundColor: isDark ? darkModeCardColor : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Colors.redAccent,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              CommonText(
                "Delete Prescription?",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              CommonText(
                "Are you sure you want to delete this prescription? This action is permanent and cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(dialogContext),
                      child: CommonText(
                        "Cancel",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        for (final med in meds) {
                          context.read<PrescriptionBloc>().add(RemoveMedication(med.id));
                        }
                      },
                      child: CommonText(
                        "Delete",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

