import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/presentation/appointments/appointment_bloc/appointment_bloc.dart';
import 'package:yiraclinics/features/presentation/appointments/widgets/tele_consult_widget.dart';
import '../../../core/colors/colors.dart';
import '../../../core/common_appbar/common_app_bar.dart';
import '../../../core/common_drop_down/common_drop_down.dart';
import '../../../core/common_input_fields/common_input_field_unlimited.dart';
import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_button.dart';
import '../../../core/constants/constants.dart';

class PatientOption {
  final String id;
  final String name;
  final String phone;
  final String gender;
  final String dob;

  const PatientOption({
    required this.id,
    required this.name,
    required this.phone,
    required this.gender,
    required this.dob,
  });
}

class AddNewAppointmentScreen extends StatefulWidget {
  final String? initialPatientName;
  final String? initialPatientPhone;

  const AddNewAppointmentScreen({
    super.key,
    this.initialPatientName,
    this.initialPatientPhone,
  });

  @override
  State<AddNewAppointmentScreen> createState() => _AddNewAppointmentScreenState();
}

class _AddNewAppointmentScreenState extends State<AddNewAppointmentScreen> {
  final TextEditingController _patientSearchController = TextEditingController();
  final FocusNode _patientFocusNode = FocusNode();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  Timer? _searchDebounce;
  bool _showPatientDropdown = false;
  List<PatientOption> _apiPatientsList = [];

  DateTime _selectedDate = DateTime.now();
  String _selectedSlot = "10:00 - 10:30";
  String _selectedDuration = "30 minutes";
  String _selectedVisitType = "Consultation";
  String _selectedDoctor = "Dr. Doctor";
  String _selectedGender = "Male";
  bool _isTeleConsultation = false;
  bool _isLoadingSlots = false;
  List<String> _dynamicSlots = const [
    "09:00 - 09:30",
    "09:30 - 10:00",
    "10:00 - 10:30",
    "10:30 - 11:00",
    "11:00 - 11:30",
    "11:30 - 12:00",
    "14:00 - 14:30",
    "14:30 - 15:00",
    "15:00 - 15:30",
    "15:30 - 16:00",
    "16:00 - 16:30",
    "16:30 - 17:00",
  ];

  Future<void> _fetchDoctorSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
    });
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
          ? currentUser.data!.id!.trim()
          : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
              ? currentUser.data!.navigationId!.trim()
              : '1';
      final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
      final String token = currentUser?.data?.accessToken ?? '';
      final String dateStr = DateFormat('yyyy-MM-dd').format(date);

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
          final List<dynamic> rawSlots = slotData['slots'] as List;
          final List<String> fetched = [];
          for (final item in rawSlots) {
            if (item is Map<String, dynamic>) {
              final bool isAvail = item['isAvailable'] == true;
              final String label = (item['label'] ?? '').toString();
              if (isAvail && label.isNotEmpty) {
                fetched.add(label);
              }
            }
          }
          if (fetched.isNotEmpty) {
            setState(() {
              _dynamicSlots = fetched;
              if (!_dynamicSlots.contains(_selectedSlot)) {
                _selectedSlot = _dynamicSlots.first;
              }
            });
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        });
      }
    }
  }

  Future<void> _fetchPatientsFromApi({String query = ''}) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String doctorId = (currentUser?.data?.id != null && currentUser!.data!.id!.trim().isNotEmpty)
          ? currentUser.data!.id!.trim()
          : (currentUser?.data?.navigationId != null && currentUser!.data!.navigationId!.trim().isNotEmpty)
              ? currentUser.data!.navigationId!.trim()
              : '1';
      final int orgId = currentUser?.data?.latestOrgId ?? 1;
      final int hospitalId = currentUser?.data?.latestHospitalId ?? 1;
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.patientsListUrl,
        data: {
          "doctorId": doctorId,
          "orgId": orgId,
          "hospitalId": hospitalId,
          if (query.trim().isNotEmpty) "searchTerm": query.trim(),
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final Map<String, dynamic> rawData = response.data as Map<String, dynamic>;
        final rawList = rawData['data'];
        List<dynamic> list = [];
        if (rawList is List) {
          list = rawList;
        } else if (rawList is Map<String, dynamic> && rawList['patients'] is List) {
          list = rawList['patients'] as List;
        }

        final fetched = list.map((item) {
          final map = item as Map<String, dynamic>;
          final name = (map['name'] ?? map['patientName'] ?? map['firstName'] ?? 'Patient').toString();
          final phone = (map['phoneNumber'] ?? map['phone'] ?? '').toString();
          final id = (map['id'] ?? map['patientId'] ?? 'PAT').toString();
          final gender = (map['gender'] ?? 'Male').toString();
          final dob = (map['dob'] ?? '').toString();
          return PatientOption(id: id, name: name, phone: phone, gender: gender, dob: dob);
        }).where((p) => p.name.trim().isNotEmpty && p.name != 'Patient').toList();

        if (mounted) {
          setState(() {
            _apiPatientsList = fetched;
          });
        }
      }
    } catch (_) {}
  }

  void _onPatientSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<AppointmentBloc>().add(LoadAppointmentsEvent(search: query.trim()));
        _fetchPatientsFromApi(query: query.trim());
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _patientFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _showPatientDropdown = _patientFocusNode.hasFocus;
        });
      }
    });
    final currentUser = GlobalSession.instance.userNotifier.value?.data;
    if (currentUser != null) {
      final name = currentUser.firstName ?? currentUser.email?.split('@').first ?? '';
      if (name.isNotEmpty) {
        _selectedDoctor = "Dr. $name";
      }
    }
    if (widget.initialPatientName != null && widget.initialPatientName!.isNotEmpty) {
      _patientSearchController.text = widget.initialPatientName!;
    }
    if (widget.initialPatientPhone != null && widget.initialPatientPhone!.isNotEmpty) {
      _phoneController.text = widget.initialPatientPhone!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppointmentBloc>().add(LoadAppointmentsEvent());
        _fetchPatientsFromApi();
        _fetchDoctorSlots(_selectedDate);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _patientSearchController.dispose();
    _patientFocusNode.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final bool isTab = isTablet(context);

    return BlocConsumer<AppointmentBloc, AppointmentState>(
      listener: (context, state) {
        if (state is OnAddAppointmentState) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Appointment booked successfully!")),
          );
          Navigator.pop(context);
        } else if (state is AppointmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final List<PatientOption> allAvailablePatients = List.from(_apiPatientsList);

        if (state is AppointmentLoaded || state.appointments.isNotEmpty) {
          final apiPatients = state.appointments
              .where((a) => a.patientName.trim().isNotEmpty && a.patientName != 'Patient')
              .map((a) => PatientOption(
                    id: a.id.isNotEmpty ? a.id : 'PAT-${a.phoneNumber.hashCode.abs().toString().padLeft(4, '0').substring(0, 4)}',
                    name: a.patientName,
                    phone: a.phoneNumber,
                    gender: "Male",
                    dob: "",
                  ))
              .toList();

          for (final p in apiPatients) {
            if (!allAvailablePatients.any((existing) =>
                (p.phone.isNotEmpty && existing.phone == p.phone) ||
                existing.name.toLowerCase() == p.name.toLowerCase())) {
              allAvailablePatients.insert(0, p);
            }
          }
        }

        if (widget.initialPatientName != null && widget.initialPatientName!.isNotEmpty) {
          if (!allAvailablePatients.any((p) => p.name.toLowerCase() == widget.initialPatientName!.toLowerCase())) {
            allAvailablePatients.insert(
              0,
              PatientOption(
                id: 'PT-SEL',
                name: widget.initialPatientName!,
                phone: widget.initialPatientPhone ?? '',
                gender: 'Male',
                dob: '',
              ),
            );
          }
        }

        final searchQuery = _patientSearchController.text.trim().toLowerCase();
        final List<PatientOption> filteredPatients = searchQuery.isEmpty
            ? allAvailablePatients
            : allAvailablePatients.where((p) {
                return p.name.toLowerCase().contains(searchQuery) ||
                    p.phone.contains(searchQuery) ||
                    p.id.toLowerCase().contains(searchQuery);
              }).toList();
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: const CommonAppBar(
            actions: [],
            titleText: "Book Appointment",
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: screenHorizontalSpacePadding,
                vertical: screenTopPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText(
                    'Patient Name *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: titleSpace),
                  TextField(
                    controller: _patientSearchController,
                    focusNode: _patientFocusNode,
                    onChanged: (val) {
                      setState(() {
                        _showPatientDropdown = true;
                      });
                      _onPatientSearchChanged(val);
                    },
                    style: TextStyle(
                      decorationThickness: 0,
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
                    ),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                      hintText: "Search Patient Name or Phone...",
                      prefixIcon: const Icon(
                        Icons.person_search_outlined,
                        color: Colors.blueGrey,
                        size: 18,
                      ),
                      suffixIcon: _patientSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  _patientSearchController.clear();
                                });
                                context.read<AppointmentBloc>().add(LoadAppointmentsEvent());
                              },
                            )
                          : const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.blueGrey,
                            ),
                      filled: true,
                      fillColor: isDark ? darkModeCardColor.withOpacity(0.8) : lightModeTextFieldBgColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: isDark ? darkModeBorderColor : lightModeBorderColor,
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: isDark ? darkModeBorderColor : lightModeBorderColor,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: isDark ? darkModeBorderColor : lightModeBorderColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if ((_patientFocusNode.hasFocus || _showPatientDropdown) && filteredPatients.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(fieldBorderRadius),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(fieldBorderRadius),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.grey.shade300,
                          ),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: filteredPatients.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final patient = filteredPatients[index];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor: primaryColor.withOpacity(0.12),
                                child: Text(
                                  patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              title: Text(
                                patient.name,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                '${patient.id} ${patient.phone.isNotEmpty ? "| Phone: ${patient.phone}" : ""}',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : Colors.grey[600],
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _patientSearchController.text = patient.name;
                                  if (patient.phone.isNotEmpty) {
                                    _phoneController.text = patient.phone;
                                  }
                                  _selectedGender = patient.gender;
                                  _showPatientDropdown = false;
                                });
                                _patientFocusNode.unfocus();
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: fieldSpace),
                  CommonText(
                    'Patient Phone Number *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: titleSpace),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      decorationThickness: 0,
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
                    ),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                      ),
                      hintText: "Enter 10-digit Phone Number...",
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: Colors.blueGrey,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: isDark ? darkModeCardColor.withOpacity(0.8) : lightModeTextFieldBgColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: isDark ? darkModeBorderColor : lightModeBorderColor,
                          width: 1.0,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: isDark ? darkModeBorderColor : lightModeBorderColor,
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(fieldBorderRadius),
                        borderSide: BorderSide(
                          color: isDark ? darkModeBorderColor : lightModeBorderColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: fieldSpace),
                  CommonText(
                    'Date *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: titleSpace),
                  _buildDOBPicker(
                    context,
                    _selectedDate,
                    isDark,
                    isTab,
                  ),
                  const SizedBox(height: fieldSpace),
                  CommonText(
                    'Available slot *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: titleSpace),
                  CommonDropdown(
                    title: _isLoadingSlots ? "Loading slots..." : "Select Slot",
                    selectedValue: _selectedSlot,
                    options: _dynamicSlots,
                    onSelected: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSlot = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: fieldSpace),
                  CommonText(
                    'Duration',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: titleSpace),
                  CommonDropdown(
                    title: "Select Duration",
                    selectedValue: _selectedDuration,
                    options: const ["30 minutes", "45 minutes", "1 hour"],
                    onSelected: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDuration = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: fieldSpace),
                  CommonText(
                    'Visit Type *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: titleSpace),
                  CommonDropdown(
                    title: "Select type",
                    selectedValue: _selectedVisitType,
                    options: const [
                      "Consultation",
                      "Follow-up",
                      "Check-up",
                      "Tele-Consult",
                    ],
                    onSelected: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedVisitType = value;
                          if (value == "Tele-Consult") {
                            _isTeleConsultation = true;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: fieldSpace),
                  CommonText(
                    'Reason / Chief Complaint *',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: titleSpace),
                  SizedBox(
                    height: 120,
                    child: CommonInputFieldUnlimited(
                      controller: _reasonController,
                      hintText: "Enter the primary reason for this visit...",
                      borderRadius: 8.0,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a reason';
                        }
                        return null;
                      },
                      onChanged: (text) {},
                    ),
                  ),
                  const SizedBox(height: fieldSpace),
                  TeleconsultationCard(
                    isTab: isTab,
                    isDark: isDark,
                    isSelected: _isTeleConsultation,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _isTeleConsultation = newValue ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: fieldSpace * 3),
                  CustomElevatedButton(
                    text: "Book Appointment",
                    onPressed: () {
                      final name = _patientSearchController.text.trim();
                      final phone = _phoneController.text.trim();

                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter patient name")),
                        );
                        return;
                      }

                      if (phone.isEmpty || phone.length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a valid 10-digit phone number")),
                        );
                        return;
                      }

                      final startTimeStr = _selectedSlot.split(" - ").first.trim();
                      final formattedTime = startTimeStr.contains(":") ? "$startTimeStr:00" : "10:00:00";

                      context.read<AppointmentBloc>().add(
                        SubmitBookAppointmentEvent(
                          patientName: name,
                          phoneNumber: phone,
                          gender: _selectedGender,
                          dob: DateFormat('yyyy-MM-dd').format(_selectedDate),
                          appointmentDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
                          startTime: formattedTime,
                          reason: _reasonController.text.trim(),
                          appointmentType: _selectedVisitType,
                          isTeleConsultation: _isTeleConsultation,
                        ),
                      );
                    },
                    width: double.infinity,
                    height: 50,
                    borderRadius: 8,
                  ),
                  const SizedBox(height: fieldSpace * 1.5),
                  SizedBox(
                    height: 50,
                    width: displayWidth(context),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? darkModeBorderColor : lightModeBorderColor),
                        foregroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(fieldBorderRadius),
                        ),
                      ),
                      child: CommonText(
                        "Discard",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w500,
                          fontSize: isTab ? displayWidth(context) * 0.02 : displayWidth(context) * 0.032,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDOBPicker(
    BuildContext context,
    DateTime currentDob,
    bool isDark,
    bool isTab,
  ) {
    final TextEditingController dobController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(currentDob),
    );

    return TextField(
      controller: dobController,
      readOnly: true,
      onTap: () => _showDatePicker(context, currentDob, isDark),
      style: TextStyle(
        decorationThickness: 0,
        fontFamily: appPoppinFont,
        fontSize: isTab ? displayWidth(context) * 0.018 : displayWidth(context) * 0.03,
      ),
      decoration: InputDecoration(
        hintStyle: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: displayWidth(context) * 0.03,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
        suffixIcon: const Icon(
          Icons.calendar_today,
          color: Colors.blueGrey,
          size: 18,
        ),
        filled: true,
        fillColor: isDark ? darkModeCardColor.withOpacity(0.8) : lightModeTextFieldBgColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          borderSide: BorderSide(
            color: isDark ? darkModeBorderColor : lightModeBorderColor,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          borderSide: BorderSide(
            color: isDark ? darkModeBorderColor : lightModeBorderColor,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          borderSide: BorderSide(
            color: isDark ? darkModeBorderColor : lightModeBorderColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  void _showDatePicker(
    BuildContext context,
    DateTime initialDate,
    bool isDark,
  ) {
    DateTime tempSelectedDate = initialDate;

    showModalBottomSheet(
      isDismissible: false,
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5,
                    width: 45,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(fieldBorderRadius),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "Select Date",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: displayWidth(context) * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: displayHeight(context) / 3.5,
                    child: CupertinoTheme(
                      data: CupertinoThemeData(
                        brightness: isDark ? Brightness.dark : Brightness.light,
                        textTheme: CupertinoTextThemeData(
                          dateTimePickerTextStyle: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: displayWidth(context) * 0.038,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.date,
                        initialDateTime: initialDate,
                        minimumYear: 2024,
                        maximumYear: 2030,
                        itemExtent: 50,
                        onDateTimeChanged: (DateTime newDate) {
                          tempSelectedDate = newDate;
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 10,
                    ),
                    child: CustomElevatedButton(
                      text: "Confirm",
                      onPressed: () {
                        setState(() {
                          _selectedDate = tempSelectedDate;
                        });
                        _fetchDoctorSlots(_selectedDate);
                        Navigator.pop(context);
                      },
                      width: double.infinity,
                      height: 50,
                      borderRadius: 8,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
