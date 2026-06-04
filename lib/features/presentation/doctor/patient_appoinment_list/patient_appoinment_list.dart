import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';

import '../../../../core/common_widgets/common_text.dart';
import '../../appointments/appointment_bloc/appointment_bloc.dart';
import '../../appointments/widgets/appointment_card.dart';

class PatientAppointmentList extends StatelessWidget {
  const PatientAppointmentList({super.key});

  @override
  Widget build(BuildContext context) {
    return PatientAppointmentListView();
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocConsumer<AppointmentBloc, AppointmentState>(
          listener: (BuildContext context, AppointmentState state) {},
          builder: (context, state) {
            if (state is AppointmentLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              );
            }
            if (state is AppointmentLoaded) {
              if (state.appointments.isEmpty) {
                return Center(
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
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return ListView.builder(
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
              );
            }

            // 3. Error Fallback UI Catch
            if (state is AppointmentError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
