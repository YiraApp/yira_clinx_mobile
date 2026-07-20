

enum NetworkStatus { online, offline }

abstract class NetworkRepository {
  Stream<NetworkStatus> get onStatusChange;
  Future<NetworkStatus> get currentStatus;
}