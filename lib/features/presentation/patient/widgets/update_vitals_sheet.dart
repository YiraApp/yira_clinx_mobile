import 'package:flutter/material.dart';
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
    String extract(String? val) {
      if (val == null || val.trim().isEmpty || val.trim() == '--') return '';
      return val.trim().replaceAll(RegExp(r'[^\d.]'), '');
    }

    final bpSys = widget.currentVitals?['bpSystolic'];
    final bpDia = widget.currentVitals?['bpDiastolic'];
    final bpFull = widget.currentVitals?['bp'];

    String sys = extract(bpSys);
    String dia = extract(bpDia);
    if (sys.isEmpty && dia.isEmpty && bpFull != null && bpFull.contains('/')) {
      final parts = bpFull.split('/');
      sys = extract(parts.first);
      if (parts.length > 1) dia = extract(parts[1]);
    }

    _bpSystolicController = TextEditingController(text: sys);
    _bpDiastolicController = TextEditingController(text: dia);
    _pulseController = TextEditingController(text: extract(widget.currentVitals?['pulse']));
    _tempController = TextEditingController(text: extract(widget.currentVitals?['temp']));
    _spO2Controller = TextEditingController(text: extract(widget.currentVitals?['spO2']));
    _weightController = TextEditingController(text: extract(widget.currentVitals?['weight']));
    _heightController = TextEditingController(text: extract(widget.currentVitals?['height']));
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
                    color: primaryColor.withValues(alpha: 0.12),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Enter your current health measurements',
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
                    label: 'e.g. 120',
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
                    label: 'e.g. 80',
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
                        label: 'e.g. 72',
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
                        label: 'e.g. 98.6',
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
                        label: 'e.g. 98',
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
                        label: 'e.g. 68',
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
              label: 'e.g. 172',
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
                  final sys = _bpSystolicController.text.trim();
                  final dia = _bpDiastolicController.text.trim();
                  final bp = (sys.isNotEmpty && dia.isNotEmpty)
                      ? '$sys/$dia'
                      : (sys.isNotEmpty ? sys : (dia.isNotEmpty ? dia : '--'));

                  final pulse = _pulseController.text.trim().isNotEmpty ? _pulseController.text.trim() : '--';
                  final temp = _tempController.text.trim().isNotEmpty ? _tempController.text.trim() : '--';
                  final spO2 = _spO2Controller.text.trim().isNotEmpty ? _spO2Controller.text.trim() : '--';
                  final weight = _weightController.text.trim().isNotEmpty ? _weightController.text.trim() : '--';
                  final height = _heightController.text.trim().isNotEmpty ? _heightController.text.trim() : '--';

                  final result = {
                    'bp': bp,
                    'bpSystolic': sys.isNotEmpty ? sys : '--',
                    'bpDiastolic': dia.isNotEmpty ? dia : '--',
                    'pulse': pulse,
                    'temp': temp,
                    'spO2': spO2,
                    'weight': weight,
                    'height': height,
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
