import 'package:equatable/equatable.dart';

class PatientInsurancePolicyEntity extends Equatable {
  final dynamic id;
  final String userId;
  final String policyHolder;
  final String policyName;
  final String insuranceProvider;
  final String policyNumber;
  final String? startDate;
  final String? endDate;
  final String? documentUrl;
  final String? localFilePath;
  final bool status;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatientInsurancePolicyEntity({
    this.id,
    required this.userId,
    required this.policyHolder,
    required this.policyName,
    required this.insuranceProvider,
    required this.policyNumber,
    this.startDate,
    this.endDate,
    this.documentUrl,
    this.localFilePath,
    this.status = true,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  String get validityText {
    if ((startDate == null || startDate!.trim().isEmpty) &&
        (endDate == null || endDate!.trim().isEmpty)) {
      return 'Lifetime / N/A';
    }
    final s = startDate?.trim().isNotEmpty == true ? startDate!.trim() : 'N/A';
    final e = endDate?.trim().isNotEmpty == true ? endDate!.trim() : 'Ongoing';
    return '$s - $e';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        policyHolder,
        policyName,
        insuranceProvider,
        policyNumber,
        startDate,
        endDate,
        documentUrl,
        localFilePath,
        status,
        isDeleted,
      ];
}
