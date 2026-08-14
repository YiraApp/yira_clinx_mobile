import 'dart:io';
import 'package:dio/dio.dart';
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
      DateTime parsedDate;
      if (isSingleDay) {
         parsedDate = DateFormat('yyyy-MM-dd').parse(targetDate);
      } else {
         parsedDate = DateTime.now(); 
      }

      final currentUser = GlobalSession.instance.userNotifier.value;
      final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
          ? currentUser.data!.id!.trim()
          : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
              ? currentUser.data!.navigationId!.trim()
              : '1';
      final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
      final String token = currentUser?.data?.accessToken ?? '';
      final String dateStr = DateFormat('yyyy-MM-dd').format(parsedDate);

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
          return slotData['slots'] as List;
        }
      }
    } catch (e) {
      print("generateTimeSlots Error: $e");
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
        final String label = (item['label'] ?? '').toString();
        
        final parts = label.split(" - ");
        final startTime = _formatTime(parts.isNotEmpty ? parts[0] : "");
        final endTime = _formatTime(parts.length > 1 ? parts[1] : "");

        fetched.add(SlotModel(
          id: id,
          startTime: startTime,
          endTime: endTime,
          label: isBooked ? 'Booked' : 'Available',
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
        final String startTime = item['startTime'].toString(); 
        final String? patientName = item['patientName']?.toString();
        final String? appointmentTypeStr = item['appointmentType']?.toString();
        
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

        fetched.add(TimeSlot(
          id: id,
          time: formattedTime,
          duration: "${durationMinutes}m",
          status: isBooked ? SlotStatus.booked : SlotStatus.available,
          patientName: isBooked ? (patientName ?? "Patient") : null,
          type: aptType,
        ));
      }
    }
    return fetched;
  }

  Future<bool> _deploySlotsToApi(List<dynamic> slotObjects, {required String targetDate}) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
          ? currentUser.data!.id!.trim()
          : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
              ? currentUser.data!.navigationId!.trim()
              : '1';
      final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
      final String token = currentUser?.data?.accessToken ?? '';

      final payload = {
        "doctorId": doctorId,
        "hospitalId": hospitalId,
        "date": targetDate,
        "slots": slotObjects.map((s) {
          if (s is TimeSlot) {
            DateTime parsedTime;
            try {
               parsedTime = DateFormat('h:mm a').parse(s.time);
            } catch (_) {
               parsedTime = DateFormat('HH:mm').parse(s.time);
            }
            final start = DateFormat('HH:mm').format(parsedTime);
            
            int durMinutes = 30;
            if (s.duration.isNotEmpty) {
               try {
                 durMinutes = int.parse(s.duration.replaceAll(RegExp(r'[^0-9]'), ''));
               } catch (_) {}
            }
            
            final end = DateFormat('HH:mm').format(parsedTime.add(Duration(minutes: durMinutes)));
            return {
              "startTime": start,
              "endTime": end,
              "isAvailable": s.status == SlotStatus.available,
              "status": s.status == SlotStatus.available ? "Available" : "Booked"
            };
          }
          return {};
        }).where((s) => s.isNotEmpty).toList()
      };

      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.doctorSlotsDeployUrl,
        data: payload,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print("deploy Error: $e");
      return false;
    }
  }

  @override
  Future<bool> deploySchedule(List<SlotEntity> slots, {required String targetDate, required bool isSingleDay}) async {
    return true; // We handle deployment in deployTimeSchedule to avoid double-posting
  }

  @override
  Future<bool> deployTimeSchedule(List<TimeSlot> slots, {required String targetDate, required bool isSingleDay}) async {
    if (!isSingleDay) return true; // Only deploy single days for now
    return await _deploySlotsToApi(slots, targetDate: targetDate);
  }
}