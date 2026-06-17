
// data/repositories/network_repository_impl.dart
import 'dart:async';
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

  NetworkRepositoryImpl({required this.remoteDataSource});

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
    final status = await InternetConnection().internetStatus;
    return status == InternetStatus.connected ? NetworkStatus.online : NetworkStatus.offline;
  }
}