import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/common_widgets/in_app_document_viewer.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/services/patient_insurance_service.dart';
import 'package:yiraclinics/features/data/models/insurance/patient_insurance_policy_model.dart';

class PatientAddEditPolicyScreen extends StatefulWidget {
  final PatientInsurancePolicyModel? policy;

  const PatientAddEditPolicyScreen({
    super.key,
    this.policy,
  });

  @override
  State<PatientAddEditPolicyScreen> createState() => _PatientAddEditPolicyScreenState();
}

class _PatientAddEditPolicyScreenState extends State<PatientAddEditPolicyScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _holderController;
  late TextEditingController _nameController;
  late TextEditingController _issuedByController;
  late TextEditingController _numberController;

  DateTime? _startDate;
  DateTime? _endDate;
  File? _selectedFile;
  String? _existingDocumentUrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.policy;

    final sessionUser = GlobalSession.instance.userNotifier.value;
    final defaultHolder = '${sessionUser?.data?.firstName ?? ''} ${sessionUser?.data?.lastName ?? ''}'.trim();

    _holderController = TextEditingController(text: p?.policyHolder ?? (defaultHolder.isNotEmpty ? defaultHolder : ''));
    _nameController = TextEditingController(text: p?.policyName ?? '');
    _issuedByController = TextEditingController(text: p?.insuranceProvider ?? '');
    _numberController = TextEditingController(text: p?.policyNumber ?? '');

    _existingDocumentUrl = p?.documentUrl;
    if (p?.localFilePath != null && p!.localFilePath!.isNotEmpty) {
      final f = File(p.localFilePath!);
      if (f.existsSync()) _selectedFile = f;
    }

    if (p?.startDate != null && p!.startDate!.isNotEmpty) {
      _startDate = _tryParseDate(p.startDate!);
    }
    if (p?.endDate != null && p!.endDate!.isNotEmpty) {
      _endDate = _tryParseDate(p.endDate!);
    }
  }

  DateTime? _tryParseDate(String dateStr) {
    try {
      final clean = dateStr.trim();
      if (clean.contains('-')) {
        final parts = clean.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            return DateTime.parse(clean);
          } else {
            return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        }
      }
      if (clean.contains('/')) {
        final parts = clean.split('/');
        if (parts.length == 3) {
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    _holderController.dispose();
    _nameController.dispose();
    _issuedByController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDate ?? now) : (_endDate ?? now.add(const Duration(days: 365)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1990),
      lastDate: DateTime(2050),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF2563EB),
                    surface: Color(0xFF1E293B),
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF2563EB),
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 365));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  void _viewSelectedDocument() {
    final path = _selectedFile?.path;
    final url = _existingDocumentUrl;
    if (path == null && url == null) return;

    final fileName = path != null
        ? path.split(RegExp(r'[/\\]')).last
        : (url != null ? url.split('/').last : 'Policy Document');
    final isPdf = fileName.toLowerCase().endsWith('.pdf');

    final hasValidLocalFile = path != null && path.isNotEmpty && File(path).existsSync();

    InAppDocumentViewer.show(
      context,
      title: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : 'Policy Document',
      category: 'Insurance Policy',
      filePath: hasValidLocalFile ? path : null,
      fileUrl: hasValidLocalFile ? null : url,
      fileType: isPdf ? 'PDF' : 'IMAGE',
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a policy name')),
      );
      return;
    }

    if (_issuedByController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please specify the policy provider (issued by)')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final sessionUser = GlobalSession.instance.userNotifier.value;
      final userId = (sessionUser?.data?.id ?? '').toString().trim();

      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final startStr = _startDate != null ? formatter.format(_startDate!) : null;
      final endStr = _endDate != null ? formatter.format(_endDate!) : null;

      final updatedModel = PatientInsurancePolicyModel(
        id: widget.policy?.id,
        userId: userId,
        policyHolder: _holderController.text.trim().isNotEmpty ? _holderController.text.trim() : 'Patient',
        policyName: _nameController.text.trim(),
        insuranceProvider: _issuedByController.text.trim(),
        policyNumber: _numberController.text.trim().isNotEmpty ? _numberController.text.trim() : 'N/A',
        startDate: startStr,
        endDate: endStr,
        documentUrl: _existingDocumentUrl,
        localFilePath: _selectedFile?.path,
        status: true,
        isDeleted: false,
      );

      await PatientInsuranceService.instance.savePolicy(updatedModel, userId: userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text(
              widget.policy == null ? 'Policy added successfully!' : 'Policy updated successfully!',
              style: const TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save policy: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = const Color(0xFF2563EB);

    final inputFill = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputBorder = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF475569);

    final DateFormat formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.policy == null ? 'Add Policy' : 'Edit Policy',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontWeight: FontWeight.w700,
            fontSize: 16.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Policy Holder
              _buildFieldLabel('Policy Holder', labelColor),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _holderController,
                hintText: 'Enter Name Of The Policy Holder',
                isDark: isDark,
                fillColor: inputFill,
                borderColor: inputBorder,
              ),
              const SizedBox(height: 16),

              // 2. Policy Name *
              _buildFieldLabel('Policy Name *', labelColor, isRequired: true),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _nameController,
                hintText: 'Enter Policy Name',
                isDark: isDark,
                fillColor: inputFill,
                borderColor: inputBorder,
                validator: (val) => val == null || val.trim().isEmpty ? 'Policy name is required' : null,
              ),
              const SizedBox(height: 16),

              // 3. Policy Issued By *
              _buildFieldLabel('Policy Issued By *', labelColor, isRequired: true),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _issuedByController,
                hintText: 'Enter Policy Issued By',
                isDark: isDark,
                fillColor: inputFill,
                borderColor: inputBorder,
                validator: (val) => val == null || val.trim().isEmpty ? 'Insurer name is required' : null,
              ),
              const SizedBox(height: 16),

              // 4. Policy Number
              _buildFieldLabel('Policy Number', labelColor),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _numberController,
                hintText: 'Enter Policy Number',
                isDark: isDark,
                fillColor: inputFill,
                borderColor: inputBorder,
              ),
              const SizedBox(height: 18),

              // 5. Validity Dates (Side-by-Side: Start Date & End Date)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Start Date', labelColor),
                        const SizedBox(height: 6),
                        _buildDatePickerBox(
                          text: _startDate != null ? formatter.format(_startDate!) : 'DD/MM/YYYY',
                          isSelected: _startDate != null,
                          onTap: () => _pickDate(isStart: true),
                          isDark: isDark,
                          fillColor: inputFill,
                          borderColor: inputBorder,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('End Date', labelColor),
                        const SizedBox(height: 6),
                        _buildDatePickerBox(
                          text: _endDate != null ? formatter.format(_endDate!) : 'DD/MM/YYYY',
                          isSelected: _endDate != null,
                          onTap: () => _pickDate(isStart: false),
                          isDark: isDark,
                          fillColor: inputFill,
                          borderColor: inputBorder,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // 6. Choose File (Dashed Box Attachment)
              _buildFieldLabel('Policy Document', labelColor),
              const SizedBox(height: 8),
              _buildFileAttachmentBox(isDark),
              const SizedBox(height: 32),

              // 7. Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color color, {bool isRequired = false}) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
    required Color fillColor,
    required Color borderColor,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(
        fontFamily: appPoppinFont,
        fontSize: 13.5,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 13,
          color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor, width: 1.1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor, width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDatePickerBox({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    required Color fillColor,
    required Color borderColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? Colors.white30 : const Color(0xFF94A3B8)),
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: isSelected ? const Color(0xFF2563EB) : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileAttachmentBox(bool isDark) {
    final fileName = _selectedFile?.path.split(RegExp(r'[/\\]')).last ??
        (_existingDocumentUrl != null && _existingDocumentUrl!.isNotEmpty
            ? _existingDocumentUrl!.split('/').last
            : null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          width: 1.1,
        ),
      ),
      child: fileName != null
          ? Row(
              children: [
                // Small Image Thumbnail shown directly by default
                InkWell(
                  onTap: _viewSelectedDocument,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                        width: 1.1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (fileName.toLowerCase().endsWith('.pdf'))
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 22),
                              Text(
                                'PDF',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          )
                        else if (_selectedFile != null && _selectedFile!.existsSync())
                          Image.file(
                            _selectedFile!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.image_outlined, size: 22, color: Color(0xFF2563EB)),
                          )
                        else if (_existingDocumentUrl != null && _existingDocumentUrl!.isNotEmpty)
                          CachedNetworkImage(
                            imageUrl: _existingDocumentUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorWidget: (ctx, url, err) => const Icon(Icons.image_outlined, size: 22, color: Color(0xFF2563EB)),
                          )
                        else
                          const Icon(Icons.description_rounded, color: Color(0xFF2563EB), size: 22),

                        // Subtle zoom badge
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.zoom_in_rounded, size: 8, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fileName,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: _pickFile,
                        child: const Text(
                          'Change file',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                // Remove / Clear File Button
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedFile = null;
                      _existingDocumentUrl = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        size: 20,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Choose File',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'PDF, JPG, PNG up to 10MB',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10.5,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Browse',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
