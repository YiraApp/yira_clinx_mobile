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

  const MedicalRecordsListScreen({
    super.key,
    this.patient,
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BlocProvider<MedicalRecordBloc>(
            create: (_) => sl<MedicalRecordBloc>(),
            child: Scaffold(
              body: CreateMedicalRecordScreen(
                patient: widget.patient,
                recordToEdit: recordToEdit,
                patientId: widget.patientId ?? widget.patient?.id,
                appointmentId: widget.appointmentId,
                hospitalId: widget.hospitalId,
                orgId: widget.orgId,
              ),
            ),
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
                  color: Colors.red.withValues(alpha: 0.1),
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
                "Delete Medical Record?",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              CommonText(
                "Are you sure you want to delete this medical record? This action is permanent and cannot be undone.",
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
                        context.read<MedicalHistoryBloc>().add(
                          DeleteMedicalHistoryRecord(item.id),
                        );
                      },
                      child: const CommonText(
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
          floatingActionButton: isPatient
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
              onDeletePressed: isPatient ? null : () => _confirmDeleteRecord(item),
              onEditPressed: isPatient ? null : () => _openRecordFormModal(item),
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
