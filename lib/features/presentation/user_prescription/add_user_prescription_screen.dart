import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/services/permission_helper.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/repositories/uploaded_record/uploaded_record_repo.dart';
import 'package:yiraclinics/features/presentation/user_prescription/prescription_bloc/prescription_bloc.dart';

class _MedicationFormItem {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String frequency = 'Twice a day (1-0-1)';
  String mealTiming = 'After Food';
  int durationDays = 5;
  bool isContinuous = false;

  void dispose() {
    nameController.dispose();
    notesController.dispose();
  }
}

class AddUserPrescriptionScreen extends StatefulWidget {
  final MedicationBloc? bloc;

  const AddUserPrescriptionScreen({super.key, this.bloc});

  @override
  State<AddUserPrescriptionScreen> createState() => _AddUserPrescriptionScreenState();
}

class _AddUserPrescriptionScreenState extends State<AddUserPrescriptionScreen> {
  // Doctor & Clinic details
  final TextEditingController _doctorNameController = TextEditingController();
  final TextEditingController _hospitalNameController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _doctorNotesController = TextEditingController();

  DateTime _consultationDate = DateTime.now();
  String _selectedSpecialty = 'General Medicine';

  // Physical prescription attachment
  File? _attachedFile;
  String? _attachedFileName;
  int? _attachedFileSize;

  // Medications list
  final List<_MedicationFormItem> _medications = [];

  bool _isSaving = false;

  // Options
  static const List<String> _specialties = [
    'General Medicine',
    'Cardiology',
    'Dermatology',
    'Pediatrics',
    'Orthopedics',
    'ENT',
    'Gynecology',
    'Dental',
    'Other',
  ];

  static const List<String> _frequencyOptions = [
    'Twice a day (1-0-1)',
    'Once a day (1-0-0)',
    'Three times (1-1-1)',
    'At Night (0-0-1)',
    'As Needed (SOS)',
  ];

  static const List<String> _mealOptions = [
    'After Food',
    'Before Food',
  ];

  static const List<int> _durationOptions = [3, 5, 7, 14, 30];

  static const List<String> _quickConditions = [
    'Fever',
    'Cold & Cough',
    'Headache',
    'Body Pain',
    'Infection',
    'Hypertension',
  ];

  @override
  void initState() {
    super.initState();
    _medications.add(_MedicationFormItem());
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _hospitalNameController.dispose();
    _conditionController.dispose();
    _doctorNotesController.dispose();
    for (final m in _medications) {
      m.dispose();
    }
    super.dispose();
  }

  void _addMedication() {
    setState(() {
      _medications.add(_MedicationFormItem());
    });
  }

  void _removeMedication(int index) {
    if (_medications.length <= 1) return;
    setState(() {
      final removed = _medications.removeAt(index);
      removed.dispose();
    });
  }

  // --- Attachment Options Bottom Sheet ---
  void _showAttachmentSourceSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E2430) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Attach Prescription",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: primaryColor),
                  title: const Text("Take Photo with Camera"),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: primaryColor),
                  title: const Text("Choose from Gallery"),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined, color: primaryColor),
                  title: const Text("Upload PDF Document"),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickFromFiles();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFromCamera() async {
    final bool hasPermission = await PermissionHelper.ensureCameraPermission(context);
    if (!hasPermission) return;

    try {
      final photo = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo != null) {
        final file = File(photo.path);
        final size = await file.length();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        setState(() {
          _attachedFile = file;
          _attachedFileName = 'Prescription_$timestamp.jpg';
          _attachedFileSize = size;
        });
      }
    } catch (e) {
      debugPrint("Camera picker error: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    final bool hasPermission = await PermissionHelper.ensurePhotosPermission(context);
    if (!hasPermission) return;

    try {
      final photo = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (photo != null) {
        final file = File(photo.path);
        final size = await file.length();
        setState(() {
          _attachedFile = file;
          _attachedFileName = photo.name.isNotEmpty ? photo.name : 'Prescription_Image.jpg';
          _attachedFileSize = size;
        });
      }
    } catch (e) {
      debugPrint("Gallery picker error: $e");
    }
  }

  Future<void> _pickFromFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        final picked = result.files.first;
        final file = File(picked.path!);
        setState(() {
          _attachedFile = file;
          _attachedFileName = picked.name;
          _attachedFileSize = picked.size;
        });
      }
    } catch (e) {
      debugPrint("File picker error: $e");
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // --- Save / Submit ---
  Future<void> _savePrescription() async {
    FocusScope.of(context).unfocus();

    final docName = _doctorNameController.text.trim();
    final hospName = _hospitalNameController.text.trim();

    if (docName.isEmpty && hospName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter Doctor Name or Hospital Name."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final validMeds = _medications.where((m) => m.nameController.text.trim().isNotEmpty).toList();
    if (validMeds.isEmpty && _attachedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter at least one medicine or attach the prescription document."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      String? uploadedPdfUrl;

      // Upload physical paper prescription if attached
      if (_attachedFile != null && _attachedFile!.existsSync()) {
        try {
          final repo = sl<RecordsRepository>();
          final uploaded = await repo.uploadDocument(
            filePath: _attachedFile!.path,
            fileName: _attachedFileName ?? 'Prescription.jpg',
            category: 'Prescription',
            description: 'Prescription from $hospName ($docName)',
          );
          if (uploaded != null && uploaded.fileUrl != null && uploaded.fileUrl!.isNotEmpty) {
            uploadedPdfUrl = uploaded.fileUrl;
          }
        } catch (e) {
          debugPrint("Prescription upload error: $e");
        }
      }

      String formattedDoctor = docName;
      if (formattedDoctor.isNotEmpty &&
          !formattedDoctor.toLowerCase().startsWith('dr.') &&
          !formattedDoctor.toLowerCase().startsWith('dr ')) {
        formattedDoctor = 'Dr. $formattedDoctor';
      }
      if (formattedDoctor.isEmpty) {
        formattedDoctor = 'Consulting Physician';
      }

      final condition = _conditionController.text.trim().isNotEmpty
          ? _conditionController.text.trim()
          : 'General Consultation';

      final List<Map<String, dynamic>> medsPayload = validMeds.map((m) {
        String freqCode = '1-0-1';
        if (m.frequency.contains('1-0-0')) freqCode = '1-0-0';
        if (m.frequency.contains('0-0-1')) freqCode = '0-0-1';
        if (m.frequency.contains('1-1-1')) freqCode = '1-1-1';
        if (m.frequency.contains('SOS')) freqCode = 'SOS';

        final int dur = m.isContinuous ? 365 : m.durationDays;
        final String durUnit = m.isContinuous ? 'Continuous' : 'Days';
        final String notes = m.notesController.text.trim();
        final String instructions = notes.isNotEmpty ? '$notes (${m.mealTiming})' : m.mealTiming;

        return {
          'medication': m.nameController.text.trim(),
          'dosage': '1 Dose',
          'frequencyType': freqCode,
          'durationValue': dur,
          'durationUnit': durUnit,
          'instructions': instructions,
          'route': 'Oral',
          'isActive': true,
        };
      }).toList();

      final Map<String, dynamic> payload = {
        'doctorName': formattedDoctor,
        'hospitalName': hospName.isNotEmpty ? hospName : 'External Clinic',
        'specialty': _selectedSpecialty,
        'notes': _doctorNotesController.text.trim(),
        'createdAt': _consultationDate.toIso8601String(),
        'diagnoses': [
          {'diagnosis': condition}
        ],
        'medications': medsPayload,
      };
      if (uploadedPdfUrl != null) {
        payload['pdfUrl'] = uploadedPdfUrl;
      }

      final MedicationBloc activeBloc = widget.bloc ?? sl<MedicationBloc>();
      final bool success = await activeBloc.addManualPrescription(payload);

      if (!success) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to save. Please check your connection and try again."),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Prescription added successfully.",
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Save error: $e");
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2430) : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E2430) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add Prescription",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2430) : Colors.white,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _savePrescription,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    "Save Prescription",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // ── Subtitle ──
          Text(
            "Record prescriptions from hospitals or clinics not on Yira Clinx.",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // ── SECTION 1: VISIT DETAILS ──
          _buildCard(
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            title: "Visit Details",
            children: [
              _buildInputLabel("Doctor Name", isDark),
              _buildCleanTextField(
                controller: _doctorNameController,
                hintText: "e.g. Dr. Ramesh Sharma",
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              _buildInputLabel("Hospital / Clinic Name", isDark),
              _buildCleanTextField(
                controller: _hospitalNameController,
                hintText: "e.g. Apollo Clinic, City Hospital",
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              _buildInputLabel("Specialty", isDark),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF273142) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSpecialty,
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF1E2430) : Colors.white,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    items: _specialties.map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSpecialty = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildInputLabel("Date of Consultation", isDark),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _consultationDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
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
                  if (picked != null) setState(() => _consultationDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF273142) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: primaryColor),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('dd MMM yyyy').format(_consultationDate),
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "Change",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildInputLabel("Reason / Diagnosis", isDark),
              _buildCleanTextField(
                controller: _conditionController,
                hintText: "e.g. Viral Fever, Cold, Routine Checkup",
                isDark: isDark,
              ),
              const SizedBox(height: 8),

              // Quick symptom tags (unified, simple)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickConditions.map((cond) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      final curr = _conditionController.text.trim();
                      if (curr.isEmpty) {
                        _conditionController.text = cond;
                      } else if (!curr.toLowerCase().contains(cond.toLowerCase())) {
                        _conditionController.text = '$curr, $cond';
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF273142) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        "+ $cond",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              _buildInputLabel("Doctor's Advice / Notes (Optional)", isDark),
              _buildCleanTextField(
                controller: _doctorNotesController,
                hintText: "e.g. Drink warm water, rest for 3 days",
                maxLines: 2,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── SECTION 2: PRESCRIBED MEDICATIONS ──
          Row(
            children: [
              Text(
                "Prescribed Medicines",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addMedication,
                icon: const Icon(Icons.add_rounded, size: 16, color: primaryColor),
                label: const Text(
                  "Add Medicine",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ..._medications.asMap().entries.map((entry) {
            return _buildMedicationItemCard(
              index: entry.key,
              item: entry.value,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
            );
          }),
          const SizedBox(height: 16),

          // ── SECTION 3: ATTACH DOCUMENT / PHOTO (OPTIONAL) ──
          _buildCard(
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            title: "Prescription Photo or PDF (Optional)",
            children: [
              if (_attachedFile != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF273142) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _attachedFileName?.endsWith('.pdf') == true
                            ? Icons.picture_as_pdf_outlined
                            : Icons.image_outlined,
                        size: 20,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "${_attachedFileName ?? 'Prescription'} (${_formatSize(_attachedFileSize)})",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          setState(() {
                            _attachedFile = null;
                            _attachedFileName = null;
                            _attachedFileSize = null;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _showAttachmentSourceSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF273142) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: borderColor,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined, size: 20, color: primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            "Attach prescription photo or PDF",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Unified Card Container ──
  Widget _buildCard({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ── Individual Medication Item Card ──
  Widget _buildMedicationItemCard({
    required int index,
    required _MedicationFormItem item,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medicine Header
          Row(
            children: [
              Text(
                "Medicine #${index + 1}",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              const Spacer(),
              if (_medications.length > 1)
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: isDark ? Colors.white38 : Colors.grey.shade500),
                  onPressed: () => _removeMedication(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "Remove Medicine",
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Medicine Name
          _buildInputLabel("Medicine Name", isDark),
          _buildCleanTextField(
            controller: item.nameController,
            hintText: "e.g. Paracetamol 650mg, Amoxicillin 500mg",
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // Frequency
          _buildInputLabel("Dosage Frequency", isDark),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _frequencyOptions.map((opt) {
              final isSelected = item.frequency == opt;
              return _buildSimpleChip(
                label: opt,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () {
                  setState(() => item.frequency = opt);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Meal Timing
          _buildInputLabel("Meal Relation", isDark),
          Row(
            children: _mealOptions.map((opt) {
              final isSelected = item.mealTiming == opt;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildSimpleChip(
                  label: opt,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () {
                    setState(() => item.mealTiming = opt);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Duration
          _buildInputLabel("Duration", isDark),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._durationOptions.map((d) {
                final isSelected = !item.isContinuous && item.durationDays == d;
                return _buildSimpleChip(
                  label: "$d Days",
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () {
                    setState(() {
                      item.isContinuous = false;
                      item.durationDays = d;
                    });
                  },
                );
              }),
              _buildSimpleChip(
                label: "Continuous",
                isSelected: item.isContinuous,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    item.isContinuous = true;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Specific notes
          _buildInputLabel("Notes (Optional)", isDark),
          _buildCleanTextField(
            controller: item.notesController,
            hintText: "e.g. Take with warm water",
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // ── Unified Simple Chip (Consistent Single Accent Theme) ──
  Widget _buildSimpleChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF273142) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  // ── Input Label ──
  Widget _buildInputLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF475569),
        ),
      ),
    );
  }

  // ── Clean Text Field ──
  Widget _buildCleanTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    required bool isDark,
  }) {
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF273142) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 13,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 12.5,
            color: isDark ? Colors.white30 : Colors.grey.shade400,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
