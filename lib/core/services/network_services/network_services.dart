
import 'dart:async';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final InternetConnection _connectionChecker = InternetConnection();

  Stream<InternetStatus> get onStatusChange => _connectionChecker.onStatusChange;

  Future<bool> hasInternet() async {
    return await _connectionChecker.hasInternetAccess;
  }
}