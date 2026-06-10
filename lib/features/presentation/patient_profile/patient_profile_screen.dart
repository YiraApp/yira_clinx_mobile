import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/appointments/appointment_bloc/appointment_bloc.dart';
import 'package:yiraclinics/features/presentation/medicine/medical_record_list_screen.dart';
import 'package:yiraclinics/features/presentation/patient_profile/clinical_notes/clinical_notes_screen.dart';
import 'package:yiraclinics/features/presentation/patient_profile/patient_profile_bloc/patient_profile_bloc.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_profile_header.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_profile_tab_bar.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_list_screen.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_records_screen.dart';
import '../../../di/dependency_injection.dart';
import '../../domain/entities/patient_profile/patient_profile_entity.dart';
import '../doctor/patient_appoinment_list/patient_appoinment_list.dart';
import '../medicine/medical_history_bloc/medical_history_bloc.dart';
import 'over_view/over_view_screen.dart';

class DoctorPatientProfileScreen extends StatefulWidget {
  const DoctorPatientProfileScreen({super.key});

  @override
  State<DoctorPatientProfileScreen> createState() =>
      _DoctorPatientProfileScreenState();
}

class _DoctorPatientProfileScreenState
    extends State<DoctorPatientProfileScreen> {
  int _activeTabIndex = 0;

  final List<String> _tabs = [
    'Overview',
    'Clinical Notes',
    'Medical Records',
    'Prescriptions',
    'Documents',
    'Appointments',
  ];
  @override
  void initState() {
    super.initState();
    context.read<PatientProfileBloc>().add(const TabChanged(0));
  }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
final bool isTab = isTablet(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CommonAppBar(
        actions: [],
      ),
      body: BlocConsumer<PatientProfileBloc, PatientProfileState>(
        listener: (BuildContext context, PatientProfileState state) {},
        builder: (context, state) {
          if (state is PatientProfileInitial) {
            context.read<PatientProfileBloc>().add(
              const LoadPatientProfile('3456'),
            );
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PatientProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PatientProfileError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  color: Colors.red,
                  fontSize: displayWidth(context) * 0.035,
                ),
              ),
            );
          }

          if (state is PatientProfileLoaded) {
            final patient = state.patient;
            final currentTab = state.activeTabIndex;

            return Column(
              children: [
                SizedBox(height: screenTopPadding,),
                PatientProfileHeader(patient: patient,isTab:isTab),
                PatientProfileTabBar(
                  tabs: _tabs,
                  selectedIndex: currentTab,
                  isTab:isTab,
                  onTabSelected: (index) {
                    context.read<PatientProfileBloc>().add(TabChanged(index));
                  },
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildActiveTabContent(context, patient, currentTab, isTab),
                  ),
                ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildActiveTabContent(
      BuildContext context,
      PatientProfileEntity patient,
      int activeTab,
      bool isTab
      ) {
    switch (activeTab) {
      case 0:
        return OverviewScreen(
          isTab: isTab,
          key: const ValueKey('OverviewTabContentFrame'),
          patient: patient,
          onPrescribeTap: () {
            context.read<PatientProfileBloc>().add(const TabChanged(3));
          },
          onNoteTap: () {
            context.read<PatientProfileBloc>().add(const TabChanged(1));
          },
          onScheduleTap: () {
            context.read<PatientProfileBloc>().add(const TabChanged(5));
          },
        );
      case 1:
        return const ClinicalNotesScreen(
          key: ValueKey('ClinicalNotesTabContentFrame'),
        );
      case 2:
        return BlocProvider<MedicalHistoryBloc>(
          create: (_) => sl<MedicalHistoryBloc>(),
          child: const MedicalRecordsListScreen(
            key: ValueKey('MedicalRecordsListFrame'),
          ),
        );
      case 3:
        return BlocProvider<PrescriptionBloc>(
          create: (_) => sl<PrescriptionBloc>(),
          child: const PrescriptionListScreen(
            key: ValueKey('PrescriptionRecordsListFrame'),
          ),
        );
      case 4:
        return BlocProvider<UploadedBloc>(
          create: (_) => sl<UploadedBloc>(),
          child: const UploadedRecordsScreen(
            key: ValueKey('UploadRecordsListFrame'),
          ),
        );
      case 5:
        return BlocProvider<AppointmentBloc>(
          create: (_) => sl<AppointmentBloc>(),
          child: const PatientAppointmentList(
            key: ValueKey('AppointmentListListFrame'),
          ),
        );
      default:
        return Center(
          key: const ValueKey('FallbackTabContentFrame'),
          child: Text(
            '${_tabs[activeTab]} Module Coming Soon',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        );
    }
  }
}
