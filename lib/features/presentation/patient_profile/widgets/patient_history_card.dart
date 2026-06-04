
import 'package:flutter/material.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/time_line_segement_item.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import 'patient_info_card.dart';

class PatientHistoryCard extends StatelessWidget {
  final PatientProfileEntity patient;

  const PatientHistoryCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PatientInfoCard(
      title: 'Visit History',
      titleIcon: Icons.history,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TimelineSegmentItem(
            label: 'Initial Registration',
            value: patient.registrationDate,
            icon: Icons.login_rounded,
            isLast: false,
          ),
          TimelineSegmentItem(
            label: 'Last Check-in Visit',
            value: patient.lastVisitDate,
            icon: Icons.assignment_turned_in_outlined,
            isLast: false,
          ),
          TimelineSegmentItem(
            label: 'Next Scheduled Appointment',
            value: patient.nextAppointment ?? 'None scheduled',
            icon: Icons.event_repeat_outlined,
            isLast: true,
            valueColor: patient.nextAppointment == null
                ? (isDark ? Colors.blue[300] : const Color(0xFF1A73E8))
                : null,
          ),
        ],
      ),
    );
  }
}