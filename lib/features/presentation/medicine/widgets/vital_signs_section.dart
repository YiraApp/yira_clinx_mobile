import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class VitalSignsSection extends StatefulWidget {
  final TextEditingController bpController;
  final TextEditingController hrController;
  final TextEditingController tempController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final TextEditingController oxygenSaturationController;
  final bool isTab;

  const VitalSignsSection({
    super.key,
    required this.bpController,
    required this.hrController,
    required this.tempController,
    required this.weightController,
    required this.heightController,
    required this.oxygenSaturationController,
    required this.isTab,
  });

  @override
  State<VitalSignsSection> createState() => _VitalSignsSectionState();
}

class _VitalSignsSectionState extends State<VitalSignsSection> {
  @override
  void initState() {
    super.initState();
    widget.weightController.addListener(_onVitalsChanged);
    widget.heightController.addListener(_onVitalsChanged);
  }

  @override
  void dispose() {
    widget.weightController.removeListener(_onVitalsChanged);
    widget.heightController.removeListener(_onVitalsChanged);
    super.dispose();
  }

  void _onVitalsChanged() {
    setState(() {});
  }

  double? _calculateBMI() {
    final weightStr = widget.weightController.text.trim();
    final heightStr = widget.heightController.text.trim();

    final weight = double.tryParse(weightStr);
    final height = double.tryParse(heightStr);

    if (weight == null || height == null || weight <= 0 || height <= 0) {
      return null;
    }

    // Height in cm converted to meters
    final heightInMeters = height > 3 ? height / 100 : height;
    if (heightInMeters <= 0) return null;

    final bmi = weight / (heightInMeters * heightInMeters);
    return bmi.isFinite ? bmi : null;
  }

  Widget _buildVitalTile({
    required BuildContext context,
    required String label,
    required String unit,
    required String hintText,
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: widget.isTab ? 13 : 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: widget.isTab ? 14 : 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: widget.isTab ? 13 : 12,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.normal,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bmi = _calculateBMI();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Icon Badge & BMI pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.monitor_heart_outlined,
                      size: 20,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Vital Signs",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: widget.isTab ? 17 : 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "Recorded patient baseline values",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: widget.isTab ? 12 : 11,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (bmi != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: bmi < 18.5
                        ? Colors.orange.withValues(alpha: 0.15)
                        : (bmi <= 24.9
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: bmi < 18.5
                          ? Colors.orange
                          : (bmi <= 24.9 ? Colors.green : Colors.red),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        size: 13,
                        color: bmi < 18.5
                            ? Colors.orange
                            : (bmi <= 24.9 ? Colors.green : Colors.red),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "BMI: ${bmi.toStringAsFixed(1)}",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: bmi < 18.5
                              ? Colors.orange
                              : (bmi <= 24.9 ? Colors.green : Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
          ),
          const SizedBox(height: 16),

          // 2-Column Grid of Vital Signs
          Row(
            children: [
              Expanded(
                child: _buildVitalTile(
                  context: context,
                  label: "Blood Pressure",
                  unit: "mmHg",
                  hintText: "120/80",
                  icon: Icons.favorite_outline,
                  iconColor: const Color(0xFFEF4444),
                  controller: widget.bpController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVitalTile(
                  context: context,
                  label: "Heart Rate",
                  unit: "bpm",
                  hintText: "72",
                  icon: Icons.timeline,
                  iconColor: const Color(0xFFE11D48),
                  controller: widget.hrController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildVitalTile(
                  context: context,
                  label: "Temperature",
                  unit: "°F",
                  hintText: "98.6",
                  icon: Icons.thermostat_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  controller: widget.tempController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVitalTile(
                  context: context,
                  label: "Oxygen (SpO2)",
                  unit: "%",
                  hintText: "98",
                  icon: Icons.air_rounded,
                  iconColor: const Color(0xFF0284C7),
                  controller: widget.oxygenSaturationController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildVitalTile(
                  context: context,
                  label: "Weight",
                  unit: "kg",
                  hintText: "70.5",
                  icon: Icons.scale_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  controller: widget.weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildVitalTile(
                  context: context,
                  label: "Height",
                  unit: "cm",
                  hintText: "175",
                  icon: Icons.straighten_outlined,
                  iconColor: const Color(0xFF059669),
                  controller: widget.heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}