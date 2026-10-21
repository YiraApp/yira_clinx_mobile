import 'package:yiraclinics/core/custom_dialogue/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/widgets/single_prescription_card.dart';
import 'package:yiraclinics/features/presentation/prescriptions/add_prescription_screen.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/common_widgets/in_app_document_viewer.dart';
import '../../../../core/api/base_api_configuration.dart';
import 'package:yiraclinics/features/domain/entities/patient_profile/patient_profile_entity.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/prescription_item.dart';

class PrescriptionListScreen extends StatelessWidget {
  final PatientProfileEntity? patient;
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;
  final bool allowAdd;

  const PrescriptionListScreen({
    super.key,
    this.patient,
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
    this.allowAdd = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isTab = isTablet(context);
    final String effectivePatientId = patientId ?? patient?.id ?? '';
    final bool isPatient = GlobalSession.instance.userNotifier.value?.data?.navigationId == "1";

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
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            final rawBaseUrl = EnvironmentService.config.accountBaseUrl;
            final baseUrl = rawBaseUrl.startsWith('http') ? rawBaseUrl : 'https://$rawBaseUrl';
            final String? directPdf = (state.pdfUrl != null && state.pdfUrl!.trim().isNotEmpty && state.pdfUrl!.trim().toLowerCase() != 'null')
                ? state.pdfUrl!.trim()
                : null;
            final presId = state.prescriptionId;
            final effectivePdfUrl = directPdf != null
                ? (directPdf.startsWith('http') ? directPdf : '$baseUrl$directPdf')
                : (presId != null && presId.isNotEmpty ? '$baseUrl/v1/api/auth/prescriptions/$presId/pdf' : '');
            final patientName = patient?.name ?? '';

            if (effectivePdfUrl.isNotEmpty) {
              InAppDocumentViewer.show(
                context,
                title: patientName.isNotEmpty ? '$patientName - Prescription' : 'Digital Prescription',
                category: 'Prescription',
                fileUrl: effectivePdfUrl,
                hospitalName: 'Yira Super Speciality Hospitals',
                isAppointmentDoc: true,
              );
            }
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
              bodyWidget = ListView(
                padding: EdgeInsets.zero,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SinglePrescriptionCard(
                    medications: validMeds,
                    date: 'Today • Clinical Consultation',
                    onEdit: (isPatient || !allowAdd)
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                fullscreenDialog: true,
                                builder: (_) => AddPrescriptionRecordScreen(
                                  patient: patient,
                                  patientId: effectivePatientId,
                                  appointmentId: appointmentId,
                                  hospitalId: hospitalId,
                                  orgId: orgId,
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
                    onDelete: (isPatient || !allowAdd)
                        ? null
                        : () {
                            _confirmDeletePrescription(context, validMeds);
                          },
                    onView: () {
                      final rawBaseUrl = EnvironmentService.config.accountBaseUrl;
                      final baseUrl = rawBaseUrl.startsWith('http') ? rawBaseUrl : 'https://$rawBaseUrl';
                      final String? directPdf = (state.pdfUrl != null && state.pdfUrl!.trim().isNotEmpty && state.pdfUrl!.trim().toLowerCase() != 'null')
                          ? state.pdfUrl!.trim()
                          : null;
                      final String? presId = (state.prescriptionId != null && state.prescriptionId!.trim().isNotEmpty)
                          ? state.prescriptionId!.trim()
                          : (appointmentId != null && appointmentId!.trim().isNotEmpty ? appointmentId!.trim() : null);

                      if (directPdf == null && presId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Prescription document is still being processed.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      final effectivePdfUrl = directPdf != null
                          ? (directPdf.startsWith('http') ? directPdf : '$baseUrl$directPdf')
                          : '$baseUrl/v1/api/auth/prescriptions/$presId/pdf';
                      final patientName = patient?.name ?? '';

                      InAppDocumentViewer.show(
                        context,
                        title: patientName.isNotEmpty ? '$patientName - Prescription' : 'Digital Prescription',
                        category: 'Prescription',
                        fileUrl: effectivePdfUrl,
                        hospitalName: 'Yira Super Speciality Hospitals',
                        isAppointmentDoc: true,
                      );
                    },
                    onPdfView: () {
                      final rawBaseUrl = EnvironmentService.config.accountBaseUrl;
                      final baseUrl = rawBaseUrl.startsWith('http') ? rawBaseUrl : 'https://$rawBaseUrl';
                      final String? directPdf = (state.pdfUrl != null && state.pdfUrl!.trim().isNotEmpty && state.pdfUrl!.trim().toLowerCase() != 'null')
                          ? state.pdfUrl!.trim()
                          : null;
                      final String? presId = (state.prescriptionId != null && state.prescriptionId!.trim().isNotEmpty)
                          ? state.prescriptionId!.trim()
                          : (appointmentId != null && appointmentId!.trim().isNotEmpty ? appointmentId!.trim() : null);

                      if (directPdf == null && presId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Prescription document is still being processed.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      final effectivePdfUrl = directPdf != null
                          ? (directPdf.startsWith('http') ? directPdf : '$baseUrl$directPdf')
                          : '$baseUrl/v1/api/auth/prescriptions/$presId/pdf';
                      final patientName = patient?.name ?? '';

                      InAppDocumentViewer.show(
                        context,
                        title: patientName.isNotEmpty ? '$patientName - Prescription' : 'Digital Prescription',
                        category: 'Prescription',
                        fileUrl: effectivePdfUrl,
                        hospitalName: 'Yira Super Speciality Hospitals',
                        isAppointmentDoc: true,
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
            floatingActionButton: (hasPrescription || isPatient || !allowAdd)
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
    showDialog(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: "Delete Prescription?",
        message: "Are you sure you want to delete this prescription? This action is permanent and cannot be undone.",
        tone: AppDialogTone.danger,
        icon: Icons.delete_forever_rounded,
        primaryLabel: "Delete",
        onPrimary: () {
          Navigator.pop(dialogContext);
          for (final med in meds) {
            context.read<PrescriptionBloc>().add(RemoveMedication(med.id));
          }
        },
        secondaryLabel: "Cancel",
        onSecondary: () => Navigator.pop(dialogContext),
      ),
    );
  }
}

