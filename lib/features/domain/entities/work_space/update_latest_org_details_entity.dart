import 'package:equatable/equatable.dart';

class UpdateLatestOrgDetailsEntity extends Equatable {
  final bool status;
  final String message;
  final LatestOrgDetailsDataEntity? data;

  const UpdateLatestOrgDetailsEntity({
    required this.status,
    required this.message,
    this.data,
  });

  @override
  List<Object?> get props => [status, message, data];
}


class LatestOrgDetailsDataEntity extends Equatable {
  final String userId;
  final String latestRoleId;
  final int latestOrgId;
  final int latestHospitalId;
  final String navigationId;

  const LatestOrgDetailsDataEntity({
    required this.userId,
    required this.latestRoleId,
    required this.latestOrgId,
    required this.latestHospitalId,
    required this.navigationId,
  });

  @override
  List<Object?> get props => [
    userId,
    latestRoleId,
    latestOrgId,
    latestHospitalId,
    navigationId,
  ];
}