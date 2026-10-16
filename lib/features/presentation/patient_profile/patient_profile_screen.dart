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
import 'package:yiraclinics/features/presentation/patient_profile/widgets/patient_record_scope.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_bloc/prescription_bloc.dart';
import 'package:yiraclinics/features/presentation/prescriptions/prescription_list_screen.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_records_screen.dart';
import '../../../di/dependency_injection.dart';
import '../../domain/entities/patient_profile/patient_profile_entity.dart';
import '../medicine/medical_history_bloc/medical_history_bloc.dart';
import 'appointments/patient_appointments_screen.dart';
import 'over_view/over_view_screen.dart';
import '../doctor/diet/doctor_patient_diet_tab.dart';

class DoctorPatientProfileScreen extends StatefulWidget {
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;
  final String? patientName;
  final String? initialStatus;
  final int initialTabIndex;
  /// Opens this tab by name (e.g. 'Diet'); wins over [initialTabIndex].
  final String? initialTabName;

  const DoctorPatientProfileScreen({
    super.key,
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
    this.patientName,
    this.initialStatus,
    this.initialTabIndex = 0,
    this.initialTabName,
  });

  @override
  State<DoctorPatientProfileScreen> createState() =>
      _DoctorPatientProfileScreenState();
}

class _DoctorPatientProfileScreenState
    extends State<DoctorPatientProfileScreen> {
  late final PageController _pageController;
  late final PatientAccessConsentBloc _consentBloc;

  bool _isPatient() {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final roleName = (currentUser?.data?.latestUserRole ?? '').toLowerCase().trim();
    final roleId = (currentUser?.data?.latestRoleId ?? '').toUpperCase().trim();
    return roleName.contains('patient') ||
        roleName == 'user' ||
        roleId == '4FC67429-28AE-4106-93EF-436228282ED0';
  }

  late final List<String> _tabs;

  /// Record tabs the doctor switched to "Full history".
  final Set<String> _fullHistoryTabs = {};

  /// A record tab for a doctor: this visit's records, or the patient's full
  /// history across hospitals once the patient has given consent. Patients
  /// looking at their own profile just see their records.
  Widget _scoped(
    String tabName,
    PatientProfileEntity patient,
    DoctorAccessStatusLoaded? accessStatus, {
    required String recordType,
    required Widget Function(bool fullHistory) build,
  }) {
    if (_isPatient()) return build(false);
    final hasAccess = accessStatus?.hasAccess ?? false;
    return PatientRecordScopeTab(
      showHistory: _fullHistoryTabs.contains(tabName),
      onChanged: (full) => setState(() => full ? _fullHistoryTabs.add(tabName) : _fullHistoryTabs.remove(tabName)),
      visitLabel: widget.appointmentId != null ? 'This visit' : 'This hospital',
      hasAccess: hasAccess,
      accessStatus: accessStatus,
      visit: () => build(false),
      history: () => hasAccess
          ? build(true)
          : PatientRecordAccessGate(
              key: ValueKey('${tabName}ConsentGate'),
              patient: patient,
              patientId: widget.patientId ?? patient.id,
              appointmentId: widget.appointmentId,
              hospitalId: int.tryParse(widget.hospitalId ?? ''),
              orgId: widget.orgId,
              consentBloc: _consentBloc,
              accessStatus: accessStatus,
              recordType: recordType,
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabs = _isPatient()
        ? [
            'Info',
            'Appointments',
            'Medical Record',
            'Prescribe',
            'Documents',
          ]
        : [
            'Info',
            'Appointments',
            'Medical Record',
            'Prescribe',
            'Diet',
            'Notes',
            'Documents',
          ];

    final namedTab = widget.initialTabName == null ? -1 : _tabs.indexOf(widget.initialTabName!);
    final safeInitialTab = namedTab != -1 ? namedTab : widget.initialTabIndex.clamp(0, _tabs.length - 1);
    _pageController = PageController(initialPage: safeInitialTab);

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
    if (safeInitialTab != 0) {
      context.read<PatientProfileBloc>().add(TabChanged(safeInitialTab));
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
                        initialStatus: widget.initialStatus,
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
                      const SizedBox(height: 12),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _tabs.length,
                          onPageChanged: (index) {
                            context.read<PatientProfileBloc>().add(TabChanged(index));
                          },
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: _buildActiveTabContent(
                                context,
                                patient,
                                index,
                                isTab,
                                accessStatus,
                              ),
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
    final String tabName = (activeTab >= 0 && activeTab < _tabs.length) ? _tabs[activeTab] : '';
    switch (tabName) {
      case 'Info':
        // Info Tab (Patient Demographics, Contacts, Medical Info, Insurance, Visit History)
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
              final idx = _tabs.indexOf('Prescribe');
              if (idx != -1) context.read<PatientProfileBloc>().add(TabChanged(idx));
            },
            onNoteTap: () {
              final idx = _tabs.indexOf('Notes');
              if (idx != -1) context.read<PatientProfileBloc>().add(TabChanged(idx));
            },
            onScheduleTap: () {
              final idx = _tabs.indexOf('Appointments');
              if (idx != -1) context.read<PatientProfileBloc>().add(TabChanged(idx));
            },
          ),
        );
      case 'Appointments':
        // Appointments Tab (Dedicated tab showing all Appointments with full clinical records)
        return BlocProvider<PatientOverViewBloc>(
          create: (_) => sl<PatientOverViewBloc>(),
          child: PatientAppointmentsScreen(
            key: const ValueKey('AppointmentsTabFrame'),
            patient: patient,
            patientId: widget.patientId ?? patient.id,
            appointmentId: widget.appointmentId,
            hospitalId: widget.hospitalId,
            orgId: widget.orgId,
            isTab: isTab,
            hasAccess: accessStatus?.hasAccess ?? true,
            onPrescribeTap: () {
              final idx = _tabs.indexOf('Prescribe');
              if (idx != -1) context.read<PatientProfileBloc>().add(TabChanged(idx));
            },
            onNoteTap: () {
              final idx = _tabs.indexOf('Notes');
              if (idx != -1) context.read<PatientProfileBloc>().add(TabChanged(idx));
            },
          ),
        );
      case 'Medical Record':
        return _scoped(
          tabName,
          patient,
          accessStatus,
          recordType: 'Medical Records & Clinical Findings',
          build: (full) => BlocProvider<MedicalHistoryBloc>(
            key: ValueKey('MedicalRecordsTabFrame$full'),
            create: (_) => sl<MedicalHistoryBloc>(),
            child: MedicalRecordsListScreen(
              patient: patient,
              patientId: widget.patientId ?? patient.id,
              appointmentId: full ? null : widget.appointmentId,
              hospitalId: full ? null : widget.hospitalId,
              orgId: full ? null : widget.orgId,
              allowAdd: !full,
            ),
          ),
        );
      case 'Prescribe':
        return _scoped(
          tabName,
          patient,
          accessStatus,
          recordType: 'Prescriptions & Medication History',
          build: (full) => BlocProvider<PrescriptionBloc>(
            key: ValueKey('PrescriptionTabFrame$full'),
            create: (_) => sl<PrescriptionBloc>()
              ..add(LoadPrescriptionData(
                patientId: widget.patientId ?? patient.id,
                appointmentId: full ? null : widget.appointmentId,
                hospitalId: full ? null : widget.hospitalId,
                orgId: full ? null : widget.orgId,
              )),
            child: PrescriptionListScreen(
              patient: patient,
              appointmentId: full ? null : widget.appointmentId,
              hospitalId: full ? null : widget.hospitalId,
              orgId: full ? null : widget.orgId,
              allowAdd: !full,
            ),
          ),
        );
      case 'Notes':
        return _scoped(
          tabName,
          patient,
          accessStatus,
          recordType: 'Clinical Consultation Notes',
          build: (full) => ClinicalNotesScreen(
            key: ValueKey('NotesTabFrame$full'),
            patientId: widget.patientId ?? patient.id,
            appointmentId: full ? null : widget.appointmentId,
            hospitalId: full ? null : widget.hospitalId,
            orgId: full ? null : widget.orgId,
            allowAdd: !full,
          ),
        );
      case 'Documents':
        return _scoped(
          tabName,
          patient,
          accessStatus,
          recordType: 'Documents & Clinical Reports',
          build: (full) => BlocProvider<UploadedBloc>(
            key: ValueKey('DocumentsTabFrame$full'),
            create: (_) => sl<UploadedBloc>(),
            child: UploadedRecordsScreen(
              patientId: widget.patientId ?? patient.id,
              appointmentId: full ? null : widget.appointmentId,
              hospitalId: full ? null : widget.hospitalId,
              orgId: full ? null : widget.orgId,
              allowAdd: !full,
            ),
          ),
        );
      case 'Diet':
        // Diet Tab (Plans prescribed to this patient, and prescribing a new one)
        return _scoped(
          tabName,
          patient,
          accessStatus,
          recordType: 'Diet Plans',
          build: (full) => DoctorPatientDietTab(
            key: ValueKey('DietTabFrame$full'),
            patientId: widget.patientId ?? patient.id,
            patientName: widget.patientName ?? patient.name,
            orgId: widget.orgId,
            hospitalId: widget.hospitalId,
            appointmentId: widget.appointmentId,
            fullHistory: full,
          ),
        );
      default:
        return Center(
          key: const ValueKey('FallbackTabFrame'),
          child: Text(
            '$tabName Tab Content',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        );
    }
  }
}
