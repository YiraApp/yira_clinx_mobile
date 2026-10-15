import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';

class RescheduleAppointmentSheet extends StatefulWidget {
  final dynamic appointmentId;
  final String doctorId;
  final String doctorName;
  final String? hospitalId;
  final String? hospitalName;
  final dynamic currentAppointmentDate;
  final String? currentStartTime;
  final String? currentEndTime;
  final bool isTeleConsultation;
  final String? patientName;
  final VoidCallback? onRescheduled;

  const RescheduleAppointmentSheet({
    super.key,
    required this.appointmentId,
    required this.doctorId,
    required this.doctorName,
    this.hospitalId,
    this.hospitalName,
    this.currentAppointmentDate,
    this.currentStartTime,
    this.currentEndTime,
    this.isTeleConsultation = false,
    this.patientName,
    this.onRescheduled,
  });

  static Future<void> show(
    BuildContext context, {
    required dynamic appointmentId,
    required String doctorId,
    required String doctorName,
    String? hospitalId,
    String? hospitalName,
    dynamic currentAppointmentDate,
    String? currentStartTime,
    String? currentEndTime,
    bool isTeleConsultation = false,
    String? patientName,
    VoidCallback? onRescheduled,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RescheduleAppointmentSheet(
        appointmentId: appointmentId,
        doctorId: doctorId,
        doctorName: doctorName,
        hospitalId: hospitalId,
        hospitalName: hospitalName,
        currentAppointmentDate: currentAppointmentDate,
        currentStartTime: currentStartTime,
        currentEndTime: currentEndTime,
        isTeleConsultation: isTeleConsultation,
        patientName: patientName,
        onRescheduled: onRescheduled,
      ),
    );
  }

  @override
  State<RescheduleAppointmentSheet> createState() => _RescheduleAppointmentSheetState();
}

class _RescheduleAppointmentSheetState extends State<RescheduleAppointmentSheet> {
  late DateTime _selectedDate;
  bool _isLoadingSlots = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _availableSlots = [];
  Map<String, dynamic>? _selectedSlot;
  String _effectiveDoctorId = '';
  String? _errorMessage;
  String _selectedSessionFilter = "All"; // "All" | "Morning" | "Afternoon" | "Evening"

  @override
  void initState() {
    super.initState();
    _effectiveDoctorId = widget.doctorId;

    final now = DateTime.now();
    // If today is late evening, default to tomorrow, otherwise start today
    if (now.hour >= 19) {
      _selectedDate = now.add(const Duration(days: 1));
    } else {
      _selectedDate = now;
    }

    _loadDoctorSlots();
  }

  int _getSlotHour(String timeStr) {
    try {
      final clean = timeStr.trim();
      if (clean.isEmpty) return 12;
      final firstPart = clean.contains(' - ') ? clean.split(' - ').first.trim() : clean;
      final isPM = firstPart.toUpperCase().contains('PM');
      final isAM = firstPart.toUpperCase().contains('AM');
      final digitsOnly = firstPart.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = digitsOnly.split(':');
      if (parts.isNotEmpty) {
        int hour = int.parse(parts[0]);
        if (isPM && hour < 12) hour += 12;
        if (isAM && hour == 12) hour = 0;
        return hour;
      }
    } catch (_) {}
    return 12;
  }

  Future<void> _loadDoctorSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _errorMessage = null;
      _selectedSlot = null;
    });

    final currentUser = GlobalSession.instance.userNotifier.value;
    final token = currentUser?.data?.accessToken ?? '';
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // If doctorId is missing, attempt to find a doctor from hospital
    if (_effectiveDoctorId.isEmpty && widget.hospitalId != null && widget.hospitalId!.isNotEmpty) {
      try {
        final docRes = await sl<ApiClient>().account(showSuccessSnack: false).post(
          URLs.hospitalDoctorsUrl,
          data: {"hospitalId": widget.hospitalId},
          options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
        );
        if (docRes.data != null && docRes.data['data'] is List) {
          final list = docRes.data['data'] as List;
          if (list.isNotEmpty) {
            final match = list.firstWhere(
              (d) => (d['doctorName'] ?? '').toString().toLowerCase().contains(widget.doctorName.toLowerCase()),
              orElse: () => list.first,
            );
            _effectiveDoctorId = (match['doctorId'] ?? match['id'] ?? '').toString();
          }
        }
      } catch (_) {}
    }

    List<Map<String, dynamic>> slots = [];

    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.doctorSlotsUrl,
        data: {
          "doctorId": _effectiveDoctorId,
          "hospitalId": widget.hospitalId,
          "date": dateStr,
        },
        options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
      );

      List<dynamic>? rawSlots;
      if (res.data != null && res.data['data'] != null) {
        final slotData = res.data['data'];
        if (slotData is List) {
          rawSlots = slotData;
        } else if (slotData is Map && slotData['slots'] is List) {
          rawSlots = slotData['slots'] as List;
        }
      }

      if (rawSlots != null && rawSlots.isNotEmpty) {
        final now = DateTime.now();
        final isToday = _selectedDate.year == now.year &&
            _selectedDate.month == now.month &&
            _selectedDate.day == now.day;

        for (final item in rawSlots) {
          if (item is Map) {
            final slotMap = Map<String, dynamic>.from(item);
            final String startTime = (slotMap['startTime'] ?? slotMap['start_time'] ?? '09:00').toString();
            final String endTime = (slotMap['endTime'] ?? slotMap['end_time'] ?? '09:15').toString();
            final String label = (slotMap['label'] ?? _formatSlotTime(startTime)).toString();
            final int startHour = _getSlotHour(startTime);

            final bool isBooked = slotMap['isBooked'] == true ||
                slotMap['is_booked'] == true ||
                slotMap['status']?.toString().toLowerCase() == 'booked' ||
                (slotMap['appointmentId'] != null &&
                    slotMap['appointmentId'].toString().isNotEmpty &&
                    slotMap['appointmentId'].toString() != 'null') ||
                slotMap['hasAppointment'] == true;

            final bool isBlocked = slotMap['isBlocked'] == true ||
                slotMap['is_blocked'] == true ||
                slotMap['status']?.toString().toLowerCase() == 'blocked' ||
                slotMap['label']?.toString().toLowerCase() == 'blocked';

            bool isPast = false;
            if (isToday) {
              final slotDt = _parseSlotDateTime(_selectedDate, startTime);
              if (slotDt != null && slotDt.isBefore(now)) {
                isPast = true;
              }
            }

            final bool isAvail = (slotMap['isAvailable'] == true || slotMap['is_available'] == true || (!isBooked && !isBlocked)) &&
                !isBooked &&
                !isBlocked &&
                !isPast;

            slots.add({
              'id': slotMap['id'] ?? slotMap['slotId'] ?? slotMap['SlotId'],
              'startTime': startTime,
              'endTime': endTime,
              'label': label,
              'startHour': startHour,
              'isAvailable': isAvail,
              'isBooked': isBooked,
              'isBlocked': isBlocked,
              'isPast': isPast,
            });
          }
        }
      }
    } catch (e) {
      _errorMessage = "Could not load slots. Please check your connection.";
    }

    if (mounted) {
      setState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
        final firstAvail = slots.where((s) => s['isAvailable'] == true).toList();
        if (firstAvail.isNotEmpty) {
          _selectedSlot = firstAvail.first;
        } else {
          _selectedSlot = null;
        }
      });
    }
  }

  DateTime? _parseSlotDateTime(DateTime baseDate, String timeStr) {
    try {
      final clean = timeStr.trim();
      final parts = clean.split(':');
      if (parts.length >= 2) {
        int h = int.parse(parts[0]);
        int m = int.parse(parts[1].split(' ')[0]);
        if (clean.toLowerCase().contains('pm') && h < 12) h += 12;
        if (clean.toLowerCase().contains('am') && h == 12) h = 0;
        return DateTime(baseDate.year, baseDate.month, baseDate.day, h, m);
      }
    } catch (_) {}
    return null;
  }

  String _formatSlotTime(String timeStr) {
    try {
      final clean = timeStr.trim();
      final firstPart = clean.contains(' - ') ? clean.split(' - ').first.trim() : clean;
      final isPM = firstPart.toUpperCase().contains('PM');
      final isAM = firstPart.toUpperCase().contains('AM');
      final digitsOnly = firstPart.replaceAll(RegExp(r'[^0-9:]'), '');
      final parts = digitsOnly.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        if (isPM && hour < 12) hour += 12;
        if (isAM && hour == 12) hour = 0;
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayH = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final displayM = minute.toString().padLeft(2, '0');
        return '$displayH:$displayM $period';
      }
    } catch (_) {}
    return timeStr;
  }

  Future<void> _handleConfirmReschedule() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available time slot.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final token = currentUser?.data?.accessToken ?? '';
    final newDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final payload = {
      "appointmentId": widget.appointmentId,
      "id": widget.appointmentId,
      "newSlotId": _selectedSlot!['id'],
      "newDoctorId": _effectiveDoctorId,
      "newDate": newDateStr,
      "startTime": _selectedSlot!['startTime'],
      "endTime": _selectedSlot!['endTime'],
    };

    bool isSuccess = false;
    String feedbackMessage = "Appointment rescheduled successfully!";

    // 1. Try mobile versioned reschedule endpoint
    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.rescheduleAppointmentUrl,
        data: payload,
        options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
      );

      if (res.data != null && (res.data['status'] == true || res.data['success'] == true)) {
        isSuccess = true;
        if (res.data['message'] != null) {
          feedbackMessage = res.data['message'].toString();
        }
      }
    } catch (_) {}

    // 2. Fallback to standard PATCH /api/appointments/:id/reschedule if mobile endpoint failed
    if (!isSuccess) {
      try {
        final patchUrl = "/api/appointments/${widget.appointmentId}/reschedule";
        final patchRes = await sl<ApiClient>().account(showSuccessSnack: false).patch(
          patchUrl,
          data: payload,
          options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
        );

        if (patchRes.data != null && (patchRes.data['status'] == true || patchRes.data['success'] == true)) {
          isSuccess = true;
          if (patchRes.data['message'] != null) {
            feedbackMessage = patchRes.data['message'].toString();
          }
        }
      } catch (err) {
        String msg = "Failed to reschedule appointment. Please try another slot.";
        if (err is DioException && err.response?.data != null) {
          final data = err.response!.data;
          if (data is Map && data['message'] != null) {
            msg = data['message'].toString();
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (isSuccess) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "$feedbackMessage (${DateFormat('EEE, d MMM').format(_selectedDate)} at ${_selectedSlot!['label'] ?? _selectedSlot!['startTime']})",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 4),
          ),
        );
        widget.onRescheduled?.call();
      }
    }
  }

  void _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Color(0xFF2563EB),
                    surface: Color(0xFF1E293B),
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF2563EB),
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadDoctorSlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);

    final String docDisplay = widget.doctorName.startsWith('Dr.') ? widget.doctorName : 'Dr. ${widget.doctorName}';
    final String hospDisplay = widget.hospitalName ?? 'Healthcare Facility';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.90,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Handle Bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),

                // Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_calendar_rounded,
                              color: Color(0xFFD97706),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Reschedule Visit",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontWeight: FontWeight.w700,
                                  fontSize: isTab ? 20 : 17,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "Choose a session & available time slot",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: isTab ? 13 : 11.5,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1),

                // Main Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Appointment Context Card
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                child: Text(
                                  docDisplay.replaceFirst('Dr. ', '').trim().isNotEmpty
                                      ? (docDisplay.replaceFirst('Dr. ', '').trim())[0].toUpperCase()
                                      : 'DR',
                                  style: const TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            docDisplay,
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontWeight: FontWeight.w700,
                                              fontSize: isTab ? 15 : 13.5,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: widget.isTeleConsultation
                                                ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                                                : const Color(0xFF059669).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            widget.isTeleConsultation ? "Video" : "In-Clinic",
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: widget.isTeleConsultation
                                                  ? const Color(0xFF2563EB)
                                                  : const Color(0xFF059669),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      hospDisplay,
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: isTab ? 13 : 11.5,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Select Date Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Select New Date",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.w700,
                                fontSize: isTab ? 16 : 14,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            InkWell(
                              onTap: _pickCustomDate,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month_rounded,
                                      size: 15,
                                      color: Color(0xFF2563EB),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Custom Date",
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontWeight: FontWeight.w600,
                                        fontSize: isTab ? 13 : 12,
                                        color: const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Horizontal Date Selector (Next 21 Days)
                        SizedBox(
                          height: 72,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: 21,
                            itemBuilder: (context, index) {
                              final date = DateTime.now().add(Duration(days: index));
                              final isSelected = date.year == _selectedDate.year &&
                                  date.month == _selectedDate.month &&
                                  date.day == _selectedDate.day;

                              final dayName = DateFormat('EEE').format(date);
                              final dayNum = DateFormat('dd').format(date);
                              final monthName = DateFormat('MMM').format(date);

                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: InkWell(
                                  onTap: () {
                                    if (!isSelected) {
                                      setState(() => _selectedDate = date);
                                      _loadDoctorSlots();
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 58,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF2563EB)
                                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          dayName.toUpperCase(),
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10,
                                            color: isSelected
                                                ? Colors.white70
                                                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dayNum,
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                            color: isSelected
                                                ? Colors.white
                                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                          ),
                                        ),
                                        Text(
                                          monthName,
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 9.5,
                                            color: isSelected
                                                ? Colors.white70
                                                : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Available Slots Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Available Time Slots",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.w700,
                                fontSize: isTab ? 16 : 14,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              DateFormat('EEE, d MMMM yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.w600,
                                fontSize: isTab ? 13 : 11.5,
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Slots Content / Shimmer / Empty State / Sessions View
                        if (_isLoadingSlots)
                          _buildSlotsShimmer(isDark)
                        else if (_errorMessage != null)
                          _buildErrorState(isDark)
                        else if (_availableSlots.isEmpty)
                          _buildNoSlotsState(isDark)
                        else
                          _buildGroupedSlotsView(isDark, isTab),

                        const SizedBox(height: 16),

                        // Summary Selection Indicator
                        if (_selectedSlot != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withValues(alpha: isDark ? 0.2 : 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF059669).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Selected: ${DateFormat('EEE, d MMM').format(_selectedDate)} at ${_selectedSlot!['label'] ?? _selectedSlot!['startTime']}",
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_isSubmitting || _selectedSlot == null)
                          ? null
                          : _handleConfirmReschedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.event_available_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Confirm Reschedule",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: isTab ? 15 : 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Grouped Slots by Session (Morning, Afternoon, Evening) ──
  Widget _buildGroupedSlotsView(bool isDark, bool isTab) {
    final morningSlots = _availableSlots.where((s) => (s['startHour'] as int) < 12).toList();
    final afternoonSlots = _availableSlots.where((s) => (s['startHour'] as int) >= 12 && (s['startHour'] as int) < 17).toList();
    final eveningSlots = _availableSlots.where((s) => (s['startHour'] as int) >= 17).toList();

    final showMorning = (_selectedSessionFilter == "All" || _selectedSessionFilter == "Morning") && morningSlots.isNotEmpty;
    final showAfternoon = (_selectedSessionFilter == "All" || _selectedSessionFilter == "Afternoon") && afternoonSlots.isNotEmpty;
    final showEvening = (_selectedSessionFilter == "All" || _selectedSessionFilter == "Evening") && eveningSlots.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Session Filter Segmented Tabs
        _buildSessionFilterTabs(morningSlots, afternoonSlots, eveningSlots, isDark),
        const SizedBox(height: 14),

        if (!showMorning && !showAfternoon && !showEvening)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Text(
                "No slots scheduled for $_selectedSessionFilter session on this date.",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ),
          ),

        // 1. Morning Session Section
        if (showMorning) ...[
          _buildSessionSection(
            title: "Morning Sessions",
            timeRange: "09:00 AM - 12:00 PM",
            icon: Icons.wb_sunny_outlined,
            iconColor: const Color(0xFFD97706),
            slots: morningSlots,
            isDark: isDark,
            isTab: isTab,
          ),
          if (showAfternoon || showEvening) const SizedBox(height: 14),
        ],

        // 2. Afternoon Session Section
        if (showAfternoon) ...[
          _buildSessionSection(
            title: "Afternoon Sessions",
            timeRange: "12:00 PM - 05:00 PM",
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFEA580C),
            slots: afternoonSlots,
            isDark: isDark,
            isTab: isTab,
          ),
          if (showEvening) const SizedBox(height: 14),
        ],

        // 3. Evening Session Section
        if (showEvening) ...[
          _buildSessionSection(
            title: "Evening Sessions",
            timeRange: "05:00 PM onwards",
            icon: Icons.nights_stay_outlined,
            iconColor: const Color(0xFF6366F1),
            slots: eveningSlots,
            isDark: isDark,
            isTab: isTab,
          ),
        ],
      ],
    );
  }

  Widget _buildSessionFilterTabs(
    List<Map<String, dynamic>> morningSlots,
    List<Map<String, dynamic>> afternoonSlots,
    List<Map<String, dynamic>> eveningSlots,
    bool isDark,
  ) {
    final int morningOpen = morningSlots.where((s) => s['isAvailable'] == true).length;
    final int afternoonOpen = afternoonSlots.where((s) => s['isAvailable'] == true).length;
    final int eveningOpen = eveningSlots.where((s) => s['isAvailable'] == true).length;
    final int totalOpen = _availableSlots.where((s) => s['isAvailable'] == true).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildSessionChip("All", totalOpen, isDark),
          const SizedBox(width: 6),
          _buildSessionChip("Morning", morningOpen, isDark, icon: Icons.wb_sunny_outlined),
          const SizedBox(width: 6),
          _buildSessionChip("Afternoon", afternoonOpen, isDark, icon: Icons.wb_sunny_rounded),
          const SizedBox(width: 6),
          _buildSessionChip("Evening", eveningOpen, isDark, icon: Icons.nights_stay_outlined),
        ],
      ),
    );
  }

  Widget _buildSessionChip(String label, int count, bool isDark, {IconData? icon}) {
    final bool isSelected = _selectedSessionFilter == label;
    return InkWell(
      onTap: () {
        setState(() => _selectedSessionFilter = label);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1D4ED8) : const Color(0xFF2563EB))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF334155)),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionSection({
    required String title,
    required String timeRange,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, dynamic>> slots,
    required bool isDark,
    required bool isTab,
  }) {
    final int openCount = slots.where((s) => s['isAvailable'] == true).length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(icon, size: 15, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w700,
                          fontSize: isTab ? 14 : 12.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        timeRange,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 10,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: openCount > 0
                      ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: openCount > 0
                        ? (isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0))
                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Text(
                  openCount > 0 ? "$openCount open" : "Full",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    color: openCount > 0
                        ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF16A34A))
                        : (isDark ? Colors.white38 : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Grid of Slots
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTab ? 4 : 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: isTab ? 2.6 : 2.15,
            ),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              return _buildSlotCard(slots[index], isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot, bool isDark) {
    final bool isAvail = slot['isAvailable'] == true;
    final bool isBooked = slot['isBooked'] == true;
    final bool isBlocked = slot['isBlocked'] == true;
    final bool isPast = slot['isPast'] == true;
    final bool isSelected = _selectedSlot != null && _selectedSlot!['id'] == slot['id'] && isAvail;
    final String label = slot['label']?.toString() ?? slot['startTime']?.toString() ?? '--:--';

    if (!isAvail) {
      final String statusLabel = isPast
          ? "Passed"
          : (isBooked
              ? "Booked"
              : (isBlocked ? "Blocked" : "Unavailable"));

      return InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isPast
                    ? "This slot has already passed."
                    : (isBooked
                        ? "This slot is already booked. Please select an available slot."
                        : "This slot is currently blocked by the doctor."),
                style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12),
              ),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2633) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isBooked
                  ? (isDark ? Colors.redAccent.withValues(alpha: 0.25) : Colors.red.withValues(alpha: 0.2))
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                    decoration: TextDecoration.lineThrough,
                    decorationColor: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isBooked) ...[
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 9.5,
                        color: isDark ? Colors.redAccent.withValues(alpha: 0.7) : Colors.red.shade400,
                      ),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: isBooked
                            ? (isDark ? Colors.redAccent.withValues(alpha: 0.8) : Colors.red.shade500)
                            : (isDark ? Colors.white30 : const Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedSlot = slot;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF0F172A) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  size: 11,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotsShimmer(bool isDark) {
    return Column(
      children: [
        for (int i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 120,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 14,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (int j = 0; j < 3; j++)
                        Expanded(
                          child: Container(
                            height: 36,
                            margin: EdgeInsets.only(right: j < 2 ? 8.0 : 0),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNoSlotsState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: Color(0xFFD97706),
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            "No Available Slots",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Doctor has no open schedule on this day. Please select another date.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
              });
              _loadDoctorSlots();
            },
            icon: const Icon(Icons.arrow_forward_rounded, size: 15),
            label: const Text("Next Day"),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              textStyle: const TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? "Error loading slots",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
              ),
            ),
          ),
          TextButton(
            onPressed: _loadDoctorSlots,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
