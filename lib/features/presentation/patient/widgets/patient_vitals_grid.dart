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

    final bp = (vitals['bp'] != null && vitals['bp']!.isNotEmpty) ? vitals['bp']! : '--';
    final pulse = (vitals['pulse'] != null && vitals['pulse']!.isNotEmpty) ? vitals['pulse']! : '--';
    final temp = (vitals['temp'] != null && vitals['temp']!.isNotEmpty) ? vitals['temp']! : '--';
    final spO2 = (vitals['spO2'] != null && vitals['spO2']!.isNotEmpty) ? vitals['spO2']! : '--';

    final items = [
      {
        'title': 'Blood Pressure',
        'value': bp,
        'unit': 'mmHg',
        'status': bp != '--' ? 'Optimal' : 'Pending',
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFFE11D48),
      },
      {
        'title': 'Pulse Rate',
        'value': pulse != '--' ? '$pulse bpm' : '--',
        'unit': 'bpm',
        'status': pulse != '--' ? 'Normal' : 'Pending',
        'icon': Icons.monitor_heart_rounded,
        'color': Colors.orange,
      },
      {
        'title': 'Temperature',
        'value': temp != '--' ? (temp.endsWith('°') ? temp : '$temp°F') : '--',
        'unit': 'Fahrenheit',
        'status': temp != '--' ? 'Normal' : 'Pending',
        'icon': Icons.thermostat_rounded,
        'color': Colors.amber[700]!,
      },
      {
        'title': 'Blood Oxygen',
        'value': spO2 != '--' ? (spO2.endsWith('%') ? spO2 : '$spO2%') : '--',
        'unit': 'SpO2',
        'status': spO2 != '--' ? 'Healthy' : 'Pending',
        'icon': Icons.air_rounded,
        'color': Colors.teal,
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
                      color: Colors.green.withValues(alpha: 0.15),
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

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: isTab ? 2.3 : 2.05,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final Color color = item['color'] as Color;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
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
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(item['icon'] as IconData, size: 14, color: color),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item['status'] as String,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 8.5,
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
                          fontSize: isTab ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '${item['title']} (${item['unit']})',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 9.5,
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
      ],
    );
  }
}
