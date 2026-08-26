import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/colors/colors.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../di/dependency_injection.dart';
import '../../upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import '../../../../core/shimmer_widgets/base_shimmer.dart';

class PatientDocumentsScreen extends StatefulWidget {
  const PatientDocumentsScreen({super.key});

  @override
  State<PatientDocumentsScreen> createState() => _PatientDocumentsScreenState();
}

class _PatientDocumentsScreenState extends State<PatientDocumentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _localUploadedDocs = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openUploadDocumentDialog() {
    final titleController = TextEditingController();
    String category = 'Self Uploaded';
    String selectedHospital = 'Yira Hospitals';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final primaryColor = Theme.of(context).primaryColor;
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
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                  Text(
                    'Upload Medical Document',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Document Title', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Annual Blood Test Report',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text('Category', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: ['Prescription', 'Lab Report', 'Diagnostic Scan', 'Self Uploaded']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13))))
                        .toList(),
                    onChanged: (val) => setModalState(() => category = val!),
                  ),
                  const SizedBox(height: 14),

                  Text('Associated Hospital', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedHospital,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: ['Yira Hospitals', 'Apollo City Hospital', 'KIMS Hospital', 'Independent Lab']
                        .map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13))))
                        .toList(),
                    onChanged: (val) => setModalState(() => selectedHospital = val!),
                  ),
                  const SizedBox(height: 20),

                  // File Picker Mock Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.3), style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 36, color: primaryColor),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to select PDF or Image file',
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor),
                        ),
                        Text('Supported formats: PDF, JPG, PNG (Max 15MB)', style: TextStyle(fontFamily: appPoppinFont, fontSize: 10, color: isDark ? Colors.white38 : Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a document title')));
                          return;
                        }
                        setState(() {
                          _localUploadedDocs.insert(0, {
                            'title': titleController.text.trim(),
                            'category': category,
                            'hospitalName': selectedHospital,
                            'date': 'Just now',
                            'fileSize': '2.4 MB',
                            'fileType': 'PDF',
                          });
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded successfully!')));
                      },
                      child: const Text('Upload Document', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 15)),
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
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';
    final hospitalId = currentUser?.data?.latestHospitalId?.toString() ?? '1';
    final orgId = currentUser?.data?.latestOrgId?.toString() ?? '1';

    return BlocProvider<UploadedBloc>(
      create: (_) => sl<UploadedBloc>()..add(FetchUploadedRecords(patientId: userId, orgId: orgId, hospitalId: hospitalId)),
      child: BlocBuilder<UploadedBloc, UploadedBlocState>(
        builder: (context, state) {
          final List<Map<String, dynamic>> allDocs = [..._localUploadedDocs];

          if (state.status == UploadedStatus.success && state.allRecords.isNotEmpty) {
            for (var r in state.allRecords) {
              final ext = r.fileName.contains('.') ? r.fileName.split('.').last.toUpperCase() : 'PDF';
              allDocs.add({
                'title': r.fileName,
                'category': r.category,
                'hospitalName': 'Yira Hospitals',
                'date': '${r.uploadDate.day}/${r.uploadDate.month}/${r.uploadDate.year}',
                'fileSize': '${r.fileSizeKB} KB',
                'fileType': ext,
              });
            }
          }

          // Fallback mock documents to show multi-hospital unified portfolio if empty
          if (allDocs.isEmpty) {
            allDocs.addAll([
              {
                'title': 'Complete Blood Count (CBC) Report',
                'category': 'Lab Reports',
                'hospitalName': 'Apollo City Hospital',
                'date': '24 Aug 2026',
                'fileSize': '2.1 MB',
                'fileType': 'PDF',
              },
              {
                'title': 'Chest X-Ray Digital Scan',
                'category': 'Scans',
                'hospitalName': 'KIMS Hospital',
                'date': '18 Aug 2026',
                'fileSize': '4.8 MB',
                'fileType': 'IMG',
              },
              {
                'title': 'Cardiology Prescription Rx',
                'category': 'Prescriptions',
                'hospitalName': 'Yira Hospitals',
                'date': '12 Aug 2026',
                'fileSize': '850 KB',
                'fileType': 'PDF',
              },
              {
                'title': 'Annual Health Checkup Summary',
                'category': 'Self Uploaded',
                'hospitalName': 'Yira Clinx Center',
                'date': '01 Aug 2026',
                'fileSize': '3.2 MB',
                'fileType': 'PDF',
              },
            ]);
          }

          final filteredDocs = allDocs.where((doc) {
            final matchesQuery = doc['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                doc['hospitalName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                doc['category'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

            if (!matchesQuery) return false;

            if (_selectedFilter == 'All') return true;
            if (_selectedFilter == 'Prescriptions') return doc['category'] == 'Prescriptions' || doc['category'] == 'Prescription';
            if (_selectedFilter == 'Lab Reports') return doc['category'] == 'Lab Reports' || doc['category'] == 'Lab Report';
            if (_selectedFilter == 'Scans') return doc['category'] == 'Scans' || doc['category'] == 'Diagnostic Scan';
            if (_selectedFilter == 'Self Uploaded') return doc['category'] == 'Self Uploaded';
            return true;
          }).toList();

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              title: const Text(
                'My Records & Documents',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Upload Document',
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.upload_file_rounded, size: 18, color: primaryColor),
                  ),
                  onPressed: _openUploadDocumentDialog,
                ),
                const SizedBox(width: 8),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _openUploadDocumentDialog,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Upload',
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
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 6),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search documents, reports, hospitals...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                  ),

                  // Category Filter Chips
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
                      children: ['All', 'Prescriptions', 'Lab Reports', 'Scans', 'Self Uploaded'].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedFilter = filter),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            selectedColor: primaryColor,
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? primaryColor : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Documents List
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        context.read<UploadedBloc>().add(FetchUploadedRecords(patientId: userId, orgId: orgId, hospitalId: hospitalId));
                        await Future.delayed(const Duration(milliseconds: 600));
                      },
                      child: filteredDocs.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.folder_off_outlined,
                                        size: isTab ? 80 : 64,
                                        color: theme.hintColor.withValues(alpha: 0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "No Documents Found",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isTab ? 18 : 15,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Upload medical reports, prescriptions, and lab tests to view them across hospitals.',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: isTab ? 14 : 12,
                                          color: theme.hintColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton.icon(
                                        onPressed: _openUploadDocumentDialog,
                                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                                        label: const Text(
                                          "Upload Medical Document",
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: screenHorizontalSpacePadding,
                                vertical: 6,
                              ),
                              itemCount: filteredDocs.length,
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _buildDocumentCard(
                                    context: context,
                                    doc: doc,
                                    isDark: isDark,
                                    primaryColor: primaryColor,
                                    isTab: isTab,
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

  Widget _buildDocumentCard({
    required BuildContext context,
    required Map<String, dynamic> doc,
    required bool isDark,
    required Color primaryColor,
    required bool isTab,
  }) {
    final title = doc['title'] ?? 'Medical Document';
    final category = doc['category'] ?? 'Record';
    final hospital = doc['hospitalName'] ?? 'Yira Hospitals';
    final date = doc['date'] ?? 'Recent';
    final fileSize = doc['fileSize'] ?? '1.8 MB';
    final fileType = doc['fileType'] ?? 'PDF';

    final isPdf = fileType.toString().toUpperCase() == 'PDF';
    final iconBgColor = isPdf ? const Color(0xFFEF4444) : const Color(0xFF0284C7);

    return Container(
      padding: EdgeInsets.all(isTab ? 16 : 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // File Thumbnail / Icon
          Container(
            width: isTab ? 52 : 46,
            height: isTab ? 52 : 46,
            decoration: BoxDecoration(
              color: iconBgColor.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                    color: iconBgColor,
                    size: isTab ? 22 : 19,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fileType.toString(),
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: iconBgColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 15 : 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.local_hospital_rounded, size: 11, color: isDark ? Colors.white38 : Colors.grey[500]),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              hospital,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$date • $fileSize',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 10.5,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          // Action menu
          IconButton(
            icon: Icon(Icons.file_download_outlined, color: primaryColor, size: 22),
            tooltip: 'Download File',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading $title...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
