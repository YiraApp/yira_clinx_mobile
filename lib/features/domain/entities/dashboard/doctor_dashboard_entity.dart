class DoctorDashboardEntity {
  final bool? status;
  final String? message;
  final DashboardDataEntity? data;

  const DoctorDashboardEntity({this.status, this.message, this.data});
}

class DashboardDataEntity {
  final int? orgId;
  final String? orgName;
  final int? hospitalId;
  final String? hospitalName;
  final DoctorProfileEntity? profile;
  final DashboardMetricsEntity? metrics;
  final List<TodaysScheduleEntity>? todaysSchedule;
  final List<RecentPatientsEntity>? recentPatients;
  final WeeklyAppointmentsEntity? weeklyAppointments;
  final MonthlyPatientsEntity? monthlyPatients;

  const DashboardDataEntity({
    this.orgId,
    this.orgName,
    this.hospitalId,
    this.hospitalName,
    this.profile,
    this.metrics,
    this.todaysSchedule,
    this.recentPatients,
    this.weeklyAppointments,
    this.monthlyPatients,
  });
}

class DoctorProfileEntity {
  final String? name;
  final String? specialty;
  final String? clinicAddress;

  const DoctorProfileEntity({this.name, this.specialty, this.clinicAddress});
}

class DashboardMetricsEntity {
  final MetricItemEntity? today;
  final MetricItemEntity? patients;
  final MetricItemEntity? done;
  final MetricItemEntity? stats;

  const DashboardMetricsEntity({this.today, this.patients, this.done, this.stats});
}

class MetricItemEntity {
  final String? title;
  final int? value;
  final String? subtext;

  const MetricItemEntity({this.title, this.value, this.subtext});
}

class TodaysScheduleEntity {
  final String? patientUserId;
  final int? orgId;
  final int? hospitalId;
  final int? appointmentId;
  final String? patientName;
  final String? time;
  final String? consultationType;
  final String? reason;
  final String? statusTag;
  final String? meetingUrl;

  const TodaysScheduleEntity({
    this.patientUserId,
    this.orgId,
    this.hospitalId,
    this.appointmentId,
    this.patientName,
    this.time,
    this.consultationType,
    this.reason,
    this.statusTag,
    this.meetingUrl,
  });
}

class RecentPatientsEntity {
  final String? patientUserId;
  final int? orgId;
  final int? hospitalId;
  final int? appointmentId;
  final String? name;
  final String? date;
  final String? consultationType;
  final String? condition;
  final String? status;

  const RecentPatientsEntity({
    this.patientUserId,
    this.orgId,
    this.hospitalId,
    this.appointmentId,
    this.name,
    this.date,
    this.consultationType,
    this.condition,
    this.status,
  });
}

class WeeklyAppointmentsEntity {
  final int? averagePerDay;
  final List<DailyDataEntity>? dailyData;
  List<String?> get xLabels => dailyData!.map((e) => e.label).toList();
  List<double?> get yValues => dailyData!.map((e) => e.value!.toDouble()).toList() ?? [];
  const WeeklyAppointmentsEntity({this.averagePerDay, this.dailyData});
}

class DailyDataEntity {
  final String? label;
  final int? value;

  const DailyDataEntity({this.label, this.value});
}

class MonthlyPatientsEntity {
  final int? yearlyTotal;
  final List<MonthlyDataEntity>? monthlyData;
  List<String?> get xLabels => monthlyData!.map((e) => e.label).toList();
  List<double> get yValues => monthlyData?.map((e) => e.value!.toDouble()).toList() ?? [];
  const MonthlyPatientsEntity({this.yearlyTotal, this.monthlyData});
}

class MonthlyDataEntity {
  final String? label;
  final int? value;

  const MonthlyDataEntity({this.label, this.value});
}