import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../../core/colors/colors.dart';
import '../../../../core/common_input_fields/common_input_field.dart';
import '../../../../core/common_widgets/common_text.dart';
import 'medication_drop_down_selector.dart';

class PrescribedPrescriptionCard extends StatelessWidget {
  final String medicineName;
  final String? currentDosage;
  final String? currentFreq;
  final String? currentDuration;
  final String? currentRoute;
  final VoidCallback onRemove;
  final Function(String?) onDosageChanged;
  final Function(String?) onFreqChanged;
  final Function(String?) onDurationChanged;
  final Function(String?) onRouteChanged;
  final bool isTab;

  const PrescribedPrescriptionCard({
    super.key,
    required this.medicineName,
    this.currentDosage,
    this.currentFreq,
    this.currentDuration,
    this.currentRoute,
    required this.onRemove,
    required this.onDosageChanged,
    required this.onFreqChanged,
    required this.onDurationChanged,
    required this.onRouteChanged, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light
                  ? Colors.grey.shade100
                  : Colors.white.withOpacity(0.03),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(fieldBorderRadius),
                topRight: Radius.circular(fieldBorderRadius),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  color: isDarkMode?Colors.white:theme.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CommonText(
                    medicineName,
                    style: TextStyle(
                      color: isDarkMode?Colors.white:theme.primaryColor,
                      fontSize:isTab
                          ? displayWidth(context) * 0.018: displayWidth(context) * 0.032,
                      fontFamily: appPoppinFont,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  onPressed: onRemove,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color:isDarkMode? darkModeCardColor:Colors.transparent,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(fieldBorderRadius),bottomRight: Radius.circular(fieldBorderRadius)),
            ),
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 500 ? 4 : 2;
                double runSpacing = 12.0;
                double spacing = 12.0;
                double itemWidth =
                    (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                    crossAxisCount;
                return Column(
                  children: [
                    SizedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonText(
                            'Dosage',
                            style: TextStyle(
                              letterSpacing: 0.5,
                              fontFamily: appPoppinFont,
                              fontSize: isTab
                                  ? displayWidth(context) * 0.02:displayWidth(context) * 0.033,
                              fontWeight: .w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          CommonInputAddRecordTextField(
                            controller: TextEditingController.fromValue(
                              TextEditingValue(
                                text: currentDosage ?? '',
                                selection: TextSelection.collapsed(
                                  offset: (currentDosage ?? '').length,
                                ),
                              ),
                            ),
                            hintText: '10mg, 40mg ...',
                            borderRadius: 8.0,
                            isRecord: true,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            onChanged: onDosageChanged,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      child: MedicationDropdownSelector(
                        label: 'Frequency',
                        value: currentFreq,
                        items: const [
                          '1-1-1 (Morning-Afternoon-Night)',
                          '1-0-1 (Morning-Night)',
                          '1-0-0 (Morning)',
                          '0-0-1 (Night)',
                          '0-1-0 (Afternoon)',
                          '1-1-0 (Morning-Afternoon)',
                          '0-1-1 (Afternoon-Night)',
                        ],
                        onChanged: onFreqChanged,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      spacing: spacing,
                      children: [
                        Expanded(
                          child: MedicationDropdownSelector(
                            label: 'Duration',
                            value: currentDuration,
                            items: const [
                              '3 Days',
                              '5 Days',
                              '7 Days',
                              '10 days',
                              '14 Days',
                              '21 Days',
                              '30 Days',
                              '60 Days',
                              '90 Days',
                            ],
                            onChanged: onDurationChanged,
                          ),
                        ),
                        Expanded(
                          child: MedicationDropdownSelector(
                            label: 'Route',
                            value: currentRoute,
                            items: const [
                              'Oral',
                              'Injection',
                              'Intravenous (IV)',
                              'Intramuscular (IM)',
                              'Subcutaneous',
                              'Topical',
                            ],
                            onChanged: onRouteChanged,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
