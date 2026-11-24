import 'package:yiraclinics/features/presentation/doctor/fitness/doctor_patient_fitness_tab.dart';
import 'package:yiraclinics/core/widgets/ios_icons.dart';
import 'package:flutter/material.dart';
import 'widgets/prescription_history_tab.dart';
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
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_record_scope.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_record_access_gate.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_records_screen.dart';
import 'suggestions/add_suggestion_sheet.dart';
import 'suggestions/doctor_suggestions_screen.dart';
import 'widgets/request_access_duration_modal.dart';
import '../doctor/diet/doctor_patient_diet_tab.dart';
import '../doctor/questionnaires/doctor_patient_questionnaires_tab.dart';
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

  /// Record tabs switched to "Full history" (without access, it shows the request screen).
  final Set<String> _fullHistoryTabs = {};

  /// Record tabs switched back to "My records"; with access they open on the full history.
  final Set<String> _myRecordsTabs = {};

  /// The hospital the doctor's own records are read at.
  String? get _myHospitalId {
    final given = widget.hospitalId?.trim() ?? '';
    if (given.isNotEmpty && given != '0') return given;
    return GlobalSession.instance.userNotifier.value?.data?.latestHospitalId?.toString();
  }

  // Tabs for Doctor Patient Management Record
  final List<String> _tabs = [
    'Info',
    'Appointments',
    'Medical Record',
    'Prescribe',
    'Diet',
    'Fitness',
    'Notes',
    'Documents',
    'Suggestions',
    'Questionnaires',
  ];

  void _openTab(BuildContext context, String name) {
    final index = _tabs.indexOf(name);
    if (index != -1) context.read<PatientProfileBloc>().add(TabChanged(index));
  }

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

                  // Only where suggestions belong; elsewhere it covered the end of each list.
                  final showSuggestionFab = const {'Info', 'Suggestions'}.contains(_tabs[currentTab.clamp(0, _tabs.length - 1)]);
                  return Scaffold(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    floatingActionButton: !showSuggestionFab ? null : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FloatingActionButton.extended(
                          heroTag: 'add_suggestion_fab',
                          onPressed: () async {
                            // A doctor advises their own patient without seeing the rest of their records.
                            final added = await AddDoctorSuggestionSheet.show(
                              context,
                              patientId: widget.patientId ?? patient.id,
                              orgId: widget.orgId,
                              hospitalId: _myHospitalId,
                              patientName: patient.name,
                            );
                            if (added == true && context.mounted) {
                              _openTab(context, 'Suggestions');
                            }
                          },
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          icon: const Icon(IosIcons.add_rounded, size: 20),
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
                      ],
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

  /// With consent the doctor sees the patient's records from every hospital,
  /// not just this one, under a note saying so.
  Widget _fullHistory(DoctorAccessStatusLoaded? accessStatus, Widget child) {
    return Column(
      children: [
        ConsentHistoryBanner(accessStatus: accessStatus),
        Expanded(child: child),
      ],
    );
  }

  /// A record tab: the doctor's own records, or the whole history once the patient gives access.
  Widget _scoped(
    String tab,
    PatientProfileEntity patient,
    DoctorAccessStatusLoaded? accessStatus, {
    required String recordType,
    required Widget Function(bool full) build,
  }) {
    final hasAccess = accessStatus?.hasAccess ?? false;
    return PatientRecordScopeTab(
      showHistory: hasAccess ? !_myRecordsTabs.contains(tab) : _fullHistoryTabs.contains(tab),
      onChanged: (full) => setState(() {
        (full ? _fullHistoryTabs : _myRecordsTabs).add(tab);
        (full ? _myRecordsTabs : _fullHistoryTabs).remove(tab);
      }),
      visitLabel: 'My records',
      hasAccess: hasAccess,
      accessStatus: accessStatus,
      visit: () => build(false),
      history: () => hasAccess
          ? build(true)
          : PatientRecordAccessGate(
              key: ValueKey('${tab}ConsentGate'),
              patient: patient,
              patientId: widget.patientId ?? patient.id,
              hospitalId: int.tryParse(widget.hospitalId ?? ''),
              orgId: widget.orgId,
              consentBloc: _consentBloc,
              accessStatus: accessStatus,
              recordType: recordType,
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
    switch (activeTab >= 0 && activeTab < _tabs.length ? _tabs[activeTab] : '') {
      case 'Info':
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
              _openTab(context, 'Prescribe');
            },
            onNoteTap: () {
              _openTab(context, 'Notes');
            },
            onScheduleTap: () {
              _openTab(context, 'Appointments');
            },
            // Past records right on the Info tab, as on the appointment page.
            onOpenRecordTab: (tab) => _openTab(context, tab),
            onRequestAccess: () => RequestAccessDurationModal.show(
              context: context,
              patient: patient,
              patientId: widget.patientId ?? patient.id,
              hospitalId: int.tryParse(widget.hospitalId ?? ''),
              consentBloc: _consentBloc,
            ),
          ),
        );
      case 'Appointments':
        // Appointments Tab (Full patient visit schedule & clinical consultations, consent-aware)
        final effectiveHospitalId = (widget.hospitalId != null &&
                widget.hospitalId!.trim().isNotEmpty &&
                widget.hospitalId != '0')
            ? widget.hospitalId
            : (GlobalSession.instance.userNotifier.value?.data?.latestHospitalId?.toString());
        return BlocProvider<PatientOverViewBloc>(
          create: (_) => sl<PatientOverViewBloc>(),
          child: PatientAppointmentsScreen(
            key: const ValueKey('PatientDetailAppointmentsTabFrame'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            hospitalId: effectiveHospitalId,
            orgId: widget.orgId,
            isTab: isTab,
            hasAccess: hasAccess,
            onRequestAccess: () => RequestAccessDurationModal.show(
              context: context,
              patient: patient,
              patientId: widget.patientId ?? patient.id,
              hospitalId: int.tryParse(widget.hospitalId ?? ''),
              consentBloc: _consentBloc,
            ),
            onPrescribeTap: () {
              _openTab(context, 'Prescribe');
            },
            onNoteTap: () {
              _openTab(context, 'Notes');
            },
          ),
        );
      case 'Medical Record':
        return _scoped(
          'Medical Record',
          patient,
          accessStatus,
          recordType: "Medical Records & Clinical Findings",
          build: (full) => BlocProvider<MedicalHistoryBloc>(
            key: ValueKey('PatientDetailMedicalRecordsTabFrame$full'),
            create: (_) => sl<MedicalHistoryBloc>(),
            child: MedicalRecordsListScreen(
              patient: patient,
              patientId: widget.patientId ?? patient.id,
              listWholeHospital: !full,
              hospitalId: full ? null : _myHospitalId,
              allowAdd: false,
            ),
          ),
        );
      case 'Prescribe':
        // Every prescription with its real date; the per-visit screen showed only
        // the latest one, labelled "Today".
        return _scoped(
          'Prescribe',
          patient,
          accessStatus,
          recordType: "Prescriptions & Medication History",
          build: (full) => PrescriptionHistoryTab(
            key: ValueKey('PatientDetailPrescriptionTabFrame$full'),
            patientId: widget.patientId ?? patient.id,
            hospitalId: full ? null : _myHospitalId,
          ),
        );
      case 'Notes':
        return _scoped(
          'Notes',
          patient,
          accessStatus,
          recordType: "Clinical Consultation Notes",
          build: (full) => ClinicalNotesScreen(
            key: ValueKey('PatientDetailNotesTabFrame$full'),
            patientId: widget.patientId ?? patient.id,
            listWholeHospital: !full,
            hospitalId: full ? null : _myHospitalId,
            allowAdd: false,
          ),
        );
      case 'Documents':
        return _scoped(
          'Documents',
          patient,
          accessStatus,
          recordType: "Documents & Clinical Reports",
          build: (full) => BlocProvider<UploadedBloc>(
            key: ValueKey('PatientDetailDocumentsTabFrame$full'),
            create: (_) => sl<UploadedBloc>(),
            child: UploadedRecordsScreen(
              patientId: widget.patientId ?? patient.id,
              listWholeHospital: !full,
              hospitalId: full ? null : _myHospitalId,
              allowAdd: false,
              allowWhatsAppShare: true,
              patientName: widget.patientName ?? patient.name,
            ),
          ),
        );
      case 'Suggestions':
        return _scoped(
          'Suggestions',
          patient,
          accessStatus,
          recordType: "Doctor Suggestions & Treatment Recommendations",
          build: (full) => DoctorSuggestionsScreen(
            key: ValueKey('PatientDetailSuggestionsTabFrame$full'),
            patientId: widget.patientId ?? patient.id,
            patientName: widget.patientName ?? patient.name,
            hospitalId: full ? null : _myHospitalId,
            showFab: false,
          ),
        );
      case 'Questionnaires':
        final questionnairesTab = DoctorPatientQuestionnairesTab(
          key: ValueKey('PatientDetailQuestionnairesTabFrame$hasAccess'),
          patientId: widget.patientId ?? patient.id,
          hospitalId: widget.hospitalId,
          fullHistory: hasAccess,
        );
        return hasAccess ? _fullHistory(accessStatus, questionnairesTab) : questionnairesTab;
      case 'Fitness':
        // The patient's synced fitness, once they have shared access with this doctor
        return DoctorPatientFitnessTab(
          key: ValueKey('PatientDetailFitnessTabFrame$hasAccess'),
          patientId: widget.patientId ?? patient.id,
          patientName: widget.patientName ?? patient.name,
          hasAccess: hasAccess,
          onRequestAccess: () => RequestAccessDurationModal.show(
            context: context,
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            hospitalId: int.tryParse(widget.hospitalId ?? ''),
            consentBloc: _consentBloc,
          ),
        );
      case 'Diet':
        // Diet Tab (Plans prescribed to this patient, and prescribing a new one)
        final dietTab = DoctorPatientDietTab(
          key: ValueKey('PatientDetailDietTabFrame$hasAccess'),
          patientId: widget.patientId ?? patient.id,
          patientName: widget.patientName ?? patient.name,
          orgId: widget.orgId,
          hospitalId: widget.hospitalId,
          fullHistory: hasAccess,
        );
        return hasAccess ? _fullHistory(accessStatus, dietTab) : dietTab;
      default:
        return Center(
          key: const ValueKey('PatientDetailFallbackTabFrame'),
          child: Text(
            'Tab Content',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        );
    }
  }
}
