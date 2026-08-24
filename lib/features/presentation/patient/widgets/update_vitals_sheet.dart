import 'package:flutter/material.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';

class UpdateVitalsSheet extends StatefulWidget {
  final Map<String, String>? currentVitals;
  final Function(Map<String, String> updatedVitals)? onSave;

  const UpdateVitalsSheet({super.key, this.currentVitals, this.onSave});

  @override
  State<UpdateVitalsSheet> createState() => _UpdateVitalsSheetState();
}

class _UpdateVitalsSheetState extends State<UpdateVitalsSheet> {
  late final TextEditingController _bpSystolicController;
  late final TextEditingController _bpDiastolicController;
  late final TextEditingController _pulseController;
  late final TextEditingController _tempController;
  late final TextEditingController _spO2Controller;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _bpSystolicController = TextEditingController(text: widget.currentVitals?['bpSystolic'] ?? '120');
    _bpDiastolicController = TextEditingController(text: widget.currentVitals?['bpDiastolic'] ?? '80');
    _pulseController = TextEditingController(text: widget.currentVitals?['pulse'] ?? '72');
    _tempController = TextEditingController(text: widget.currentVitals?['temp'] ?? '98.6');
    _spO2Controller = TextEditingController(text: widget.currentVitals?['spO2'] ?? '98');
    _weightController = TextEditingController(text: widget.currentVitals?['weight'] ?? '68');
    _heightController = TextEditingController(text: widget.currentVitals?['height'] ?? '172');
  }

  @override
  void dispose() {
    _bpSystolicController.dispose();
    _bpDiastolicController.dispose();
    _pulseController.dispose();
    _tempController.dispose();
    _spO2Controller.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final isTab = isTablet(context);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.favorite_rounded, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Record Health Vitals',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Self-recorded health metrics are shared with your doctor',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Blood Pressure Row
            Text(
              'Blood Pressure (mmHg)',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _bpSystolicController,
                    label: 'Systolic (e.g. 120)',
                    icon: Icons.compress_rounded,
                    isDark: isDark,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('/', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: _buildInputField(
                    controller: _bpDiastolicController,
                    label: 'Diastolic (e.g. 80)',
                    icon: Icons.expand_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Pulse Rate & Temperature
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pulse Rate (bpm)', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(height: 6),
                      _buildInputField(
                        controller: _pulseController,
                        label: '72',
                        icon: Icons.monitor_heart_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Temperature (°F)', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(height: 6),
                      _buildInputField(
                        controller: _tempController,
                        label: '98.6',
                        icon: Icons.thermostat_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // SpO2 & Weight
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SpO2 (%)', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(height: 6),
                      _buildInputField(
                        controller: _spO2Controller,
                        label: '98',
                        icon: Icons.air_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weight (kg)', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(height: 6),
                      _buildInputField(
                        controller: _weightController,
                        label: '68',
                        icon: Icons.scale_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Height
            Text('Height (cm)', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 6),
            _buildInputField(
              controller: _heightController,
              label: '172',
              icon: Icons.height_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  final result = {
                    'bp': '${_bpSystolicController.text}/${_bpDiastolicController.text}',
                    'bpSystolic': _bpSystolicController.text,
                    'bpDiastolic': _bpDiastolicController.text,
                    'pulse': _pulseController.text,
                    'temp': _tempController.text,
                    'spO2': _spO2Controller.text,
                    'weight': _weightController.text,
                    'height': _heightController.text,
                    'lastUpdated': 'Just now',
                  };
                  if (widget.onSave != null) {
                    widget.onSave!(result);
                  }
                  Navigator.pop(context, result);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vitals updated successfully!')),
                  );
                },
                child: const Text(
                  'Save Vitals Record',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 13,
          color: isDark ? Colors.white38 : Colors.grey[400],
        ),
        prefixIcon: Icon(icon, size: 18, color: isDark ? Colors.white60 : Colors.grey[600]),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
