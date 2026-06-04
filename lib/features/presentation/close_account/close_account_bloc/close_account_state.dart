part of 'close_account_bloc.dart';

enum CloseAccountStatus { initial, submitting, success, failure }
@immutable

class CloseAccountState extends Equatable {
  final CloseAccountStatus status;
  final String generatedVerificationCode;
  final String inputCode;
  final bool isTCOnchecked;
  final bool hasUnsyncedData;
  final String? errorMessage;

  const CloseAccountState({
    this.status = CloseAccountStatus.initial,
    this.generatedVerificationCode = '',
    this.inputCode = '',
    this.isTCOnchecked = false,
    this.hasUnsyncedData = false,
    this.errorMessage,
  });

  bool get isCodeValid => inputCode == generatedVerificationCode && inputCode.length == 6;

  CloseAccountState copyWith({
    CloseAccountStatus? status,
    String? generatedVerificationCode,
    String? inputCode,
    bool? isTCOnchecked,
    bool? hasUnsyncedData,
    String? errorMessage,
  }) {
    return CloseAccountState(
      status: status ?? this.status,
      generatedVerificationCode: generatedVerificationCode ?? this.generatedVerificationCode,
      inputCode: inputCode ?? this.inputCode,
      isTCOnchecked: isTCOnchecked ?? this.isTCOnchecked,
      hasUnsyncedData: hasUnsyncedData ?? this.hasUnsyncedData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    generatedVerificationCode,
    inputCode,
    isTCOnchecked,
    hasUnsyncedData,
    errorMessage,
  ];
}
