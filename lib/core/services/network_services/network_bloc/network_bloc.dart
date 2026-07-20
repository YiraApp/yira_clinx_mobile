import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../domain/neetwork_repo/network_repo.dart';
part 'network_event.dart';
part 'network_state.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  final NetworkRepository _networkRepository;
  StreamSubscription? _networkSubscription;
  Timer? _debounceTimer;
  NetworkBloc({required NetworkRepository networkRepository})
    : _networkRepository = networkRepository,
      super(const NetworkInitial()) {
    on<ObserveNetwork>(_onObserve);
    on<NetworkChanged>(_onNotify);

    add(ObserveNetwork());
  }
  void _onObserve(ObserveNetwork event, Emitter<NetworkState> emit) {
    _networkSubscription?.cancel();
    _networkSubscription = _networkRepository.onStatusChange.listen(
      (status) => add(NetworkChanged(status)),
    );
  }

  void _onNotify(NetworkChanged event, Emitter<NetworkState> emit) async {
    _debounceTimer?.cancel();

    if (event.status == NetworkStatus.online) {
      emit(NetworkLoaded(NetworkStatus.online));
      return;
    }
    try {
      final actualStatus = await _networkRepository.currentStatus.timeout(
        const Duration(milliseconds: 600),
      );

      if (actualStatus == NetworkStatus.offline) {
        emit(NetworkLoaded(NetworkStatus.offline));
      } else {
        _startDebounceGracePeriod(event.status, emit);
      }
    } catch (_) {
      emit(NetworkLoaded(NetworkStatus.offline));
    }
  }

  void _startDebounceGracePeriod(
    NetworkStatus status,
    Emitter<NetworkState> emit,
  ) {
    _debounceTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!isClosed) {
        emit(NetworkLoaded(status));
      }
    });
  }

  @override
  Future<void> close() {
    _networkSubscription?.cancel();
    _debounceTimer?.cancel();
    return super.close();
  }
}
