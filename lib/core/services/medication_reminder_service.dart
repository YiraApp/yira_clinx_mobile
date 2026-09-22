import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/services/notification_services/notification_services.dart';
import 'package:yiraclinics/core/urls/urls.dart';
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

    // Asynchronously synchronize with backend for active user
    fetchRemoteReminders();
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

  /// Fetches reminders saved on the backend MSSQL database and merges with local doses
  Future<void> fetchRemoteReminders() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';
      if (token.isEmpty) return;

      final client = ApiClient();
      final response = await client.account(showSuccessSnack: false).get(
        URLs.patientMedicationRemindersUrl,
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic data = response.data['data'] ?? response.data['result'];
        if (data is List) {
          final currentMap = {for (var r in remindersNotifier.value) r.id: r};
          final List<MedicationReminder> remoteList = [];

          for (final item in data) {
            final parsed = MedicationReminder.fromMap(Map<String, dynamic>.from(item));
            // Preserve locally tracked dose completion status
            final localExisting = currentMap[parsed.id];
            if (localExisting != null && localExisting.takenDoses.isNotEmpty) {
              final mergedDoses = Map<String, bool>.from(parsed.takenDoses)..addAll(localExisting.takenDoses);
              remoteList.add(parsed.copyWith(takenDoses: mergedDoses));
            } else {
              remoteList.add(parsed);
            }
          }

          if (remoteList.isNotEmpty) {
            remindersNotifier.value = remoteList;
            await _persistList(remoteList);
            debugPrint("[MedicationReminderService] Successfully synced ${remoteList.length} reminders from backend");
          }
        }
      }
    } catch (e) {
      debugPrint("[MedicationReminderService] Remote fetch ignored (offline/fallback): $e");
    }
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

      // Asynchronously send to backend scheduler
      _syncSaveReminderToBackend(reminder);
    } catch (e) {
      debugPrint("[MedicationReminderService] Error saving reminder: $e");
    }
  }

  Future<void> _syncSaveReminderToBackend(MedicationReminder reminder) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';
      final userId = currentUser?.data?.id ?? '';
      if (token.isEmpty || userId.isEmpty) return;

      final client = ApiClient();
      await client.account(showSuccessSnack: false).post(
        URLs.patientMedicationRemindersUrl,
        data: {
          'id': reminder.id,
          'userId': userId,
          'prescriptionId': reminder.prescriptionId,
          'medicineName': reminder.medicineName,
          'dosage': reminder.dosage,
          'instructions': reminder.instructions,
          'mealRelation': reminder.mealRelation,
          'times': reminder.times,
          'startDate': reminder.startDate.toIso8601String(),
          'endDate': reminder.endDate.toIso8601String(),
          'durationDays': reminder.durationDays,
          'isContinuous': reminder.isContinuous,
          'doctorName': reminder.doctorName,
          'doctorPhoto': reminder.doctorPhoto,
          'condition': reminder.condition,
          'isActive': reminder.isActive,
        },
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        ),
      );
      debugPrint("[MedicationReminderService] Successfully synced reminder ${reminder.id} to backend scheduler");
    } catch (e) {
      debugPrint("[MedicationReminderService] Error syncing reminder to backend: $e");
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

      // Asynchronously delete from backend
      _syncDeleteReminderToBackend(reminderId);
    } catch (e) {
      debugPrint("[MedicationReminderService] Error deleting reminder: $e");
    }
  }

  Future<void> _syncDeleteReminderToBackend(String reminderId) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';
      if (token.isEmpty) return;

      final client = ApiClient();
      await client.account(showSuccessSnack: false).delete(
        "${URLs.patientMedicationRemindersUrl}/$reminderId",
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        ),
      );
      debugPrint("[MedicationReminderService] Successfully deactivated reminder $reminderId on backend");
    } catch (e) {
      debugPrint("[MedicationReminderService] Error deactivating reminder on backend: $e");
    }
  }

  /// Syncs all existing local reminders to the backend in a batch
  Future<void> syncAllToBackend() async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';
      final userId = currentUser?.data?.id ?? '';
      if (token.isEmpty || userId.isEmpty) return;

      final remindersList = remindersNotifier.value;
      if (remindersList.isEmpty) return;

      final client = ApiClient();
      await client.account(showSuccessSnack: false).post(
        URLs.patientMedicationRemindersSyncUrl,
        data: {
          'userId': userId,
          'reminders': remindersList.map((r) => {
            'id': r.id,
            'prescriptionId': r.prescriptionId,
            'medicineName': r.medicineName,
            'dosage': r.dosage,
            'instructions': r.instructions,
            'mealRelation': r.mealRelation,
            'times': r.times,
            'startDate': r.startDate.toIso8601String(),
            'endDate': r.endDate.toIso8601String(),
            'durationDays': r.durationDays,
            'isContinuous': r.isContinuous,
            'doctorName': r.doctorName,
            'doctorPhoto': r.doctorPhoto,
            'condition': r.condition,
            'isActive': r.isActive,
          }).toList(),
        },
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $token',
          },
        ),
      );
      debugPrint("[MedicationReminderService] Synced ${remindersList.length} local reminders to backend in batch");
    } catch (e) {
      debugPrint("[MedicationReminderService] Error in syncAllToBackend: $e");
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
