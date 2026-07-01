
import 'package:equatable/equatable.dart';

class VersionTokenStatusEntity extends Equatable {
  final bool status;
  final String message;
  final GetVersionTokenStatusEntity? data;

  const VersionTokenStatusEntity({
    required this.status,
    required this.message,
    this.data,
  });

  @override
  List<Object?> get props => [status, message, data];
}

class GetVersionTokenStatusEntity extends Equatable {
  final bool versionStatus;
  final String updateType;
  final bool tokenStatus;

  const GetVersionTokenStatusEntity({
    required this.versionStatus,
    required this.updateType,
    required this.tokenStatus,
  });

  @override
  List<Object?> get props => [versionStatus, updateType, tokenStatus];
}