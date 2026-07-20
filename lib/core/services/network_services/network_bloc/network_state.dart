part of 'network_bloc.dart';

@immutable
abstract class NetworkState {
  final NetworkStatus status;
  const NetworkState(this.status);
}
class NetworkInitial extends NetworkState {
  const NetworkInitial() : super(NetworkStatus.online); // Instant load baseline
}
class NetworkLoaded extends NetworkState {
  const NetworkLoaded(super.status);
}
