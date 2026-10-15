import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/network_services/domain/neetwork_repo/network_repo.dart';
import '../services/network_services/network_bloc/network_bloc.dart';
import 'no_internet_screen.dart';

class InternetGuard extends StatelessWidget {
  final Widget? child;

  const InternetGuard({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ?child,
        BlocBuilder<NetworkBloc, NetworkState>(
          buildWhen: (previous, current) => previous.status != current.status,
          builder: (context, state) {
            final bool isOffline = state.status == NetworkStatus.offline;
            return Positioned.fill(
              child: IgnorePointer(
                ignoring: !isOffline,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  opacity: isOffline ? 1.0 : 0.0,
                  curve: Curves.easeInOut,
                  child: isOffline ? const NoInternetScreen() : const SizedBox.shrink(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}