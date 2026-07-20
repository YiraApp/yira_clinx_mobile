import '../../../domain/entities/dashboard/doctor_dashboard_entity.dart';


class DoctorDashBoardModel extends DoctorDashboardEntity {
  DoctorDashBoardModel({
    super.status,
    super.message,
    DashboardDataModel? super.data,
  });

  factory DoctorDashBoardModel.fromJson(Map<String, dynamic> json) {
    return DoctorDashBoardModel(
      status: json['status'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null ? DashboardDataModel.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      if (data != null) 'data': (data as DashboardDataModel).toJson(),
    };
  }
}

class DashboardDataModel extends DashboardDataEntity {
  DashboardDataModel({
    super.orgId,
    super.orgName,
    super.hospitalId,
    super.hospitalName,
    DoctorProfileModel? super.profile,
    DashboardMetricsModel? super.metrics,
    List<TodaysScheduleModel>? super.todaysSchedule,
    List<RecentPatientsModel>? super.recentPatients,
    WeeklyAppointmentsModel? super.weeklyAppointments,
    MonthlyPatientsModel? super.monthlyPatients,
  });

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    return DashboardDataModel(
      orgId: json['orgId'] as int?,
      orgName: json['orgName'] as String?,
      hospitalId: json['hospitalId'] as int?,
      hospitalName: json['hospitalName'] as String?,
      profile: json['profile'] != null ? DoctorProfileModel.fromJson(json['profile']) : null,
      metrics: json['metrics'] != null ? DashboardMetricsModel.fromJson(json['metrics']) : null,
      todaysSchedule: json['todaysSchedule'] != null
          ? (json['todaysSchedule'] as List).map((v) => TodaysScheduleModel.fromJson(v)).toList()
          : null,
      recentPatients: json['recentPatients'] != null
          ? (json['recentPatients'] as List).map((v) => RecentPatientsModel.fromJson(v)).toList()
          : null,
      weeklyAppointments: json['weeklyAppointments'] != null
          ? WeeklyAppointmentsModel.fromJson(json['weeklyAppointments'])
          : null,
      monthlyPatients: json['monthlyPatients'] != null
          ? MonthlyPatientsModel.fromJson(json['monthlyPatients'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orgId': orgId,
      'orgName': orgName,
      'hospitalId': hospitalId,
      'hospitalName': hospitalName,
      if (profile != null) 'profile': (profile as DoctorProfileModel).toJson(),
      if (metrics != null) 'metrics': (metrics as DashboardMetricsModel).toJson(),
      if (todaysSchedule != null)
        'todaysSchedule': todaysSchedule!.map((v) => (v as TodaysScheduleModel).toJson()).toList(),
      if (recentPatients != null)
        'recentPatients': recentPatients!.map((v) => (v as RecentPatientsModel).toJson()).toList(),
      if (weeklyAppointments != null)
        'weeklyAppointments': (weeklyAppointments as WeeklyAppointmentsModel).toJson(),
      if (monthlyPatients != null) 'monthlyPatients': (monthlyPatients as MonthlyPatientsModel).toJson(),
    };
  }
}

class DoctorProfileModel extends DoctorProfileEntity {
  DoctorProfileModel({super.name, super.specialty, super.clinicAddress});

  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) {
    return DoctorProfileModel(
      name: json['name'] as String?,
      specialty: json['specialty'] as String?,
      clinicAddress: json['clinicAddress'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialty': specialty,
      'clinicAddress': clinicAddress,
    };
  }
}

class DashboardMetricsModel extends DashboardMetricsEntity {
  DashboardMetricsModel({
    MetricItemModel? super.today,
    MetricItemModel? super.patients,
    MetricItemModel? super.done,
    MetricItemModel? super.stats,
  });

  factory DashboardMetricsModel.fromJson(Map<String, dynamic> json) {
    return DashboardMetricsModel(
      today: json['today'] != null ? MetricItemModel.fromJson(json['today']) : null,
      patients: json['patients'] != null ? MetricItemModel.fromJson(json['patients']) : null,
      done: json['done'] != null ? MetricItemModel.fromJson(json['done']) : null,
      stats: json['stats'] != null ? MetricItemModel.fromJson(json['stats']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (today != null) 'today': (today as MetricItemModel).toJson(),
      if (patients != null) 'patients': (patients as MetricItemModel).toJson(),
      if (done != null) 'done': (done as MetricItemModel).toJson(),
      if (stats != null) 'stats': (stats as MetricItemModel).toJson(),
    };
  }
}

class MetricItemModel extends MetricItemEntity {
  MetricItemModel({super.title, super.value, super.subtext});

  factory MetricItemModel.fromJson(Map<String, dynamic> json) {
    return MetricItemModel(
      title: json['title'] as String?,
      value: json['value'] as int?,
      subtext: json['subtext'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'value': value,
      'subtext': subtext,
    };
  }
}

class TodaysScheduleModel extends TodaysScheduleEntity {
  TodaysScheduleModel({
    super.patientUserId,
    super.orgId,
    super.hospitalId,
    super.appointmentId,
    super.patientName,
    super.time,
    super.consultationType,
    super.reason,
    super.statusTag,
  });

  factory TodaysScheduleModel.fromJson(Map<String, dynamic> json) {
    return TodaysScheduleModel(
      patientUserId: json['patientUserId'],
      orgId: json['orgId'] as int?,
      hospitalId: json['hospitalId'] as int?,
      appointmentId: json['appointmentId'] as int?,
      patientName: json['patientName'] as String?,
      time: json['time'] as String?,
      consultationType: json['consultationType'] as String?,
      reason: json['reason'] as String?,
      statusTag: json['statusTag'] as String?,
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
  RecentPatientsModel({
    super.patientUserId,
    super.orgId,
    super.hospitalId,
    super.appointmentId,
    super.name,
    super.date,
    super.consultationType,
    super.condition,
    super.status,
  });

  factory RecentPatientsModel.fromJson(Map<String, dynamic> json) {
    return RecentPatientsModel(
      patientUserId: json['patientUserId']  as String?,
      orgId: json['orgId'] as int?,
      hospitalId: json['hospitalId'] as int?,
      appointmentId: json['appointmentId'] as int?,
      name: json['name'] as String?,
      date: json['date'] as String?,
      consultationType: json['consultationType'] as String?,
      condition: json['condition'] as String?,
      status: json['status'] as String?,
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
  WeeklyAppointmentsModel({super.averagePerDay, List<DailyDataModel>? super.dailyData});

  factory WeeklyAppointmentsModel.fromJson(Map<String, dynamic> json) {
    return WeeklyAppointmentsModel(
      averagePerDay: json['averagePerDay'] as int?,
      dailyData: json['dailyData'] != null
          ? (json['dailyData'] as List).map((v) => DailyDataModel.fromJson(v)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averagePerDay': averagePerDay,
      if (dailyData != null) 'dailyData': dailyData!.map((v) => (v as DailyDataModel).toJson()).toList(),
    };
  }
}

class DailyDataModel extends DailyDataEntity {
  DailyDataModel({super.label, super.value});

  factory DailyDataModel.fromJson(Map<String, dynamic> json) {
    return DailyDataModel(
      label: json['label'] as String?,
      value: json['value'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }
}

class MonthlyPatientsModel extends MonthlyPatientsEntity {
  MonthlyPatientsModel({super.yearlyTotal, List<MonthlyDataModel>? super.monthlyData});

  factory MonthlyPatientsModel.fromJson(Map<String, dynamic> json) {
    return MonthlyPatientsModel(
      yearlyTotal: json['yearlyTotal'] as int?,
      monthlyData: json['monthlyData'] != null
          ? (json['monthlyData'] as List).map((v) => MonthlyDataModel.fromJson(v)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'yearlyTotal': yearlyTotal,
      if (monthlyData != null) 'monthlyData': monthlyData!.map((v) => (v as MonthlyDataModel).toJson()).toList(),
    };
  }
}

class MonthlyDataModel extends MonthlyDataEntity {
  MonthlyDataModel({super.label, super.value});

  factory MonthlyDataModel.fromJson(Map<String, dynamic> json) {
    return MonthlyDataModel(
      label: json['label'] as String?,
      value: json['value'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }
}