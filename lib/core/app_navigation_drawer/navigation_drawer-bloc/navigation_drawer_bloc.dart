import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../local/flutter_secure_storage.dart';

part 'navigation_drawer_event.dart';
part 'navigation_drawer_state.dart';

class NavigationDrawerBloc extends Bloc<NavigationDrawerEvent, NavigationDrawerState> {
  final SecureStorageService _secureStorageService;

  NavigationDrawerBloc(this._secureStorageService) : super(const NavigationDrawerState(selectedIndex: 0)) {
    on<InitializeDrawerData>(_onInitializeDrawerData);

    on<NavItemChanged>((event, emit) {
      emit(state.copyWith(selectedIndex: event.index));
    });

    on<DashBoardNav>((event, emit) {
      emit(DashboardNavState(index: 0, version: state.appVersion));
    });

    on<AppointmentsNav>((event, emit) {
      emit(AppointmentsNavState(index: 1, version: state.appVersion));
    });

    on<PatientsNav>((event, emit) {
      emit(PatientsNavState(index: 2, version: state.appVersion));
    });

    on<DoctorSlotsNav>((event, emit) {
      emit(DoctorSlotNavState(index: 3, version: state.appVersion));
    });

    on<SettingsNav>((event, emit) {
      emit(SettingsNavState(index: 7, version: state.appVersion));
    });

    on<ContactNavEvent>((event, emit) {
      emit(ContactNavState(version: state.appVersion));
    });

    on<PrivacyNavEvent>((event, emit) {
      emit(PrivacyNavState(version: state.appVersion));
    });

    on<ReadAboutUsNavEvent>((event, emit) {
      emit(ReadAboutUsNavState(version: state.appVersion));
    });

    on<LogoutNavEvent>((event, emit) {
      emit(LogoutNavState(version: state.appVersion));
    });
  }

  Future<void> _onInitializeDrawerData(
      InitializeDrawerData event,
      Emitter<NavigationDrawerState> emit,
      ) async {
    final String? savedVersion = await _secureStorageService.readSecureValue<String>(SecureCacheKey.appVersionInfo);
    if (savedVersion != null) {
      emit(state.copyWith(appVersion: savedVersion));
    }
  }
}