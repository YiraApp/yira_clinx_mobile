import 'package:yiraclinics/core/custom_dialogue/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/medical_record_card.dart';
import 'package:yiraclinics/features/presentation/medicine/create_medicine_screen.dart';
import 'package:yiraclinics/features/presentation/medicine/medical_record_bloc/medical_record_bloc.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import '../../../../core/constants/constants.dart';
import 'package:yiraclinics/features/domain/entities/medicine/medical_history_entity.dart';
import 'package:yiraclinics/features/domain/entities/patient_profile/patient_profile_entity.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import 'medical_history_bloc/medical_history_bloc.dart';

class MedicalRecordsListScreen extends StatefulWidget {
  final PatientProfileEntity? patient;
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;
  final bool allowAdd;

  const MedicalRecordsListScreen({
    super.key,
    this.patient,
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
    this.allowAdd = true,
  });

  @override
  State<MedicalRecordsListScreen> createState() =>
      _MedicalRecordsListScreenState();
}

class _MedicalRecordsListScreenState extends State<MedicalRecordsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MedicalHistoryBloc>().add(LoadMedicalHistoryRecords(
          patientId: widget.patientId ?? widget.patient?.id,
          appointmentId: widget.appointmentId,
          hospitalId: widget.hospitalId,
          orgId: widget.orgId,
        ));
  }

  void _refreshRecords() {
    context.read<MedicalHistoryBloc>().add(LoadMedicalHistoryRecords(
          patientId: widget.patientId ?? widget.patient?.id,
          appointmentId: widget.appointmentId,
          hospitalId: widget.hospitalId,
          orgId: widget.orgId,
        ));
  }

  void _openRecordFormModal([MedicalRecordBriefEntity? recordToEdit]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BlocProvider<MedicalRecordBloc>(
          create: (_) => sl<MedicalRecordBloc>(),
          child: CreateMedicalRecordScreen(
            patient: widget.patient,
            recordToEdit: recordToEdit,
            patientId: widget.patientId ?? widget.patient?.id,
            appointmentId: widget.appointmentId,
            hospitalId: widget.hospitalId,
            orgId: widget.orgId,
          ),
        ),
      ),
    ).then((_) {
      if (context.mounted) {
        _refreshRecords();
      }
    });
  }

  void _confirmDeleteRecord(MedicalRecordBriefEntity item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: "Delete Medical Record?",
        message: "Are you sure you want to delete this medical record? This action is permanent and cannot be undone.",
        tone: AppDialogTone.danger,
        icon: Icons.delete_forever_rounded,
        primaryLabel: "Delete",
        onPrimary: () {
          Navigator.pop(dialogContext);
          context.read<MedicalHistoryBloc>().add(
            DeleteMedicalHistoryRecord(item.id),
          );
        },
        secondaryLabel: "Cancel",
        onSecondary: () => Navigator.pop(dialogContext),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTab = isTablet(context);
    return BlocConsumer<MedicalHistoryBloc, MedicalHistoryState>(
      buildWhen: (previous, current) =>
          current is MedicalHistoryLoading ||
          current is MedicalHistoryError ||
          current is MedicalHistoryLoaded,
      listenWhen: (previous, current) =>
          current is AddMedicalRecordNavState ||
          current is SingleMedicineDetailsNavState,
      listener: (BuildContext context, MedicalHistoryState state) {
        if (state is AddMedicalRecordNavState) {
          _openRecordFormModal();
        } else if (state is SingleMedicineDetailsNavState) {
          Navigator.pushNamed(
            context,
            AppRoutes.medicalRecordDetailsScreen,
            arguments: state.record,
          );
        }
      },
      builder: (context, state) {
        final bool isPatient =
            GlobalSession.instance.userNotifier.value?.data?.navigationId == "1";

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          floatingActionButton: (isPatient || !widget.allowAdd)
              ? null
              : FloatingActionButton(
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    context.read<MedicalHistoryBloc>().add(
                          AddMedicalRecordNavEvent(),
                        );
                  },
                ),
          body: _buildBody(context, state, isTab, isPatient),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, MedicalHistoryState state, bool isTab, bool isPatient) {
    if (state is MedicalHistoryLoading) {
      return MedicalRecordListShimmer(itemCount: 4, isTab: isTab);
    }

    if (state is MedicalHistoryError) {
      return Center(child: CommonText(state.message));
    }

    if (state is MedicalHistoryLoaded) {
      if (state.records.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const CommonText("No medical records history found."),
            ],
          ),
        );
      }
      return ListView.builder(
        padding: const EdgeInsets.only(
          left: screenHorizontalSpacePadding,
          right: screenHorizontalSpacePadding,
          bottom: 80,
        ),
        itemCount: state.records.length,
        itemBuilder: (context, index) {
          final item = state.records[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: fieldSpace),
            child: MedicalRecordCard(
              isTab: isTab,
              title: item.title,
              formattedDate: DateFormat(
                'MMMM dd, yyyy',
              ).format(item.recordDate),
              doctorName: item.doctorName,
              status: item.status,
              chiefComplaint: item.chiefComplaint,
              diagnosis: item.diagnosis,
              vitalsSummary: item.vitalsSummary,
              onDetailsPressed: () {
                context.read<MedicalHistoryBloc>().add(
                  SingleMedicineDetailsNavEvent(recordId: item.id, record: item),
                );
              },
              onDeletePressed: (isPatient || !widget.allowAdd) ? null : () => _confirmDeleteRecord(item),
              onEditPressed: (isPatient || !widget.allowAdd) ? null : () => _openRecordFormModal(item),
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
