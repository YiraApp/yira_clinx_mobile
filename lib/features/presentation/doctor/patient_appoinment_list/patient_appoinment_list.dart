import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/features/presentation/doctor/patient_appoinment_list/widgets/appointment_record_fab.dart';

import '../../../../core/common_widgets/common_text.dart';
import '../../appointments/appointment_bloc/appointment_bloc.dart';
import '../../appointments/widgets/appointment_card.dart';

class PatientAppointmentList extends StatelessWidget {
  const PatientAppointmentList({super.key});

  @override
  Widget build(BuildContext context) {
    return const PatientAppointmentListView();
  }
}

class PatientAppointmentListView extends StatefulWidget {
  const PatientAppointmentListView({super.key});

  @override
  State<PatientAppointmentListView> createState() =>
      _PatientAppointmentListViewState();
}

class _PatientAppointmentListViewState
    extends State<PatientAppointmentListView> {
  @override
  void initState() {
    super.initState();
    context.read<AppointmentBloc>().add(LoadAppointmentsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AppointmentBloc, AppointmentState>(
      buildWhen: (previous, current)=> current is ! OnAddAppointmentState,
      listener: (BuildContext context, AppointmentState state) {
        if(state is OnAddAppointmentState){
          Navigator.pushNamed(context, AppRoutes.addAppointmentScreen);
        }
      },
      builder: (context, state) {

        if (state is AppointmentLoading) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          );
        }
        if (state is AppointmentLoaded) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            floatingActionButton:AppointmentRecordFab( OnAppointmentBook: () {
               context.read<AppointmentBloc>().add(OnAddAppointmentEvent());
            }),
            body: SafeArea(
              child: state.appointments.isEmpty
                  ? Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          size: displayWidth(context) * 0.18,
                          color: Theme.of(context).hintColor.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        CommonText(
                          "No Appointments Available",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontWeight: FontWeight.w600,
                            fontSize: displayWidth(context) * 0.04,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        CommonText(
                          'No appointments scheduled for today.',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontWeight: FontWeight.w400,
                            fontSize: displayWidth(context) * 0.03,
                            color: Theme.of(context).hintColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add, size: 16),
                            label: CommonText(
                              "Book Appointment",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.w500,
                                fontSize: displayWidth(context) * 0.03,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(fieldBorderRadius),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.only(
                  left: screenHorizontalSpacePadding,
                  right: screenHorizontalSpacePadding,
                  top: 0,
                ),
                itemCount: state.appointments.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final appointment = state.appointments[index];
                  return AppointmentCard(
                    isPatientProfile: true,
                    appointment: appointment,
                    isTeleConsultation: true,
                    onEdit: () {},
                  );
                },
              ),
            ),
          );
        }
        if (state is AppointmentError) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: appPoppinFont,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ),
          );
        }
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: const SizedBox.shrink(),
        );
      },
    );
  }
}