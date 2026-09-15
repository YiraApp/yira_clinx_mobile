import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/neetwork_repo/network_repo.dart';
part 'network_event.dart';
part 'network_state.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  final NetworkRepository _networkRepository;
  StreamSubscription? _networkSubscription;
  Timer? _offlineGraceTimer;

  NetworkBloc({required NetworkRepository networkRepository})
    : _networkRepository = networkRepository,
      super(const NetworkInitial()) {
    on<ObserveNetwork>(_onObserve);
    on<NetworkChanged>(_onNotify);
    on<NetworkStatusChangedEvent>(_onStatusConfirmed);

    add(ObserveNetwork());
  }

  void _onObserve(ObserveNetwork event, Emitter<NetworkState> emit) {
    _networkSubscription?.cancel();
    _networkSubscription = _networkRepository.onStatusChange.listen(
      (status) => add(NetworkChanged(status)),
    );
  }

  void _onNotify(NetworkChanged event, Emitter<NetworkState> emit) async {
    if (event.status == NetworkStatus.online) {
      _offlineGraceTimer?.cancel();
      _offlineGraceTimer = null;
      if (state.status != NetworkStatus.online) {
        emit(const NetworkLoaded(NetworkStatus.online));
      }
      return;
    }

    // When an offline status is received, do NOT flash the banner immediately.
    // Start a 4-second grace period to verify whether the disconnection is persistent.
    _offlineGraceTimer?.cancel();
    _offlineGraceTimer = Timer(const Duration(seconds: 4), () async {
      if (isClosed) return;
      try {
        final current = await _networkRepository.currentStatus.timeout(
          const Duration(seconds: 4),
        );
        if (current == NetworkStatus.offline && !isClosed) {
          add(NetworkStatusChangedEvent(NetworkStatus.offline));
        } else if (current == NetworkStatus.online && !isClosed) {
          add(NetworkStatusChangedEvent(NetworkStatus.online));
        }
      } catch (_) {
        if (!isClosed) {
          add(NetworkStatusChangedEvent(NetworkStatus.offline));
        }
      }
    });
  }

  void _onStatusConfirmed(
    NetworkStatusChangedEvent event,
    Emitter<NetworkState> emit,
  ) {
    if (state.status != event.status) {
      emit(NetworkLoaded(event.status));
    }
  }

  @override
  Future<void> close() {
    _networkSubscription?.cancel();
    _offlineGraceTimer?.cancel();
    return super.close();
  }
}
