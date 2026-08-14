import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/utils/utils.dart';
import 'package:yiraclinics/features/domain/entities/uploaded_record/uploaded_record_entity.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/uploaded_bloc/uploaded_bloc.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/widgets/uploaded_record_card.dart';
import 'package:yiraclinics/features/presentation/upload_documnets/upload_records_screen.dart';
import '../../../core/common_widgets/common_text.dart';

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
  });

  @override
  State<UploadedRecordsScreen> createState() => _UploadedRecordsScreenState();
}

class _UploadedRecordsScreenState extends State<UploadedRecordsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UploadedBloc>().add(FetchUploadedRecords(
          patientId: widget.patientId,
          appointmentId: widget.appointmentId,
          hospitalId: widget.hospitalId,
          orgId: widget.orgId,
        ));
  }

  void _viewDocument(BuildContext context, UploadedRecord record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String url = (record.fileUrl ?? '').trim();
    final String path = (record.filePath ?? '').trim();
    final String target = url.isNotEmpty ? url : path;
    final String lower = (target.isNotEmpty ? target : record.fileName).toLowerCase();

    final bool isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');

    // 1. Direct Image preview if local file exists
    if (isImage && path.isNotEmpty && File(path).existsSync()) {
      showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.black.withValues(alpha: 0.9),
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                maxScale: 4.0,
                child: Image.file(File(path), fit: BoxFit.contain),
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
      return;
    }

    // 2. Direct launch if HTTP Azure Blob URL exists
    if (url.startsWith('http://') || url.startsWith('https://')) {
      Utils.launchURL(url);
      return;
    }

    // 3. Fallback Document Preview Modal (shows file details & action button to view)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? darkModeCardColor : Colors.white,
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
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: primaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.fileName,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.category,
                        style: const TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : const Color(0xFFFAFBFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFEDEFF3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Upload Date", style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: Theme.of(context).hintColor)),
                      Text(DateFormat('MMM dd, yyyy').format(record.uploadDate), style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("File Size", style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: Theme.of(context).hintColor)),
                      Text(
                        record.fileSizeKB >= 1024
                            ? '${(record.fileSizeKB / 1024).toStringAsFixed(1)} MB'
                            : '${record.fileSizeKB} KB',
                        style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(modalContext),
                    child: Text("Close", style: TextStyle(fontFamily: appPoppinFont, color: isDark ? Colors.white70 : Colors.black87)),
                  ),
                ),
                if (target.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 18, color: Colors.white),
                      label: const Text("Open Document", style: TextStyle(fontFamily: appPoppinFont, color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(modalContext);
                        if (target.startsWith('http://') || target.startsWith('https://')) {
                          Utils.launchURL(target);
                        } else {
                          Utils.launchURL('file://$target');
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isTab = isTablet(context);

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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
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
              context.read<UploadedBloc>().add(FetchUploadedRecords(
                    patientId: widget.patientId,
                    appointmentId: widget.appointmentId,
                    hospitalId: widget.hospitalId,
                    orgId: widget.orgId,
                  ));
            }
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          floatingActionButton: FloatingActionButton(
            backgroundColor: primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              context.read<UploadedBloc>().add(UploadRecordScreenNavEvent());
            },
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: screenHorizontalSpacePadding,
              vertical: 0.0,
            ),
            child: Column(
              children: [
                Expanded(child: _buildRecordsList(context, state, isTab)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordsList(
      BuildContext context, UploadedBlocState state, bool isTab) {
    if (state.status == UploadedStatus.loading) {
      return const ListCardShimmer(itemCount: 4);
    }

    if (state.allRecords.isEmpty) {
      return Center(
        child: CommonText(
          "No documents found for this appointment.",
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: displayWidth(context) * (isTab ? 0.018 : 0.035),
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 3.0),
      itemCount: state.allRecords.length,
      itemBuilder: (context, index) {
        final record = state.allRecords[index];
        return UploadedRecordCard(
          record: record,
          isTab: isTab,
          onView: () => _viewDocument(context, record),
          onDelete: () {
            context
                .read<UploadedBloc>()
                .add(DeleteUploadedRecordItem(record.id));
          },
        );
      },
    );
  }
}
