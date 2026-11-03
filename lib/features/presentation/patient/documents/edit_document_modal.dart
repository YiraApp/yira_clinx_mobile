import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/common_widgets/in_app_document_viewer.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/services/permission_helper.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/features/domain/entities/uploaded_record/uploaded_record_entity.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_bloc/uploaded_bloc.dart';

class EditDocumentModal {
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _emerald = Color(0xFF10B981);

  static const List<String> defaultCategories = [
    'Lab Report',
    'Prescription',
    'Scan / Imaging',
    'Discharge Summary',
    'Insurance Card',
    'General',
    'Other',
  ];

  static Future<void> show(
    BuildContext context, {
    required BuildContext blocContext,
    required UploadedRecord doc,
    List<String>? availableCategories,
  }) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleController = TextEditingController(text: doc.fileName);
    final notesController = TextEditingController(text: doc.description ?? '');

    final categories = availableCategories?.where((c) => c != 'All').toList() ?? defaultCategories;
    String selectedCategory = doc.category.isNotEmpty ? doc.category : categories.first;
    if (!categories.map((c) => c.toLowerCase()).contains(selectedCategory.toLowerCase())) {
      selectedCategory = categories.first;
    }

    File? replacementFile;
    String? replacementFileName;
    int? replacementFileSizeKB;
    bool isSaving = false;

    // Determine current doc file type
    final currentDocUrl = (doc.fileUrl ?? '').trim();
    final currentDocPath = (doc.filePath ?? '').trim();
    final currentDocLower = '${doc.fileName} $currentDocUrl $currentDocPath'.toLowerCase();
    final bool isCurrentImage = currentDocLower.contains('.jpg') ||
        currentDocLower.contains('.jpeg') ||
        currentDocLower.contains('.png') ||
        currentDocLower.contains('.webp');

    void openCurrentPreview() {
      final ext = (doc.fileType ?? (doc.fileName.contains('.') ? doc.fileName.split('.').last : 'PDF')).toUpperCase();
      final dateStr = DateFormat('dd MMM yyyy').format(doc.uploadDate);
      final fileSizeStr = doc.fileSizeKB > 0
          ? (doc.fileSizeKB >= 1024
              ? '${(doc.fileSizeKB / 1024).toStringAsFixed(1)} MB'
              : '${doc.fileSizeKB} KB')
          : null;

      InAppDocumentViewer.show(
        context,
        title: doc.fileName,
        category: doc.category,
        fileUrl: currentDocUrl.isNotEmpty ? currentDocUrl : null,
        filePath: currentDocPath.isNotEmpty ? currentDocPath : null,
        fileType: ext,
        fileSize: fileSizeStr,
        hospitalName: doc.hospitalName,
        doctorName: doc.doctorName,
        date: dateStr,
        isAppointmentDoc: doc.isAppointmentDoc,
      );
    }

    void openReplacementPreview() {
      if (replacementFile == null) return;
      final name = replacementFileName ?? 'Replacement Document';
      final ext = (name.contains('.') ? name.split('.').last : 'PDF').toUpperCase();
      final sizeStr = replacementFileSizeKB != null
          ? (replacementFileSizeKB! >= 1024
              ? '${(replacementFileSizeKB! / 1024).toStringAsFixed(1)} MB'
              : '$replacementFileSizeKB KB')
          : null;

      InAppDocumentViewer.show(
        context,
        title: name,
        category: selectedCategory,
        filePath: replacementFile!.path,
        fileType: ext,
        fileSize: sizeStr,
        date: DateFormat('dd MMM yyyy').format(DateTime.now()),
      );
    }

    Future<void> pickFromCamera(StateSetter setModalState) async {
      final hasPermission = await PermissionHelper.ensureCameraPermission(context);
      if (!hasPermission) return;
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (image != null) {
        final file = File(image.path);
        final sizeKb = (file.lengthSync() / 1024).round();
        setModalState(() {
          replacementFile = file;
          replacementFileName = image.name.isNotEmpty
              ? image.name
              : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';
          replacementFileSizeKB = sizeKb;
        });
      }
    }

    Future<void> pickFromGallery(StateSetter setModalState) async {
      final hasPermission = await PermissionHelper.ensurePhotosPermission(context);
      if (!hasPermission) return;
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        final file = File(image.path);
        final sizeKb = (file.lengthSync() / 1024).round();
        setModalState(() {
          replacementFile = file;
          replacementFileName = image.name.isNotEmpty
              ? image.name
              : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
          replacementFileSizeKB = sizeKb;
        });
      }
    }

    Future<void> pickDocumentFile(StateSetter setModalState) async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        final file = File(result.files.first.path!);
        final sizeKb = (file.lengthSync() / 1024).round();
        setModalState(() {
          replacementFile = file;
          replacementFileName = result.files.first.name;
          replacementFileSizeKB = sizeKb;
        });
      }
    }

    void showSourceActionSheet(StateSetter setModalState) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (sheetCtx) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload / Replace Document',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select file source for replacing this document:',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF3B82F6), size: 22),
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  'Use camera to take a clear photo of report',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11.5,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  pickFromCamera(setModalState);
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _emerald.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: _emerald, size: 22),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  'Select existing photo from device album',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11.5,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  pickFromGallery(setModalState);
                },
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF8B5CF6), size: 22),
                ),
                title: Text(
                  'Select PDF / Document',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  'Browse PDF, DOC, or scan files',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11.5,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  pickDocumentFile(setModalState);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.9,
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _emerald.withValues(alpha: isDark ? 0.2 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: _emerald, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Document Details',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Preview file, replace upload or edit metadata',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, size: 20, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ─── 1. CURRENT DOCUMENT PREVIEW CARD ──────────────────────
                  Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 16, color: _primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        'Current Document',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 48,
                            height: 48,
                            color: isCurrentImage
                                ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
                                : const Color(0xFFEF4444).withValues(alpha: 0.1),
                                child: isCurrentImage
                                    ? (currentDocUrl.isNotEmpty
                                        ? Image.network(
                                            currentDocUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_outlined, color: _primaryBlue),
                                          )
                                        : (currentDocPath.isNotEmpty && File(currentDocPath).existsSync()
                                            ? Image.file(
                                                File(currentDocPath),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_outlined, color: _primaryBlue),
                                              )
                                            : const Icon(Icons.image_outlined, color: _primaryBlue)))
                                    : const Center(
                                        child: Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 24),
                                      ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Metadata
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _primaryBlue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ACTIVE FILE',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: _primaryBlue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (doc.fileSizeKB > 0)
                                    Text(
                                      doc.fileSizeKB >= 1024
                                          ? '${(doc.fileSizeKB / 1024).toStringAsFixed(1)} MB'
                                          : '${doc.fileSizeKB} KB',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                doc.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Preview Button
                        OutlinedButton.icon(
                          onPressed: openCurrentPreview,
                          icon: const Icon(Icons.visibility_outlined, size: 15),
                          label: const Text('Preview'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: _primaryBlue,
                            side: const BorderSide(color: _primaryBlue, width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ─── 2. REPLACE DOCUMENT / UPLOAD ANOTHER FILE ────────────
                  Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 17, color: _emerald),
                      const SizedBox(width: 6),
                      Text(
                        'Replace Document File',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        ),
                      ),
                      const Spacer(),
                      if (replacementFile != null)
                        TextButton.icon(
                          onPressed: () => showSourceActionSheet(setModalState),
                          icon: const Icon(Icons.sync_rounded, size: 14),
                          label: const Text('Change'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: _primaryBlue,
                            textStyle: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (replacementFile == null)
                    InkWell(
                      onTap: () => showSourceActionSheet(setModalState),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: _emerald.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.file_upload_outlined, color: _emerald, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload New File to Replace',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Pick Camera photo, Gallery or PDF file',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Builder(
                      builder: (context) {
                        final newFileName = replacementFileName ?? 'new_file';
                        final newLower = newFileName.toLowerCase();
                        final bool isNewImage = newLower.endsWith('.jpg') ||
                            newLower.endsWith('.jpeg') ||
                            newLower.endsWith('.png') ||
                            newLower.endsWith('.webp');

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _emerald.withValues(alpha: isDark ? 0.14 : 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _emerald.withValues(alpha: 0.6),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Replacement Thumbnail
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: isNewImage ? Colors.black12 : const Color(0xFFEF4444).withValues(alpha: 0.12),
                                  child: isNewImage && replacementFile != null
                                      ? Image.file(
                                          replacementFile!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_outlined, color: _emerald),
                                        )
                                      : const Center(
                                          child: Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 24),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Metadata
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _emerald,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'NEW REPLACEMENT',
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        if (replacementFileSizeKB != null)
                                          Text(
                                            replacementFileSizeKB! >= 1024
                                                ? '${(replacementFileSizeKB! / 1024).toStringAsFixed(1)} MB'
                                                : '$replacementFileSizeKB KB',
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontSize: 11,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      newFileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Preview Action for Replacement
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 20, color: _emerald),
                                tooltip: 'Preview new replacement file',
                                onPressed: openReplacementPreview,
                              ),
                              // Cancel / Remove replacement
                              IconButton(
                                icon: Icon(Icons.cancel_outlined, size: 20, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                                tooltip: 'Remove replacement',
                                onPressed: () {
                                  setModalState(() {
                                    replacementFile = null;
                                    replacementFileName = null;
                                    replacementFileSizeKB = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 18),

                  // ─── 3. DOCUMENT NAME FIELD ────────────────────────────────
                  Text(
                    'Document Name',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: titleController,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Blood Test Report',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      prefixIcon: const Icon(Icons.description_outlined, size: 18, color: Color(0xFF64748B)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── 4. CATEGORY SELECTOR ──────────────────────────────────
                  Text(
                    'Category',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory.toLowerCase() == cat.toLowerCase();
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => selectedCategory = cat);
                          }
                        },
                        selectedColor: _primaryBlue,
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? _primaryBlue : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // ─── 5. NOTES / DESCRIPTION FIELD ──────────────────────────
                  Text(
                    'Clinical Notes / Description (Optional)',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: notesController,
                    maxLines: 3,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add notes about doctor, diagnosis or findings...',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── 6. SAVE BUTTON ────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final newTitle = titleController.text.trim();
                              if (newTitle.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Document name cannot be empty'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);

                              try {
                                final currentUser = GlobalSession.instance.userNotifier.value;
                                final token = currentUser?.data?.accessToken ?? '';
                                final currentUserId = currentUser?.data?.id ?? '';
                                final patientId = currentUserId.isNotEmpty ? currentUserId : '1';
                                final client = ApiClient();

                                if (replacementFile != null) {
                                  // ─── REPLACE FILE UPLOAD ───
                                  final repName = replacementFileName ??
                                      replacementFile!.path.split(Platform.pathSeparator).last;

                                  final formData = FormData.fromMap({
                                    'files': await MultipartFile.fromFile(
                                      replacementFile!.path,
                                      filename: repName,
                                    ),
                                    'fileName': newTitle,
                                    'category': selectedCategory,
                                    'documentCategory': selectedCategory,
                                    if (notesController.text.trim().isNotEmpty)
                                      'description': notesController.text.trim(),
                                    'patientId': patientId.isNotEmpty ? patientId : '1',
                                    'hospitalId': currentUser?.data?.latestHospitalId?.toString() ?? '1',
                                    'organizationId': currentUser?.data?.latestOrgId?.toString() ?? '1',
                                    if (currentUserId.isNotEmpty) 'uploadedByUserId': currentUserId,
                                    'isPatientUploaded': currentUser?.data?.navigationId == "1" ? "true" : "false",
                                    'isDoctorUploaded': currentUser?.data?.navigationId != "1" ? "true" : "false",
                                  });

                                  UploadedRecord? newUploadedRecord;
                                  try {
                                    final response = await client.account(showSuccessSnack: false).post(
                                      URLs.medicalDocumentsUrl,
                                      data: formData,
                                      options: Options(
                                        headers: {
                                          if (token.isNotEmpty)
                                            HttpHeaders.authorizationHeader: 'Bearer $token',
                                          'Content-Type': 'multipart/form-data',
                                        },
                                        extra: {'suppressErrorSnack': true},
                                      ),
                                    );

                                    if (response.data != null && response.data is Map<String, dynamic>) {
                                      final mapData = response.data as Map<String, dynamic>;
                                      final rawJson = mapData['data'] ?? mapData['result'] ?? mapData['payload'] ?? mapData;
                                      Map<String, dynamic>? json;
                                      if (rawJson is List && rawJson.isNotEmpty && rawJson.first is Map<String, dynamic>) {
                                        json = rawJson.first as Map<String, dynamic>;
                                      } else if (rawJson is Map<String, dynamic>) {
                                        json = rawJson;
                                      }

                                      if (json != null) {
                                        int sizeKb = replacementFileSizeKB ?? 0;
                                        final rawSize = json['fileSizeKB'] ?? json['FileSize'] ?? json['fileSize'];
                                        if (rawSize != null) {
                                          final parsed = int.tryParse(rawSize.toString());
                                          if (parsed != null && parsed > 0) {
                                            sizeKb = parsed > 1024 ? (parsed ~/ 1024) : parsed;
                                          }
                                        }
                                        final blobUrl = (json['blobUrl'] ?? json['BlobUrl'] ?? json['fileUrl'] ?? json['url'] ?? json['Url'] ?? '').toString();
                                        newUploadedRecord = UploadedRecord(
                                          id: (json['id'] ?? json['Id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
                                          fileName: newTitle,
                                          category: selectedCategory,
                                          uploadDate: DateTime.now(),
                                          fileSizeKB: sizeKb,
                                          fileUrl: blobUrl.isNotEmpty ? blobUrl : null,
                                          filePath: replacementFile!.path,
                                          description: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                          doctorName: doc.doctorName,
                                          hospitalName: doc.hospitalName,
                                          appointmentDate: doc.appointmentDate,
                                          appointmentId: doc.appointmentId,
                                          fileType: (repName.contains('.') ? repName.split('.').last : 'PDF').toUpperCase(),
                                          isAppointmentDoc: doc.isAppointmentDoc,
                                          isPatientUploaded: true,
                                          isDeletable: true,
                                        );
                                      }
                                    }
                                  } catch (uploadErr) {
                                    debugPrint('Upload replacement error: $uploadErr');
                                  }

                                  newUploadedRecord ??= doc.copyWith(
                                    fileName: newTitle,
                                    category: selectedCategory,
                                    description: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                    filePath: replacementFile!.path,
                                    fileSizeKB: replacementFileSizeKB ?? doc.fileSizeKB,
                                    fileType: (repName.contains('.') ? repName.split('.').last : 'PDF').toUpperCase(),
                                    uploadDate: DateTime.now(),
                                  );

                                  // Delete old doc from backend if it had a distinct ID
                                  if (doc.id.isNotEmpty && doc.id != newUploadedRecord.id) {
                                    try {
                                      await client.account(showSuccessSnack: false).delete(
                                        '${URLs.medicalDocumentsUrl}/${doc.id}',
                                        options: Options(
                                          headers: {if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token'},
                                          extra: {'suppressErrorSnack': true},
                                        ),
                                      );
                                    } catch (delErr) {
                                      debugPrint('Error deleting old doc after replacement: $delErr');
                                    }
                                  }

                                  // Update state in Bloc
                                  if (blocContext.mounted) {
                                    blocContext.read<UploadedBloc>().add(
                                      ReplaceUploadedRecord(oldRecordId: doc.id, newRecord: newUploadedRecord),
                                    );
                                  }

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                            SizedBox(width: 8),
                                            Text('Document replaced & updated successfully'),
                                          ],
                                        ),
                                        backgroundColor: _emerald,
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } else {
                                  // ─── METADATA ONLY UPDATE ───
                                  final updatedDoc = doc.copyWith(
                                    fileName: newTitle,
                                    category: selectedCategory,
                                    description: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                                  );

                                  if (blocContext.mounted) {
                                    blocContext.read<UploadedBloc>().add(UpdateUploadedRecord(updatedDoc));
                                  }
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }

                                  if (token.isNotEmpty && doc.id.isNotEmpty) {
                                    try {
                                      await client.account(showSuccessSnack: false).put(
                                        '${URLs.medicalDocumentsUrl}/${doc.id}',
                                        data: {
                                          'fileName': newTitle,
                                          'category': selectedCategory,
                                          'description': notesController.text.trim(),
                                        },
                                        options: Options(
                                          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
                                          extra: {'suppressErrorSnack': true},
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint('Error updating document on backend: $e');
                                    }
                                  }

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                            SizedBox(width: 8),
                                            Text('Document updated successfully'),
                                          ],
                                        ),
                                        backgroundColor: _emerald,
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              } catch (err) {
                                debugPrint('Save document error: $err');
                                setModalState(() => isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update document: $err'),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: replacementFile != null ? _emerald : _primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  replacementFile != null ? Icons.cloud_done_rounded : Icons.check_circle_outline_rounded,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  replacementFile != null ? 'Save & Replace Document' : 'Save Changes',
                                  style: const TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
