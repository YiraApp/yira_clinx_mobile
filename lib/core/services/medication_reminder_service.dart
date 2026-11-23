import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
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
  MedicationReminderService._privateConstructor() {
    // Each family profile has its own medicines: when the open profile changes,
    // show that profile's list instead of the previous one's.
    GlobalSession.instance.userNotifier.addListener(_onSessionChanged);
  }
  static final MedicationReminderService instance = MedicationReminderService._privateConstructor();

  /// Remembers the open profile, so the floating popup (which has no session) can
  /// find the right list when it marks a dose taken.
  static const String _lastProfileKey = 'saved_medication_reminders_profile_v1';

  static String _keyFor(String profileId, String kind) =>
      'saved_medication_reminders_v1${kind.isEmpty ? '' : '_$kind'}_${profileId.isEmpty ? 'guest' : profileId}';

  /// The family profile the app has open (the account holder or a dependent).
  static String get _profileId => GlobalSession.instance.userNotifier.value?.data?.id?.trim() ?? '';

  final ValueNotifier<List<MedicationReminder>> remindersNotifier = ValueNotifier<List<MedicationReminder>>([]);

  /// True while the list is being fetched and nothing is stored on the phone yet.
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  /// The profile whose list is in [remindersNotifier]; null before the first load.
  String? _loadedFor;

  void _onSessionChanged() {
    final id = _profileId;
    if (_loadedFor == null || id == _loadedFor) return;
    remindersNotifier.value = [];
    _loadedFor = null;
    if (id.isNotEmpty) init();
  }

  Future<void> init({bool force = false}) async {
    final id = _profileId;
    if (!force && _loadedFor == id && id.isNotEmpty) return;
    _loadedFor = id;
    final local = await loadReminders();
    if (id.isEmpty) return;
    isLoading.value = local.isEmpty;
    await fetchRemoteReminders();
  }

  /// Clears in-memory reminders and de-initializes service on logout
  Future<void> clear() async {
    try {
      remindersNotifier.value = [];
      isLoading.value = false;
      _loadedFor = null;
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().where((k) => k.startsWith('saved_medication_reminders')).toList()) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint("[MedicationReminderService] Error clearing reminders: $e");
    }
  }

  /// The profile whose stored list to use: the open one, or (in the floating popup,
  /// which has no session) the last one the app had open.
  Future<String> _storageProfile(SharedPreferences prefs) async {
    final id = _profileId;
    if (id.isNotEmpty) return id;
    return prefs.getString(_lastProfileKey) ?? '';
  }

  Future<List<MedicationReminder>> loadReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // The floating popup runs separately and may have marked a dose taken.
      await prefs.reload();
      final raw = prefs.getString(_keyFor(await _storageProfile(prefs), ''));
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

  /// Every medicine call names the open profile (x-user-id), so the server keeps a
  /// dependent's medicines apart from the account holder's. Without it the server
  /// used the signed-in account for everything, so medicines added for one person
  /// showed up for the whole family.
  Options _options(String profileId) {
    final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
    return Options(
      headers: {
        if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
        if (profileId.isNotEmpty) 'x-user-id': profileId,
      },
      extra: const {'showSuccessSnack': false, 'suppressErrorSnack': true},
    );
  }

  Future<Set<String>> _pending(String profileId, String kind) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyFor(profileId, kind)) ?? const []).toSet();
  }

  Future<void> _setPending(String profileId, String kind, String id, bool pending) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_keyFor(profileId, kind)) ?? const []).toSet();
    pending ? set.add(id) : set.remove(id);
    await prefs.setStringList(_keyFor(profileId, kind), set.toList());
  }

  /// Fetches the open profile's reminders from the server. Changes that couldn't
  /// reach the server earlier (a stop or a new reminder made offline) are sent
  /// first, so a stopped medicine doesn't come back and keep reminding.
  Future<void> fetchRemoteReminders() async {
    final profileId = _profileId;
    if (profileId.isEmpty) return;
    try {
      await _retryPending(profileId);

      final response = await ApiClient().account(showSuccessSnack: false).get(
            URLs.patientMedicationRemindersUrl,
            queryParameters: {'userId': profileId},
            options: _options(profileId),
          );
      // The person switched profile meanwhile: this list isn't theirs.
      if (_profileId != profileId) return;

      if (response.statusCode == 200 && response.data != null) {
        final dynamic data = response.data['data'] ?? response.data['result'];
        if (data is List) {
          final pendingDeletes = await _pending(profileId, 'deletes');
          final pendingSaves = await _pending(profileId, 'saves');
          final currentMap = {for (var r in remindersNotifier.value) r.id: r};
          final List<MedicationReminder> remoteList = [];

          for (final item in data) {
            final parsed = MedicationReminder.fromMap(Map<String, dynamic>.from(item));
            if (pendingDeletes.contains(parsed.id)) continue;
            // Preserve locally tracked dose completion status
            final localExisting = currentMap[parsed.id];
            if (localExisting != null && localExisting.takenDoses.isNotEmpty) {
              final mergedDoses = Map<String, bool>.from(parsed.takenDoses)..addAll(localExisting.takenDoses);
              remoteList.add(parsed.copyWith(takenDoses: mergedDoses));
            } else {
              remoteList.add(parsed);
            }
          }
          // Reminders saved on this phone that the server hasn't got yet stay.
          final remoteIds = remoteList.map((r) => r.id).toSet();
          for (final local in currentMap.values) {
            if (pendingSaves.contains(local.id) && !remoteIds.contains(local.id)) remoteList.insert(0, local);
          }

          remindersNotifier.value = remoteList;
          await _persistList(remoteList, profileId: profileId);
          debugPrint("[MedicationReminderService] Synced ${remoteList.length} reminders for profile $profileId");
        }
      }
    } catch (e) {
      debugPrint("[MedicationReminderService] Remote fetch ignored (offline/fallback): $e");
    } finally {
      if (_profileId == profileId) isLoading.value = false;
    }
  }

  Future<void> _retryPending(String profileId) async {
    for (final id in await _pending(profileId, 'deletes')) {
      await _syncDeleteReminderToBackend(id, profileId);
    }
    final saves = await _pending(profileId, 'saves');
    if (saves.isEmpty) return;
    for (final r in remindersNotifier.value.where((r) => saves.contains(r.id)).toList()) {
      await _syncSaveReminderToBackend(r, profileId);
    }
  }

  Future<void> saveReminder(MedicationReminder reminder) async {
    final profileId = _profileId;
    try {
      final currentList = List<MedicationReminder>.from(remindersNotifier.value);
      final index = currentList.indexWhere((r) => r.id == reminder.id);
      if (index >= 0) {
        currentList[index] = reminder;
      } else {
        currentList.insert(0, reminder);
      }

      remindersNotifier.value = currentList;
      await _persistList(currentList, profileId: profileId);

      // No notification here: the screen that saved it already confirms it.

      // The server sends the reminders; until it has this one it's retried on the next load.
      await _setPending(profileId, 'saves', reminder.id, true);
      _syncSaveReminderToBackend(reminder, profileId);
    } catch (e) {
      debugPrint("[MedicationReminderService] Error saving reminder: $e");
    }
  }

  Future<bool> _syncSaveReminderToBackend(MedicationReminder reminder, String profileId) async {
    try {
      if (profileId.isEmpty) return false;
      await ApiClient().account(showSuccessSnack: false).post(
        URLs.patientMedicationRemindersUrl,
        data: {
          'id': reminder.id,
          'userId': profileId,
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
        options: _options(profileId),
      );
      await _setPending(profileId, 'saves', reminder.id, false);
      debugPrint("[MedicationReminderService] Saved reminder ${reminder.id} on the server");
      return true;
    } catch (e) {
      debugPrint("[MedicationReminderService] Error syncing reminder to backend: $e");
      return false;
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
      }
    } catch (e) {
      debugPrint("[MedicationReminderService] Error toggling dose: $e");
    }
  }

  /// Marks a dose as taken (never un-marks it). Reads and writes storage
  /// directly, so the floating popup can call it while the app is closed;
  /// the app picks the change up the next time it loads reminders.
  Future<bool> markDoseTaken(String reminderId, String timeKey, {String? date}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final profileId = await _storageProfile(prefs);
      final raw = prefs.getString(_keyFor(profileId, ''));
      if (raw == null || raw.isEmpty) return false;
      final list = (json.decode(raw) as List)
          .map((item) => MedicationReminder.fromMap(Map<String, dynamic>.from(item)))
          .toList();
      final index = list.indexWhere((r) => r.id == reminderId);
      if (index < 0) return false;

      final now = DateTime.now();
      final day = (date != null && date.isNotEmpty)
          ? date
          : "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final doses = Map<String, bool>.from(list[index].takenDoses)..["${day}_$timeKey"] = true;
      list[index] = list[index].copyWith(takenDoses: doses);

      await _persistList(list, profileId: profileId);
      if (_profileId.isEmpty || _profileId == profileId) remindersNotifier.value = list;
      return true;
    } catch (e) {
      debugPrint("[MedicationReminderService] Error marking dose taken: $e");
      return false;
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    final profileId = _profileId;
    try {
      final currentList = List<MedicationReminder>.from(remindersNotifier.value);
      currentList.removeWhere((r) => r.id == reminderId);
      remindersNotifier.value = currentList;
      await _persistList(currentList, profileId: profileId);

      // Until the server has stopped it, it keeps sending reminders: retried on each load.
      await _setPending(profileId, 'saves', reminderId, false);
      await _setPending(profileId, 'deletes', reminderId, true);
      await _syncDeleteReminderToBackend(reminderId, profileId);
    } catch (e) {
      debugPrint("[MedicationReminderService] Error deleting reminder: $e");
    }
  }

  Future<bool> _syncDeleteReminderToBackend(String reminderId, String profileId) async {
    try {
      if (profileId.isEmpty) return false;
      await ApiClient().account(showSuccessSnack: false).delete(
        "${URLs.patientMedicationRemindersUrl}/$reminderId",
        data: {'userId': profileId},
        options: _options(profileId),
      );
      await _setPending(profileId, 'deletes', reminderId, false);
      debugPrint("[MedicationReminderService] Stopped reminder $reminderId on the server");
      return true;
    } catch (e) {
      debugPrint("[MedicationReminderService] Error deactivating reminder on backend: $e");
      return false;
    }
  }

  /// Syncs all existing local reminders to the backend in a batch
  Future<void> syncAllToBackend() async {
    final profileId = _profileId;
    try {
      if (profileId.isEmpty) return;
      final remindersList = remindersNotifier.value;
      if (remindersList.isEmpty) return;

      await ApiClient().account(showSuccessSnack: false).post(
        URLs.patientMedicationRemindersSyncUrl,
        data: {
          'userId': profileId,
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
        options: _options(profileId),
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

  Future<void> deletePrescriptionReminders(String prescriptionId) async {
    final related = remindersNotifier.value
        .where((r) => r.prescriptionId == prescriptionId)
        .toList();
    for (final r in related) {
      await deleteReminder(r.id);
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

  Future<void> _persistList(List<MedicationReminder> list, {String? profileId}) async {
    final prefs = await SharedPreferences.getInstance();
    final id = profileId ?? await _storageProfile(prefs);
    final jsonList = list.map((r) => r.toMap()).toList();
    await prefs.setString(_keyFor(id, ''), json.encode(jsonList));
    if (id.isNotEmpty) await prefs.setString(_lastProfileKey, id);
  }
}
