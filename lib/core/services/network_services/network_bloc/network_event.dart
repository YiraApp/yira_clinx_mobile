part of 'network_bloc.dart';

@immutable
abstract class NetworkEvent {}
class ObserveNetwork extends NetworkEvent {}
class NetworkChanged extends NetworkEvent {
  final NetworkStatus status;
  NetworkChanged(this.status);

}
class NetworkStatusChangedEvent extends NetworkEvent {
  final NetworkStatus status;
  NetworkStatusChangedEvent(this.status);
}
