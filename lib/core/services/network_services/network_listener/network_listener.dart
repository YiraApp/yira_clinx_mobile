
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/network_services/domain/neetwork_repo/network_repo.dart';
import '../../../../core/services/network_services/network_bloc/network_bloc.dart';

class NetworkListener extends StatelessWidget {
  final VoidCallback onOnline;
  final Widget child;

  const NetworkListener({
    super.key,
    required this.onOnline,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<NetworkBloc, NetworkState>(
      listenWhen: (previous, current) =>
      previous.status == NetworkStatus.offline && current.status == NetworkStatus.online,
      listener: (context, state) => onOnline(),
      child: child,
    );
  }
}