import 'package:flutter/material.dart';
import '../../../../config/app_route/app_routes.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../vitals/patient_vitals_tracking_screen.dart';

class PatientVitalsCard extends StatelessWidget {
  final Map<String, String> vitals;
  final VoidCallback onUpdateVitals;
  final String? patientName;
  final String? profileImagePath;
  final VoidCallback? onProfileTap;
  final bool isLoading;

  static const Color _primaryBlue = Color(0xFF2563EB);

  const PatientVitalsCard({
    super.key,
    required this.vitals,
    required this.onUpdateVitals,
    this.patientName,
    this.profileImagePath,
    this.onProfileTap,
    this.isLoading = false,
  });

  void _openTracking(BuildContext context, VitalMetricType metric) {
    Navigator.pushNamed(
      context,
      AppRoutes.patientVitalsTracking,
      arguments: metric,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);

    final bp = (vitals['bp'] != null && vitals['bp']!.isNotEmpty) ? vitals['bp']! : '--';
    final pulse = (vitals['pulse'] != null && vitals['pulse']!.isNotEmpty) ? vitals['pulse']! : '--';
    final temp = (vitals['temp'] != null && vitals['temp']!.isNotEmpty) ? vitals['temp']! : '--';
    final spO2 = (vitals['spO2'] != null && vitals['spO2']!.isNotEmpty) ? vitals['spO2']! : '--';
    final weight = (vitals['weight'] != null && vitals['weight']!.isNotEmpty) ? vitals['weight']! : '--';
    final height = (vitals['height'] != null && vitals['height']!.isNotEmpty) ? vitals['height']! : '--';

    String bmiVal = '--';
    String bmiStatus = 'Pending';
    final wNum = double.tryParse(weight.replaceAll(RegExp(r'[^\d.]'), ''));
    final hNum = double.tryParse(height.replaceAll(RegExp(r'[^\d.]'), ''));
    if (wNum != null && hNum != null && wNum > 0 && hNum > 0) {
      final hMeter = hNum > 3 ? hNum / 100.0 : hNum;
      final bmi = wNum / (hMeter * hMeter);
      bmiVal = bmi.toStringAsFixed(1);
      if (bmi < 18.5) {
        bmiStatus = 'Underweight';
      } else if (bmi < 25) {
        bmiStatus = 'Normal';
      } else if (bmi < 30) {
        bmiStatus = 'Overweight';
      } else {
        bmiStatus = 'Obese';
      }
    }

    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF64748B).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: "Health Vitals" & "Graphs / Update" Actions
          Padding(
            padding: EdgeInsets.fromLTRB(isTab ? 18 : 14, isTab ? 16 : 14, isTab ? 18 : 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.favorite_outline_rounded, size: 16, color: _primaryBlue),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Health Vitals',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 16 : 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "Graphs" Button
                    InkWell(
                      onTap: () => _openTracking(context, VitalMetricType.bloodPressure),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.show_chart_rounded, size: 14, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                            const SizedBox(width: 4),
                            Text(
                              'Graphs',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // "Update" Button
                    InkWell(
                      onTap: onUpdateVitals,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_note_rounded, size: 14, color: _primaryBlue),
                            SizedBox(width: 4),
                            Text(
                              'Update',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. BMI Indicator Bar (if calculated)
          if (bmiVal != '--')
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isTab ? 18 : 14, vertical: 2),
              child: InkWell(
                onTap: () => _openTracking(context, VitalMetricType.weight),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.speed_rounded, size: 14, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        'BMI: ',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        bmiVal,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          bmiStatus,
                          style: const TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isTab ? 18 : 14),
            child: Divider(
              height: 1,
              color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(height: 8),

          // 3. Vitals Grid (Unified Clean Single-Color Tiles)
          Padding(
            padding: EdgeInsets.fromLTRB(isTab ? 14 : 10, 0, isTab ? 14 : 10, isTab ? 14 : 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context: context,
                        label: 'Blood Pressure',
                        value: bp,
                        unit: bp != '--' ? 'mmHg' : '',
                        icon: Icons.favorite_outline_rounded,
                        isDark: isDark,
                        isTab: isTab,
                        onTap: () => _openTracking(context, VitalMetricType.bloodPressure),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        context: context,
                        label: 'Heart Rate',
                        value: pulse,
                        unit: pulse != '--' ? 'BPM' : '',
                        icon: Icons.monitor_heart_outlined,
                        isDark: isDark,
                        isTab: isTab,
                        onTap: () => _openTracking(context, VitalMetricType.heartRate),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context: context,
                        label: 'SpO2 Oxygen',
                        value: spO2,
                        unit: spO2 != '--' ? '%' : '',
                        icon: Icons.air_rounded,
                        isDark: isDark,
                        isTab: isTab,
                        onTap: () => _openTracking(context, VitalMetricType.spO2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        context: context,
                        label: 'Temperature',
                        value: temp,
                        unit: temp != '--' ? '°F' : '',
                        icon: Icons.thermostat_outlined,
                        isDark: isDark,
                        isTab: isTab,
                        onTap: () => _openTracking(context, VitalMetricType.temperature),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context: context,
                        label: 'Weight',
                        value: weight,
                        unit: weight != '--' ? 'kg' : '',
                        icon: Icons.scale_outlined,
                        isDark: isDark,
                        isTab: isTab,
                        onTap: () => _openTracking(context, VitalMetricType.weight),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        context: context,
                        label: 'Height',
                        value: height,
                        unit: height != '--' ? 'cm' : '',
                        icon: Icons.height_rounded,
                        isDark: isDark,
                        isTab: isTab,
                        onTap: () => _openTracking(context, VitalMetricType.weight),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required bool isDark,
    required bool isTab,
    required VoidCallback onTap,
  }) {
    final hasVal = value != '--';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTab ? 14 : 10,
            vertical: isTab ? 12 : 9,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: _primaryBlue),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 17 : 15,
                      fontWeight: FontWeight.bold,
                      color: hasVal
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? Colors.white38 : Colors.grey.shade400),
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 3),
                    Text(
                      unit,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
