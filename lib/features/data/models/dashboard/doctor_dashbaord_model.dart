import 'package:flutter/foundation.dart';
import '../../../domain/entities/dashboard/doctor_dashboard_entity.dart';

class DoctorDashBoardModel extends DoctorDashboardEntity {
  const DoctorDashBoardModel({
    required super.status,
    required super.message,
    super.data,
  });

  factory DoctorDashBoardModel.fromJson(Map<String, dynamic> json) {
    try {
      return DoctorDashBoardModel(
        status: json['status'] as bool? ?? false,
        message: json['message'] as String? ?? '',
        data: json['data'] != null ? DataModel.fromJson(json['data']) : null,
      );
    } catch (e, stackTrace) {
      debugPrint('Parsing error in DoctorDashBoardModel: $e\n$stackTrace');
      return DoctorDashBoardModel(
        status: false,
        message: 'Data parsing error encountered.',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data != null ? DataModel.fromEntity(data!).toJson() : null,
    };
  }
}

class DataModel extends DashboardDataEntity {
  const DataModel({
    required super.profile,
    required super.metrics,
    required super.todaysSchedule,
    required super.recentPatients,
    required super.weeklyAppointments,
    required super.monthlyPatients,
  });

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      profile: ProfileModel.fromJson(
        json['profile'] as Map<String, dynamic>? ?? {},
      ),
      metrics: MetricsModel.fromJson(
        json['metrics'] as Map<String, dynamic>? ?? {},
      ),
      todaysSchedule: (json['todaysSchedule'] as List? ?? [])
          .map((v) => TodaysScheduleModel.fromJson(v as Map<String, dynamic>))
          .toList(),
      recentPatients: (json['recentPatients'] as List? ?? [])
          .map((v) => RecentPatientsModel.fromJson(v as Map<String, dynamic>))
          .toList(),
      weeklyAppointments: WeeklyAppointmentsModel.fromJson(
        json['weeklyAppointments'] as Map<String, dynamic>? ?? {},
      ),
      monthlyPatients: MonthlyPatientsModel.fromJson(
        json['monthlyPatients'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  factory DataModel.fromEntity(DashboardDataEntity entity) {
    return DataModel(
      profile: entity.profile,
      metrics: entity.metrics,
      todaysSchedule: entity.todaysSchedule,
      recentPatients: entity.recentPatients,
      weeklyAppointments: entity.weeklyAppointments,
      monthlyPatients: entity.monthlyPatients,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': ProfileModel.fromEntity(profile).toJson(),
      'metrics': MetricsModel.fromEntity(metrics).toJson(),
      'todaysSchedule': todaysSchedule
          .map((v) => TodaysScheduleModel.fromEntity(v).toJson())
          .toList(),
      'recentPatients': recentPatients
          .map((v) => RecentPatientsModel.fromEntity(v).toJson())
          .toList(),
      'weeklyAppointments': WeeklyAppointmentsModel.fromEntity(
        weeklyAppointments,
      ).toJson(),
      'monthlyPatients': MonthlyPatientsModel.fromEntity(
        monthlyPatients,
      ).toJson(),
    };
  }
}

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.name,
    required super.specialty,
    required super.clinicAddress,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['name'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      clinicAddress: json['clinicAddress'] as String? ?? '',
    );
  }

  factory ProfileModel.fromEntity(ProfileEntity entity) {
    return ProfileModel(
      name: entity.name,
      specialty: entity.specialty,
      clinicAddress: entity.clinicAddress,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'specialty': specialty,
    'clinicAddress': clinicAddress,
  };
}

class MetricsModel extends MetricsEntity {
  const MetricsModel({
    required super.today,
    required super.patients,
    required super.done,
    required super.stats,
  });

  factory MetricsModel.fromJson(Map<String, dynamic> json) {
    return MetricsModel(
      today: TodayModel.fromJson(
        json['today'] as Map<String, dynamic>? ?? {},
        'Today',
      ),
      patients: TodayModel.fromJson(
        json['patients'] as Map<String, dynamic>? ?? {},
        'Patients',
      ),
      done: TodayModel.fromJson(
        json['done'] as Map<String, dynamic>? ?? {},
        'Done',
      ),
      stats: TodayModel.fromJson(
        json['stats'] as Map<String, dynamic>? ?? {},
        'Stats',
      ),
    );
  }

  factory MetricsModel.fromEntity(MetricsEntity entity) {
    return MetricsModel(
      today: entity.today,
      patients: entity.patients,
      done: entity.done,
      stats: entity.stats,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'today': TodayModel.fromEntity(today).toJson(),
      'patients': TodayModel.fromEntity(patients).toJson(),
      'done': TodayModel.fromEntity(done).toJson(),
      'stats': TodayModel.fromEntity(stats).toJson(),
    };
  }
}

class TodayModel extends MetricCardEntity {
  const TodayModel({
    required super.title,
    required super.value,
    required super.subtext,
  });

  factory TodayModel.fromJson(Map<String, dynamic> json, String fallbackTitle) {
    return TodayModel(
      title: json['title'] as String? ?? fallbackTitle,
      value: (json['value'] as num? ?? 0).toInt(),
      subtext: json['subtext'] as String? ?? '',
    );
  }

  factory TodayModel.fromEntity(MetricCardEntity entity) {
    return TodayModel(
      title: entity.title,
      value: entity.value,
      subtext: entity.subtext,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'value': value,
    'subtext': subtext,
  };
}

class TodaysScheduleModel extends TodaysScheduleEntity {
  const TodaysScheduleModel({
    required super.patientUserId,
    required super.orgId,
    required super.hospitalId,
    required super.appointmentId,
    required super.patientName,
    required super.time,
    required super.consultationType,
    required super.reason,
    required super.statusTag,
  });

  factory TodaysScheduleModel.fromJson(Map<String, dynamic> json) {
    return TodaysScheduleModel(
      patientUserId: (json['patientUserId'] as num? ?? 0).toInt(),
      orgId: (json['orgId'] as num? ?? 0).toInt(),
      hospitalId: (json['hospitalId'] as num? ?? 0).toInt(),
      appointmentId: (json['appointmentId'] as num? ?? 0).toInt(),
      patientName: json['patientName'] as String? ?? '',
      time: json['time'] as String? ?? '',
      consultationType: json['consultationType'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      statusTag: json['statusTag'] as String? ?? '',
    );
  }

  factory TodaysScheduleModel.fromEntity(TodaysScheduleEntity entity) {
    return TodaysScheduleModel(
      patientUserId: entity.patientUserId,
      orgId: entity.orgId,
      hospitalId: entity.hospitalId,
      appointmentId: entity.appointmentId,
      patientName: entity.patientName,
      time: entity.time,
      consultationType: entity.consultationType,
      reason: entity.reason,
      statusTag: entity.statusTag,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientUserId': patientUserId,
      'orgId': orgId,
      'hospitalId': hospitalId,
      'appointmentId': appointmentId,
      'patientName': patientName,
      'time': time,
      'consultationType': consultationType,
      'reason': reason,
      'statusTag': statusTag,
    };
  }
}

class RecentPatientsModel extends RecentPatientsEntity {
  const RecentPatientsModel({
    required super.patientUserId,
    required super.orgId,
    required super.hospitalId,
    required super.appointmentId,
    required super.name,
    required super.date,
    required super.consultationType,
    required super.condition,
    required super.status,
  });

  factory RecentPatientsModel.fromJson(Map<String, dynamic> json) {
    return RecentPatientsModel(
      patientUserId: (json['patientUserId'] as num? ?? 0).toInt(),
      orgId: (json['orgId'] as num? ?? 0).toInt(),
      hospitalId: (json['hospitalId'] as num? ?? 0).toInt(),
      appointmentId: (json['appointmentId'] as num? ?? 0).toInt(),
      name: json['name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      consultationType: json['consultationType'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  factory RecentPatientsModel.fromEntity(RecentPatientsEntity entity) {
    return RecentPatientsModel(
      patientUserId: entity.patientUserId,
      orgId: entity.orgId,
      hospitalId: entity.hospitalId,
      appointmentId: entity.appointmentId,
      name: entity.name,
      date: entity.date,
      consultationType: entity.consultationType,
      condition: entity.condition,
      status: entity.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientUserId': patientUserId,
      'orgId': orgId,
      'hospitalId': hospitalId,
      'appointmentId': appointmentId,
      'name': name,
      'date': date,
      'consultationType': consultationType,
      'condition': condition,
      'status': status,
    };
  }
}

class WeeklyAppointmentsModel extends WeeklyAppointmentsEntity {
  const WeeklyAppointmentsModel({
    required super.averagePerDay,
    required super.dailyData,
  });

  factory WeeklyAppointmentsModel.fromJson(Map<String, dynamic> json) {
    return WeeklyAppointmentsModel(
      averagePerDay: (json['averagePerDay'] as num? ?? 0).toInt(),
      dailyData: (json['dailyData'] as List? ?? [])
          .map((v) => ChartDataPointModel.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  factory WeeklyAppointmentsModel.fromEntity(WeeklyAppointmentsEntity entity) {
    return WeeklyAppointmentsModel(
      averagePerDay: entity.averagePerDay,
      dailyData: entity.dailyData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averagePerDay': averagePerDay,
      'dailyData': dailyData
          .map((v) => ChartDataPointModel.fromEntity(v).toJson())
          .toList(),
    };
  }
}

class MonthlyPatientsModel extends MonthlyPatientsEntity {
  const MonthlyPatientsModel({
    required super.yearlyTotal,
    required super.monthlyData,
  });

  factory MonthlyPatientsModel.fromJson(Map<String, dynamic> json) {
    return MonthlyPatientsModel(
      yearlyTotal: (json['yearlyTotal'] as num? ?? 0).toInt(),
      monthlyData: (json['monthlyData'] as List? ?? [])
          .map((v) => ChartDataPointModel.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  factory MonthlyPatientsModel.fromEntity(MonthlyPatientsEntity entity) {
    return MonthlyPatientsModel(
      yearlyTotal: entity.yearlyTotal,
      monthlyData: entity.monthlyData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'yearlyTotal': yearlyTotal,
      'monthlyData': monthlyData
          .map((v) => ChartDataPointModel.fromEntity(v).toJson())
          .toList(),
    };
  }
}

class ChartDataPointModel extends ChartDataPoint {
  const ChartDataPointModel({required super.label, required super.value});

  factory ChartDataPointModel.fromJson(Map<String, dynamic> json) {
    return ChartDataPointModel(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num? ?? 0.0).toDouble(),
    );
  }

  factory ChartDataPointModel.fromEntity(ChartDataPoint entity) {
    return ChartDataPointModel(label: entity.label, value: entity.value);
  }

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}
