import 'package:yiraclinics/features/domain/entities/insurance/patient_insurance_policy_entity.dart';

class PatientInsurancePolicyModel extends PatientInsurancePolicyEntity {
  const PatientInsurancePolicyModel({
    super.id,
    required super.userId,
    required super.policyHolder,
    required super.policyName,
    required super.insuranceProvider,
    required super.policyNumber,
    super.startDate,
    super.endDate,
    super.documentUrl,
    super.localFilePath,
    super.status,
    super.isDeleted,
    super.createdAt,
    super.updatedAt,
  });

  factory PatientInsurancePolicyModel.fromJson(Map<String, dynamic> json) {
    return PatientInsurancePolicyModel(
      id: json['id'] ?? json['Id'],
      userId: (json['userId'] ?? json['UserId'] ?? '').toString(),
      policyHolder: (json['policyHolder'] ?? json['PolicyHolder'] ?? json['name'] ?? '').toString(),
      policyName: (json['policyName'] ?? json['PolicyName'] ?? json['planName'] ?? '').toString(),
      insuranceProvider: (json['insuranceProvider'] ??
              json['InsuranceProvider'] ??
              json['provider'] ??
              json['company'] ??
              '')
          .toString(),
      policyNumber: (json['policyNumber'] ?? json['InsuranceNumber'] ?? json['number'] ?? '').toString(),
      startDate: json['startDate'] ?? json['StartDate'],
      endDate: json['endDate'] ?? json['EndDate'],
      documentUrl: json['documentUrl'] ?? json['DocumentUrl'],
      localFilePath: json['localFilePath'],
      status: json['status'] ?? json['Status'] ?? true,
      isDeleted: json['isDeleted'] ?? json['IsDeleted'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'policyHolder': policyHolder,
      'policyName': policyName,
      'insuranceProvider': insuranceProvider,
      'policyNumber': policyNumber,
      'startDate': startDate,
      'endDate': endDate,
      'documentUrl': documentUrl,
      'localFilePath': localFilePath,
      'status': status,
      'isDeleted': isDeleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  PatientInsurancePolicyModel copyWith({
    dynamic id,
    String? userId,
    String? policyHolder,
    String? policyName,
    String? insuranceProvider,
    String? policyNumber,
    String? startDate,
    String? endDate,
    String? documentUrl,
    String? localFilePath,
    bool? status,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PatientInsurancePolicyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      policyHolder: policyHolder ?? this.policyHolder,
      policyName: policyName ?? this.policyName,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      policyNumber: policyNumber ?? this.policyNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      documentUrl: documentUrl ?? this.documentUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
