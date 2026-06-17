import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../domain/neetwork_repo/network_repo.dart';

part 'network_event.dart';
part 'network_state.dart';

class NetworkBloc extends Bloc<NetworkEvent, NetworkState> {
  final NetworkRepository _networkRepository;
  StreamSubscription? _networkSubscription;

  NetworkBloc({required NetworkRepository networkRepository})
      : _networkRepository = networkRepository,
        super(const NetworkInitial()) {
    on<ObserveNetwork>(_onObserve);
    on<NetworkChanged>(_onNotify);

    // Automatically trigger observation on creation
    add(ObserveNetwork());
  }

  void _onObserve(ObserveNetwork event, Emitter<NetworkState> emit) {
    _networkSubscription?.cancel();
    _networkSubscription = _networkRepository.onStatusChange.listen(
          (status) => add(NetworkChanged(status)),
    );
  }

  void _onNotify(NetworkChanged event, Emitter<NetworkState> emit) {
    emit(NetworkLoaded(event.status));
  }

  @override
  Future<void> close() {
    _networkSubscription?.cancel();
    return super.close();
  }
}
