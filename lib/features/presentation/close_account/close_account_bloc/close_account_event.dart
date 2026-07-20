part of 'close_account_bloc.dart';

@immutable
abstract class CloseAccountEvent extends Equatable {
  const CloseAccountEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCloseAccountEvent extends CloseAccountEvent {
  const InitializeCloseAccountEvent();
}

class ConfirmationCodeChangedEvent extends CloseAccountEvent {
  final String code;
  const ConfirmationCodeChangedEvent(this.code);

  @override
  List<Object?> get props => [code];
}

class ToggleTermsCheckboxEvent extends CloseAccountEvent {
  final bool isChecked;
  const ToggleTermsCheckboxEvent({required this.isChecked});

  @override
  List<Object?> get props => [isChecked];
}

class SubmitCloseAccountEvent extends CloseAccountEvent {
  const SubmitCloseAccountEvent();
}

class SyncAndCloseAccountEvent extends CloseAccountEvent {
  const SyncAndCloseAccountEvent();
}

class ForceCloseAccountEvent extends CloseAccountEvent {
  const ForceCloseAccountEvent();
}
