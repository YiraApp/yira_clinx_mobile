
import 'package:flutter/material.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/time_line_segement_item.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import '../../../domain/entities/patient_profile/patient_profile_entity.dart';
import 'patient_info_card.dart';

class PatientHistoryCard extends StatelessWidget {
  final VisitHistoryEntity patient;
  final bool isTab;
  const PatientHistoryCard({super.key, required this.patient, required this.isTab});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PatientInfoCard(
      isTab: isTab,
      title: 'Visit History',
      titleIcon: Icons.history,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TimelineSegmentItem(
            isTab: isTab,
            label: 'Initial Registration',
            value: patient.initialRegistration ?? '',
            icon: Icons.login_rounded,
            isLast: false,
          ),
          TimelineSegmentItem(
            isTab: isTab,
            label: 'Last Check-in Visit',
            value: patient.lastCheckInVisit ?? '',
            icon: Icons.assignment_turned_in_outlined,
            isLast: false,
          ),
          TimelineSegmentItem(
            isTab: isTab,
            label: 'Next Scheduled Appointment',
            value: patient.nextScheduledAppointment ?? 'None scheduled',
            icon: Icons.event_repeat_outlined,
            isLast: true,
            valueColor: patient.nextScheduledAppointment == null
                ? (isDark ? Colors.blue[300] : const Color(0xFF1A73E8))
                : null,
          ),
        ],
      ),
    );
  }
}