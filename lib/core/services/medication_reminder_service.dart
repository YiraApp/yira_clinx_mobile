import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/services/notification_services/notification_services.dart';
import 'package:yiraclinics/features/data/models/medication/medication_reminder_model.dart';

class TodayMedicationDose {
  final MedicationReminder reminder;
  final String slot; // Formatted time e.g. "08:00 AM"
  final String time;
  final bool isTaken;

  TodayMedicationDose({
    required this.reminder,
    required this.slot,
    required this.time,
    required this.isTaken,
  });
}

class MedicationReminderService {
  MedicationReminderService._privateConstructor();
  static final MedicationReminderService instance = MedicationReminderService._privateConstructor();

  static const String _storageKey = 'saved_medication_reminders_v1';
  final ValueNotifier<List<MedicationReminder>> remindersNotifier = ValueNotifier<List<MedicationReminder>>([]);
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await loadReminders();
    _isInitialized = true;
  }

  Future<List<MedicationReminder>> loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List list = json.decode(raw);
        final loaded = list.map((item) => MedicationReminder.fromMap(Map<String, dynamic>.from(item))).toList();
        remindersNotifier.value = loaded;
        return loaded;
      }
    } catch (e) {
      debugPrint("[MedicationReminderService] Error loading reminders: $e");
    }
    remindersNotifier.value = [];
    return [];
  }

  Future<void> saveReminder(MedicationReminder reminder) async {
    try {
      final currentList = List<MedicationReminder>.from(remindersNotifier.value);
      final index = currentList.indexWhere((r) => r.id == reminder.id);
      if (index >= 0) {
        currentList[index] = reminder;
      } else {
        currentList.insert(0, reminder);
      }

      remindersNotifier.value = currentList;
      await _persistList(currentList);

      // Trigger immediate notification confirming reminder is scheduled
      final timesStr = reminder.times.join(', ');
      await NotificationService.instance.showNotification(
        title: "💊 Reminder Scheduled",
        body: "We'll notify you to take ${reminder.medicineName} (${reminder.mealRelation}) for ${reminder.durationDays} days at $timesStr.",
        payload: jsonEncode({'type': 'medication_reminder', 'id': reminder.id}),
      );
    } catch (e) {
      debugPrint("[MedicationReminderService] Error saving reminder: $e");
    }
  }

  Future<void> toggleDoseTaken(String reminderId, String timeKey) async {
    try {
      final now = DateTime.now();
      final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_$timeKey";

      final currentList = List<MedicationReminder>.from(remindersNotifier.value);
      final index = currentList.indexWhere((r) => r.id == reminderId);
      if (index >= 0) {
        final r = currentList[index];
        final updatedDoses = Map<String, bool>.from(r.takenDoses);
        final currentVal = updatedDoses[dateKey] == true;
        updatedDoses[dateKey] = !currentVal;

        currentList[index] = r.copyWith(takenDoses: updatedDoses);
        remindersNotifier.value = currentList;
        await _persistList(currentList);

        if (!currentVal) {
          // Send feedback notification when dose taken
          await NotificationService.instance.showNotification(
            title: "🎉 Medicine Taken!",
            body: "Great! You logged your dose of ${r.medicineName} for $timeKey.",
          );
        }
      }
    } catch (e) {
      debugPrint("[MedicationReminderService] Error toggling dose: $e");
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      final currentList = List<MedicationReminder>.from(remindersNotifier.value);
      currentList.removeWhere((r) => r.id == reminderId);
      remindersNotifier.value = currentList;
      await _persistList(currentList);
    } catch (e) {
      debugPrint("[MedicationReminderService] Error deleting reminder: $e");
    }
  }

  bool isMedicineConverted(String? prescriptionId, String medicineName) {
    final cleanName = medicineName.trim().toLowerCase();
    return remindersNotifier.value.any((r) {
      final matchName = r.medicineName.trim().toLowerCase() == cleanName;
      if (prescriptionId != null && prescriptionId.isNotEmpty) {
        return matchName && r.prescriptionId == prescriptionId;
      }
      return matchName;
    });
  }

  MedicationReminder? getReminderForMedicine(String? prescriptionId, String medicineName) {
    final cleanName = medicineName.trim().toLowerCase();
    try {
      return remindersNotifier.value.firstWhere((r) {
        final matchName = r.medicineName.trim().toLowerCase() == cleanName;
        if (prescriptionId != null && prescriptionId.isNotEmpty) {
          return matchName && r.prescriptionId == prescriptionId;
        }
        return matchName;
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteMedicineReminder(String? prescriptionId, String medicineName) async {
    final reminder = getReminderForMedicine(prescriptionId, medicineName);
    if (reminder != null) {
      await deleteReminder(reminder.id);
    }
  }

  List<TodayMedicationDose> getTodayDoses() {
    final List<TodayMedicationDose> doses = [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final reminder in remindersNotifier.value) {
      if (!reminder.isActive) continue;

      final start = DateTime(reminder.startDate.year, reminder.startDate.month, reminder.startDate.day);
      final end = DateTime(reminder.endDate.year, reminder.endDate.month, reminder.endDate.day);

      // Check if today is within start and end date
      if (today.isBefore(start)) continue;
      if (!reminder.isContinuous && today.isAfter(end)) continue;

      for (final time in reminder.times) {
        final isTaken = reminder.isDoseTakenToday(time);

        doses.add(TodayMedicationDose(
          reminder: reminder,
          slot: time,
          time: time,
          isTaken: isTaken,
        ));
      }
    }

    // Sort doses chronologically by time
    doses.sort((a, b) => _timeToMinutes(a.time).compareTo(_timeToMinutes(b.time)));

    return doses;
  }

  int _timeToMinutes(String timeStr) {
    try {
      final format = DateFormat('hh:mm a');
      final dt = format.parse(timeStr.trim());
      return dt.hour * 60 + dt.minute;
    } catch (_) {
      try {
        final format24 = DateFormat('HH:mm');
        final dt = format24.parse(timeStr.trim());
        return dt.hour * 60 + dt.minute;
      } catch (_) {
        return 0;
      }
    }
  }

  Future<void> _persistList(List<MedicationReminder> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((r) => r.toMap()).toList();
    await prefs.setString(_storageKey, json.encode(jsonList));
  }
}
