// import 'package:bloc/bloc.dart';
// import 'package:meta/meta.dart';
//
// part 'navigation_drawer_event.dart';
// part 'navigation_drawer_state.dart';
//
// class NavigationDrawerBloc
//     extends Bloc<NavigationDrawerEvent, NavigationDrawerState> {
//   NavigationDrawerBloc() : super(NavigationDrawerState(selectedIndex: 0)) {
//     on<NavItemChanged>((event, emit) {
//       emit(state.copyWith(selectedIndex: event.index));
//     });
//     on<LogoutRequested>((event, emit) {});
//     on<DashBoardNav>((event, emit) {
//       emit(DashboardNavState());
//     });
//     on<AppointmentsNav>((event, emit) {
//       emit(AppointmentsNavState());
//     });
//     on<PatientsNav>((event, emit) {
//       emit(PatientsNavState());
//     });
//     on<DoctorSlotsNav>((event, emit) {
//       emit(DoctorSlotNavState());
//     });
//     on<SettingsNav>((event, emit) {
//       emit(SettingsNavState());
//     });
//   }
// }
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'navigation_drawer_event.dart';
part 'navigation_drawer_state.dart';

class NavigationDrawerBloc
    extends Bloc<NavigationDrawerEvent, NavigationDrawerState> {
  NavigationDrawerBloc() : super(NavigationDrawerState(selectedIndex: 0)) {

    on<NavItemChanged>((event, emit) {
      emit(state.copyWith(selectedIndex: event.index));
    });

    on<DashBoardNav>((event, emit) {
      emit(DashboardNavState(index: 0 ));
    });

    on<AppointmentsNav>((event, emit) {
      emit(AppointmentsNavState(index: 1));
    });

    on<PatientsNav>((event, emit) {
      emit(PatientsNavState(index: 2));
    });

    on<DoctorSlotsNav>((event, emit) {
      emit(DoctorSlotNavState(index: 3));
    });

    on<SettingsNav>((event, emit) {
      emit(SettingsNavState(index: 7));
    });

    on<LogoutRequested>((event, emit) {

    });
  }
}