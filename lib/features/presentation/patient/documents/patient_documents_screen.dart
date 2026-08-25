import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class _PatientDocumentsScreenState extends State<PatientDocumentsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _documents = [];

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openUploadDocumentDialog() {
    final titleController = TextEditingController();
    String category = 'Self';
    String tags = '';

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
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upload Medical Document',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),

                  // Title Field
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

                  // Category Selection
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
                    items: ['Self', 'General', 'Appointments']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13))))
                        .toList(),
                    onChanged: (val) => setModalState(() => category = val!),
                  ),
                  const SizedBox(height: 14),

                  // Mock File Picker Dropzone
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryColor.withOpacity(0.3), style: BorderStyle.solid),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload_rounded, color: primaryColor, size: 36),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap to select medical PDF or image files (Up to 25MB)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Upload Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        if (titleController.text.trim().isNotEmpty) {
                          setState(() {
                            _documents.insert(0, {
                              'id': DateTime.now().millisecondsSinceEpoch.toString(),
                              'title': titleController.text.trim(),
                              'category': category,
                              'hospital': 'Self Uploaded Document',
                              'date': 'Today',
                              'fileSize': '3.2 MB',
                              'fileType': 'PDF',
                              'tags': 'Self Upload',
                              'isSelf': true,
                            });
                          });
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Medical document uploaded successfully!')),
                        );
                      },
                      child: const Text('Upload Document', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, color: Colors.white)),
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
    final currentUser = GlobalSession.instance.userNotifier.value;
    final userId = currentUser?.data?.id ?? '';

    return BlocProvider<UploadedBloc>(
      create: (_) => sl<UploadedBloc>()..add(FetchUploadedRecords(patientId: userId)),
      child: BlocBuilder<UploadedBloc, UploadedBlocState>(
        builder: (context, state) {
          if ((state.status == UploadedStatus.initial || state.status == UploadedStatus.loading) && state.allRecords.isEmpty) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                elevation: 0,
                backgroundColor: theme.scaffoldBackgroundColor,
                title: const Text('My Documents', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold)),
              ),
              body: ListView.builder(
                padding: const EdgeInsets.all(screenHorizontalSpacePadding),
                itemCount: 4,
                itemBuilder: (_, __) => const AppointmentCardShimmer(),
              ),
            );
          }

          List<Map<String, dynamic>> currentList = state.allRecords.map((r) => {
            'id': r.id,
            'title': r.fileName,
            'category': r.category.isEmpty ? 'General' : r.category,
            'hospital': '🏥 Yira Health Network',
            'date': '${r.uploadDate.day}/${r.uploadDate.month}/${r.uploadDate.year}',
            'fileSize': '${(r.fileSizeKB / 1024).toStringAsFixed(1)} MB',
            'fileType': r.fileName.contains('.') ? r.fileName.split('.').last.toUpperCase() : 'PDF',
            'fileUrl': r.fileUrl,
            'tags': r.category,
            'isSelf': r.category.toLowerCase().contains('self'),
          }).toList();

          List<Map<String, dynamic>> filteredList = currentList.where((doc) {
            final matchesSearch = doc['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                doc['hospital'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                doc['tags'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesSearch;
          }).toList();

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              title: const Text(
                'My Documents',
                style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    icon: Icon(Icons.upload_file_rounded, color: primaryColor, size: 26),
                    onPressed: _openUploadDocumentDialog,
                  ),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: isDark ? Colors.white60 : Colors.grey[600],
                indicatorColor: primaryColor,
                labelStyle: const TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Appointments'),
                  Tab(text: 'General'),
                  Tab(text: 'Self'),
                ],
              ),
            ),
            body: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(screenHorizontalSpacePadding),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search documents by title, hospital, or tags...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // Documents List Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDocumentListView(context, userId, filteredList),
                      _buildDocumentListView(context, userId, filteredList.where((d) => d['category'] == 'Appointments').toList()),
                      _buildDocumentListView(context, userId, filteredList.where((d) => d['category'] == 'General').toList()),
                      _buildDocumentListView(context, userId, filteredList.where((d) => d['category'] == 'Self').toList()),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'fab_patient_documents',
              backgroundColor: primaryColor,
              onPressed: _openUploadDocumentDialog,
              icon: const Icon(Icons.file_upload_outlined, color: Colors.white),
              label: const Text('Upload Document', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentListView(BuildContext context, String userId, List<Map<String, dynamic>> items) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<UploadedBloc>().add(FetchUploadedRecords(patientId: userId));
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text('No medical documents found.', style: TextStyle(fontFamily: appPoppinFont, color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding, vertical: 8),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildDocumentCard(item),
                );
              },
            ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final bool isSelf = item['isSelf'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
        ),
      ),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Title + Attribution Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['fileType'] == 'PDF' ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🏥 ${item['hospital']}',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Details & Action Buttons Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item['date']} • ${item['fileSize']}',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: isDark ? Colors.white54 : Colors.grey[600]),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening preview for ${item['title']}')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.download_rounded, size: 18),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Downloading ${item['title']}...')),
                          );
                        },
                      ),
                      if (isSelf)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _documents.removeWhere((d) => d['id'] == item['id']);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Document deleted.')),
                            );
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
  }
}
