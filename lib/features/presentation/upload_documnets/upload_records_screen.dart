import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import '../../domain/entities/uploaded_record/uploaded_record_entity.dart';

import '../../../../core/common_widgets/common_text.dart';
import '../../../core/common_drop_down/common_drop_down.dart';
import '../../../core/common_widgets/custom_border_button.dart';
import '../../../core/common_widgets/custom_button.dart';

class UploadDocumentsScreen extends StatefulWidget {
  final String? patientName;
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;

  const UploadDocumentsScreen({
    super.key,
    required this.patientName,
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
  });

  @override
  State<UploadDocumentsScreen> createState() => _UploadDocumentsScreenState();
}

class _UploadDocumentsScreenState extends State<UploadDocumentsScreen> {
  final List<String> categoriesList = const [
    'Imaging / Radiology',
    'Appointments',
    'General',
    'Self(Patient)',
  ];

  late String selectedCategory;
  List<Map<String, dynamic>> stagedFiles = [];
  bool isUploading = false;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    selectedCategory = categoriesList.first;
  }

  // --- 1. Button Tap Handler ---
  void _handleBrowseTap() {
    _showPickerOptions(context);
  }

  // --- 2. Bottom Sheet ---
  Future<void> _showPickerOptions(BuildContext context) async {
    if (_isPicking) return;

    final String? selection = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: primaryColor),
                title: const Text('Upload Photo from Gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: primaryColor),
                title: const Text('Take Photo with Camera'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.folder, color: primaryColor),
                title: const Text('Upload Document from Files'),
                onTap: () => Navigator.pop(context, 'files'),
              ),
            ],
          ),
        );
      },
    );

    if (selection != null && mounted) {
      // Delay to ensure bottom sheet view controller dismissal animation is completely finished in iOS/Android
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _pickFiles(source: selection);
    }
  }

  void _previewStagedFile(BuildContext context, Map<String, dynamic> file) {
    final String filePath = file['path'] ?? '';
    if (filePath.isEmpty) return;

    final lowerPath = filePath.toLowerCase();
    final bool isImage = lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg') || lowerPath.endsWith('.png');

    if (isImage && File(filePath).existsSync()) {
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                maxScale: 4.0,
                child: Image.file(File(filePath), fit: BoxFit.contain),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // --- 3. Native File / Photo Picker ---
  Future<void> _pickFiles({required String source}) async {
    if (_isPicking) return;
    _isPicking = true;

    try {
      if (source == 'gallery') {
        final ImagePicker picker = ImagePicker();
        List<XFile> images = [];
        try {
          images = await picker.pickMultiImage();
        } catch (e) {
          debugPrint('pickMultiImage exception: $e');
        }
        if (images.isEmpty) {
          try {
            final XFile? single = await picker.pickImage(source: ImageSource.gallery);
            if (single != null) images = [single];
          } catch (e) {
            debugPrint('pickImage gallery exception: $e');
          }
        }
        if (images.isNotEmpty) {
          final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
          int skippedCount = 0;
          for (int i = 0; i < images.length; i++) {
            final image = images[i];
            final int size = await image.length();
            if (size > 5 * 1024 * 1024) {
              skippedCount++;
              continue;
            }
            final String ext = image.name.contains('.')
                ? image.name.substring(image.name.lastIndexOf('.') + 1)
                : 'jpg';
            final String cleanName = images.length > 1
                ? 'IMG_${timestamp}_${i + 1}.$ext'
                : 'IMG_$timestamp.$ext';

            if (mounted) {
              setState(() {
                final isDuplicate = stagedFiles.any((f) => f['path'] == image.path);
                if (!isDuplicate) {
                  stagedFiles.add({
                    'name': cleanName,
                    'size': size,
                    'path': image.path,
                  });
                }
              });
            }
          }
          if (skippedCount > 0 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$skippedCount image(s) exceeded the 5MB limit and were skipped.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        }
      } else if (source == 'camera') {
        final ImagePicker picker = ImagePicker();
        final XFile? photo = await picker.pickImage(source: ImageSource.camera);
        if (photo != null) {
          final int size = await photo.length();
          if (size > 5 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('The captured photo exceeds the 5MB size limit.'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
            return;
          }
          final String ext = photo.name.contains('.')
              ? photo.name.substring(photo.name.lastIndexOf('.') + 1)
              : 'jpg';
          final String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
          final String cleanName = 'CAP_$timestamp.$ext';

          if (mounted) {
            setState(() {
              final isDuplicate = stagedFiles.any((f) => f['path'] == photo.path);
              if (!isDuplicate) {
                stagedFiles.add({
                  'name': cleanName,
                  'size': size,
                  'path': photo.path,
                });
              }
            });
          }
        }
      } else {
        FilePickerResult? result;
        try {
          result = await FilePicker.platform.pickFiles(
            type: FileType.any,
            allowMultiple: true,
          );
        } catch (e) {
          debugPrint('FilePicker error: $e');
        }

        if (result != null && result.files.isNotEmpty && mounted) {
          int skippedCount = 0;
          setState(() {
            for (final file in result!.files) {
              if (file.path != null) {
                if (file.size > 5 * 1024 * 1024) {
                  skippedCount++;
                  continue;
                }
                final isDuplicate = stagedFiles.any((f) => f['path'] == file.path);
                if (!isDuplicate) {
                  stagedFiles.add({
                    'name': file.name,
                    'size': file.size,
                    'path': file.path,
                  });
                }
              }
            }
          });
          if (skippedCount > 0 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$skippedCount document(s) exceeded the 5MB limit and were skipped.'),
                backgroundColor: Colors.orangeAccent,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('File/Photo Picker Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown Size';
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = (bytes / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      return '$mb MB';
    }
  }

  // --- 4. Upload Confirmation ---
  void _handleUploadConfirmation(BuildContext context) async {
    if (stagedFiles.isEmpty) return;

    final bloc = context.read<UploadedBloc>();
    final repo = bloc.repository;
    final navigator = Navigator.of(context);

    setState(() {
      isUploading = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      for (int i = 0; i < stagedFiles.length; i++) {
        final file = stagedFiles[i];
        final rawSize = file['size'] as int?;
        final sizeInKb = rawSize != null ? (rawSize / 1024).round() : 2048;
        final String filePath = file['path'] ?? '';
        final String fileName = file['name'] ?? 'Document';

        UploadedRecord? uploaded;
        if (filePath.isNotEmpty) {
          uploaded = await repo.uploadDocument(
            filePath: filePath,
            fileName: fileName,
            category: selectedCategory,
            patientId: widget.patientId,
            appointmentId: widget.appointmentId,
            hospitalId: widget.hospitalId,
            orgId: widget.orgId,
          );
        }

        final recordToAdd = uploaded ?? UploadedRecord(
          id: '${timestamp}_$i',
          fileName: fileName,
          category: selectedCategory,
          uploadDate: DateTime.now(),
          fileSizeKB: sizeInKb,
          filePath: filePath,
        );

        bloc.add(AddUploadedRecord(recordToAdd));
      }

      bloc.add(FetchUploadedRecords(
        patientId: widget.patientId,
        appointmentId: widget.appointmentId,
        hospitalId: widget.hospitalId,
        orgId: widget.orgId,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text("${stagedFiles.length} document(s) uploaded successfully!"),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      debugPrint("Upload confirmation error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
        navigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                screenHorizontalSpacePadding,
                0,
                screenHorizontalSpacePadding,
                28,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText(
                    "Upload Clinical Documents",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab
                          ? displayWidth(context) * 0.032
                          : displayWidth(context) * 0.054,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CommonText(
                    "For patient: ${widget.patientName}",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab
                          ? displayWidth(context) * 0.022
                          : displayWidth(context) * 0.034,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: screenHorizontalSpacePadding,
                  vertical: 26.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommonText(
                      "Document Category",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab
                            ? displayWidth(context) * 0.02
                            : displayWidth(context) * 0.035,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CommonDropdown(
                      title: "Select Category",
                      selectedValue: selectedCategory,
                      options: categoriesList,
                      onSelected: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: fieldSpace),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CommonText(
                          "Selected Files",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab
                                ? displayWidth(context) * 0.02
                                : displayWidth(context) * 0.035,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: CommonText(
                            "${stagedFiles.length} Files",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab
                                  ? displayWidth(context) * 0.018
                                  : displayWidth(context) * 0.026,
                              color: primaryColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    stagedFiles.isEmpty
                        ? GestureDetector(
                      onTap: _handleBrowseTap, // Updated Tap Handler
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 36,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.transparent
                              : Colors.white,
                          borderRadius: BorderRadius.circular(
                            fieldBorderRadius,
                          ),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  fieldBorderRadius,
                                ),
                              ),
                              child: const Icon(
                                Icons.note_add_rounded,
                                color: Color(0xFF0066FF),
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 16),
                            CommonText(
                              "Tap to select files",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab
                                    ? displayWidth(context) * 0.02
                                    : displayWidth(context) * 0.035,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            CommonText(
                              "Support for PDF, JPG, PNG up to 5MB",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab
                                    ? displayWidth(context) * 0.018
                                    : displayWidth(context) * 0.03,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.transparent
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  fieldBorderRadius,
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey.withOpacity(0.2)
                                      : primaryColor,
                                  width: 0.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CommonText(
                                "Browse Files",
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: isTab
                                      ? displayWidth(context) * 0.018
                                      : displayWidth(context) * 0.032,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        : const SizedBox.shrink(),
                    const SizedBox(height: fieldSpace),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: stagedFiles.length,
                      itemBuilder: (context, index) {
                        final file = stagedFiles[index];
                        final rawSize = file['size'] as int?;
                        final String filePath = file['path'] ?? '';
                        final String lowerPath = filePath.toLowerCase();
                        final bool isImage = lowerPath.endsWith('.jpg') ||
                            lowerPath.endsWith('.jpeg') ||
                            lowerPath.endsWith('.png');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.surface
                                : const Color(0xFFFAFBFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : const Color(0xFFEDEFF3),
                            ),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _previewStagedFile(context, file),
                                child: isImage && filePath.isNotEmpty && File(filePath).existsSync()
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          File(filePath),
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(
                                            isDark ? 0.15 : 0.06,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.description_outlined,
                                          color: isDark
                                              ? primaryColor.withOpacity(0.9)
                                              : primaryColor,
                                          size: 20,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _previewStagedFile(context, file),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CommonText(
                                        file['name'] ?? 'Document',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isTab
                                              ? displayWidth(context) * 0.018
                                              : displayWidth(context) * 0.03,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      CommonText(
                                        _formatFileSize(rawSize),
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          color: theme.hintColor,
                                          fontSize: isTab
                                              ? displayWidth(context) * 0.018
                                              : displayWidth(context) * 0.028,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.cancel_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    stagedFiles.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (stagedFiles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
                        child: Center(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              side: const BorderSide(
                                color: primaryColor,
                                width: 0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  fieldBorderRadius,
                                ),
                              ),
                            ),
                            onPressed: _handleBrowseTap, // Updated Tap Handler
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: primaryColor,
                              size: 18,
                            ),
                            label: CommonText(
                              "Add More Files",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: isTab
                                    ? displayWidth(context) * 0.02
                                    : displayWidth(context) * 0.035,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(fieldBorderRadius),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : const Color(0xFFE5E9F0),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CommonBorderButton(
                      height: 40,
                      text: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: isUploading
                        ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                        : CustomElevatedButton(
                      text: "Confirm Upload",
                      onPressed: (stagedFiles.isEmpty || isUploading)
                          ? null
                          : () => _handleUploadConfirmation(context),
                      width: double.infinity,
                      height: 40,
                      borderRadius: 8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}