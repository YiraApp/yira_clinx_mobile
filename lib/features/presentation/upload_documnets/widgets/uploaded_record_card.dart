import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/utils/utils.dart';
import 'package:yiraclinics/features/domain/entities/uploaded_record/uploaded_record_entity.dart';

class UploadedRecordCard extends StatefulWidget {
  final UploadedRecord record;
  final VoidCallback? onDelete;
  final VoidCallback? onView;
  final VoidCallback? onDownload;
  final bool isTab;

  const UploadedRecordCard({
    super.key,
    required this.record,
    this.onDelete,
    this.onView,
    this.onDownload,
    required this.isTab,
  });

  @override
  State<UploadedRecordCard> createState() => _UploadedRecordCardState();
}

class _UploadedRecordCardState extends State<UploadedRecordCard> {
  bool _isDescExpanded = false;
  bool _isDownloading = false;

  static const Color _primaryBlue = Color(0xFF2563EB);

  Future<void> _handleDownload() async {
    if (widget.onDownload != null) {
      widget.onDownload!();
      return;
    }

    final fileUrl = (widget.record.fileUrl ?? '').trim();
    final filePath = (widget.record.filePath ?? '').trim();
    final title = widget.record.fileName;
    final ext = (widget.record.fileType ?? (title.contains('.') ? title.split('.').last : 'PDF')).toLowerCase();

    if (fileUrl.isEmpty && filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document file is not available to download directly.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

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
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fileName = widget.record.fileName;
    final category = widget.record.category;
    final ext = (widget.record.fileType ??
            (fileName.contains('.') ? fileName.split('.').last : 'PDF'))
        .toUpperCase();

    final hasDescription = widget.record.description != null &&
        widget.record.description!.trim().isNotEmpty;
    final description = widget.record.description?.trim() ?? '';

    // Check if hospital added this document vs self upload
    final isHospitalAdded = !widget.record.isPatientUploaded &&
        widget.record.hospitalName != null &&
        widget.record.hospitalName!.trim().isNotEmpty;
    final hospitalName = isHospitalAdded ? widget.record.hospitalName!.trim() : null;
    final doctorName = isHospitalAdded &&
            widget.record.doctorName != null &&
            widget.record.doctorName!.trim().isNotEmpty
        ? widget.record.doctorName!.trim()
        : null;

    final fileSizeStr = widget.record.fileSizeKB > 0
        ? (widget.record.fileSizeKB >= 1024
            ? '${(widget.record.fileSizeKB / 1024).toStringAsFixed(1)} MB'
            : '${widget.record.fileSizeKB} KB')
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onView,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(widget.isTab ? 16 : 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : const Color(0xFF64748B).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Simple Unified Icon + Title + Category Badge + 3 DOTS MENU
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: widget.isTab ? 42 : 38,
                    height: widget.isTab ? 42 : 38,
                    decoration: BoxDecoration(
                      color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.description_outlined,
                        color: _primaryBlue,
                        size: widget.isTab ? 22 : 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: widget.isTab ? 14.5 : 13.5,
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
                              ),
                            ),
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
                              ext,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ─── 3 DOTS MENU (VIEW, DOWNLOAD, DELETE) ───
                  if (_isDownloading)
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
                        if (action == 'view' && widget.onView != null) {
                          widget.onView!();
                        } else if (action == 'download') {
                          _handleDownload();
                        } else if (action == 'delete' && widget.onDelete != null) {
                          widget.onDelete!();
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
                        if (widget.onDelete != null)
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

              // YouTube-style Collapsible Description Render
              if (hasDescription) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDescExpanded = !_isDescExpanded;
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
                          maxLines: _isDescExpanded ? 20 : 2,
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
                            _isDescExpanded ? 'Show less' : '...more',
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

              const SizedBox(height: 6),

              // Metadata Row (Upload Date, File Size, Doctor if hospital-added)
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, yyyy').format(widget.record.uploadDate),
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 10.5,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  if (fileSizeStr.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.data_usage_rounded,
                          size: 11,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fileSizeStr,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 10.5,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  if (isHospitalAdded && doctorName != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 11,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctorName,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}