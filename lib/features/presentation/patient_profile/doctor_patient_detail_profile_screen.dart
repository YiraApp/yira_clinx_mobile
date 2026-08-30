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
import 'suggestions/add_suggestion_sheet.dart';
import 'suggestions/doctor_suggestions_screen.dart';
import 'widgets/request_access_duration_modal.dart';
import '../../../di/dependency_injection.dart';
import '../../domain/entities/patient_profile/patient_profile_entity.dart';
import '../medicine/medical_history_bloc/medical_history_bloc.dart';
import 'appointments/patient_appointments_screen.dart';
import 'over_view/over_view_screen.dart';

class DoctorPatientDetailProfileScreen extends StatefulWidget {
  final String? patientId;
  final String? hospitalId;
  final String? orgId;
  final String? patientName;
  final int initialTabIndex;

  const DoctorPatientDetailProfileScreen({
    super.key,
    this.patientId,
    this.hospitalId,
    this.orgId,
    this.patientName,
    this.initialTabIndex = 0,
  });

  @override
  State<DoctorPatientDetailProfileScreen> createState() =>
      _DoctorPatientDetailProfileScreenState();
}

class _DoctorPatientDetailProfileScreenState
    extends State<DoctorPatientDetailProfileScreen> {
  late final PageController _pageController;
  late final PatientAccessConsentBloc _consentBloc;

  // 7 tabs for Doctor Patient Management Record
  final List<String> _tabs = [
    'Info',
    'Appointments',
    'Medical Record',
    'Prescribe',
    'Notes',
    'Documents',
    'Suggestions',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialTabIndex);

    final currentDoctorId =
        GlobalSession.instance.userNotifier.value?.data?.id ?? '';
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
      context
          .read<PatientProfileBloc>()
          .add(TabChanged(widget.initialTabIndex));
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
            if (state is PatientProfileInitial || state is PatientProfileLoading) {
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

              return BlocBuilder<PatientAccessConsentBloc,
                  PatientAccessConsentState>(
                builder: (context, consentState) {
                  final DoctorAccessStatusLoaded? accessStatus =
                      consentState is DoctorAccessStatusLoaded
                          ? consentState
                          : null;

                  final bool hasAccess = accessStatus?.hasAccess ?? false;

                  return Scaffold(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    floatingActionButton: FloatingActionButton.extended(
                      onPressed: () async {
                        if (!hasAccess) {
                          RequestAccessDurationModal.show(
                            context: context,
                            patient: patient,
                            patientId: widget.patientId ?? patient.id,
                            hospitalId: int.tryParse(widget.hospitalId ?? ''),
                            consentBloc: _consentBloc,
                          );
                          return;
                        }
                        final added = await AddDoctorSuggestionSheet.show(
                          context,
                          patientId: widget.patientId ?? patient.id,
                          orgId: widget.orgId,
                          hospitalId: widget.hospitalId,
                          patientName: patient.name,
                        );
                        if (added == true && context.mounted) {
                          context.read<PatientProfileBloc>().add(const TabChanged(6));
                        }
                      },
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        "Add Suggestion",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    body: Column(
                      children: [
                        // Header with showStatus: false (No appointment status badge)
                        PatientProfileHeader(
                          patient: patient,
                          isTab: isTab,
                          appointmentId: null,
                          patientId: widget.patientId ?? patient.id,
                          initialStatus: null,
                          showStatus: false,
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
                              context
                                  .read<PatientProfileBloc>()
                                  .add(TabChanged(index));
                            },
                          ),
                        ),

                        // Tab Content PageView
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _tabs.length,
                            onPageChanged: (index) {
                              context
                                  .read<PatientProfileBloc>()
                                  .add(TabChanged(index));
                            },
                            itemBuilder: (context, index) {
                              return _buildActiveTabContent(
                                context,
                                patient,
                                index,
                                isTab,
                                hasAccess,
                                accessStatus,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
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
    bool hasAccess,
    DoctorAccessStatusLoaded? accessStatus,
  ) {
    switch (activeTab) {
      case 0:
        // Info Tab (Patient Demographics, Contacts, Medical Info, Insurance, Visit History)
        return BlocProvider<PatientOverViewBloc>(
          create: (_) => sl<PatientOverViewBloc>(),
          child: OverviewScreen(
            isTab: isTab,
            key: const ValueKey('PatientDetailInfoTabFrame'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            hospitalId: widget.hospitalId,
            orgId: widget.orgId,
            onPrescribeTap: () {
              context.read<PatientProfileBloc>().add(const TabChanged(3));
            },
            onNoteTap: () {
              context.read<PatientProfileBloc>().add(const TabChanged(4));
            },
            onScheduleTap: () {
              context.read<PatientProfileBloc>().add(const TabChanged(1));
            },
          ),
        );
      case 1:
        // Appointments Tab (Full patient visit schedule & clinical consultations, consent-aware)
        return BlocProvider<PatientOverViewBloc>(
          create: (_) => sl<PatientOverViewBloc>(),
          child: PatientAppointmentsScreen(
            key: const ValueKey('PatientDetailAppointmentsTabFrame'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            hospitalId: widget.hospitalId,
            orgId: widget.orgId,
            isTab: isTab,
            hasAccess: hasAccess,
            onPrescribeTap: () {
              context.read<PatientProfileBloc>().add(const TabChanged(3));
            },
            onNoteTap: () {
              context.read<PatientProfileBloc>().add(const TabChanged(4));
            },
          ),
        );
      case 2:
        // Medical Record Tab (Gated by patient consent, read-only tracking)
        if (!hasAccess) {
          return PatientRecordAccessGate(
            key: const ValueKey('MedicalRecordsConsentGate'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            hospitalId: int.tryParse(widget.hospitalId ?? ''),
            orgId: widget.orgId,
            consentBloc: _consentBloc,
            accessStatus: accessStatus,
            recordType: "Medical Records & Clinical Findings",
          );
        }
        return BlocProvider<MedicalHistoryBloc>(
          create: (_) => sl<MedicalHistoryBloc>(),
          child: MedicalRecordsListScreen(
            key: const ValueKey('PatientDetailMedicalRecordsTabFrame'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            hospitalId: widget.hospitalId,
            orgId: widget.orgId,
            allowAdd: false,
          ),
        );
      case 3:
        // Prescribe Tab (Gated by patient consent, read-only tracking)
        if (!hasAccess) {
          return PatientRecordAccessGate(
            key: const ValueKey('PrescriptionsConsentGate'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            hospitalId: int.tryParse(widget.hospitalId ?? ''),
            orgId: widget.orgId,
            consentBloc: _consentBloc,
            accessStatus: accessStatus,
            recordType: "Prescriptions & Medication History",
          );
        }
        return BlocProvider<PrescriptionBloc>(
          create: (_) => sl<PrescriptionBloc>()
            ..add(LoadPrescriptionData(
              patientId: widget.patientId ?? patient.id,
              hospitalId: widget.hospitalId,
              orgId: widget.orgId,
            )),
          child: PrescriptionListScreen(
            key: const ValueKey('PatientDetailPrescriptionTabFrame'),
            patient: patient,
            hospitalId: widget.hospitalId,
            orgId: widget.orgId,
            allowAdd: false,
          ),
        );
      case 4:
        // Notes Tab (Gated by patient consent, read-only tracking)
        if (!hasAccess) {
          return PatientRecordAccessGate(
            key: const ValueKey('ClinicalNotesConsentGate'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            hospitalId: int.tryParse(widget.hospitalId ?? ''),
            orgId: widget.orgId,
            consentBloc: _consentBloc,
            accessStatus: accessStatus,
            recordType: "Clinical Consultation Notes",
          );
        }
        return ClinicalNotesScreen(
          key: const ValueKey('PatientDetailNotesTabFrame'),
          patientId: widget.patientId ?? patient.id,
          hospitalId: widget.hospitalId,
          orgId: widget.orgId,
          allowAdd: false,
        );
      case 5:
        // Documents Tab (Gated by patient consent, read-only tracking)
        if (!hasAccess) {
          return PatientRecordAccessGate(
            key: const ValueKey('DocumentsConsentGate'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            hospitalId: int.tryParse(widget.hospitalId ?? ''),
            orgId: widget.orgId,
            consentBloc: _consentBloc,
            accessStatus: accessStatus,
            recordType: "Documents & Clinical Reports",
          );
        }
        return BlocProvider<UploadedBloc>(
          create: (_) => sl<UploadedBloc>(),
          child: UploadedRecordsScreen(
            key: const ValueKey('PatientDetailDocumentsTabFrame'),
            patientId: widget.patientId ?? patient.id,
            hospitalId: widget.hospitalId,
            orgId: widget.orgId,
            allowAdd: false,
          ),
        );
      case 6:
        // Suggestions Tab (Gated by patient consent)
        if (!hasAccess) {
          return PatientRecordAccessGate(
            key: const ValueKey('SuggestionsConsentGate'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            hospitalId: int.tryParse(widget.hospitalId ?? ''),
            orgId: widget.orgId,
            consentBloc: _consentBloc,
            accessStatus: accessStatus,
            recordType: "Doctor Suggestions & Treatment Recommendations",
          );
        }
        return DoctorSuggestionsScreen(
          key: const ValueKey('PatientDetailSuggestionsTabFrame'),
          patientId: widget.patientId ?? patient.id,
          hospitalId: widget.hospitalId,
          orgId: widget.orgId,
          patientName: widget.patientName ?? patient.name,
          showFab: false,
        );
      default:
        return Center(
          key: const ValueKey('PatientDetailFallbackTabFrame'),
          child: Text(
            '${_tabs[activeTab]} Tab Content',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        );
    }
  }
}
