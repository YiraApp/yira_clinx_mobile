import 'package:flutter/material.dart';

import 'record_tab_ui.dart';

class PatientInfoCard extends StatelessWidget {
  final String title;
  final IconData titleIcon;
  final Widget child;
  final bool isTab;

  const PatientInfoCard({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.child,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    // The screen's column centres its children; keep the card full width.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: RecordCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecordSectionTitle(icon: titleIcon, title: title),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
