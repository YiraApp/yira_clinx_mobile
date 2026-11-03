import 'package:flutter/material.dart';
import '../../../domain/entities/over_view/over_view_entity.dart';
import 'metric_tile_item.dart';
import 'patient_info_card.dart';
import 'record_tab_ui.dart';

class PatientContactCard extends StatelessWidget {
  final ContactInformationEntity patient;
  final bool isTab;
  const PatientContactCard({super.key, required this.patient, required this.isTab});

  @override
  Widget build(BuildContext context) {
    final name = (patient.emergencyContact?.name ?? '').trim();
    final phone = (patient.emergencyContact?.phone ?? '').trim();
    final relation = (patient.emergencyContact?.relationship ?? '').trim();
    final person = [name, if (relation.isNotEmpty) '($relation)'].where((e) => e.isNotEmpty).join(' ');
    final hasContact = name.isNotEmpty || phone.isNotEmpty;

    return PatientInfoCard(
      isTab: isTab,
      title: 'Contact Information',
      titleIcon: Icons.perm_contact_calendar_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MetricTileItem(
            isTab: isTab,
            icon: Icons.phone_android_rounded,
            label: 'Phone',
            value: patient.phone ?? '',
            accentColor: Colors.blue,
          ),
          const RecordDivider(indent: 30),
          MetricTileItem(
            isTab: isTab,
            icon: Icons.alternate_email_rounded,
            label: 'Email Address',
            value: patient.emailAddress ?? '',
            accentColor: Colors.teal,
          ),
          const RecordDivider(indent: 30),
          MetricTileItem(
            isTab: isTab,
            icon: Icons.map_outlined,
            label: 'Residential Address',
            value: patient.residentialAddress ?? '',
            accentColor: Colors.indigo,
          ),
          const RecordDivider(indent: 30),
          MetricTileItem(
            isTab: isTab,
            icon: hasContact ? Icons.phone_in_talk_outlined : Icons.person_off_outlined,
            label: 'Emergency Contact',
            value: hasContact ? [person, phone].where((e) => e.isNotEmpty).join(' · ') : 'Not added by the patient',
            accentColor: Colors.red,
          ),
        ],
      ),
    );
  }
}
