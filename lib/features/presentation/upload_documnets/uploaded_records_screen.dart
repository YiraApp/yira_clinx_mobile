import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/domain/entities/uploaded_record/uploaded_record_entity.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/widgets/uploaded_record_card.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/upload_records_screen.dart';
import '../../../core/common_widgets/in_app_document_viewer.dart';

class UploadedRecordsScreen extends StatefulWidget {
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;

  const UploadedRecordsScreen({
    super.key,
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
    this.allowAdd = true,
  });

  final bool allowAdd;

  @override
  State<UploadedRecordsScreen> createState() => _UploadedRecordsScreenState();
}

class _UploadedRecordsScreenState extends State<UploadedRecordsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'Lab Report',
    'Prescription',
    'Imaging / Radiology',
    'Discharge Summary',
    'General',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialRecords();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchInitialRecords() {
    context.read<UploadedBloc>().add(FetchUploadedRecords(
          patientId: widget.patientId,
          appointmentId: widget.appointmentId,
          hospitalId: widget.hospitalId,
          orgId: widget.orgId,
          limit: 15,
          page: 1,
        ));
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 250) {
      final state = context.read<UploadedBloc>().state;
      if (state.hasMore && !state.isLoadingMore && state.status == UploadedStatus.success) {
        context.read<UploadedBloc>().add(LoadMoreUploadedRecords(
              patientId: widget.patientId,
              appointmentId: widget.appointmentId,
              hospitalId: widget.hospitalId,
              orgId: widget.orgId,
              limit: 15,
            ));
      }
    }
  }

  void _viewDocument(BuildContext context, UploadedRecord record) {
    final String url = (record.fileUrl ?? '').trim();
    final String path = (record.filePath ?? '').trim();
    final ext = (record.fileType ??
            (record.fileName.contains('.') ? record.fileName.split('.').last : 'PDF'))
        .toUpperCase();

    final fileSizeStr = record.fileSizeKB > 0
        ? (record.fileSizeKB >= 1024
            ? '${(record.fileSizeKB / 1024).toStringAsFixed(1)} MB'
            : '${record.fileSizeKB} KB')
        : '';

    InAppDocumentViewer.show(
      context,
      title: record.fileName,
      category: record.category,
      fileUrl: url.isNotEmpty ? url : null,
      filePath: path.isNotEmpty ? path : null,
      fileType: ext,
      fileSize: fileSizeStr.isNotEmpty ? fileSizeStr : null,
      date: DateFormat('MMM dd, yyyy').format(record.uploadDate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    return BlocConsumer<UploadedBloc, UploadedBlocState>(
      buildWhen: (previous, current) => current is! UploadRecordScreenNavState,
      listener: (context, state) {
        if (state is UploadRecordScreenNavState) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => FractionallySizedBox(
              heightFactor: 0.9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: BlocProvider<UploadedBloc>.value(
                  value: context.read<UploadedBloc>(),
                  child: Scaffold(
                    body: UploadDocumentsScreen(
                      patientName: 'Patient Documents',
                      patientId: widget.patientId,
                      appointmentId: widget.appointmentId,
                      hospitalId: widget.hospitalId,
                      orgId: widget.orgId,
                    ),
                  ),
                ),
              ),
            ),
          ).then((_) {
            if (context.mounted) {
              _fetchInitialRecords();
            }
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          floatingActionButton: !widget.allowAdd
              ? null
              : FloatingActionButton.extended(
                  backgroundColor: primaryColor,
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
                  onPressed: () {
                    context.read<UploadedBloc>().add(UploadRecordScreenNavEvent());
                  },
                ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // 1. Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    context.read<UploadedBloc>().add(SearchQueryChanged(val));
                  },
                  decoration: InputDecoration(
                    hintText: 'Search documents by name, category, or note...',
                    hintStyle: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12.5,
                      color: isDark ? Colors.white38 : Colors.grey[400],
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              context.read<UploadedBloc>().add(SearchQueryChanged(''));
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Category Filter Pills
                SizedBox(
                  height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _categories.length,
                    itemBuilder: (context, idx) {
                      final cat = _categories[idx];
                      final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedCategory = cat);
                              context.read<UploadedBloc>().add(FilterCategoryChanged(cat));
                            }
                          },
                          labelStyle: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                          selectedColor: primaryColor,
                          backgroundColor:
                              isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? primaryColor
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
                const SizedBox(height: 10),

                // 3. Document List with YouTube-style Pagination
                Expanded(child: _buildRecordsList(context, state, isTab, isDark)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordsList(
    BuildContext context,
    UploadedBlocState state,
    bool isTab,
    bool isDark,
  ) {
    if (state.status == UploadedStatus.loading) {
      return UploadedRecordListShimmer(itemCount: 4, isTab: isTab);
    }

    final records = state.filteredRecords;

    if (records.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          _fetchInitialRecords();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      size: 34,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.searchQuery.isNotEmpty
                        ? 'No Matching Documents'
                        : 'No Documents Uploaded',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.searchQuery.isNotEmpty
                        ? 'Try clearing your search or category filter.'
                        : 'Tap the button below to upload lab reports, scan files, or prescriptions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final int totalCount = records.length + (state.isLoadingMore ? 1 : (state.hasMore ? 0 : 1));

    return RefreshIndicator(
      onRefresh: () async {
        _fetchInitialRecords();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4.0, bottom: 80.0),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          if (index < records.length) {
            final record = records[index];
            return UploadedRecordCard(
              record: record,
              isTab: isTab,
              onView: () => _viewDocument(context, record),
              onDelete: widget.allowAdd
                  ? () {
                      context.read<UploadedBloc>().add(DeleteUploadedRecordItem(record.id));
                    }
                  : null,
            );
          }

          // YouTube-style bottom loading or end-of-list footer
          if (state.isLoadingMore) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Loading more records...',
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
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            child: Text(
              '• All ${records.length} documents loaded •',
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
    );
  }
}
