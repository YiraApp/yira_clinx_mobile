import '../../../domain/entities/appointments/appointment_entity.dart';

class AppointmentModel extends Appointment {
  const AppointmentModel({
    required super.id,
    required super.tokenNumber,
    required super.time,
    required super.duration,
    required super.patientName,
    required super.phoneNumber,
    required super.type,
    required super.category,
    required super.status,
    super.statusRaw = '',
    super.patientStatus,
    super.patientUserId,
    super.doctorName = 'Doctor',
    super.relation = 'Self',
    super.isPrimary = true,
    super.orgId,
    super.hospitalId,
    super.hospitalName,
    super.organizationName,
    super.reason,
    super.meetingUrl,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    AppointmentType appType = AppointmentType.inClinic;
    final typeStr = (json['type'] ?? json['appointmentType'] ?? '').toString().toLowerCase();
    if (typeStr.contains('video') || typeStr.contains('tele')) {
      appType = AppointmentType.videoCall;
    }

    AppointmentStatus appStatus = AppointmentStatus.confirmed;
    final statusStr = (json['status'] ?? '').toString().toLowerCase();
    if (statusStr.contains('pending')) {
      appStatus = AppointmentStatus.paymentPending;
    } else if (statusStr.contains('info')) {
      appStatus = AppointmentStatus.pendingInfo;
    }

    String patientStatusStr = (json['patientStatus'] ?? json['patient_status'] ?? '').toString();
    if (patientStatusStr.toLowerCase() == 'active' || patientStatusStr.toLowerCase() == 'inactive') {
      patientStatusStr = '';
    }
    if (patientStatusStr.isEmpty) {
      final cat = (json['category'] ?? json['type'] ?? '').toString().toLowerCase();
      final reas = (json['reason'] ?? '').toString().toLowerCase();
      if (cat.contains('follow') || reas.contains('follow')) {
        patientStatusStr = 'Follow-up';
      } else if (cat.contains('new') || reas.contains('new')) {
        patientStatusStr = 'New Patient';
      } else {
        patientStatusStr = '';
      }
    }

    return AppointmentModel(
      id: (json['id'] ?? '').toString(),
      tokenNumber: (json['tokenNumber'] ?? 'Token #1').toString(),
      time: (json['time'] ?? json['appointmentDate'] ?? '').toString(),
      duration: (json['duration'] ?? json['startTime'] ?? '30 MIN').toString(),
      patientName: (json['patientName'] ?? 'Patient').toString(),
      doctorName: (json['doctorName'] ?? 'Doctor').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      type: appType,
      category: (json['category'] ?? json['appointmentType'] ?? 'Consultation').toString(),
      status: appStatus,
      statusRaw: (json['status'] ?? 'Scheduled').toString(),
      patientStatus: patientStatusStr,
      patientUserId: json['patientUserId']?.toString(),
      relation: (json['relation'] ?? 'Self').toString(),
      isPrimary: json['isPrimary'] == true || (json['relation'] ?? 'Self').toString().toLowerCase() == 'self',
      orgId: json['orgId'] is int ? json['orgId'] : int.tryParse((json['orgId'] ?? '').toString()),
      hospitalId: json['hospitalId'] is int ? json['hospitalId'] : int.tryParse((json['hospitalId'] ?? '').toString()),
      hospitalName: (json['hospitalName'] ?? json['hospital_name'] ?? '').toString(),
      organizationName: (json['organizationName'] ?? json['orgName'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      meetingUrl: (json['meetingUrl'] ?? json['meeting_url'] ?? json['videoCallUrl'] ?? json['MeetingUrl'])?.toString(),
    );
  }
}

class AppointmentDashboardDataModel {
  final int todayCount;
  final int confirmedCount;
  final int pendingCount;
  final int completedCount;
  final int aiOptimizationScore;
  final List<AppointmentModel> appointments;

  const AppointmentDashboardDataModel({
    required this.todayCount,
    required this.confirmedCount,
    required this.pendingCount,
    this.completedCount = 0,
    required this.aiOptimizationScore,
    required this.appointments,
  });

  factory AppointmentDashboardDataModel.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] ?? json;
    final aptListRaw = (payload['appointments'] as List<dynamic>?) ?? [];

    return AppointmentDashboardDataModel(
      todayCount: payload['todayCount'] ?? 0,
      confirmedCount: payload['confirmedCount'] ?? 0,
      pendingCount: payload['pendingCount'] ?? 0,
      completedCount: payload['completedCount'] ?? 0,
      aiOptimizationScore: payload['aiOptimizationScore'] ?? 94,
      appointments: aptListRaw
          .map((item) => AppointmentModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
