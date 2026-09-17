import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/services/medication_reminder_service.dart';
import 'package:yiraclinics/features/data/models/medication/medication_reminder_model.dart';

class ConvertTabletSheet extends StatefulWidget {
  final String medicineName;
  final String? dosage;
  final String? initialInstructions;
  final String? prescriptionId;
  final String? doctorName;
  final String? condition;
  final VoidCallback? onConverted;

  const ConvertTabletSheet({
    super.key,
    required this.medicineName,
    this.dosage,
    this.initialInstructions,
    this.prescriptionId,
    this.doctorName,
    this.condition,
    this.onConverted,
  });

  static Future<void> show(
    BuildContext context, {
    required String medicineName,
    String? dosage,
    String? initialInstructions,
    String? prescriptionId,
    String? doctorName,
    String? condition,
    VoidCallback? onConverted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConvertTabletSheet(
        medicineName: medicineName,
        dosage: dosage,
        initialInstructions: initialInstructions,
        prescriptionId: prescriptionId,
        doctorName: doctorName,
        condition: condition,
        onConverted: onConverted,
      ),
    );
  }

  @override
  State<ConvertTabletSheet> createState() => _ConvertTabletSheetState();
}

class _ConvertTabletSheetState extends State<ConvertTabletSheet> {
  int _durationDays = 7;
  bool _isContinuous = false;
  bool _isCustomDays = false;
  final TextEditingController _customDaysController = TextEditingController(text: '7');

  String _mealRelation = 'After Food';

  // Flexible list of times (supports 1 to 10+ times a day)
  final List<String> _times = ['08:00 AM', '08:00 PM'];

  final List<int> _quickDays = [3, 5, 7, 10, 14, 30];
  final List<String> _mealOptions = ['After Food', 'Before Food', 'Anytime'];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _sortTimes();
  }

  @override
  void dispose() {
    _customDaysController.dispose();
    super.dispose();
  }

  void _sortTimes() {
    _times.sort((a, b) => _timeToMinutes(a).compareTo(_timeToMinutes(b)));
  }

  int _timeToMinutes(String timeStr) {
    try {
      final dt = DateFormat('hh:mm a').parse(timeStr.trim());
      return dt.hour * 60 + dt.minute;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _addNewTime() async {
    HapticFeedback.selectionClick();
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      final formatted = DateFormat('hh:mm a').format(dt);

      setState(() {
        if (!_times.contains(formatted)) {
          _times.add(formatted);
          _sortTimes();
        }
      });
    }
  }

  void _removeTime(String time) {
    HapticFeedback.lightImpact();
    setState(() {
      _times.remove(time);
    });
  }

  Future<void> _confirmAndSave() async {
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add at least one reminder time."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final effectiveDays = _isContinuous ? 365 : _durationDays;
    final endDate = _isContinuous
        ? startDate.add(const Duration(days: 3650))
        : startDate.add(Duration(days: effectiveDays));

    final reminder = MedicationReminder(
      id: "med_${DateTime.now().millisecondsSinceEpoch}_${widget.medicineName.hashCode.abs()}",
      prescriptionId: widget.prescriptionId,
      medicineName: widget.medicineName,
      dosage: widget.dosage ?? '',
      instructions: widget.initialInstructions ?? '',
      durationDays: effectiveDays,
      isContinuous: _isContinuous,
      startDate: startDate,
      endDate: endDate,
      times: List<String>.from(_times),
      mealRelation: _mealRelation,
      doctorName: widget.doctorName ?? '',
      condition: widget.condition ?? '',
    );

    await MedicationReminderService.instance.saveReminder(reminder);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      widget.onConverted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isContinuous
                      ? "Continuous reminder set for ${widget.medicineName} (${_times.length} times daily)"
                      : "Reminder set: ${widget.medicineName} (${_times.length} times/day for $_durationDays days)",
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final finishDate = now.add(Duration(days: _durationDays));
    final dateRangeStr = "${DateFormat('MMM d').format(now)} – ${DateFormat('MMM d, yyyy').format(finishDate)}";

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Title & Close Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/dashboard_icons/pill_prescriptions_thick.png',
                  width: 38,
                  height: 38,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Set Medicine Reminder",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.medicineName,
                        style: const TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 16),

            // ── 1. DURATION (CONTINUOUS, PRESETS & CUSTOM) ──
            Text(
              "How many days to take?",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),

            // Primary Duration Row: Continuous (Ongoing) vs Custom Days
            Row(
              children: [
                // Continuous Option
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isContinuous = true;
                        _isCustomDays = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      decoration: BoxDecoration(
                        color: _isContinuous
                            ? primaryColor
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isContinuous
                              ? primaryColor
                              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.all_inclusive_rounded,
                            size: 16,
                            color: _isContinuous ? Colors.white : primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Continuous",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _isContinuous
                                  ? Colors.white
                                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Custom Days Option
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isCustomDays = true;
                        _isContinuous = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      decoration: BoxDecoration(
                        color: (_isCustomDays && !_isContinuous)
                            ? primaryColor
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (_isCustomDays && !_isContinuous)
                              ? primaryColor
                              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_calendar_rounded,
                            size: 16,
                            color: (_isCustomDays && !_isContinuous) ? Colors.white : primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Custom Days",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: (_isCustomDays && !_isContinuous)
                                  ? Colors.white
                                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quick Preset Days Chips (3, 5, 7, 10, 14, 30 days)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickDays.map((days) {
                final isSelected = !_isContinuous && !_isCustomDays && _durationDays == days;
                return ChoiceChip(
                  label: Text("$days days"),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  labelStyle: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _isContinuous = false;
                        _isCustomDays = false;
                        _durationDays = days;
                        _customDaysController.text = days.toString();
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8),

            // If Custom days is selected: Show Stepper / Textfield
            if (_isCustomDays && !_isContinuous) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Text(
                      "Enter number of days:",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                      onPressed: () {
                        if (_durationDays > 1) {
                          setState(() {
                            _durationDays--;
                            _customDaysController.text = _durationDays.toString();
                          });
                        }
                      },
                    ),
                    SizedBox(
                      width: 48,
                      child: TextField(
                        controller: _customDaysController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            setState(() => _durationDays = parsed);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                      onPressed: () {
                        setState(() {
                          _durationDays++;
                          _customDaysController.text = _durationDays.toString();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],

            Text(
              _isContinuous
                  ? "Ongoing medication • Daily reminders until stopped"
                  : "Duration: $_durationDays days ($dateRangeStr)",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11.5,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 20),

            // ── 2. REMINDER TIMINGS: ANY NUMBER OF TIMES (1 TO 10+) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Reminder Timings",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      "${_times.length} time${_times.length == 1 ? '' : 's'} a day",
                      style: const TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _addNewTime,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryColor, width: 1.1),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_alarm_rounded, size: 15, color: primaryColor),
                  label: const Text(
                    "Add Time",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_times.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Text(
                    "No timings added. Tap 'Add Time' to set a reminder.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _times.map((timeStr) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: primaryColor),
                        const SizedBox(width: 5),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _removeTime(timeStr),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            // ── 3. MEAL RELATION ──
            Text(
              "When to take?",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _mealOptions.map((opt) {
                final isSelected = _mealRelation == opt;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(opt),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    labelStyle: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    onSelected: (val) {
                      if (val) setState(() => _mealRelation = opt);
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _confirmAndSave,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _times.isEmpty
                            ? "Add a Time to Schedule"
                            : _isContinuous
                                ? "Set Continuous Reminder (${_times.length} times/day)"
                                : "Set Reminder (${_times.length} times/day for $_durationDays days)",
                        style: const TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
