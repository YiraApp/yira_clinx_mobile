import 'package:flutter/material.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';

class PatientVitalsCard extends StatelessWidget {
  final Map<String, String> vitals;
  final VoidCallback onUpdateVitals;
  final String? patientName;
  final bool isLoading;

  const PatientVitalsCard({
    super.key,
    required this.vitals,
    required this.onUpdateVitals,
    this.patientName,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    final bp = vitals['bp'] ?? '120/80';
    final pulse = vitals['pulse'] ?? '72';
    final temp = vitals['temp'] ?? '98.6';
    final spO2 = vitals['spO2'] ?? '98';
    final weight = vitals['weight'] ?? '68';
    final height = vitals['height'] ?? '172';
    final lastUpdated = vitals['lastUpdated'] ?? 'Today';
    final displayName = (patientName != null && patientName!.trim().isNotEmpty) ? patientName!.trim() : 'Patient';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTab ? 18 : 15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Welcome Back
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.monitor_heart_rounded, color: primaryColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, $displayName',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Health Vitals • Updated $lastUpdated',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              color: isDark ? Colors.white54 : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onUpdateVitals,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note_rounded, size: 16, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Update',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Vitals Metrics Grid (2 items per row)
          // Row 1: Blood Pressure & Heart Rate
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context: context,
                  label: 'Blood Pressure',
                  value: bp,
                  unit: 'mmHg',
                  icon: Icons.favorite_rounded,
                  iconColor: const Color(0xFFE11D48),
                ),
              ),
              Container(width: 1, height: 46, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              Expanded(
                child: _buildMetricItem(
                  context: context,
                  label: 'Heart Rate',
                  value: pulse,
                  unit: 'bpm',
                  icon: Icons.show_chart_rounded,
                  iconColor: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Row 2: SpO2 Level & Temperature
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context: context,
                  label: 'SpO2 Oxygen',
                  value: spO2.endsWith('%') ? spO2 : '$spO2%',
                  unit: 'Optimal Level',
                  icon: Icons.air_rounded,
                  iconColor: Colors.teal,
                ),
              ),
              Container(width: 1, height: 46, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              Expanded(
                child: _buildMetricItem(
                  context: context,
                  label: 'Temperature',
                  value: temp.endsWith('°') ? temp : '$temp°',
                  unit: 'Fahrenheit',
                  icon: Icons.thermostat_rounded,
                  iconColor: Colors.amber[800]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Row 3: Weight & BMI
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context: context,
                  label: 'Body Weight',
                  value: weight.contains('kg') ? weight : '$weight kg',
                  unit: height.contains('cm') ? height : '$height cm',
                  icon: Icons.fitness_center_rounded,
                  iconColor: Colors.indigo,
                ),
              ),
              Container(width: 1, height: 46, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              Expanded(
                child: _buildMetricItem(
                  context: context,
                  label: 'BMI Status',
                  value: (vitals['bmi'] != null && vitals['bmi']!.isNotEmpty) ? vitals['bmi']! : '22.8',
                  unit: 'Normal Range',
                  icon: Icons.health_and_safety_rounded,
                  iconColor: const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required BuildContext context,
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTab = isTablet(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: isTab ? 16 : 14, color: iconColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 12 : 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (isLoading)
            BaseShimmer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2, bottom: 4),
                    width: 64,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 11,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              value,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 17 : 15.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              unit,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 11.5 : 10.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white38 : Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
