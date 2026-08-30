import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/utils/utils.dart';

class InAppDocumentViewer extends StatefulWidget {
  final String title;
  final String category;
  final String? fileUrl;
  final String? filePath;
  final String fileType;
  final String? fileSize;
  final String? hospitalName;
  final String? doctorName;
  final String? date;
  final bool isAppointmentDoc;

  const InAppDocumentViewer({
    super.key,
    required this.title,
    this.category = 'General',
    this.fileUrl,
    this.filePath,
    this.fileType = 'PDF',
    this.fileSize,
    this.hospitalName,
    this.doctorName,
    this.date,
    this.isAppointmentDoc = false,
  });

  static void show(
    BuildContext context, {
    required String title,
    String category = 'General',
    String? fileUrl,
    String? filePath,
    String fileType = 'PDF',
    String? fileSize,
    String? hospitalName,
    String? doctorName,
    String? date,
    bool isAppointmentDoc = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InAppDocumentViewer(
          title: title,
          category: category,
          fileUrl: fileUrl,
          filePath: filePath,
          fileType: fileType,
          fileSize: fileSize,
          hospitalName: hospitalName,
          doctorName: doctorName,
          date: date,
          isAppointmentDoc: isAppointmentDoc,
        ),
      ),
    );
  }

  @override
  State<InAppDocumentViewer> createState() => _InAppDocumentViewerState();
}

class _InAppDocumentViewerState extends State<InAppDocumentViewer> {
  final TransformationController _transformationController = TransformationController();
  final PdfViewerController _pdfController = PdfViewerController();
  double _currentScale = 1.0;
  bool _showInfo = false;
  bool _pdfLoadFailed = false;

  // In-Memory Document Buffer & State
  Uint8List? _documentBytes;
  bool _isLoading = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _detectedAsImage = false;

  static const Color _primaryBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _loadDocumentData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _pdfController.dispose();
    super.dispose();
  }

  String get _effectiveUrl {
    final u = (widget.fileUrl ?? '').trim();
    if (u.isEmpty) return '';
    if (!u.startsWith('http://') && !u.startsWith('https://') && !u.contains('://')) {
      return 'https://$u';
    }
    return u;
  }

  bool get _isImage {
    if (_detectedAsImage) return true;

    final ft = widget.fileType.toUpperCase().trim();
    if (ft == 'PNG' || ft == 'JPG' || ft == 'JPEG' || ft == 'WEBP' || ft == 'GIF' || ft.contains('IMAGE')) {
      return true;
    }
    if (ft == 'PDF' || ft == 'DOC' || ft == 'DOCX') {
      return false;
    }

    final urlWithoutQuery = _effectiveUrl.split('?').first.toLowerCase();
    final pathWithoutQuery = (widget.filePath ?? '').split('?').first.toLowerCase();
    final titleLower = widget.title.split('?').first.toLowerCase();

    final imageExtensions = ['.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp'];
    for (var ext in imageExtensions) {
      if (urlWithoutQuery.endsWith(ext) || pathWithoutQuery.endsWith(ext) || titleLower.endsWith(ext)) {
        return true;
      }
    }
    return false;
  }

  bool get _isPdf {
    if (_isImage) return false;
    return true;
  }

  bool get _hasLocalFile {
    final p = widget.filePath ?? '';
    return p.isNotEmpty && File(p).existsSync();
  }

  bool get _hasRemoteUrl {
    return _effectiveUrl.startsWith('http://') || _effectiveUrl.startsWith('https://');
  }

  Future<void> _loadDocumentData() async {
    // 1. If local file exists, read bytes directly
    if (_hasLocalFile) {
      try {
        final bytes = await File(widget.filePath!).readAsBytes();
        _inspectBytes(bytes);
        if (mounted) {
          setState(() {
            _documentBytes = bytes;
            _isLoading = false;
          });
        }
        return;
      } catch (e) {
        debugPrint('[InAppDocumentViewer] Local file read error: $e');
      }
    }

    // 2. If remote URL exists and is not a simple image, download bytes for resilient in-memory PDF rendering
    if (_hasRemoteUrl) {
      if (_isImage) {
        return;
      }

      setState(() {
        _isLoading = true;
        _downloadProgress = 0.0;
        _pdfLoadFailed = false;
      });

      try {
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 25),
            receiveTimeout: const Duration(seconds: 35),
            responseType: ResponseType.bytes,
            followRedirects: true,
          ),
        );

        final response = await dio.get<List<int>>(
          _effectiveUrl,
          onReceiveProgress: (received, total) {
            if (total > 0 && mounted) {
              setState(() {
                _downloadProgress = (received / total).clamp(0.0, 1.0);
              });
            }
          },
        );

        if (response.data != null && response.data!.isNotEmpty && mounted) {
          final bytes = Uint8List.fromList(response.data!);
          _inspectBytes(bytes);
          setState(() {
            _documentBytes = bytes;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('[InAppDocumentViewer] Dio download error: $e, trying network renderer');
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _inspectBytes(Uint8List bytes) {
    if (bytes.length >= 4) {
      if ((bytes[0] == 0xFF && bytes[1] == 0xD8) ||
          (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) ||
          (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) ||
          (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46)) {
        _detectedAsImage = true;
      }
    }
  }

  void _zoomIn() {
    setState(() {
      _currentScale = (_currentScale * 1.3).clamp(1.0, 5.0);
      _transformationController.value = Matrix4.diagonal3Values(_currentScale, _currentScale, 1.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentScale = (_currentScale / 1.3).clamp(1.0, 5.0);
      _transformationController.value = Matrix4.diagonal3Values(_currentScale, _currentScale, 1.0);
    });
  }

  void _resetZoom() {
    setState(() {
      _currentScale = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  Future<void> _downloadDocument() async {
    if (_isDownloading) return;

    if (!_hasRemoteUrl && !_hasLocalFile) {
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
      String cleanTitle = widget.title.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      if (!cleanTitle.contains('.')) {
        cleanTitle += _isPdf ? '.pdf' : (_isImage ? '.jpg' : '.pdf');
      }
      final savePath = '${dir.path}/$cleanTitle';

      if (_hasRemoteUrl) {
        final dio = Dio();
        await dio.download(
          _effectiveUrl,
          savePath,
          options: Options(responseType: ResponseType.bytes),
        );
      } else if (_hasLocalFile) {
        await File(widget.filePath!).copy(savePath);
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
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
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

  void _openFile() {
    if (_hasRemoteUrl) {
      Utils.launchURL(_effectiveUrl);
    } else if (_hasLocalFile) {
      Utils.launchURL('file://${widget.filePath!}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document URL is not directly available.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    widget.category,
                    style: const TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.fileType.toUpperCase(),
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 10.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Download Document',
            icon: _isDownloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBlue),
                  )
                : Icon(
                    Icons.file_download_outlined,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    size: 22,
                  ),
            onPressed: _isDownloading ? null : _downloadDocument,
          ),
          IconButton(
            tooltip: 'Document Info',
            icon: Icon(
              _showInfo ? Icons.info_rounded : Icons.info_outline_rounded,
              color: _showInfo ? _primaryBlue : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
            onPressed: () => setState(() => _showInfo = !_showInfo),
          ),
          if (_hasRemoteUrl)
            IconButton(
              tooltip: 'Open in Browser',
              icon: Icon(Icons.open_in_new_rounded, color: isDark ? Colors.white70 : const Color(0xFF64748B), size: 20),
              onPressed: _openFile,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Collapsible Document Info Sheet
            if (_showInfo) _buildInfoBanner(isDark),

            // Main Document Content Viewer Area
            Expanded(
              child: _buildContentViewer(isDark),
            ),

            // Bottom Controls Bar (Responsive & Non-overflowing)
            _buildBottomControls(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildContentViewer(bool isDark) {
    try {
      if (_isLoading) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: _primaryBlue),
              const SizedBox(height: 16),
              Text(
                _downloadProgress > 0
                    ? 'Loading document (${(_downloadProgress * 100).toInt()}%)...'
                    : 'Preparing document preview...',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );
      }

      if (_isImage) return _buildImageViewer(isDark);
      if (_isPdf && !_pdfLoadFailed) return _buildPdfViewer(isDark);
      return _buildDocumentFallback(isDark);
    } catch (e) {
      debugPrint('[InAppDocumentViewer] Build error: $e');
      return _buildDocumentFallback(isDark);
    }
  }

  Widget _buildInfoBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.hospitalName != null && widget.hospitalName!.isNotEmpty)
            _buildMetaRow('Hospital', widget.hospitalName!, Icons.local_hospital_rounded, isDark),
          if (widget.doctorName != null && widget.doctorName!.isNotEmpty)
            _buildMetaRow('Doctor', widget.doctorName!, Icons.person_rounded, isDark),
          if (widget.date != null && widget.date!.isNotEmpty)
            _buildMetaRow('Date', widget.date!, Icons.calendar_today_rounded, isDark),
          if (widget.fileSize != null && widget.fileSize!.isNotEmpty)
            _buildMetaRow('File Size', widget.fileSize!, Icons.data_usage_rounded, isDark),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _primaryBlue),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageViewer(bool isDark) {
    if (_documentBytes != null && _documentBytes!.isNotEmpty) {
      return InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 5.0,
        child: Center(
          child: Image.memory(
            _documentBytes!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildDocumentFallback(isDark),
          ),
        ),
      );
    }

    if (_hasLocalFile) {
      return InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 5.0,
        child: Center(
          child: Image.file(
            File(widget.filePath!),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildDocumentFallback(isDark),
          ),
        ),
      );
    }

    if (_hasRemoteUrl) {
      return InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 5.0,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: _effectiveUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: _primaryBlue),
            ),
            errorWidget: (context, url, error) => _buildDocumentFallback(isDark),
          ),
        ),
      );
    }

    return _buildDocumentFallback(isDark);
  }

  Widget _buildPdfViewer(bool isDark) {
    if (_documentBytes != null && _documentBytes!.isNotEmpty) {
      return SfPdfViewer.memory(
        _documentBytes!,
        controller: _pdfController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoadFailed: (details) {
          debugPrint('[InAppDocumentViewer] SfPdfViewer memory load failed: ${details.description}');
          if (mounted) {
            setState(() {
              _pdfLoadFailed = true;
            });
          }
        },
      );
    }

    if (_hasLocalFile) {
      return SfPdfViewer.file(
        File(widget.filePath!),
        controller: _pdfController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoadFailed: (details) {
          debugPrint('[InAppDocumentViewer] SfPdfViewer file load failed: ${details.description}');
          if (mounted) {
            setState(() {
              _pdfLoadFailed = true;
            });
          }
        },
      );
    }

    if (_hasRemoteUrl) {
      return SfPdfViewer.network(
        _effectiveUrl,
        controller: _pdfController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoadFailed: (details) {
          debugPrint('[InAppDocumentViewer] SfPdfViewer network load failed: ${details.description}');
          if (mounted) {
            setState(() {
              _pdfLoadFailed = true;
            });
          }
        },
      );
    }

    return _buildDocumentFallback(isDark);
  }

  Widget _buildDocumentFallback(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insert_drive_file_rounded,
                  size: 48,
                  color: _primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Document Format: ${widget.fileType.toUpperCase()}',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 220,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _downloadDocument,
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: const Text(
                    'Download File',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          if (_isImage) ...[
            IconButton(
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              tooltip: 'Zoom Out',
              icon: const Icon(Icons.zoom_out_rounded, size: 20),
              onPressed: _zoomOut,
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              tooltip: 'Reset Zoom',
              icon: const Icon(Icons.restart_alt_rounded, size: 20),
              onPressed: _resetZoom,
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              tooltip: 'Zoom In',
              icon: const Icon(Icons.zoom_in_rounded, size: 20),
              onPressed: _zoomIn,
            ),
            const Spacer(),
          ] else if (_isPdf && !_pdfLoadFailed) ...[
            IconButton(
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              tooltip: 'Previous Page',
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: () => _pdfController.previousPage(),
            ),
            const SizedBox(width: 4),
            IconButton(
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              tooltip: 'Next Page',
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              onPressed: () => _pdfController.nextPage(),
            ),
            const Spacer(),
          ] else ...[
            const Icon(Icons.cloud_done_rounded, size: 15, color: Color(0xFF10B981)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Cloud Doc',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
          ],
          OutlinedButton.icon(
            onPressed: _downloadDocument,
            icon: _isDownloading
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBlue),
                  )
                : const Icon(Icons.file_download_outlined, size: 14),
            label: const Text(
              'Download',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryBlue,
              side: const BorderSide(color: _primaryBlue, width: 1),
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton.icon(
            onPressed: _openFile,
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: Text(
              _isImage ? 'Original' : 'Browser',
              style: const TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
