import 'package:yiraclinics/features/domain/entities/appointments/appointment_entity.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/doctor_dashboard_entity.dart';
import 'package:yiraclinics/features/domain/entities/dashboard/patient_entity.dart';
import 'package:yiraclinics/features/domain/entities/slot/slot_appointment_entity.dart';
import 'package:yiraclinics/features/presentation/slot/slot_bloc/slot_bloc.dart';

class ProviderTourMockData {
  ProviderTourMockData._();

  /// Rich demo dashboard entity for onboarding tour
  static DoctorDashboardEntity get demoDoctorDashboard {
    return DoctorDashboardEntity(
      status: true,
      message: 'Demo Dashboard Data for Tour',
      data: DashboardDataEntity(
        orgId: 1,
        orgName: 'Yira Health Group',
        hospitalId: 101,
        hospitalName: 'Yira Hospital',
        profile: const DoctorProfileEntity(
          name: 'Dr. Rajesh Sharma',
          specialty: 'Cardiologist & General Physician',
          clinicAddress: 'Room 304, Yira Hospital, Hyderabad',
        ),
        metrics: const DashboardMetricsEntity(
          today: MetricItemEntity(title: "Today's Patients", value: 12, subtext: '+15% from yesterday'),
          patients: MetricItemEntity(title: 'Consulted', value: 8, subtext: '66% completed'),
          done: MetricItemEntity(title: 'Teleconsults', value: 3, subtext: 'Live video visits'),
          stats: MetricItemEntity(title: 'Pending', value: 4, subtext: 'In queue'),
        ),
        todaysSchedule: const [
          TodaysScheduleEntity(
            patientUserId: 'demo_user_1',
            appointmentId: 1001,
            patientName: 'Rahul Verma',
            time: '09:30 AM',
            consultationType: 'In-Clinic',
            reason: 'Hypertension Follow-up',
            statusTag: 'In Progress',
            patientStatus: 'In Clinic',
          ),
          TodaysScheduleEntity(
            patientUserId: 'demo_user_2',
            appointmentId: 1002,
            patientName: 'Pooja Sharma',
            time: '10:15 AM',
            consultationType: 'Teleconsultation',
            reason: 'ECG Report Review',
            statusTag: 'LIVE VIDEO',
            meetingUrl: 'https://meet.yiraclinics.com/demo-consult',
            patientStatus: 'Online',
          ),
          TodaysScheduleEntity(
            patientUserId: 'demo_user_3',
            appointmentId: 1003,
            patientName: 'Amitabh Sen',
            time: '11:00 AM',
            consultationType: 'In-Clinic',
            reason: 'Routine Cardiac Health Check',
            statusTag: 'Confirmed',
            patientStatus: 'Waiting',
          ),
        ],
        recentPatients: const [
          RecentPatientsEntity(
            patientUserId: 'demo_user_1',
            appointmentId: 1001,
            name: 'Rahul Verma',
            date: 'Today, 09:30 AM',
            consultationType: 'In-Clinic',
            condition: 'Hypertension',
            status: 'In Progress',
          ),
          RecentPatientsEntity(
            patientUserId: 'demo_user_2',
            appointmentId: 1002,
            name: 'Pooja Sharma',
            date: 'Today, 10:15 AM',
            consultationType: 'Teleconsultation',
            condition: 'Arrhythmia Follow-up',
            status: 'Confirmed',
          ),
        ],
        weeklyAppointments: const WeeklyAppointmentsEntity(
          averagePerDay: 14,
          dailyData: [
            DailyDataEntity(label: 'Mon', value: 8),
            DailyDataEntity(label: 'Tue', value: 14),
            DailyDataEntity(label: 'Wed', value: 11),
            DailyDataEntity(label: 'Thu', value: 16),
            DailyDataEntity(label: 'Fri', value: 18),
            DailyDataEntity(label: 'Sat', value: 9),
            DailyDataEntity(label: 'Sun', value: 2),
          ],
        ),
      ),
    );
  }

  /// Demo appointments for Appointments Dashboard tour
  static List<Appointment> get demoAppointments {
    return const [
      Appointment(
        id: 'appt_101',
        tokenNumber: '01',
        time: '09:30 AM',
        duration: '20 min',
        patientName: 'Rahul Verma',
        phoneNumber: '+91 98765 43210',
        type: AppointmentType.inClinic,
        category: 'Follow-up',
        status: AppointmentStatus.confirmed,
        statusRaw: 'Completed',
        reason: 'Hypertension Follow-up Consultation',
        doctorName: 'Dr. Rajesh Sharma',
        patientStatus: 'Completed',
      ),
      Appointment(
        id: 'appt_102',
        tokenNumber: '02',
        time: '10:15 AM',
        duration: '20 min',
        patientName: 'Pooja Sharma',
        phoneNumber: '+91 98451 23456',
        type: AppointmentType.videoCall,
        category: 'Consultation',
        status: AppointmentStatus.confirmed,
        statusRaw: 'In Progress',
        reason: 'ECG Test Results & Medication Review',
        meetingUrl: 'https://meet.yiraclinics.com/demo-consult',
        doctorName: 'Dr. Rajesh Sharma',
        patientStatus: 'In Call',
      ),
      Appointment(
        id: 'appt_103',
        tokenNumber: '03',
        time: '11:00 AM',
        duration: '20 min',
        patientName: 'Amitabh Sen',
        phoneNumber: '+91 97123 45678',
        type: AppointmentType.inClinic,
        category: 'Checkup',
        status: AppointmentStatus.confirmed,
        statusRaw: 'Confirmed',
        reason: 'Chest Pain Screening & Vitals',
        doctorName: 'Dr. Rajesh Sharma',
        patientStatus: 'Arrived',
      ),
      Appointment(
        id: 'appt_104',
        tokenNumber: '04',
        time: '02:30 PM',
        duration: '20 min',
        patientName: 'Sneha Reddy',
        phoneNumber: '+91 99887 76655',
        type: AppointmentType.inClinic,
        category: 'New Patient',
        status: AppointmentStatus.confirmed,
        statusRaw: 'Scheduled',
        reason: 'Initial Consultation for Blood Pressure',
        doctorName: 'Dr. Rajesh Sharma',
        patientStatus: 'Pending',
      ),
    ];
  }

  /// Demo patients for Patient Management screen tour
  static List<PatientEntity> get demoPatients {
    return const [
      PatientEntity(
        id: 'pat_001',
        userId: 'demo_user_1',
        name: 'Rahul Verma',
        condition: 'Hypertension, Stage 1',
        lastVisit: 'Today',
        status: 'Active',
        gender: 'Male',
        age: 42,
        visits: 8,
        allergy: 'Penicillin',
        isFavorite: true,
      ),
      PatientEntity(
        id: 'pat_002',
        userId: 'demo_user_2',
        name: 'Pooja Sharma',
        condition: 'Arrhythmia Follow-up',
        lastVisit: 'Yesterday',
        status: 'Active',
        gender: 'Female',
        age: 28,
        visits: 4,
        allergy: 'None',
        isFavorite: true,
      ),
      PatientEntity(
        id: 'pat_003',
        userId: 'demo_user_3',
        name: 'Amitabh Sen',
        condition: 'General Cardiac Checkup',
        lastVisit: '3 days ago',
        status: 'Active',
        gender: 'Male',
        age: 35,
        visits: 2,
        allergy: 'Sulfa Drugs',
        isFavorite: false,
      ),
      PatientEntity(
        id: 'pat_004',
        userId: 'demo_user_4',
        name: 'Sneha Reddy',
        condition: 'Diabetes Type 2 Care',
        lastVisit: '1 week ago',
        status: 'Active',
        gender: 'Female',
        age: 58,
        visits: 14,
        allergy: 'Aspirin',
        isFavorite: false,
      ),
    ];
  }

  /// Demo slot state for Slot Dashboard tour
  static SlotDataState get demoSlotDataState {
    final now = DateTime.now();
    return SlotDataState(
      isSingleDay: true,
      targetDate: now,
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      durationMinutes: 20,
      bufferType: '5 Minutes',
      fromTime: '09:00 AM',
      toTime: '05:00 PM',
      slots: [
        SlotEntity(
          id: 'slot_1',
          startTime: '09:00 AM',
          endTime: '09:20 AM',
          label: 'Booked',
          appointment: SlotAppointmentEntity(
            id: 'appt_101',
            patientName: 'Rahul Verma',
            contactNumber: '+91 98765 43210',
            reason: 'Hypertension Follow-up',
          ),
        ),
        SlotEntity(
          id: 'slot_2',
          startTime: '09:25 AM',
          endTime: '09:45 AM',
          label: 'Booked',
          appointment: SlotAppointmentEntity(
            id: 'appt_102',
            patientName: 'Pooja Sharma',
            contactNumber: '+91 98451 23456',
            reason: 'ECG Review (Teleconsult)',
          ),
        ),
        SlotEntity(
          id: 'slot_3',
          startTime: '09:50 AM',
          endTime: '10:10 AM',
          label: 'Available',
        ),
        SlotEntity(
          id: 'slot_4',
          startTime: '10:15 AM',
          endTime: '10:35 AM',
          label: 'Available',
        ),
        SlotEntity(
          id: 'slot_5',
          startTime: '10:40 AM',
          endTime: '11:00 AM',
          label: 'Booked',
          appointment: SlotAppointmentEntity(
            id: 'appt_103',
            patientName: 'Amitabh Sen',
            contactNumber: '+91 97123 45678',
            reason: 'Routine Vitals Check',
          ),
        ),
        SlotEntity(
          id: 'slot_6',
          startTime: '11:05 AM',
          endTime: '11:25 AM',
          label: 'Available',
        ),
        SlotEntity(
          id: 'slot_7',
          startTime: '02:00 PM',
          endTime: '02:20 PM',
          label: 'Available',
        ),
        SlotEntity(
          id: 'slot_8',
          startTime: '02:25 PM',
          endTime: '02:45 PM',
          label: 'Booked',
          appointment: SlotAppointmentEntity(
            id: 'appt_104',
            patientName: 'Sneha Reddy',
            contactNumber: '+91 99887 76655',
            reason: 'BP Check & Prescription Refill',
          ),
        ),
        SlotEntity(
          id: 'slot_9',
          startTime: '02:50 PM',
          endTime: '03:10 PM',
          label: 'Available',
        ),
        SlotEntity(
          id: 'slot_10',
          startTime: '03:15 PM',
          endTime: '03:35 PM',
          label: 'Available',
        ),
      ],
      timeSlots: const [],
      isLoading: false,
    );
  }
}
