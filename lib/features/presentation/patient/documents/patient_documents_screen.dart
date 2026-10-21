import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/api/base_api_configuration.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/in_app_document_viewer.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';
import '../../../../core/utils/utils.dart';
import '../../../../di/dependency_injection.dart';
import '../../../domain/entities/medical_report/medical_report_analysis.dart';
import '../../../domain/entities/uploaded_record/uploaded_record_entity.dart';
import '../../upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import '../diet/diet_ui.dart';
import 'report_insights_screen.dart';
import 'report_upload_sheet.dart';

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

  /// Analyses seen in this session, so reopening insights is instant.
  final Map<String, MedicalReportAnalysis> _analyses = {};

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
        if (EnvironmentService.config.accountBaseUrl.startsWith('https://') &&
            (effectiveUrl.contains('localhost:5000') ||
             effectiveUrl.contains('127.0.0.1:5000') ||
             RegExp(r'192\.168\.\d+\.\d+:5000').hasMatch(effectiveUrl))) {
          effectiveUrl = effectiveUrl.replaceAll(RegExp(r'https?://[^/]+'), EnvironmentService.config.accountBaseUrl);
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

  // ─── UPLOAD + AI ANALYSIS ─────────────────────────────────────────────────
  Future<void> _openReportUpload(BuildContext blocContext) async {
    final result = await ReportUploadSheet.show(context);
    if (result == null || !mounted) return;

    final analysis = result.analysis;
    final record = UploadedRecord(
      id: result.documentId.isNotEmpty ? result.documentId : DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: result.fileName,
      category: result.category,
      uploadDate: DateTime.now(),
      fileSizeKB: 0,
      fileUrl: result.fileUrl,
      fileType: result.fileName.toLowerCase().endsWith('.pdf') ? 'PDF' : 'JPG',
      isPatientUploaded: true,
      aiStatus: analysis?.status.name,
    );
    if (!blocContext.mounted) return;
    blocContext.read<UploadedBloc>().add(AddUploadedRecord(record));
    _refresh(blocContext);

    if (analysis != null) {
      _analyses[record.id] = analysis;
      _openInsights(blocContext, record);
    } else if (result.analysisError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report saved. ${result.analysisError!.message}'),
          behavior: SnackBarBehavior.floating,
          action: result.documentId.isEmpty
              ? null
              : SnackBarAction(label: 'Retry', onPressed: () => _openInsights(blocContext, record)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${result.fileName}" uploaded'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _refresh(BuildContext blocContext) {
    final user = GlobalSession.instance.userNotifier.value?.data;
    blocContext.read<UploadedBloc>().add(FetchUploadedRecords(
          patientId: user?.id ?? '',
          orgId: user?.latestOrgId?.toString() ?? '1',
          hospitalId: user?.latestHospitalId?.toString() ?? '1',
          limit: 20,
          page: 1,
        ));
  }

  /// PDFs and photos can be read by the AI; Word files and others can't.
  bool _canAnalyze(UploadedRecord doc) {
    final type = '${doc.fileType ?? ''} ${doc.fileName}'.toLowerCase();
    if (RegExp(r'docx?|xlsx?|txt').hasMatch(type)) return false;
    return (doc.fileUrl ?? '').trim().isNotEmpty && int.tryParse(doc.id) != null;
  }

  void _openInsights(BuildContext blocContext, UploadedRecord doc) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReportInsightsScreen(
        documentId: doc.id,
        documentTitle: doc.fileName,
        initialAnalysis: _analyses[doc.id] ?? MedicalReportAnalysis.tryParse(doc.aiAnalysisJson),
        onViewDocument: () => _openFullPageDocument(context, doc),
        onAnalyzed: (analysis) {
          _analyses[doc.id] = analysis;
          if (!blocContext.mounted) return;
          blocContext.read<UploadedBloc>().add(UpdateUploadedRecord(doc.copyWith(aiStatus: analysis.status.name)));
        },
      ),
    ));
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
                  onPressed: () => _openReportUpload(blocContext),
                ),
                const SizedBox(width: 8),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _openReportUpload(blocContext),
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
                                            onPressed: () => _openReportUpload(blocContext),
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
                        } else if (action == 'insights') {
                          _openInsights(blocContext, doc);
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
                        if (_canAnalyze(doc))
                          PopupMenuItem<String>(
                            value: 'insights',
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome_rounded, size: 18, color: DietUi.violet),
                                const SizedBox(width: 10),
                                Text(
                                  doc.aiStatus == null ? 'Analyse with AI' : 'AI insights',
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

              if (_canAnalyze(doc)) ...[
                const SizedBox(height: 10),
                _buildAiRow(blocContext, doc, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The AI verdict for a report, or an invitation to analyse it.
  Widget _buildAiRow(BuildContext blocContext, UploadedRecord doc, bool isDark) {
    final status = doc.aiStatus == null ? null : reportStatusFrom(doc.aiStatus);
    final ({Color color, IconData icon, String label}) style = switch (status) {
      null => (color: DietUi.violet, icon: Icons.auto_awesome_rounded, label: 'Analyse with Yira AI'),
      ReportStatus.normal => (color: DietUi.green, icon: Icons.verified_rounded, label: 'All clear'),
      ReportStatus.attention => (color: DietUi.amber, icon: Icons.error_outline_rounded, label: 'Needs attention'),
      ReportStatus.critical => (color: DietUi.red, icon: Icons.warning_amber_rounded, label: 'Critical - see a doctor'),
      ReportStatus.unknown => (color: DietUi.slate, icon: Icons.help_outline_rounded, label: 'No health insights'),
    };

    return InkWell(
      onTap: () => _openInsights(blocContext, doc),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: style.color.withValues(alpha: isDark ? 0.14 : 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: style.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(style.icon, size: 16, color: style.color),
            const SizedBox(width: 8),
            if (status != null) ...[
              Text('AI', style: DietUi.text(10.5, FontWeight.w700, DietUi.muted(isDark), spacing: 0.4)),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                style.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DietUi.text(12, FontWeight.w700, style.color),
              ),
            ),
            Text(status == null ? 'Get insights' : 'View insights', style: DietUi.text(11.5, FontWeight.w600, DietUi.blue)),
            const Icon(Icons.chevron_right_rounded, size: 18, color: DietUi.blue),
          ],
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
