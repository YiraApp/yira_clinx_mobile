import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/utils/utils.dart';
import 'package:yiraclinics/features/domain/entities/medical_report/medical_report_analysis.dart';
import 'package:yiraclinics/features/domain/entities/uploaded_record/uploaded_record_entity.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';
import 'package:yiraclinics/features/presentation/patient_profile/widgets/record_tab_ui.dart';

class UploadedRecordCard extends StatefulWidget {
  final UploadedRecord record;
  final VoidCallback? onDelete;
  final VoidCallback? onView;
  final VoidCallback? onDownload;

  /// Opens the AI insights; the row only shows once the report is analysed.
  final VoidCallback? onAiInsights;
  final bool isTab;

  const UploadedRecordCard({
    super.key,
    required this.record,
    this.onDelete,
    this.onView,
    this.onDownload,
    this.onAiInsights,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RecordCard(
        onTap: widget.onView,
        padding: EdgeInsets.all(widget.isTab ? 16 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RecordCardHeader(
              icon: Icons.description_outlined,
              title: fileName,
              subtitle: [category, ext].where((e) => e.trim().isNotEmpty).join(' · '),
              trailing: _isDownloading
                    ? const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBlue),
                      ),
                    )
                    : PopupMenuButton<String>(
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
            ),

            // YouTube-style Collapsible Description Render
            if (hasDescription) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isDescExpanded = !_isDescExpanded;
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      maxLines: _isDescExpanded ? 20 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: DietUi.text(12, FontWeight.w400, DietUi.body(isDark), height: 1.4),
                    ),
                    if (description.length > 70) ...[
                      const SizedBox(height: 2),
                      Text(
                        _isDescExpanded ? 'Show less' : '...more',
                        style: DietUi.text(11, FontWeight.w600, DietUi.blue),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Upload date, file size, and who added it when a hospital did
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                RecordMeta(
                  icon: Icons.calendar_today_outlined,
                  text: DateFormat('MMM dd, yyyy').format(widget.record.uploadDate),
                ),
                if (fileSizeStr.isNotEmpty) RecordMeta(icon: Icons.data_usage_rounded, text: fileSizeStr),
                if (hospitalName != null) RecordMeta(icon: Icons.local_hospital_outlined, text: hospitalName),
                if (doctorName != null) RecordMeta(icon: Icons.person_outline_rounded, text: doctorName),
              ],
            ),
            if (widget.onAiInsights != null && widget.record.aiStatus != null) ...[
              const SizedBox(height: 10),
              _aiRow(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _aiRow(bool isDark) {
    final ({Color color, IconData icon, String label}) style = switch (reportStatusFrom(widget.record.aiStatus)) {
      ReportStatus.normal => (color: DietUi.green, icon: Icons.verified_rounded, label: 'All clear'),
      ReportStatus.attention => (color: DietUi.amber, icon: Icons.error_outline_rounded, label: 'Needs attention'),
      ReportStatus.critical => (color: DietUi.red, icon: Icons.warning_amber_rounded, label: 'Critical findings'),
      ReportStatus.unknown => (color: DietUi.slate, icon: Icons.help_outline_rounded, label: 'No health insights'),
    };
    return InkWell(
      onTap: widget.onAiInsights,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(style.icon, size: 16, color: style.color),
            const SizedBox(width: 6),
            Text('AI', style: DietUi.text(10.5, FontWeight.w600, DietUi.muted(isDark), spacing: 0.4)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(style.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: DietUi.text(12, FontWeight.w600, style.color)),
            ),
            const RecordCardLink(label: 'View insights'),
          ],
        ),
      ),
    );
  }
}
