import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/services/medical_report_ai_service.dart';
import 'package:yiraclinics/core/services/permission_helper.dart';
import 'package:yiraclinics/features/presentation/patient/diet/diet_ui.dart';

/// One page photo, or the whole PDF.
class _ReportFile {
  final File file;
  final bool isPdf;
  final int pages;

  const _ReportFile(this.file, {this.isPdf = false, this.pages = 1});
}

/// Upload a medical report as a PDF (up to 10 pages) or as photos of its
/// pages (camera or gallery, up to 10), and optionally read it with AI.
class ReportUploadSheet extends StatefulWidget {
  const ReportUploadSheet({super.key});

  /// Returns the upload result, or null if the patient closed the sheet.
  static Future<ReportUploadResult?> show(BuildContext context) {
    return showModalBottomSheet<ReportUploadResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ReportUploadSheet(),
    );
  }

  @override
  State<ReportUploadSheet> createState() => _ReportUploadSheetState();
}

class _ReportUploadSheetState extends State<ReportUploadSheet> {
  static const int _maxPages = MedicalReportAiService.maxPages;
  static const _categories = ['Lab Report', 'Scan / Imaging', 'Discharge Summary', 'Prescription', 'Insurance Card', 'Other'];

  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final List<_ReportFile> _files = [];
  String _category = 'Lab Report';
  bool _analyze = true;
  bool _picking = false;
  bool _working = false;
  String? _error;

  int get _pageCount => _files.fold(0, (sum, f) => sum + f.pages);
  bool get _hasPdf => _files.any((f) => f.isPdf);
  int get _photosLeft => _maxPages - _pageCount;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setError(String? message) => setState(() => _error = message);

  Future<void> _addFromCamera() async {
    if (!await _canAddPhotos()) return;
    if (!mounted || !await PermissionHelper.ensureCameraPermission(context)) return;
    await _guardPicking(() async {
      final photo = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 92);
      if (photo == null) return;
      final prepared = await MedicalReportAiService.preparePhoto(photo.path);
      setState(() => _files.add(_ReportFile(prepared)));
    });
  }

  Future<void> _addFromGallery() async {
    if (!await _canAddPhotos()) return;
    if (!mounted || !await PermissionHelper.ensurePhotosPermission(context)) return;
    await _guardPicking(() async {
      final left = _photosLeft;
      List<XFile> picked = [];
      try {
        picked = left > 1 ? await ImagePicker().pickMultiImage(imageQuality: 92, limit: left) : [];
      } catch (_) {}
      if (picked.isEmpty) {
        final single = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 92);
        if (single != null) picked = [single];
      }
      if (picked.isEmpty) return;
      if (picked.length > left) {
        _setError('Only $left more page${left == 1 ? '' : 's'} can be added. The first $left were kept.');
        picked = picked.take(left).toList();
      }
      final prepared = <_ReportFile>[];
      for (final p in picked) {
        prepared.add(_ReportFile(await MedicalReportAiService.preparePhoto(p.path)));
      }
      setState(() => _files.addAll(prepared));
    });
  }

  Future<void> _pickPdf() async {
    if (_files.isNotEmpty && !_hasPdf) {
      final replace = await _confirm('Replace photos with a PDF?', 'A report can be one PDF or photos of its pages, not both.');
      if (replace != true) return;
    }
    if (!mounted || !await PermissionHelper.ensureDocumentPermission(context)) return;
    await _guardPicking(() async {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['pdf']);
      final path = result?.files.single.path;
      if (path == null) return;
      final file = File(path);
      if (await file.length() > MedicalReportAiService.maxFileBytes) {
        _setError('This PDF is larger than 10 MB. Try a smaller file.');
        return;
      }
      final pages = await MedicalReportAiService.pdfPageCount(path);
      if (pages != null && pages > _maxPages) {
        _setError('This PDF has $pages pages. Reports can have up to $_maxPages pages.');
        return;
      }
      if (_titleController.text.trim().isEmpty) {
        final name = result!.files.single.name;
        _titleController.text = name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
      }
      setState(() {
        _files
          ..clear()
          ..add(_ReportFile(file, isPdf: true, pages: pages ?? 1));
      });
    });
  }

  Future<bool> _canAddPhotos() async {
    if (_hasPdf) {
      final replace = await _confirm('Replace the PDF with photos?', 'A report can be one PDF or photos of its pages, not both.');
      if (replace != true) return false;
      setState(() => _files.clear());
    }
    if (_photosLeft <= 0) {
      _setError('You can add up to $_maxPages pages.');
      return false;
    }
    return true;
  }

  Future<void> _guardPicking(Future<void> Function() pick) async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      await pick();
    } catch (e) {
      _setError("Couldn't add the file. Please try again.");
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<bool?> _confirm(String title, String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DietUi.card(isDark),
        title: Text(title, style: DietUi.text(16, FontWeight.w700, DietUi.strong(isDark))),
        content: Text(message, style: DietUi.text(13, FontWeight.w400, DietUi.body(isDark), height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Replace')),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_files.isEmpty) {
      _setError('Add a PDF or photos of your report first.');
      return;
    }
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : '$_category ${DateFormat('d MMM yyyy').format(DateTime.now())}';

    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final result = await MedicalReportAiService.uploadReport(
        files: [for (final f in _files) f.file],
        title: title,
        category: _category,
        notes: _notesController.text,
        analyze: _analyze,
      );
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: BoxDecoration(
        color: DietUi.card(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _working
              ? _ProgressView(key: const ValueKey('progress'), isDark: isDark, analyzing: _analyze, pages: _pageCount)
              : SingleChildScrollView(
                  key: const ValueKey('form'),
                  padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + bottomInset),
                  child: _form(isDark),
                ),
        ),
      ),
    );
  }

  Widget _form(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(color: DietUi.line(isDark), borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            DietUi.iconBadge(Icons.upload_file_rounded, DietUi.blue, isDark, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upload medical report', style: DietUi.text(16, FontWeight.w700, DietUi.strong(isDark))),
                  Text(
                    'A PDF or photos of the pages, up to $_maxPages pages',
                    style: DietUi.text(12, FontWeight.w400, DietUi.muted(isDark)),
                  ),
                ],
              ),
            ),
            Material(
              color: DietUi.sunken(isDark),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded, size: 20, color: DietUi.muted(isDark)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Sources
        Row(
          children: [
            _source(isDark, Icons.document_scanner_outlined, _files.isEmpty || _hasPdf ? 'Scan pages' : 'Scan next', _addFromCamera),
            const SizedBox(width: 8),
            _source(isDark, Icons.photo_library_outlined, 'Photos', _addFromGallery),
            const SizedBox(width: 8),
            _source(isDark, Icons.picture_as_pdf_outlined, 'PDF file', _pickPdf),
          ],
        ),
        const SizedBox(height: 12),
        if (_files.isNotEmpty) ...[
          _pagesStrip(isDark),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.layers_outlined, size: 14, color: DietUi.muted(isDark)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _hasPdf
                      ? 'PDF · $_pageCount page${_pageCount == 1 ? '' : 's'}'
                      : '$_pageCount of $_maxPages pages · photos are joined into one report',
                  style: DietUi.text(11.5, FontWeight.w500, DietUi.muted(isDark)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ] else ...[
          DietUi.notice(
            'For best results, photograph each page flat, in good light, with all text visible.',
            DietUi.blue,
            Icons.tips_and_updates_outlined,
            isDark,
          ),
          const SizedBox(height: 14),
        ],

        if (_error != null) ...[
          DietUi.notice(_error!, DietUi.red, Icons.error_outline_rounded, isDark),
          const SizedBox(height: 12),
        ],

        _label('Report name', isDark),
        _field(_titleController, 'e.g. Blood test, Thyroid profile, MRI knee', isDark),
        const SizedBox(height: 14),
        _label('Category', isDark),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in _categories)
              ChoiceChip(
                label: Text(c),
                selected: _category == c,
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => setState(() {
                  _category = c;
                  if (c == 'Insurance Card') _analyze = false;
                }),
                labelStyle: DietUi.text(11.5, _category == c ? FontWeight.w700 : FontWeight.w500, _category == c ? Colors.white : DietUi.body(isDark)),
                selectedColor: DietUi.blue,
                backgroundColor: DietUi.sunken(isDark),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: _category == c ? DietUi.blue : DietUi.line(isDark)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _label('Notes (optional)', isDark),
        _field(_notesController, 'Anything your doctor should know', isDark, lines: 2),
        const SizedBox(height: 16),

        // AI toggle
        InkWell(
          onTap: () => setState(() => _analyze = !_analyze),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            decoration: BoxDecoration(
              color: _analyze ? DietUi.violet.withValues(alpha: isDark ? 0.16 : 0.06) : DietUi.sunken(isDark),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _analyze ? DietUi.violet.withValues(alpha: 0.5) : DietUi.line(isDark)),
            ),
            child: Row(
              children: [
                DietUi.iconBadge(Icons.auto_awesome_rounded, DietUi.violet, isDark, size: 36, iconSize: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Analyse with Yira AI', style: DietUi.text(13.5, FontWeight.w700, DietUi.strong(isDark))),
                      const SizedBox(height: 1),
                      Text(
                        'Plain-language summary, flagged values, urgent alerts and which doctor to see.',
                        style: DietUi.text(11.5, FontWeight.w400, DietUi.muted(isDark), height: 1.35),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _analyze,
                  activeTrackColor: DietUi.violet,
                  onChanged: (v) => setState(() => _analyze = v),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _picking || _files.isEmpty ? null : _submit,
            icon: Icon(_analyze ? Icons.auto_awesome_rounded : Icons.cloud_upload_rounded, size: 18),
            label: Text(_analyze ? 'Upload & analyse' : 'Upload report', style: DietUi.text(14, FontWeight.w700, Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: DietUi.blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: DietUi.blue.withValues(alpha: 0.35),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _source(bool isDark, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: _picking ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: DietUi.sunken(isDark),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DietUi.line(isDark)),
          ),
          child: Column(
            children: [
              Icon(icon, color: DietUi.blue, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DietUi.text(12, FontWeight.w600, DietUi.strong(isDark)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pagesStrip(bool isDark) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _files.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = _files[i];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: f.isPdf ? 150 : 72,
                height: 96,
                decoration: BoxDecoration(
                  color: DietUi.sunken(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DietUi.line(isDark)),
                ),
                clipBehavior: Clip.antiAlias,
                child: f.isPdf
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, color: DietUi.red, size: 26),
                            const SizedBox(height: 6),
                            Text(
                              f.file.path.split('/').last,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: DietUi.text(10.5, FontWeight.w600, DietUi.strong(isDark), height: 1.25),
                            ),
                          ],
                        ),
                      )
                    : Image.file(f.file, fit: BoxFit.cover, cacheWidth: 200),
              ),
              if (!f.isPdf)
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(6)),
                    child: Text('${i + 1}', style: DietUi.text(10, FontWeight.w700, Colors.white)),
                  ),
                ),
              Positioned(
                right: -6,
                top: -6,
                child: InkWell(
                  onTap: () => setState(() {
                    _files.removeAt(i);
                    _error = null;
                  }),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: DietUi.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: DietUi.card(isDark), width: 2),
                    ),
                    child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _label(String text, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: DietUi.text(12.5, FontWeight.w600, DietUi.strong(isDark))),
      );

  Widget _field(TextEditingController controller, String hint, bool isDark, {int lines = 1}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: DietUi.line(isDark)),
    );
    return TextField(
      controller: controller,
      maxLines: lines,
      style: DietUi.text(13, FontWeight.w500, DietUi.strong(isDark)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: DietUi.text(12.5, FontWeight.w400, DietUi.hint(isDark)),
        filled: true,
        fillColor: DietUi.sunken(isDark),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: DietUi.blue, width: 1.4)),
      ),
    );
  }
}

class _ProgressView extends StatefulWidget {
  final bool isDark;
  final bool analyzing;
  final int pages;

  const _ProgressView({super.key, required this.isDark, required this.analyzing, required this.pages});

  @override
  State<_ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<_ProgressView> {
  int _step = 0;
  Timer? _timer;

  List<String> get _steps => widget.analyzing
      ? [
          'Uploading ${widget.pages} page${widget.pages == 1 ? '' : 's'} securely',
          'Reading every page',
          'Checking each value against normal ranges',
          'Looking for anything urgent',
          'Preparing your insights',
        ]
      : ['Uploading ${widget.pages} page${widget.pages == 1 ? '' : 's'} securely', 'Saving to your records'];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3000), (_) {
      if (_step < _steps.length - 1) setState(() => _step++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final color = widget.analyzing ? DietUi.violet : DietUi.blue;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 72, height: 72, child: CircularProgressIndicator(strokeWidth: 3, color: color)),
              DietUi.iconBadge(widget.analyzing ? Icons.auto_awesome_rounded : Icons.cloud_upload_rounded, color, isDark, size: 52, iconSize: 24),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            widget.analyzing ? 'Analysing your report' : 'Uploading your report',
            style: DietUi.text(16, FontWeight.w700, DietUi.strong(isDark)),
          ),
          const SizedBox(height: 4),
          Text(
            widget.analyzing ? 'Usually 10-30 seconds. Please keep the app open.' : 'Just a moment',
            style: DietUi.text(12, FontWeight.w400, DietUi.muted(isDark)),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < _steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: i < _step
                        ? const Icon(Icons.check_circle_rounded, size: 18, color: DietUi.green)
                        : i == _step
                            ? Padding(padding: const EdgeInsets.all(2), child: CircularProgressIndicator(strokeWidth: 2, color: color))
                            : Icon(Icons.radio_button_unchecked_rounded, size: 18, color: DietUi.hint(isDark)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _steps[i],
                      style: DietUi.text(12.5, i <= _step ? FontWeight.w600 : FontWeight.w400, i <= _step ? DietUi.strong(isDark) : DietUi.hint(isDark)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
