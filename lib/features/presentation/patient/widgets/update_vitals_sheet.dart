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

  Map<String, String> _errors = {};

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

  bool _validateInputs() {
    final newErrors = <String, String>{};

    final sysText = _bpSystolicController.text.trim();
    final diaText = _bpDiastolicController.text.trim();
    final pulseText = _pulseController.text.trim();
    final tempText = _tempController.text.trim();
    final spO2Text = _spO2Controller.text.trim();
    final weightText = _weightController.text.trim();
    final heightText = _heightController.text.trim();

    // Check if at least one vital was entered
    if (sysText.isEmpty &&
        diaText.isEmpty &&
        pulseText.isEmpty &&
        tempText.isEmpty &&
        spO2Text.isEmpty &&
        weightText.isEmpty &&
        heightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one vital reading.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return false;
    }

    double? sysVal;
    double? diaVal;

    // 1. Systolic BP (Max: 260, Min: 40 mmHg)
    if (sysText.isNotEmpty) {
      sysVal = double.tryParse(sysText);
      if (sysVal == null) {
        newErrors['sys'] = 'Invalid number';
      } else if (sysVal < 40) {
        newErrors['sys'] = 'Min 40 mmHg';
      } else if (sysVal > 260) {
        newErrors['sys'] = 'Max 260 mmHg';
      }
    }

    // 2. Diastolic BP (Max: 160, Min: 30 mmHg)
    if (diaText.isNotEmpty) {
      diaVal = double.tryParse(diaText);
      if (diaVal == null) {
        newErrors['dia'] = 'Invalid number';
      } else if (diaVal < 30) {
        newErrors['dia'] = 'Min 30 mmHg';
      } else if (diaVal > 160) {
        newErrors['dia'] = 'Max 160 mmHg';
      }
    }

    // Logical BP consistency: Diastolic must be less than Systolic
    if (sysVal != null && diaVal != null) {
      if (diaVal >= sysVal) {
        newErrors['dia'] = 'Must be < Systolic';
      }
    }

    // 3. Pulse / Heart Rate (Max: 250, Min: 30 bpm)
    if (pulseText.isNotEmpty) {
      final pulseVal = double.tryParse(pulseText);
      if (pulseVal == null) {
        newErrors['pulse'] = 'Invalid number';
      } else if (pulseVal < 30) {
        newErrors['pulse'] = 'Min 30 bpm';
      } else if (pulseVal > 250) {
        newErrors['pulse'] = 'Max 250 bpm';
      }
    }

    // 4. Body Temperature (Supports Fahrenheit or Celsius)
    if (tempText.isNotEmpty) {
      final tempVal = double.tryParse(tempText);
      if (tempVal == null) {
        newErrors['temp'] = 'Invalid number';
      } else if (tempVal > 45) {
        // Fahrenheit mode (Max: 108.0°F, Min: 90.0°F)
        if (tempVal < 90.0) {
          newErrors['temp'] = 'Min 90.0°F';
        } else if (tempVal > 108.0) {
          newErrors['temp'] = 'Max 108.0°F';
        }
      } else {
        // Celsius mode (Max: 43.0°C, Min: 32.0°C)
        if (tempVal < 32.0) {
          newErrors['temp'] = 'Min 32.0°C';
        } else if (tempVal > 43.0) {
          newErrors['temp'] = 'Max 43.0°C';
        }
      }
    }

    // 5. SpO2 Oxygen Saturation (Max: 100%, Min: 50%)
    if (spO2Text.isNotEmpty) {
      final spO2Val = double.tryParse(spO2Text);
      if (spO2Val == null) {
        newErrors['spO2'] = 'Invalid number';
      } else if (spO2Val < 50) {
        newErrors['spO2'] = 'Min 50%';
      } else if (spO2Val > 100) {
        newErrors['spO2'] = 'Max 100%';
      }
    }

    // 6. Weight (Max: 350 kg, Min: 2 kg)
    if (weightText.isNotEmpty) {
      final weightVal = double.tryParse(weightText);
      if (weightVal == null) {
        newErrors['weight'] = 'Invalid number';
      } else if (weightVal < 2.0) {
        newErrors['weight'] = 'Min 2 kg';
      } else if (weightVal > 350.0) {
        newErrors['weight'] = 'Max 350 kg';
      }
    }

    // 7. Height (Max: 260 cm, Min: 30 cm)
    if (heightText.isNotEmpty) {
      final heightVal = double.tryParse(heightText);
      if (heightVal == null) {
        newErrors['height'] = 'Invalid number';
      } else if (heightVal < 30.0) {
        newErrors['height'] = 'Min 30 cm';
      } else if (heightVal > 260.0) {
        newErrors['height'] = 'Max 260 cm';
      }
    }

    setState(() {
      _errors = newErrors;
    });

    if (newErrors.isNotEmpty) {
      final firstMsg = newErrors.values.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Validation error: $firstMsg'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }

    return true;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _bpSystolicController,
                    label: 'Systolic (e.g. 120)',
                    icon: Icons.compress_rounded,
                    isDark: isDark,
                    errorText: _errors['sys'],
                    helperText: 'Max: 260 mmHg',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: Text('/', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: _buildInputField(
                    controller: _bpDiastolicController,
                    label: 'Diastolic (e.g. 80)',
                    icon: Icons.expand_rounded,
                    isDark: isDark,
                    errorText: _errors['dia'],
                    helperText: 'Max: 160 mmHg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Pulse Rate & Temperature
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        errorText: _errors['pulse'],
                        helperText: 'Max: 250 bpm',
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
                        errorText: _errors['temp'],
                        helperText: 'Max: 108°F / 43°C',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // SpO2 & Weight
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        errorText: _errors['spO2'],
                        helperText: 'Max: 100%',
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
                        errorText: _errors['weight'],
                        helperText: 'Max: 350 kg',
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
              errorText: _errors['height'],
              helperText: 'Max: 260 cm',
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
                  if (!_validateInputs()) return;

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
    String? errorText,
    String? helperText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onChanged: (_) {
            if (_errors.isNotEmpty) {
              setState(() => _errors.clear());
            }
          },
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
            prefixIcon: Icon(
              icon,
              size: 18,
              color: hasError ? const Color(0xFFEF4444) : (isDark ? Colors.white60 : Colors.grey[600]),
            ),
            filled: true,
            fillColor: hasError
                ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                : (isDark ? const Color(0xFF0F172A) : Colors.grey[100]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: hasError ? const BorderSide(color: Color(0xFFEF4444), width: 1.2) : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: hasError ? const BorderSide(color: Color(0xFFEF4444), width: 1.2) : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFEF4444) : Theme.of(context).primaryColor,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              errorText,
              style: const TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              helperText,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 9.5,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
