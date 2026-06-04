import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/medical_record_card.dart';
import 'package:yiraclinics/features/presentation/medicine/widgets/medical_record_tab.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../patient_profile/widgets/add_records_buttons.dart';
import 'medical_history_bloc/medical_history_bloc.dart';


class MedicalRecordsListScreen extends StatefulWidget {
  const MedicalRecordsListScreen({super.key});

  @override
  State<MedicalRecordsListScreen> createState() => _MedicalRecordsListScreenState();
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
    final bool isTab = isTablet(context);

    return Scaffold(
      floatingActionButton:MedicalRecordFab( onAddRecordTapped: () {  },

      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      /*appBar: PreferredSize(
        preferredSize: Size.fromHeight(isTablet(context) ? 68.0 : 30.0),
        child: AppBar(
          title: CommonText(
            "Medical Records",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: displayWidth(context) * 0.035,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),*/
      body: BlocBuilder<MedicalHistoryBloc, MedicalHistoryState>(
        builder: (context, state) {
          if (state is MedicalHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MedicalHistoryError) {
            return Center(child: CommonText(state.message));
          } else if (state is MedicalHistoryLoaded) {
            if (state.records.isEmpty) {
              return const Center(child: CommonText("No medical records history found."));
            }
            return ListView.builder(
              padding: const EdgeInsets.only(left: screenHorizontalSpacePadding,right: screenHorizontalSpacePadding,bottom: 60),
              itemCount: state.records.length,
              itemBuilder: (context, index) {
                final item = state.records[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: MedicalRecordCard(

                    title: item.title,
                    formattedDate: DateFormat('MMMM dd, yyyy').format(item.recordDate),
                    doctorName: item.doctorName,
                    status: item.status,
                    chiefComplaint: item.chiefComplaint,
                    diagnosis: item.diagnosis,
                    vitalsSummary: item.vitalsSummary,
                    onDetailsPressed: () {
                    },
                    onDeletePressed: () {
                      context.read<MedicalHistoryBloc>().add(DeleteMedicalHistoryRecord(item.id));
                    },
                    onEditPressed: (){},
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),

    );
  }
}