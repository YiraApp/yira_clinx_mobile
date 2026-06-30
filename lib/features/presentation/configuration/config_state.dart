part of 'config_bloc.dart';

@immutable
abstract class ConfigState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ConfigInitial extends ConfigState {}

class LoadDataStatus extends ConfigState {}

// 3. Success State
class GetDataSuccessState extends ConfigState {
  final LoginEntity? loginEntity;

  GetDataSuccessState(this.loginEntity);

  @override
  List<Object?> get props => [loginEntity];
}

class GetDataFailureState extends ConfigState {
  final String? errorMessage;

  GetDataFailureState(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
