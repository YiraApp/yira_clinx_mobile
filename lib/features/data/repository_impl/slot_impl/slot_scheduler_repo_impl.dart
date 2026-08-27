import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import '../../../domain/entities/slot/slot_appointment_entity.dart';
import '../../../domain/entities/slot/time_slot_entity.dart';
import '../../../domain/repositories/slot/scheduler_repo.dart';
import '../../models/slot/slot_appointment_model.dart';

class SchedulerRepositoryImpl implements SchedulerRepository {
  
  String _formatTime(String time24) {
    try {
      final parts = time24.split(":");
      if (parts.length >= 2) {
        int h = int.parse(parts[0]);
        int m = int.parse(parts[1]);
        final dt = DateTime(2000, 1, 1, h, m);
        return DateFormat('h:mm a').format(dt);
      }
    } catch (_) {}
    return time24;
  }

  Future<List<dynamic>> _fetchSlotsFromApi(String targetDate, bool isSingleDay) async {
    try {
      // targetDate is already in yyyy-MM-dd format from the bloc
      final String dateStr = isSingleDay ? targetDate : DateFormat('yyyy-MM-dd').format(DateTime.now());

      final currentUser = GlobalSession.instance.userNotifier.value;
      final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
          ? currentUser.data!.id!.trim()
          : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
              ? currentUser.data!.navigationId!.trim()
              : '1';
      final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
      final String token = currentUser?.data?.accessToken ?? '';

      debugPrint("SlotRepo: Fetching slots for doctor=$doctorId, hospital=$hospitalId, date=$dateStr");

      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.doctorSlotsUrl,
        data: {
          "doctorId": doctorId,
          "hospitalId": hospitalId,
          "date": dateStr,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final rawData = response.data as Map<String, dynamic>;
        final slotData = rawData['data'];
        if (slotData != null && slotData['slots'] is List) {
          final slots = slotData['slots'] as List;
          debugPrint("SlotRepo: Received ${slots.length} slots from API");
          return slots;
        }
      }
    } catch (e) {
      debugPrint("SlotRepo: _fetchSlotsFromApi Error: $e");
    }
    return [];
  }


  @override
  Future<List<SlotEntity>> generateSlots({
    required bool isSingleDay,
    required String targetDate,
    required int durationMinutes,
    required String bufferType,
  }) async {
    final rawSlots = await _fetchSlotsFromApi(targetDate, isSingleDay);
    
    if (rawSlots.isEmpty) {
      return [];
    }

    final List<SlotEntity> fetched = [];
    for (final item in rawSlots) {
      if (item is Map<String, dynamic>) {
        final String id = item['id'].toString();
        final bool isBooked = item['isBooked'] == true;
        final bool isBlocked = item['isBlocked'] == true || (item['isAvailable'] == false && !isBooked);
        final String label = (item['label'] ?? '').toString();
        final String? patientName = item['patientName']?.toString();
        final String? appointmentId = item['appointmentId']?.toString();
        final String? reason = item['reason']?.toString();
        
        final parts = label.split(" - ");
        final startTime = _formatTime(parts.isNotEmpty ? parts[0] : "");
        final endTime = _formatTime(parts.length > 1 ? parts[1] : "");

        SlotAppointmentEntity? appt;
        if (isBooked) {
          appt = SlotAppointmentEntity(
            id: appointmentId ?? id,
            patientName: patientName ?? 'Patient',
            contactNumber: 'N/A',
            reason: reason,
          );
        }

        String slotLabel = 'Available';
        if (isBooked) {
          slotLabel = 'Booked';
        } else if (isBlocked) {
          slotLabel = 'Blocked';
        }

        fetched.add(SlotModel(
          id: id,
          startTime: _formatTime(startTime),
          endTime: _formatTime(endTime),
          label: slotLabel,
          appointment: appt,
        ));
      }
    }
    return fetched;
  }

  @override
  Future<List<TimeSlot>> generateTimeSlots({
    required bool isSingleDay,
    required String targetDate,
    required int durationMinutes,
    required String bufferType,
  }) async {
    final rawSlots = await _fetchSlotsFromApi(targetDate, isSingleDay);
    
    if (rawSlots.isEmpty) {
      return [];
    }

    final List<TimeSlot> fetched = [];
    for (final item in rawSlots) {
      if (item is Map<String, dynamic>) {
        final String id = item['id'].toString();
        final bool isBooked = item['isBooked'] == true;
        final bool isBlocked = item['isBlocked'] == true || (item['isAvailable'] == false && !isBooked);
        final String startTime = item['startTime'].toString(); 
        final String? patientName = item['patientName']?.toString();
        final String? appointmentTypeStr = item['appointmentType']?.toString();
        final String? appointmentId = item['appointmentId']?.toString();
        final String? reason = item['reason']?.toString();
        
        final formattedTime = _formatTime(startTime);

        AppointmentType? aptType;
        if (isBooked) {
          if (appointmentTypeStr != null && appointmentTypeStr.isNotEmpty) {
             aptType = AppointmentType.values.firstWhere(
               (e) => e.toString().split('.').last.toLowerCase() == appointmentTypeStr.replaceAll('-', '').replaceAll(' ', '').toLowerCase(),
               orElse: () => AppointmentType.regularCheckUp,
             );
          } else {
             aptType = AppointmentType.regularCheckUp;
          }
        }

        SlotStatus status = SlotStatus.available;
        if (isBooked) {
          status = SlotStatus.booked;
        } else if (isBlocked) {
          status = SlotStatus.blocked;
        }

        fetched.add(TimeSlot(
          id: id,
          time: formattedTime,
          duration: isBlocked ? "Blocked" : "${durationMinutes}m",
          status: status,
          patientName: isBooked ? (patientName ?? "Patient") : null,
          type: aptType,
          appointmentId: appointmentId,
          reason: reason,
        ));
      }
    }
    return fetched;
  }

  @override
  Future<List<BreakTimeEntity>> fetchBreakTimes({
    required String targetDate,
    required bool isSingleDay,
  }) async {
    try {
      final String dateStr = isSingleDay ? targetDate : DateFormat('yyyy-MM-dd').format(DateTime.now());
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
          ? currentUser.data!.id!.trim()
          : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
              ? currentUser.data!.navigationId!.trim()
              : '1';
      final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.doctorSlotsUrl,
        data: {
          "doctorId": doctorId,
          "hospitalId": hospitalId,
          "date": dateStr,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final rawData = response.data as Map<String, dynamic>;
        final slotData = rawData['data'];
        if (slotData != null && slotData['breaks'] is List) {
          final breaksList = slotData['breaks'] as List;
          final List<BreakTimeEntity> result = [];
          for (final b in breaksList) {
            if (b is Map<String, dynamic>) {
              result.add(BreakTimeEntity(
                id: (b['id'] ?? 'break_${result.length + 1}').toString(),
                fromTime: _formatTime((b['fromTime'] ?? b['startTime'] ?? '').toString()),
                toTime: _formatTime((b['toTime'] ?? b['endTime'] ?? '').toString()),
                label: (b['label'] ?? 'Break ${result.length + 1}').toString(),
              ));
            }
          }
          if (result.isNotEmpty) return result;
        }
      }
    } catch (e) {
      debugPrint("SlotRepo: fetchBreakTimes error: $e");
    }
    return [];
  }

  DateTime _parseTimeString(String t) {
    try {
      final cleaned = t.replaceAll(RegExp(r'[\s\u00A0\u2000-\u200B\u202F]+'), ' ').trim();
      final match = RegExp(r'^(\d{1,2}):(\d{2})\s*([a-zA-Z]{2})?', caseSensitive: false).firstMatch(cleaned);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        String? ampm = match.group(3)?.toUpperCase();
        if (ampm == 'PM' && hour < 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        return DateTime(2000, 1, 1, hour, minute);
      }
      return DateFormat('HH:mm').parse(cleaned);
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<bool> _deploySlotsToApi(
    List<dynamic> slotObjects, {
    required String targetDate,
    List<Map<String, dynamic>>? breakTimes,
  }) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
          ? currentUser.data!.id!.trim()
          : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
              ? currentUser.data!.navigationId!.trim()
              : '1';
      final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
      final String token = currentUser?.data?.accessToken ?? '';

      final List<Map<String, dynamic>> breakTimesPayload = (breakTimes ?? []).map((b) => {
        "fromTime": DateFormat('HH:mm').format(_parseTimeString(b["fromTime"]?.toString() ?? '')),
        "toTime": DateFormat('HH:mm').format(_parseTimeString(b["toTime"]?.toString() ?? '')),
        "label": b["label"]?.toString() ?? '',
      }).toList();

      final List<Map<String, dynamic>> slotsPayload = [];
      for (final s in slotObjects) {
        if (s is SlotEntity) {
          final dtStart = _parseTimeString(s.startTime);
          final dtEnd = _parseTimeString(s.endTime);
          final startMin = dtStart.hour * 60 + dtStart.minute;
          final endMin = dtEnd.hour * 60 + dtEnd.minute;

          // Check if slot falls in any break period
          bool overlapsBreak = false;
          for (final b in (breakTimes ?? [])) {
            final bStartDt = _parseTimeString(b["fromTime"]?.toString() ?? '');
            final bEndDt = _parseTimeString(b["toTime"]?.toString() ?? '');
            final bStart = bStartDt.hour * 60 + bStartDt.minute;
            final bEnd = bEndDt.hour * 60 + bEndDt.minute;
            if (bStart < bEnd && startMin < bEnd && endMin > bStart) {
              overlapsBreak = true;
              break;
            }
          }
          if (overlapsBreak) {
            debugPrint("SlotRepo: Stripping out slot ${s.startTime} - ${s.endTime} overlapping break");
            continue;
          }

          final start = DateFormat('HH:mm').format(dtStart);
          final end = DateFormat('HH:mm').format(dtEnd);
          final isAvailable = s.label == 'Available';
          final isBlocked = s.label == 'Blocked';
          slotsPayload.add({
            "startTime": start,
            "endTime": end,
            "isAvailable": isAvailable,
            "status": isAvailable ? "Available" : (isBlocked ? "Blocked" : "Booked")
          });
        } else if (s is TimeSlot) {
          final parsedTime = _parseTimeString(s.time);
          final startMin = parsedTime.hour * 60 + parsedTime.minute;
          
          int durMinutes = 20;
          if (s.duration.isNotEmpty && s.duration != 'Blocked') {
            try {
              durMinutes = int.parse(s.duration.replaceAll(RegExp(r'[^0-9]'), ''));
            } catch (_) {}
          }
          final endMin = startMin + durMinutes;

          bool overlapsBreak = false;
          for (final b in (breakTimes ?? [])) {
            final bStartDt = _parseTimeString(b["fromTime"]?.toString() ?? '');
            final bEndDt = _parseTimeString(b["toTime"]?.toString() ?? '');
            final bStart = bStartDt.hour * 60 + bStartDt.minute;
            final bEnd = bEndDt.hour * 60 + bEndDt.minute;
            if (bStart < bEnd && startMin < bEnd && endMin > bStart) {
              overlapsBreak = true;
              break;
            }
          }
          if (overlapsBreak) {
            debugPrint("SlotRepo: Stripping out timeSlot ${s.time} overlapping break");
            continue;
          }
          
          final start = DateFormat('HH:mm').format(parsedTime);
          final end = DateFormat('HH:mm').format(parsedTime.add(Duration(minutes: durMinutes)));
          final isAvailable = s.status == SlotStatus.available;
          slotsPayload.add({
            "startTime": start,
            "endTime": end,
            "isAvailable": isAvailable,
            "status": isAvailable ? "Available" : (s.status == SlotStatus.blocked ? "Blocked" : "Booked")
          });
        }
      }

      final payload = {
        "doctorId": doctorId,
        "hospitalId": hospitalId,
        "date": targetDate,
        "slots": slotsPayload,
        "breakTimes": breakTimesPayload,
      };

      debugPrint("SlotRepo: Deploying ${slotsPayload.length} slots (breaks: ${breakTimesPayload.length}) for doctor=$doctorId, hospital=$hospitalId, date=$targetDate");

      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.doctorSlotsDeployUrl,
        data: payload,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("SlotRepo: Deploy SUCCESS");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("SlotRepo: deploy Error: $e");
      return false;
    }
  }

  @override
  Future<bool> deploySchedule(
    List<SlotEntity> slots, {
    required String targetDate,
    required bool isSingleDay,
    List<Map<String, dynamic>>? breakTimes,
  }) async {
    return await _deploySlotsToApi(slots, targetDate: targetDate, breakTimes: breakTimes);
  }

  @override
  Future<bool> deployTimeSchedule(
    List<TimeSlot> slots, {
    required String targetDate,
    required bool isSingleDay,
    List<Map<String, dynamic>>? breakTimes,
  }) async {
    return await _deploySlotsToApi(slots, targetDate: targetDate, breakTimes: breakTimes);
  }

  @override
  Future<bool> blockSlot({required String slotId, bool block = true}) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String token = currentUser?.data?.accessToken ?? '';
      debugPrint("SlotRepo: Calling blockSlot for slotId=$slotId, block=$block");
      final response = await sl<ApiClient>().account(showSuccessSnack: true).post(
        URLs.doctorSlotBlockUrl,
        data: {
          "slotId": int.tryParse(slotId) ?? slotId,
          "block": block,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("blockSlot Error: $e");
      return false;
    }
  }

  @override
  Future<bool> bookSlotAppointment({
    required String slotId,
    required String patientName,
    required String patientPhone,
    required String appointmentDate,
    required String startTime,
    String? reason,
    String? appointmentType,
  }) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
          ? currentUser.data!.id!.trim()
          : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
              ? currentUser.data!.navigationId!.trim()
              : '1';
      final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
      final int orgId = currentUser?.data?.latestOrgId ?? 1;
      final String token = currentUser?.data?.accessToken ?? '';

      DateTime parsedTime;
      try {
        parsedTime = DateFormat('h:mm a').parse(startTime);
      } catch (_) {
        try {
          parsedTime = DateFormat('HH:mm').parse(startTime);
        } catch (_) {
          parsedTime = DateTime.now();
        }
      }
      final formattedStartTime = "${DateFormat('HH:mm').format(parsedTime)}:00";

      debugPrint("SlotRepo: Booking appointment: doctor=$doctorId, hosp=$hospitalId, org=$orgId, patient=$patientName, date=$appointmentDate, time=$formattedStartTime");

      final response = await sl<ApiClient>().account(showSuccessSnack: true).post(
        URLs.bookAppointmentUrl,
        data: {
          "doctorId": doctorId,
          "hospitalId": hospitalId,
          "orgId": orgId,
          "patientName": patientName,
          "patientPhone": patientPhone,
          "appointmentDate": appointmentDate,
          "startTime": formattedStartTime,
          "reason": reason ?? "Consultation",
          "appointmentType": appointmentType ?? "Regular Check-up",
          "isTeleConsultation": false,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("bookSlotAppointment Error: $e");
      return false;
    }
  }

  @override
  Future<bool> cancelSlotAppointment({
    required String appointmentId,
    String? slotId,
  }) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String token = currentUser?.data?.accessToken ?? '';

      debugPrint("SlotRepo: Cancelling appointmentId=$appointmentId");

      final response = await sl<ApiClient>().account(showSuccessSnack: true).post(
        URLs.updateAppointmentStatusUrl,
        data: {
          "appointmentId": int.tryParse(appointmentId) ?? appointmentId,
          "status": "Cancelled",
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("cancelSlotAppointment Error: $e");
      return false;
    }
  }
}