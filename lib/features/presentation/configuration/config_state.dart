part of 'config_bloc.dart';

@immutable
abstract class ConfigState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ConfigInitial extends ConfigState {}

class LoadDataStatus extends ConfigState {}


class GetDataSuccessState extends ConfigState {
  final LoginEntity coreData;
  final VersionTokenStatusEntity? versionData;

   GetDataSuccessState({
    required this.coreData,
    this.versionData,
  });

  @override
  List<Object?> get props => [coreData, versionData];
}
class GetTokenSuccessState extends ConfigState {
  final VersionTokenStatusEntity? getVersionTokenStatusEntity;

  GetTokenSuccessState(this.getVersionTokenStatusEntity);

  @override
  List<Object?> get props => [getVersionTokenStatusEntity];
}

class GetDataFailureState extends ConfigState {
  final String? errorMessage;

  GetDataFailureState(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class GetTokenFailureState extends ConfigState {
  final String? errorMessage;

  GetTokenFailureState(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
