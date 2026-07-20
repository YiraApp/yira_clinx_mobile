
import 'package:equatable/equatable.dart';

class CommonEntity extends Equatable {
  final bool status;
  final String message;
  final dynamic data;

  const CommonEntity({
    required this.status,
    required this.message,
    this.data,
  });

  @override
  List<Object?> get props => [status, message, data];
}