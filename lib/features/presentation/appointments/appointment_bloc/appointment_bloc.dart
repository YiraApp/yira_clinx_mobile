import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../domain/entities/appointments/appointment_entity.dart';

part 'appointment_event.dart';
part 'appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  AppointmentBloc() : super(AppointmentInitial()) {
    on<LoadAppointmentsEvent>((event, emit) async {
      emit(AppointmentLoading());
      try {
        await Future.delayed(const Duration(milliseconds: 800));

        final List<Appointment> dummyAppointments =
        [
          const Appointment(
            id: "1",
            tokenNumber: "Token #1",
            time: "11:30",
            duration: "30 MIN",
            patientName: "Mani N",
            phoneNumber: "9908875796",
            type: AppointmentType.inClinic,
            category: "Consultation",
            status: AppointmentStatus.confirmed,
          ),
          const Appointment(
            id: "2",
            tokenNumber: "Token #9",
            time: "13:00",
            duration: "30 MIN",
            patientName: "Teja Ch",
            phoneNumber: "9908875788",
            type: AppointmentType.inClinic,
            category: "Consultation",
            status: AppointmentStatus.paymentPending,
          ),
          const Appointment(
            id: "3",
            tokenNumber: "Token #8",
            time: "14:00",
            duration: "30 MIN",
            patientName: "Mani N",
            phoneNumber: "9908875796",
            type: AppointmentType.videoCall,
            category: "Follow-up",
            status: AppointmentStatus.paymentPending,
          ),
        ];
        emit(AppointmentLoaded(
          appointments: dummyAppointments,
          todayCount: 7,
          confirmedCount: 3,
          pendingCount: 0,
          aiOptimizationScore: 94,
        ));
      } catch (e) {
        emit(AppointmentError("Failed to fetch dashboard records"));
      }
    });
    on<OnAddAppointmentEvent>((event, emit) async {
      emit(OnAddAppointmentState());
    });
  }

}
