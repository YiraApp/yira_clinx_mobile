import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/services/gemini_analysis_service.dart';
import 'package:yiraclinics/core/services/permission_helper.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/prescription_analysis_result.dart';

/// Bottom sheet that lets the user pick/capture a prescription image or PDF (up to 2 pages),
/// sends it to Gemini AI for analysis, and returns the extracted result directly to the form.
///
/// Returns a [ScanResult] containing both the analysis result and the
/// scanned file, or `null` if cancelled.
class ScanPrescriptionSheet extends StatefulWidget {
  const ScanPrescriptionSheet({super.key});

  /// Shows the enhanced sheet and returns the scan result, or `null` if dismissed.
  static Future<ScanResult?> show(BuildContext context) {
    return showModalBottomSheet<ScanResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ScanPrescriptionSheet(),
    );
  }

  @override
  State<ScanPrescriptionSheet> createState() => _ScanPrescriptionSheetState();
}

class _ScanPrescriptionSheetState extends State<ScanPrescriptionSheet>
    with TickerProviderStateMixin {
  _SheetState _state = _SheetState.pickSource;
  String _statusText = 'Reading your prescription...';
  String? _errorMessage;
  bool _isPdf = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _rotationController;
  Timer? _statusTimer;
  int _statusStep = 0;

  static const List<String> _imageScanSteps = [
    'Reading prescription document...',
    'Scanning handwriting & Rx details...',
    'Extracting medicines, dosages & timings...',
    'Finalizing details for form auto-fill...',
  ];

  static const List<String> _pdfScanSteps = [
    'Reading PDF document (up to 2 pages)...',
    'Analyzing prescription pages & doctor details...',
    'Extracting medicines, frequency & instructions...',
    'Consolidating all pages for form auto-fill...',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _startStatusProgression(bool isPdf) {
    _statusTimer?.cancel();
    _statusStep = 0;
    final steps = isPdf ? _pdfScanSteps : _imageScanSteps;
    _statusText = steps[0];

    _statusTimer = Timer.periodic(const Duration(milliseconds: 1600), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_statusStep < steps.length - 1) {
        setState(() {
          _statusStep++;
          _statusText = steps[_statusStep];
        });
      }
    });
  }

  // ── Source Pickers ──

  Future<void> _pickFromCamera() async {
    final hasPermission = await PermissionHelper.ensureCameraPermission(context);
    if (!hasPermission || !mounted) return;

    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
      );
      if (photo != null) {
        _isPdf = false;
        _analyzeFile(File(photo.path));
      }
    } catch (e) {
      debugPrint('[ScanSheet] Camera error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final hasPermission = await PermissionHelper.ensurePhotosPermission(context);
    if (!hasPermission || !mounted) return;

    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (photo != null) {
        _isPdf = false;
        _analyzeFile(File(photo.path));
      }
    } catch (e) {
      debugPrint('[ScanSheet] Gallery error: $e');
    }
  }

  Future<void> _pickPdf() async {
    final hasPermission = await PermissionHelper.ensureDocumentPermission(context);
    if (!hasPermission || !mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        _isPdf = true;
        _analyzeFile(File(result.files.first.path!));
      }
    } catch (e) {
      debugPrint('[ScanSheet] File picker error: $e');
    }
  }

  // ── Analysis ──

  Future<void> _analyzeFile(File file) async {
    if (!mounted) return;

    setState(() {
      _state = _SheetState.analyzing;
      _errorMessage = null;
    });

    _startStatusProgression(_isPdf);
    HapticFeedback.mediumImpact();

    try {
      final result = await GeminiAnalysisService.analyze(file);

      if (!mounted) return;

      if (!result.hasData) {
        _statusTimer?.cancel();
        setState(() {
          _state = _SheetState.error;
          _errorMessage =
              'Could not detect any clear prescription information.\nPlease try a clearer photo or PDF.';
        });
        return;
      }

      _statusTimer?.cancel();
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(ScanResult(result: result, scannedFile: file));
    } on GeminiAnalysisException catch (e) {
      if (!mounted) return;
      _statusTimer?.cancel();
      setState(() {
        _state = _SheetState.error;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      _statusTimer?.cancel();
      setState(() {
        _state = _SheetState.error;
        _errorMessage = 'Something went wrong while analyzing. Please try again.';
      });
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF131722) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOutCubic,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag pill
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                if (_state == _SheetState.pickSource) _buildPickSource(isDark),
                if (_state == _SheetState.analyzing) _buildAnalyzing(isDark),
                if (_state == _SheetState.error) _buildError(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Pick Source View ──

  Widget _buildPickSource(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row with Title and Close Button
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    const Color(0xFF6366F1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Scan Prescription',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(isDark ? 0.25 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'AI AUTO-FILL',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'AI reads your prescription and auto-fills the form for instant editing',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),

        // Camera Card
        _buildEnhancedOption(
          gradientColors: [const Color(0xFF0284C7), const Color(0xFF0EA5E9)],
          icon: Icons.camera_alt_rounded,
          title: 'Take Photo',
          subtitle: 'Capture physical paper prescription',
          badgeText: 'Instant OCR',
          isDark: isDark,
          onTap: _pickFromCamera,
        ),
        const SizedBox(height: 12),

        // Gallery Card
        _buildEnhancedOption(
          gradientColors: [const Color(0xFF7C3AED), const Color(0xFF9333EA)],
          icon: Icons.photo_library_rounded,
          title: 'Choose from Gallery',
          subtitle: 'Upload prescription photo from your device',
          badgeText: 'Images',
          isDark: isDark,
          onTap: _pickFromGallery,
        ),
        const SizedBox(height: 12),

        // PDF Card (Highlights 2 pages support)
        _buildEnhancedOption(
          gradientColors: [const Color(0xFFE11D48), const Color(0xFFF43F5E)],
          icon: Icons.picture_as_pdf_rounded,
          title: 'Upload PDF Document',
          subtitle: 'E-prescription or clinical discharge summary',
          badgeText: 'Supports up to 2 pages',
          badgeColor: const Color(0xFF0284C7),
          isDark: isDark,
          onTap: _pickPdf,
        ),
        const SizedBox(height: 18),

        // Security and edit note
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2232) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.security_rounded,
                size: 16,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your data is processed securely. You can review and edit all fields directly on the form before saving.',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 11,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildEnhancedOption({
    required List<Color> gradientColors,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    Color? badgeColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1B2232) : Colors.white;
    final effectiveBadgeColor = badgeColor ?? gradientColors.first;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: gradientColors.first.withOpacity(0.12),
        highlightColor: gradientColors.first.withOpacity(0.06),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Vibrant Gradient Icon Box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: effectiveBadgeColor.withOpacity(isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: effectiveBadgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 11.5,
                        color: isDark ? Colors.white38 : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Analyzing View (Enhanced AI Scanner) ──

  Widget _buildAnalyzing(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 14),

        // Glowing Animated Radar Scanner
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer radar pulse
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryColor.withOpacity(isDark ? 0.35 : 0.2),
                        primaryColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Rotating gradient ring
              RotationTransition(
                turns: _rotationController,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        primaryColor.withOpacity(0.0),
                        primaryColor,
                        const Color(0xFF6366F1),
                        primaryColor.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),
              ),

              // Center icon core
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2638) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isPdf ? Icons.picture_as_pdf_rounded : Icons.document_scanner_rounded,
                    size: 32,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Title
        Text(
          'Analyzing Prescription',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),

        // Document Type Indicator Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(isDark ? 0.2 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withOpacity(0.2),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                size: 13,
                color: primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                _isPdf ? 'PDF Document (Up to 2 pages)' : 'Prescription Photo',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Dynamic Animated Step Text
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.2),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            _statusText,
            key: ValueKey<String>(_statusText),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ),

        const SizedBox(height: 22),

        // Sleek Gradient Progress Bar
        SizedBox(
          width: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              color: primaryColor,
              minHeight: 4,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Auto-fills your form in seconds...',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 11,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // ── Error View ──

  Widget _buildError(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.error_outline_rounded,
              size: 34,
              color: Color(0xFFEF4444),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Analysis Failed',
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _errorMessage ?? 'Could not process the prescription.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Helpful Tips Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2232) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Helpful Tips:',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
              _buildBulletTip('Ensure prescription is flat, well-lit and in focus', isDark),
              _buildBulletTip('PDFs support up to 2 pages of clinical data', isDark),
              _buildBulletTip('You can always enter or edit details manually', isDark),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : const Color(0xFF475569),
                  side: BorderSide(
                    color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Enter Manually',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _state = _SheetState.pickSource;
                    _errorMessage = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildBulletTip(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 11,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _SheetState { pickSource, analyzing, error }

/// Result returned by the scan sheet containing both the AI extraction
/// and the physical file (to attach with the prescription).
class ScanResult {
  final PrescriptionAnalysisResult result;
  final File scannedFile;

  const ScanResult({required this.result, required this.scannedFile});
}
