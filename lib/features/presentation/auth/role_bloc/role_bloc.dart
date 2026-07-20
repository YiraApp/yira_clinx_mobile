import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';

import '../../../domain/entities/role/role_entity.dart';
import '../use_case/role_use_case.dart';

part 'role_event.dart';
part 'role_state.dart';

class RoleBloc extends Bloc<RoleEvent, RoleState> {
  final SelectRoleUseCase selectRoleUseCase;

  RoleBloc({required this.selectRoleUseCase}) : super(RoleInitial()) {

    on<LoadRolesEvent>(_onLoadRoles);
    on<ChooseRoleEvent>(_onChooseRole);
    on<RoleSelected>((event, emit) {
      emit(RoleSelectedState(event.roleEntity));
    },);
    on<ClearRoleSelectionEvent>((event, emit) {
      emit(RolesLoaded(roles: []));
    });
  }

  Future<void> _onLoadRoles(LoadRolesEvent event, Emitter<RoleState> emit) async {
    emit(RoleLoading());
    try {
      final rolesList = await selectRoleUseCase.getAvailableRoles();
      emit(RolesLoaded(
        roles: rolesList,
        selectedRole: rolesList.isNotEmpty ? rolesList.first.type : null,
      ));
    } catch (e) {
      print("Error loading roles: $e");
    }
  }

  void _onChooseRole(ChooseRoleEvent event, Emitter<RoleState> emit) {
    if (state is RolesLoaded) {
      final currentState = state as RolesLoaded;
      emit(currentState.copyWith(selectedRole: event.selectedRole));
    }
  }
}
