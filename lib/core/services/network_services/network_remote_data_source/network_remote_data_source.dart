

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

abstract class NetworkRemoteDataSource {
  Stream<InternetStatus> get onStatusChange;
}