
import 'package:flutter/foundation.dart';

@immutable
class DoctorDashboardEntity {
  final bool status;
  final String message;
  final DashboardDataEntity? data;

  const DoctorDashboardEntity({
    required this.status,
    required this.message,
    this.data,
  });
}

class DashboardDataEntity {
  final ProfileEntity profile;
  final MetricsEntity metrics;
  final List<TodaysScheduleEntity> todaysSchedule;
  final List<RecentPatientsEntity> recentPatients;
  final WeeklyAppointmentsEntity weeklyAppointments;
  final MonthlyPatientsEntity monthlyPatients;

  const DashboardDataEntity({
    required this.profile,
    required this.metrics,
    required this.todaysSchedule,
    required this.recentPatients,
    required this.weeklyAppointments,
    required this.monthlyPatients,
  });
}

class ProfileEntity {
  final String name;
  final String specialty;
  final String clinicAddress;

  const ProfileEntity({
    required this.name,
    required this.specialty,
    required this.clinicAddress,
  });
}

class MetricsEntity {
  final MetricCardEntity today;
  final MetricCardEntity patients;
  final MetricCardEntity done;
  final MetricCardEntity stats;

  const MetricsEntity({
    required this.today,
    required this.patients,
    required this.done,
    required this.stats,
  });
}

class MetricCardEntity {
  final String title;
  final int value;
  final String subtext;

  const MetricCardEntity({
    required this.title,
    required this.value,
    required this.subtext,
  });
}

class TodaysScheduleEntity {
  final int patientUserId;
  final int orgId;
  final int hospitalId;
  final int appointmentId;
  final String patientName;
  final String initital;
  final String time;
  final String consultationType;
  final String reason;
  final String statusTag;

  const TodaysScheduleEntity({
    required this.patientUserId,
    required this.orgId,
    required this.hospitalId,
    required this.appointmentId,
    required this.patientName,
    required this.time,
    required this.consultationType,
    required this.reason,
    required this.statusTag, required this.initital,
  });
}

class RecentPatientsEntity {
  final int patientUserId;
  final int orgId;
  final int hospitalId;
  final int appointmentId;
  final String name;
  final String date;
  final String initial;
  final String consultationType;
  final String condition;
  final String status;

  const RecentPatientsEntity({
    required this.patientUserId,
    required this.orgId,
    required this.hospitalId,
    required this.appointmentId,
    required this.name,
    required this.date,
    required this.consultationType,
    required this.condition,
    required this.status, required this.initial,
  });
}

class WeeklyAppointmentsEntity {
  final int averagePerDay;
  final List<ChartDataPoint> dailyData;

  // X-Axis and Y-Axis helper mappings for your charts
  List<String> get xLabels => dailyData.map((e) => e.label).toList();
  List<double> get yValues => dailyData.map((e) => e.value).toList();

  const WeeklyAppointmentsEntity({
    required this.averagePerDay,
    required this.dailyData,
  });
}

class MonthlyPatientsEntity {
  final int yearlyTotal;
  final List<ChartDataPoint> monthlyData;
  List<String> get xLabels => monthlyData.map((e) => e.label).toList();
  List<double> get yValues => monthlyData.map((e) => e.value).toList();

  const MonthlyPatientsEntity({
    required this.yearlyTotal,
    required this.monthlyData,
  });
}

class ChartDataPoint {
  final String label;
  final double value;

  const ChartDataPoint({
    required this.label,
    required this.value,
  });
}