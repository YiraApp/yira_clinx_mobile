import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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

            return Column(
              children: [
                PatientProfileHeader(patient: patient),
                PatientProfileTabBar(
                  tabs: _tabs,
                  onTabSelected: (index) {
                    setState(() {
                      _activeTabIndex = index;
                    });
                    debugPrint('Tab switched context indices target: $index');
                  },
                ),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildActiveTabContent(patient),
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

  Widget _buildActiveTabContent(PatientProfileEntity patient) {
    switch (_activeTabIndex) {
      case 0:
        return OverviewScreen(
          key: const ValueKey('OverviewTabContentFrame'),
          patient: patient,
        );
      case 1:
        return const ClinicalNotesScreen(
          key: ValueKey('ClinicalNotesTabContentFrame'),
        );
      case 2:
        return BlocProvider<MedicalHistoryBloc>(
          create: (_) => sl<MedicalHistoryBloc>(),
          child: const MedicalRecordsListScreen(key: ValueKey('MedicalRecordsListFrame')),
        );
      case 3:
        return BlocProvider<PrescriptionBloc>(
          create: (_) => sl<PrescriptionBloc>(),
          child: const PrescriptionListScreen(key: ValueKey('PrescriptionRecordsListFrame')),
        );
      case 4:
        return BlocProvider<UploadedBloc>(
          create: (_) => sl<UploadedBloc>(),
          child: const UploadedRecordsScreen(key: ValueKey('UploadRecordsListFrame')),
        );
      case 5:
        return BlocProvider<AppointmentBloc>(
          create: (_) => sl<AppointmentBloc>(),
          child: const PatientAppointmentList(key: ValueKey('AppointmentListListFrame')),
        );
      default:
        return Center(
          key: const ValueKey('FallbackTabContentFrame'),
          child: Text(
            '${_tabs[_activeTabIndex]} Module Coming Soon',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        );
    }
  }
}