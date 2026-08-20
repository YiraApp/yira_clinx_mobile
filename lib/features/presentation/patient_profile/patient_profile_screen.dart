import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/consent/bloc/patient_access_consent_bloc.dart';
import 'package:yiraclinics/features/presentation/consent/bloc/patient_access_consent_event.dart';
import 'package:yiraclinics/features/presentation/consent/bloc/patient_access_consent_state.dart';
import 'package:yiraclinics/features/presentation/medicine/medical_record_list_screen.dart';
import 'package:yiraclinics/features/presentation/patient_profile/clinical_notes/clinical_notes_screen.dart';
import 'package:yiraclinics/features/presentation/patient_profile/patient_over_view_bloc/patient_over_view_bloc.dart';
import 'package:yiraclinics/features/presentation/patient_profile/patient_profile_bloc/patient_profile_bloc.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_profile_header.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_profile_tab_bar.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_record_access_gate.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_list_screen.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_records_screen.dart';
import '../../../di/dependency_injection.dart';
import '../../domain/entities/patient_profile/patient_profile_entity.dart';
import '../medicine/medical_history_bloc/medical_history_bloc.dart';
import 'over_view/over_view_screen.dart';

class DoctorPatientProfileScreen extends StatefulWidget {
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;
  final String? patientName;
  final int initialTabIndex;

  const DoctorPatientProfileScreen({
    super.key,
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
    this.patientName,
    this.initialTabIndex = 0,
  });

  @override
  State<DoctorPatientProfileScreen> createState() =>
      _DoctorPatientProfileScreenState();
}

class _DoctorPatientProfileScreenState
    extends State<DoctorPatientProfileScreen> {
  late final PageController _pageController;
  late final PatientAccessConsentBloc _consentBloc;

  // 5 attached tabs matching exact user spec and web layout
  final List<String> _tabs = [
    'Info',
    'Medical Record',
    'Prescribe',
    'Notes',
    'Documents',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialTabIndex);

    final currentDoctorId = GlobalSession.instance.userNotifier.value?.data?.id ?? '';
    _consentBloc = sl<PatientAccessConsentBloc>()
      ..add(CheckAccessStatusEvent(
        patientId: widget.patientId ?? '3456',
        doctorId: currentDoctorId,
      ));

    context.read<PatientProfileBloc>().add(
      LoadPatientProfile(
        widget.patientId ?? '3456',
        patientName: widget.patientName,
      ),
    );
    if (widget.initialTabIndex != 0) {
      context.read<PatientProfileBloc>().add(TabChanged(widget.initialTabIndex));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _consentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTab = isTablet(context);

    return BlocProvider.value(
      value: _consentBloc,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: BlocConsumer<PatientProfileBloc, PatientProfileState>(
          listener: (BuildContext context, PatientProfileState state) {
            if (state is PatientProfileLoaded) {
              if (_pageController.hasClients &&
                  _pageController.page?.round() != state.activeTabIndex) {
                _pageController.animateToPage(
                  state.activeTabIndex,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            }
          },
          builder: (context, state) {
            if (state is PatientProfileInitial) {
              context.read<PatientProfileBloc>().add(
                LoadPatientProfile(
                  widget.patientId ?? '3456',
                  patientName: widget.patientName,
                ),
              );
              return PatientProfileScreenShimmer(
                isDark: Theme.of(context).brightness == Brightness.dark,
                isTab: isTab,
              );
            }

            if (state is PatientProfileLoading) {
              return PatientProfileScreenShimmer(
                isDark: Theme.of(context).brightness == Brightness.dark,
                isTab: isTab,
              );
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

              return BlocBuilder<PatientAccessConsentBloc, PatientAccessConsentState>(
                builder: (context, consentState) {
                  final DoctorAccessStatusLoaded? accessStatus =
                      consentState is DoctorAccessStatusLoaded ? consentState : null;

                  return Column(
                    children: [
                      PatientProfileHeader(
                        patient: patient,
                        isTab: isTab,
                        appointmentId: widget.appointmentId,
                        patientId: widget.patientId ?? patient.id,
                        hospitalId: int.tryParse(widget.hospitalId ?? ''),
                        consentBloc: _consentBloc,
                        accessStatus: accessStatus,
                        onBack: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        tabBar: PatientProfileTabBar(
                          tabs: _tabs,
                          selectedIndex: currentTab,
                          isTab: isTab,
                          onTabSelected: (index) {
                            context.read<PatientProfileBloc>().add(TabChanged(index));
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _tabs.length,
                          onPageChanged: (index) {
                            context.read<PatientProfileBloc>().add(TabChanged(index));
                          },
                          itemBuilder: (context, index) {
                            return _buildActiveTabContent(
                              context,
                              patient,
                              index,
                              isTab,
                              accessStatus,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            }

            return PatientProfileScreenShimmer(
              isDark: Theme.of(context).brightness == Brightness.dark,
              isTab: isTab,
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(
    BuildContext context,
    PatientProfileEntity patient,
    int activeTab,
    bool isTab,
    DoctorAccessStatusLoaded? accessStatus,
  ) {
    final bool hasApprovedAccess = accessStatus?.hasAccess ?? false;

    switch (activeTab) {
      case 0:
        // Info / Overview Tab (Always available for basic review & scheduling)
        return BlocProvider<PatientOverViewBloc>(
          create: (_) => sl<PatientOverViewBloc>(),
          child: OverviewScreen(
            isTab: isTab,
            key: const ValueKey('InfoTabContentFrame'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            appointmentId: widget.appointmentId,
            hospitalId: widget.hospitalId,
            orgId: widget.orgId,
            onPrescribeTap: () {
              context.read<PatientProfileBloc>().add(const TabChanged(2));
            },
            onNoteTap: () {
              context.read<PatientProfileBloc>().add(const TabChanged(3));
            },
            onScheduleTap: () {
              context.read<PatientProfileBloc>().add(const TabChanged(1));
            },
          ),
        );
      case 1:
        // Medical Record Tab (Requires Patient Consent Approval)
        if (!hasApprovedAccess) {
          return PatientRecordAccessGate(
            key: const ValueKey('MedicalRecordsLockGate'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            appointmentId: widget.appointmentId,
            hospitalId: int.tryParse(widget.hospitalId ?? ''),
            consentBloc: _consentBloc,
            accessStatus: accessStatus,
            recordType: "Medical Records & Diagnoses",
          );
        }
        return BlocProvider<MedicalHistoryBloc>(
          create: (_) => sl<MedicalHistoryBloc>(),
          child: MedicalRecordsListScreen(
            key: const ValueKey('MedicalRecordsTabFrame'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            appointmentId: widget.appointmentId,
            hospitalId: widget.hospitalId,
            orgId: widget.orgId,
          ),
        );
      case 2:
        // Prescribe Tab (Requires Patient Consent Approval)
        if (!hasApprovedAccess) {
          return PatientRecordAccessGate(
            key: const ValueKey('PrescriptionsLockGate'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            appointmentId: widget.appointmentId,
            hospitalId: int.tryParse(widget.hospitalId ?? ''),
            consentBloc: _consentBloc,
            accessStatus: accessStatus,
            recordType: "Prescriptions & Medications",
          );
        }
        return BlocProvider<PrescriptionBloc>(
          create: (_) => sl<PrescriptionBloc>()
            ..add(LoadPrescriptionData(
              patientId: widget.patientId ?? patient.id,
              appointmentId: widget.appointmentId,
              hospitalId: widget.hospitalId,
              orgId: widget.orgId,
            )),
          child: PrescriptionListScreen(
            key: const ValueKey('PrescriptionTabFrame'),
            patient: patient,
            appointmentId: widget.appointmentId,
            hospitalId: widget.hospitalId,
            orgId: widget.orgId,
          ),
        );
      case 3:
        // Notes Tab (Requires Patient Consent Approval)
        if (!hasApprovedAccess) {
          return PatientRecordAccessGate(
            key: const ValueKey('ClinicalNotesLockGate'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            appointmentId: widget.appointmentId,
            hospitalId: int.tryParse(widget.hospitalId ?? ''),
            consentBloc: _consentBloc,
            accessStatus: accessStatus,
            recordType: "Clinical Consultations & Notes",
          );
        }
        return ClinicalNotesScreen(
          key: const ValueKey('NotesTabFrame'),
          patientId: widget.patientId ?? patient.id,
          appointmentId: widget.appointmentId,
          hospitalId: widget.hospitalId,
          orgId: widget.orgId,
        );
      case 4:
        // Documents Tab (Requires Patient Consent Approval)
        if (!hasApprovedAccess) {
          return PatientRecordAccessGate(
            key: const ValueKey('DocumentsLockGate'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            appointmentId: widget.appointmentId,
            hospitalId: int.tryParse(widget.hospitalId ?? ''),
            consentBloc: _consentBloc,
            accessStatus: accessStatus,
            recordType: "Medical Documents & Lab Reports",
          );
        }
        return BlocProvider<UploadedBloc>(
          create: (_) => sl<UploadedBloc>(),
          child: UploadedRecordsScreen(
            key: const ValueKey('DocumentsTabFrame'),
            patientId: widget.patientId ?? patient.id,
            appointmentId: widget.appointmentId,
            hospitalId: widget.hospitalId,
            orgId: widget.orgId,
          ),
        );
      default:
        return Center(
          key: const ValueKey('FallbackTabFrame'),
          child: Text(
            '${_tabs[activeTab]} Tab Content',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        );
    }
  }
}
