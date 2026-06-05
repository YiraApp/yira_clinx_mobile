import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/medical_record_card.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/medical_record_tab.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import 'medical_history_bloc/medical_history_bloc.dart';

class MedicalRecordsListScreen extends StatefulWidget {
  const MedicalRecordsListScreen({super.key});

  @override
  State<MedicalRecordsListScreen> createState() =>
      _MedicalRecordsListScreenState();
}

class _MedicalRecordsListScreenState extends State<MedicalRecordsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MedicalHistoryBloc>().add(LoadMedicalHistoryRecords());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<MedicalHistoryBloc, MedicalHistoryState>(
      buildWhen: (previous, current) => current is! AddMedicalRecordNavState || current is SingleMedicineDetailsNavState,
      listener: (BuildContext context, MedicalHistoryState state) {
        if (state is AddMedicalRecordNavState) {
          Navigator.pushNamed(context, AppRoutes.addPrescriptionScreen);
        } else if(state is SingleMedicineDetailsNavState){
          Navigator.pushNamed(context, AppRoutes.medicalRecordDetailsScreen);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          floatingActionButton: state is MedicalHistoryLoaded
              ? MedicalRecordFab(
                  onAddRecordTapped: () {
                    context.read<MedicalHistoryBloc>().add(
                      AddMedicalRecordNavEvent(),
                    );
                  },
                )
              : null,
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, MedicalHistoryState state) {
    if (state is MedicalHistoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is MedicalHistoryError) {
      return Center(child: CommonText(state.message));
    }

    if (state is MedicalHistoryLoaded) {
      if (state.records.isEmpty) {
        return const Center(
          child: CommonText("No medical records history found."),
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
            padding: const EdgeInsets.only(bottom: 20.0),
            child: MedicalRecordCard(
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
                  SingleMedicineDetailsNavEvent(),
                );
              },
              onDeletePressed: () {
                context.read<MedicalHistoryBloc>().add(
                  DeleteMedicalHistoryRecord(item.id),
                );
              },
              onEditPressed: () {},
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
