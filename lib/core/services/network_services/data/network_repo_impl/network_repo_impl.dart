import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../../domain/neetwork_repo/network_repo.dart';
import '../../network_remote_data_source/network_remote_data_source.dart';

class NetworkRemoteDataSourceImpl implements NetworkRemoteDataSource {
  final InternetConnection _connection;
  NetworkRemoteDataSourceImpl(this._connection);

  @override
  Stream<InternetStatus> get onStatusChange => _connection.onStatusChange;
}

class NetworkRepositoryImpl implements NetworkRepository {
  final NetworkRemoteDataSource remoteDataSource;
  final Connectivity _connectivity;

  NetworkRepositoryImpl({
    required this.remoteDataSource,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity();

  @override
  Stream<NetworkStatus> get onStatusChange {
    return remoteDataSource.onStatusChange.map((status) {
      return status == InternetStatus.connected
          ? NetworkStatus.online
          : NetworkStatus.offline;
    });
  }

  @override
  Future<NetworkStatus> get currentStatus async {
    try {
      // 1. Check physical/hardware network interfaces
      final connectivityResults = await _connectivity.checkConnectivity();
      final bool hasNoNetwork = connectivityResults.isEmpty ||
          connectivityResults.contains(ConnectivityResult.none);

      if (hasNoNetwork) {
        return NetworkStatus.offline;
      }

      // 2. Active network interface exists; probe internet reachability
      final status = await InternetConnection().internetStatus.timeout(
        const Duration(seconds: 3),
      );
      if (status == InternetStatus.connected) {
        return NetworkStatus.online;
      }

      // Quick retry in case of a brief radio wake-up delay
      await Future.delayed(const Duration(milliseconds: 500));
      final retryStatus = await InternetConnection().internetStatus.timeout(
        const Duration(seconds: 3),
      );
      return retryStatus == InternetStatus.connected
          ? NetworkStatus.online
          : NetworkStatus.offline;
    } catch (_) {
      try {
        final results = await _connectivity.checkConnectivity();
        if (results.isEmpty || results.contains(ConnectivityResult.none)) {
          return NetworkStatus.offline;
        }
        // Active WiFi/Mobile interface is present, avoid false offline on single probe timeout
        return NetworkStatus.online;
      } catch (_) {
        return NetworkStatus.offline;
      }
    }
  }
}