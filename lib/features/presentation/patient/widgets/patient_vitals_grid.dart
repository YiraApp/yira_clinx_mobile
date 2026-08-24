import 'package:flutter/material.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';

class PatientVitalsGrid extends StatelessWidget {
  final Map<String, String> vitals;
  final VoidCallback onUpdateVitals;

  const PatientVitalsGrid({
    super.key,
    required this.vitals,
    required this.onUpdateVitals,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final isTab = isTablet(context);

    final items = [
      {
        'title': 'Blood Pressure',
        'value': vitals['bp'] ?? '120/80',
        'unit': 'mmHg',
        'status': 'Optimal',
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFFE11D48),
      },
      {
        'title': 'Pulse Rate',
        'value': vitals['pulse'] ?? '72',
        'unit': 'bpm',
        'status': 'Normal',
        'icon': Icons.monitor_heart_rounded,
        'color': Colors.orange,
      },
      {
        'title': 'Temperature',
        'value': '${vitals['temp'] ?? '98.6'}°',
        'unit': 'Fahrenheit',
        'status': 'Normal',
        'icon': Icons.thermostat_rounded,
        'color': Colors.amber[700]!,
      },
      {
        'title': 'Blood Oxygen',
        'value': '${vitals['spO2'] ?? '98'}%',
        'unit': 'SpO2',
        'status': 'Healthy',
        'icon': Icons.air_rounded,
        'color': Colors.teal,
      },
      {
        'title': 'Weight & Height',
        'value': '${vitals['weight'] ?? '68'} kg',
        'unit': '${vitals['height'] ?? '172'} cm',
        'status': 'BMI 23.0',
        'icon': Icons.accessibility_new_rounded,
        'color': Colors.indigo,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    'Health Vitals Overview',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 18 : 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Updated ${vitals['lastUpdated'] ?? 'Today'}',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onUpdateVitals,
              icon: Icon(Icons.edit_note_rounded, size: 18, color: primaryColor),
              label: Text(
                'Update Vitals',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: isTab ? 120 : 105,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final Color color = item['color'] as Color;

              return Container(
                width: isTab ? 160 : 138,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item['icon'] as IconData, size: 16, color: color),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['status'] as String,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['value'] as String,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${item['title']} (${item['unit']})',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 10,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
