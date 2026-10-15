import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/neetwork_repo/network_repo.dart';
part 'network_event.dart';
part 'network_state.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState>
    with WidgetsBindingObserver {
  final NetworkRepository _networkRepository;
  StreamSubscription? _networkSubscription;
  Timer? _offlineGraceTimer;
  bool _isInForeground = true;

  NetworkBloc({required NetworkRepository networkRepository})
    : _networkRepository = networkRepository,
      super(const NetworkInitial()) {
    WidgetsBinding.instance.addObserver(this);

    on<ObserveNetwork>(_onObserve);
    on<NetworkChanged>(_onNotify);
    on<NetworkStatusChangedEvent>(_onStatusConfirmed);
    on<AppResumedNetworkCheckEvent>(_onAppResumedCheck);
    on<RetryNetworkCheckEvent>(_onRetryCheck);

    add(ObserveNetwork());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isInForeground = true;
      _offlineGraceTimer?.cancel();
      _offlineGraceTimer = null;
      add(AppResumedNetworkCheckEvent());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _isInForeground = false;
      _offlineGraceTimer?.cancel();
      _offlineGraceTimer = null;
    }
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

    // When the app is in the background or in the Recents (task switcher) view,
    // Android restricts background socket access, causing socket checks to fail.
    // We suppress offline transitions while the app is not in the foreground.
    if (!_isInForeground) {
      return;
    }

    // When an offline status is received in foreground, do NOT flash the banner immediately.
    // Start a 6-second grace period to verify whether the disconnection is persistent.
    _offlineGraceTimer?.cancel();
    _offlineGraceTimer = Timer(const Duration(seconds: 6), () async {
      if (isClosed || !_isInForeground) return;
      try {
        final current = await _networkRepository.currentStatus.timeout(
          const Duration(seconds: 4),
        );
        if (current == NetworkStatus.offline && !isClosed && _isInForeground) {
          add(NetworkStatusChangedEvent(NetworkStatus.offline));
        } else if (current == NetworkStatus.online && !isClosed) {
          add(NetworkStatusChangedEvent(NetworkStatus.online));
        }
      } catch (_) {
        if (!isClosed && _isInForeground) {
          add(NetworkStatusChangedEvent(NetworkStatus.offline));
        }
      }
    });
  }

  Future<void> _onAppResumedCheck(
    AppResumedNetworkCheckEvent event,
    Emitter<NetworkState> emit,
  ) async {
    // Give mobile radios and socket stack 1.2s to wake up after the app is resumed
    await Future.delayed(const Duration(milliseconds: 1200));
    if (isClosed || !_isInForeground) return;

    try {
      final current = await _networkRepository.currentStatus.timeout(
        const Duration(seconds: 4),
      );
      if (isClosed || !_isInForeground) return;

      if (current == NetworkStatus.online) {
        if (state.status != NetworkStatus.online) {
          emit(const NetworkLoaded(NetworkStatus.online));
        }
      } else {
        if (state.status != NetworkStatus.offline) {
          emit(const NetworkLoaded(NetworkStatus.offline));
        }
      }
    } catch (_) {
      // In case of timeout during radio wake-up, do not trigger false offline
    }
  }

  Future<void> _onRetryCheck(
    RetryNetworkCheckEvent event,
    Emitter<NetworkState> emit,
  ) async {
    try {
      final current = await _networkRepository.currentStatus.timeout(
        const Duration(seconds: 4),
      );
      if (current == NetworkStatus.online) {
        _offlineGraceTimer?.cancel();
        _offlineGraceTimer = null;
        emit(const NetworkLoaded(NetworkStatus.online));
        event.completer?.complete(true);
      } else {
        if (state.status != NetworkStatus.offline) {
          emit(const NetworkLoaded(NetworkStatus.offline));
        }
        event.completer?.complete(false);
      }
    } catch (_) {
      if (state.status != NetworkStatus.offline) {
        emit(const NetworkLoaded(NetworkStatus.offline));
      }
      event.completer?.complete(false);
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _networkSubscription?.cancel();
    _offlineGraceTimer?.cancel();
    return super.close();
  }
}
