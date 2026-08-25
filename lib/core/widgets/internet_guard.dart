import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../services/network_services/domain/neetwork_repo/network_repo.dart';
import '../services/network_services/network_bloc/network_bloc.dart';

class InternetGuard extends StatelessWidget {
  final Widget? child;

  const InternetGuard({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (child != null) child!,
        BlocBuilder<NetworkBloc, NetworkState>(
          buildWhen: (previous, current) => previous.status != current.status,
          builder: (context, state) {
            final bool isOffline = state.status == NetworkStatus.offline;
            if (!isOffline) {
              return const SizedBox.shrink();
            }

            return const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _OfflineBottomBanner(),
            );
          },
        ),
      ],
    );
  }
}

class _OfflineBottomBanner extends StatelessWidget {
  const _OfflineBottomBanner();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double screenWidth = mediaQuery.size.width;
    final bool isTabletDevice = mediaQuery.size.shortestSide >= 600;
    final double safeBottomPadding = mediaQuery.padding.bottom;

    final double fontSize = isTabletDevice
        ? screenWidth * 0.016
        : screenWidth * 0.034;

    final double iconSize = isTabletDevice ? 22.0 : 18.0;

    return Container(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 14.0,
        bottom: safeBottomPadding > 0 ? safeBottomPadding + 8.0 : 14.0,
      ),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: Colors.white,
            size: iconSize,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "No Internet Connection. Waiting for network to stabilize...",
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                fontFamily: appPoppinFont,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const _LivePulseDot(),
        ],
      ),
    );
  }
}

class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot();

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.white54,
              blurRadius: 4,
              spreadRadius: 1,
            )
          ],
        ),
      ),
    );
  }
}