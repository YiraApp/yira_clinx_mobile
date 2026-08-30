import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/in_app_document_viewer.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';
import '../../../../core/utils/utils.dart';
import '../../../../di/dependency_injection.dart';
import '../../../domain/entities/uploaded_record/uploaded_record_entity.dart';
import '../../upload_documnets/uploaded_bloc/uploaded_bloc.dart';

class PatientDocumentsScreen extends StatefulWidget {
  const PatientDocumentsScreen({super.key});

  @override
  State<PatientDocumentsScreen> createState() => _PatientDocumentsScreenState();
}

class _PatientDocumentsScreenState extends State<PatientDocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'newest';
  final Set<String> _expandedDocIds = <String>{};
  final Set<String> _downloadingDocIds = <String>{};

  static const Color _primaryBlue = Color(0xFF2563EB);

  final List<String> _categoryFilters = const [
    'All',
    'Lab Report',
    'Prescription',
    'Scan / Imaging',
    'Discharge Summary',
    'Insurance Card',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 250) {
      final bloc = context.read<UploadedBloc?>();
      if (bloc != null) {
        final state = bloc.state;
        if (state.hasMore && !state.isLoadingMore && state.status == UploadedStatus.success) {
          final currentUser = GlobalSession.instance.userNotifier.value;
          final userId = currentUser?.data?.id ?? '';
          final orgId = currentUser?.data?.latestOrgId?.toString() ?? '1';
          final hospitalId = currentUser?.data?.latestHospitalId?.toString() ?? '1';

          bloc.add(LoadMoreUploadedRecords(
            patientId: userId,
            orgId: orgId,
            hospitalId: hospitalId,
            limit: 15,
          ));
        }
      }
    }
  }

  // ─── FULL PAGE IN-APP DOCUMENT VIEWER ──────────────────────────────────────
  void _openFullPageDocument(BuildContext context, UploadedRecord record) {
    final title = record.fileName;
    final category = record.category;
    final fileUrl = (record.fileUrl ?? '').trim();
    final filePath = (record.filePath ?? '').trim();
    final ext = (record.fileType ?? (title.contains('.') ? title.split('.').last : 'PDF')).toUpperCase();
    final dateStr = DateFormat('dd MMM yyyy').format(record.uploadDate);
    final fileSizeStr = record.fileSizeKB > 0
        ? (record.fileSizeKB >= 1024
            ? '${(record.fileSizeKB / 1024).toStringAsFixed(1)} MB'
            : '${record.fileSizeKB} KB')
        : null;

    final isHospitalAdded = !record.isPatientUploaded && record.hospitalName != null && record.hospitalName!.trim().isNotEmpty;

    InAppDocumentViewer.show(
      context,
      title: title,
      category: category,
      fileUrl: fileUrl.isNotEmpty ? fileUrl : null,
      filePath: filePath.isNotEmpty ? filePath : null,
      fileType: ext,
      fileSize: fileSizeStr,
      hospitalName: isHospitalAdded ? record.hospitalName : null,
      doctorName: isHospitalAdded ? record.doctorName : null,
      date: dateStr,
      isAppointmentDoc: record.isAppointmentDoc,
    );
  }

  // ─── DIRECT DOWNLOAD ACTION ────────────────────────────────────────────────
  Future<void> _downloadDocument(UploadedRecord record) async {
    final docId = record.id;
    final title = record.fileName;
    final fileUrl = (record.fileUrl ?? '').trim();
    final filePath = (record.filePath ?? '').trim();
    final ext = (record.fileType ?? (title.contains('.') ? title.split('.').last : 'PDF')).toLowerCase();

    if (_downloadingDocIds.contains(docId)) return;

    if (fileUrl.isEmpty && filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document file is not available to download directly.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _downloadingDocIds.add(docId));

    try {
      final dir = await getApplicationDocumentsDirectory();
      String cleanTitle = title.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      if (!cleanTitle.contains('.')) {
        cleanTitle += '.$ext';
      }
      final savePath = '${dir.path}/$cleanTitle';

      if (fileUrl.isNotEmpty) {
        String effectiveUrl = fileUrl;
        if (!effectiveUrl.startsWith('http://') && !effectiveUrl.startsWith('https://')) {
          effectiveUrl = 'https://$effectiveUrl';
        }
        final dio = Dio();
        await dio.download(
          effectiveUrl,
          savePath,
          options: Options(responseType: ResponseType.bytes),
        );
      } else if (filePath.isNotEmpty && File(filePath).existsSync()) {
        await File(filePath).copy(savePath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Downloaded "$cleanTitle" successfully!')),
              ],
            ),
            backgroundColor: const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Open',
              textColor: _primaryBlue,
              onPressed: () => Utils.launchURL('file://$savePath'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download document: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingDocIds.remove(docId));
      }
    }
  }

  void _openUploadDocumentDialog(
    BuildContext blocContext,
    String userId,
    String orgId,
    String hospitalId,
  ) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    String? selectedFilePath;
    String? selectedFileName;
    int? selectedFileSize;
    String selectedCategory = 'Lab Report';
    bool isUploading = false;
    String? uploadError;

    final categories = const [
      'Lab Report',
      'Prescription',
      'Scan / Imaging',
      'Discharge Summary',
      'Insurance Card',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

          return Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.upload_file_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload Medical Document',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Add your lab reports, scan files, or prescriptions',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (uploadError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              uploadError!,
                              style: const TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // File Picker Container
                  InkWell(
                    onTap: () async {
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
                        );

                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.first;
                          setModalState(() {
                            selectedFilePath = file.path;
                            selectedFileName = file.name;
                            selectedFileSize = file.size;
                            uploadError = null;
                            if (titleController.text.trim().isEmpty) {
                              final nameWithoutExt = file.name.contains('.')
                                  ? file.name.substring(0, file.name.lastIndexOf('.'))
                                  : file.name;
                              titleController.text = nameWithoutExt;
                            }
                          });
                        }
                      } catch (e) {
                        setModalState(() {
                          uploadError = 'Could not select file: $e';
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selectedFilePath != null
                              ? _primaryBlue
                              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          width: selectedFilePath != null ? 1.5 : 1,
                        ),
                      ),
                      child: selectedFilePath != null
                          ? Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.check_circle_rounded, color: _primaryBlue, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedFileName ?? 'File Selected',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (selectedFileSize != null)
                                        Text(
                                          selectedFileSize! >= 1024 * 1024
                                              ? '${(selectedFileSize! / (1024 * 1024)).toStringAsFixed(1)} MB'
                                              : '${(selectedFileSize! / 1024).toStringAsFixed(0)} KB',
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 11,
                                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setModalState(() {
                                      selectedFilePath = null;
                                      selectedFileName = null;
                                      selectedFileSize = null;
                                    });
                                  },
                                  child: const Text('Change', style: TextStyle(fontSize: 12, color: _primaryBlue)),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 36, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to choose document / report file',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Supports PDF, JPG, PNG, DOC (up to 10 MB)',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11,
                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Document Name Input
                  Text(
                    'Document Title',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Blood Test Report, MRI Scan, Prescription',
                      hintStyle: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Description / Notes Input
                  Text(
                    'Clinical Description / Notes (Optional)',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add remarks, test findings, doctor remarks, or reason...',
                      hintStyle: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category Selector
                  Text(
                    'Category',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setModalState(() => selectedCategory = cat);
                        },
                        labelStyle: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                        selectedColor: _primaryBlue,
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? _primaryBlue
                                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isUploading
                          ? null
                          : () async {
                              if (selectedFilePath == null) {
                                setModalState(() => uploadError = 'Please select a file to upload.');
                                return;
                              }
                              final finalTitle = titleController.text.trim().isNotEmpty
                                  ? titleController.text.trim()
                                  : (selectedFileName ?? 'Document');
                              final finalNotes = notesController.text.trim();

                              setModalState(() {
                                isUploading = true;
                                uploadError = null;
                              });

                              try {
                                final repo = blocContext.read<UploadedBloc>().repository;
                                final uploaded = await repo.uploadDocument(
                                  filePath: selectedFilePath!,
                                  fileName: finalTitle,
                                  category: selectedCategory,
                                  description: finalNotes.isNotEmpty ? finalNotes : null,
                                  patientId: userId,
                                  orgId: orgId,
                                  hospitalId: hospitalId,
                                );

                                if (uploaded != null) {
                                  blocContext.read<UploadedBloc>().add(AddUploadedRecord(uploaded));
                                }

                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);

                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text('"$finalTitle" uploaded successfully!'),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF0F172A),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() {
                                  isUploading = false;
                                  uploadError = 'Failed to upload document: $e';
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Upload Medical Document',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final orgId = (currentUser?.data?.latestOrgId?.toString() ?? '1');
    final hospitalId = (currentUser?.data?.latestHospitalId?.toString() ?? '1');

    return BlocProvider<UploadedBloc>(
      create: (_) => sl<UploadedBloc>()
        ..add(FetchUploadedRecords(
          patientId: userId,
          orgId: orgId,
          hospitalId: hospitalId,
          limit: 20,
          page: 1,
        )),
      child: Builder(
        builder: (blocContext) {
          final uploadedState = blocContext.watch<UploadedBloc>().state;
          final allDocs = uploadedState.allRecords;

          // Filter documents by category & search query
          List<UploadedRecord> filteredDocs = allDocs.where((doc) {
            final catStr = doc.category.toLowerCase();
            final titleStr = doc.fileName.toLowerCase();
            final hospStr = (doc.hospitalName ?? '').toLowerCase();
            final docNameStr = (doc.doctorName ?? '').toLowerCase();
            final descStr = (doc.description ?? '').toLowerCase();
            final q = _searchQuery.toLowerCase().trim();

            if (_selectedCategory != 'All') {
              final selectedLow = _selectedCategory.toLowerCase();
              final isMatch = catStr.contains(selectedLow) ||
                  (selectedLow.contains('scan') && (catStr.contains('imaging') || catStr.contains('scan') || catStr.contains('radiology'))) ||
                  (selectedLow.contains('lab') && (catStr.contains('lab') || catStr.contains('report')));
              if (!isMatch) return false;
            }

            if (q.isNotEmpty) {
              return titleStr.contains(q) || hospStr.contains(q) || docNameStr.contains(q) || catStr.contains(q) || descStr.contains(q);
            }
            return true;
          }).toList();

          // Sort documents
          if (_sortBy == 'name') {
            filteredDocs.sort((a, b) => a.fileName.compareTo(b.fileName));
          } else if (_sortBy == 'oldest') {
            filteredDocs.sort((a, b) => a.uploadDate.compareTo(b.uploadDate));
          } else {
            filteredDocs.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
          }

          // Show shimmer skeleton while initial fetch or loading
          final showShimmer = (uploadedState.status == UploadedStatus.loading || uploadedState.status == UploadedStatus.initial) && allDocs.isEmpty;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              title: const Text(
                'Medical Documents',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.sort_rounded, size: 18, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                  tooltip: 'Sort Documents',
                  onSelected: (val) => setState(() => _sortBy = val),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'newest', child: Text('Newest First')),
                    const PopupMenuItem(value: 'oldest', child: Text('Oldest First')),
                    const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
                  ],
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Upload Document',
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.upload_file_rounded, size: 18, color: _primaryBlue),
                  ),
                  onPressed: () => _openUploadDocumentDialog(blocContext, userId, orgId, hospitalId),
                ),
                const SizedBox(width: 8),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _openUploadDocumentDialog(blocContext, userId, orgId, hospitalId),
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Upload Document',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // 1. Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 4),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search medical documents, lab tests, reports...',
                        hintStyle: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12.5,
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),

                  // 2. Category Filter Pills with Active Count Badges (Clean Neutral & Primary)
                  Container(
                    height: 38,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
                      itemCount: _categoryFilters.length,
                      itemBuilder: (context, index) {
                        final category = _categoryFilters[index];
                        final isSelected = _selectedCategory.toLowerCase() == category.toLowerCase();

                        int catCount = allDocs.length;
                        if (category != 'All') {
                          final selectedLow = category.toLowerCase();
                          catCount = allDocs.where((d) {
                            final c = d.category.toLowerCase();
                            return c.contains(selectedLow) ||
                                (selectedLow.contains('scan') && (c.contains('imaging') || c.contains('scan'))) ||
                                (selectedLow.contains('lab') && (c.contains('lab') || c.contains('report')));
                          }).length;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(category),
                                if (catCount > 0) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : (isDark ? Colors.white12 : Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      catCount.toString(),
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedCategory = category);
                            },
                            labelStyle: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                            selectedColor: _primaryBlue,
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? _primaryBlue
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          ),
                        );
                      },
                    ),
                  ),

                  // 3. Documents List with YouTube-style Pagination & Shimmer
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        blocContext.read<UploadedBloc>().add(FetchUploadedRecords(
                              patientId: userId,
                              orgId: orgId,
                              hospitalId: hospitalId,
                              limit: 20,
                              page: 1,
                            ));
                        await Future.delayed(const Duration(milliseconds: 600));
                      },
                      child: showShimmer
                          ? _buildShimmerList(isDark)
                          : filteredDocs.isEmpty
                              ? Center(
                                  child: SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: isTab ? 90 : 76,
                                            height: isTab ? 90 : 76,
                                            decoration: BoxDecoration(
                                              color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.folder_shared_rounded,
                                                size: 38,
                                                color: _primaryBlue,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _searchQuery.isNotEmpty
                                                ? "No Matching Documents"
                                                : "No Medical Documents Found",
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontWeight: FontWeight.bold,
                                              fontSize: isTab ? 18 : 16,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _searchQuery.isNotEmpty
                                                ? 'No records match "$_searchQuery". Try clearing your search or filter.'
                                                : 'Upload your medical reports, scan files, and lab tests to securely access them anytime.',
                                            style: TextStyle(
                                              fontFamily: appPoppinFont,
                                              fontSize: isTab ? 13.5 : 12,
                                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                              height: 1.4,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 20),
                                          ElevatedButton.icon(
                                            onPressed: () => _openUploadDocumentDialog(blocContext, userId, orgId, hospitalId),
                                            icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                                            label: const Text(
                                              "Upload First Document",
                                              style: TextStyle(
                                                fontFamily: appPoppinFont,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _primaryBlue,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: screenHorizontalSpacePadding,
                                    vertical: 6,
                                  ),
                                  itemCount: filteredDocs.length + (uploadedState.isLoadingMore ? 1 : 1),
                                  itemBuilder: (context, index) {
                                    if (index < filteredDocs.length) {
                                      final doc = filteredDocs[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: _buildDocumentCard(
                                          context: context,
                                          blocContext: blocContext,
                                          doc: doc,
                                          isDark: isDark,
                                          isTab: isTab,
                                        ),
                                      );
                                    }

                                    // YouTube-style pagination bottom loader
                                    if (uploadedState.isLoadingMore) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        alignment: Alignment.center,
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBlue),
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'Loading more medical documents...',
                                              style: TextStyle(
                                                fontFamily: appPoppinFont,
                                                fontSize: 11.5,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    return Container(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '• All ${filteredDocs.length} medical documents loaded •',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11,
                                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },
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

  // ─── SIMPLE & CLEAN DOCUMENT CARD (UNIFIED DESIGN) ──────────────────────────
  Widget _buildDocumentCard({
    required BuildContext context,
    required BuildContext blocContext,
    required UploadedRecord doc,
    required bool isDark,
    required bool isTab,
  }) {
    final title = doc.fileName;
    final category = doc.category;
    final fileType = (doc.fileType ?? (title.contains('.') ? title.split('.').last : 'PDF')).toUpperCase();

    final uploadedDocDate = DateFormat('dd MMM yyyy').format(doc.uploadDate);
    final fileSize = doc.fileSizeKB > 0
        ? (doc.fileSizeKB >= 1024
            ? '${(doc.fileSizeKB / 1024).toStringAsFixed(1)} MB'
            : '${doc.fileSizeKB} KB')
        : '';
    final isDeletable = doc.isDeletable;
    final docId = doc.id;
    final isDownloading = _downloadingDocIds.contains(docId);

    // Check if hospital added this document vs self upload
    final isHospitalAdded = !doc.isPatientUploaded && doc.hospitalName != null && doc.hospitalName!.trim().isNotEmpty;
    final hospitalName = isHospitalAdded ? doc.hospitalName!.trim() : null;
    final doctorName = isHospitalAdded && doc.doctorName != null && doc.doctorName!.trim().isNotEmpty ? doc.doctorName!.trim() : null;

    final hasDescription = doc.description != null && doc.description!.trim().isNotEmpty;
    final description = doc.description?.trim() ?? '';
    final isExpanded = _expandedDocIds.contains(docId);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openFullPageDocument(context, doc),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isTab ? 16 : 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF64748B).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Simple Unified Icon + Title & Category Tags + 3 DOTS MENU
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isTab ? 42 : 38,
                    height: isTab ? 42 : 38,
                    decoration: BoxDecoration(
                      color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.description_outlined,
                        color: _primaryBlue,
                        size: isTab ? 22 : 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title and Category Pill + Hospital Badge (if hospital-added)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 14.5 : 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Clean Simple Category Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Hospital Name Tag (ONLY added when hospital uploaded the record)
                            if (isHospitalAdded && hospitalName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _primaryBlue.withValues(alpha: isDark ? 0.15 : 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _primaryBlue.withValues(alpha: 0.25),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_hospital_rounded, size: 10, color: _primaryBlue),
                                    const SizedBox(width: 3.5),
                                    Text(
                                      hospitalName,
                                      style: const TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryBlue,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            Text(
                              fileType,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                            ),
                            Text(
                              '• $uploadedDocDate',
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
                  ),

                  // ─── 3 DOTS MENU (VIEW, DOWNLOAD, DELETE) ───
                  if (isDownloading)
                    const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBlue),
                      ),
                    )
                  else
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Options',
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      elevation: 6,
                      onSelected: (action) {
                        if (action == 'view') {
                          _openFullPageDocument(context, doc);
                        } else if (action == 'download') {
                          _downloadDocument(doc);
                        } else if (action == 'delete') {
                          blocContext.read<UploadedBloc>().add(DeleteUploadedRecordItem(docId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Document removed'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'view',
                          child: Row(
                            children: [
                              const Icon(Icons.visibility_outlined, size: 18, color: _primaryBlue),
                              const SizedBox(width: 10),
                              Text(
                                'View Document',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'download',
                          child: Row(
                            children: [
                              Icon(Icons.file_download_outlined, size: 18, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                              const SizedBox(width: 10),
                              Text(
                                'Download',
                                style: TextStyle(
                                  fontFamily: appPoppinFont,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDeletable && docId.isNotEmpty)
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: const Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                                SizedBox(width: 10),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),

              // YouTube-style Expandable Description Render
              if (hasDescription) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedDocIds.remove(docId);
                      } else {
                        _expandedDocIds.add(docId);
                      }
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          maxLines: isExpanded ? 20 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            height: 1.4,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        if (description.length > 70) ...[
                          const SizedBox(height: 2),
                          Text(
                            isExpanded ? 'Show less' : '...more',
                            style: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _primaryBlue,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // Metadata Chips (Only File Size for self-upload, or Doctor if hospital added)
              if (fileSize.isNotEmpty || (isHospitalAdded && doctorName != null)) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (fileSize.isNotEmpty)
                      _buildMetaChip(
                        icon: Icons.data_usage_rounded,
                        label: 'Size',
                        value: fileSize,
                        isDark: isDark,
                      ),
                    if (isHospitalAdded && doctorName != null)
                      _buildMetaChip(
                        icon: Icons.person_outline_rounded,
                        label: 'Doctor',
                        value: doctorName,
                        isDark: isDark,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 10,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 6),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: BaseShimmer(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
