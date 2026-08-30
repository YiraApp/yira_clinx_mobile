import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/di/dependency_injection.dart';

class ScanDoctorQrSheet extends StatefulWidget {
  final Function(Map<String, dynamic> linkedDoctor)? onDoctorLinked;

  const ScanDoctorQrSheet({super.key, this.onDoctorLinked});

  static Future<void> show(BuildContext context, {Function(Map<String, dynamic> linkedDoctor)? onDoctorLinked}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ScanDoctorQrSheet(onDoctorLinked: onDoctorLinked),
      ),
    );
  }

  @override
  State<ScanDoctorQrSheet> createState() => _ScanDoctorQrSheetState();
}

class _ScanDoctorQrSheetState extends State<ScanDoctorQrSheet> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _laserAnimController;
  late final Animation<double> _laserAnimation;
  late final MobileScannerController _scannerController;
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isTorchOn = false;
  bool _hasDetected = false;
  bool _hasCameraPermission = true;
  bool _cameraPermissionDenied = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestCameraPermission();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _cameraPermissionDenied = false;
        _hasCameraPermission = true;
      });
      _checkAndRequestCameraPermission();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _laserAnimController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRequestCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      if (status.isDenied) {
        final newStatus = await Permission.camera.request();
        if (newStatus.isGranted || newStatus.isLimited) {
          if (mounted) {
            setState(() {
              _hasCameraPermission = true;
              _cameraPermissionDenied = false;
            });
            try {
              await _scannerController.start();
            } catch (_) {}
          }
        }
      } else if (status.isGranted || status.isLimited) {
        if (mounted) {
          setState(() {
            _hasCameraPermission = true;
            _cameraPermissionDenied = false;
          });
          try {
            await _scannerController.start();
          } catch (_) {}
        }
      } else {
        // Fallback: try starting native camera directly in case permission_handler returned a false negative
        try {
          await _scannerController.start();
        } catch (_) {}
      }
    } catch (_) {
      try {
        await _scannerController.start();
      } catch (_) {}
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final barcodeCapture = await _scannerController.analyzeImage(image.path);
        if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
          final raw = barcodeCapture.barcodes.first.rawValue;
          if (raw != null && raw.isNotEmpty) {
            await _processDoctorIdentifier(raw);
            return;
          }
        }
        setState(() {
          _errorMessage = 'Could not detect a valid QR code in this image.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to scan image from gallery.';
      });
    }
  }

  Future<void> _processDoctorIdentifier(String input) async {
    if (_hasDetected || _isLoading) return;
    
    final raw = input.trim();
    if (raw.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter or scan a valid Doctor QR URL or ID';
      });
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _hasDetected = true;
      _errorMessage = null;
    });

    String cleanDoctorId = raw;
    if (cleanDoctorId.contains('/doctor/')) {
      cleanDoctorId = cleanDoctorId.split('/doctor/')[1].split('?')[0].split('/')[0].trim();
    }
    cleanDoctorId = cleanDoctorId.replaceAll(RegExp(r'^[/#]+|[/#]+$'), '');

    final currentUser = GlobalSession.instance.userNotifier.value;
    final token = currentUser?.data?.accessToken ?? '';
    final orgId = currentUser?.data?.latestOrgId ?? 9;
    final hospitalId = currentUser?.data?.latestHospitalId ?? 11;

    try {
      final response = await sl<ApiClient>().account(showSuccessSnack: false).post(
        '/v1/api/auth/provider/profile',
        data: {
          "doctorId": cleanDoctorId,
          "hospitalId": hospitalId,
          "orgId": orgId,
        },
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        final docData = resData['data'] is Map<String, dynamic> ? resData['data'] : (resData is Map<String, dynamic> ? resData : null);

        if (docData != null) {
          final doctorUserId = (docData['userId'] ?? docData['doctorId'] ?? cleanDoctorId).toString().trim();
          final doctorHospId = (docData['hospitalId'] != null && docData['hospitalId'] != 0) ? docData['hospitalId'] : hospitalId;
          final doctorOrgId = (docData['orgId'] != null && docData['orgId'] != 0) ? docData['orgId'] : orgId;

          final photoUrl = (docData['imagePath'] ?? docData['ImagePath'] ?? docData['photoUrl'] ?? docData['photo'] ?? docData['profilePicture'] ?? docData['profilePhoto'] ?? docData['avatar'] ?? '').toString().trim();

          final realDoctor = {
            'id': doctorUserId,
            'doctorId': doctorUserId,
            'name': docData['displayName'] ?? docData['name'] ?? 'Dr. ${docData['firstName'] ?? ''} ${docData['lastName'] ?? ''}'.trim(),
            'specialty': docData['specialty'] ?? 'Specialist',
            'department': docData['department'] ?? 'General Outpatient',
            'hospitalName': docData['hospitalName'] ?? 'Yira Clinx Medical Center',
            'hospitalId': doctorHospId,
            'orgId': doctorOrgId,
            'qualification': docData['qualification'] ?? 'MBBS',
            'experience': docData['experience'] ?? '',
            'consultationFee': docData['consultationFee'] ?? 500,
            'phoneNumber': docData['phoneNumber'] ?? docData['phone'] ?? '',
            'email': docData['email'] ?? '',
            'imagePath': photoUrl,
            'photo': photoUrl,
            'isLinked': true,
            'linkedAt': DateTime.now().toIso8601String(),
          };

          await _saveDoctorLocally(realDoctor);



          if (widget.onDoctorLinked != null) {
            widget.onDoctorLinked!(realDoctor);
          }
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF059669),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Connected with ${realDoctor['name']} successfully!',
                        style: const TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return;
        }
      }

      setState(() {
        _hasDetected = false;
        _errorMessage = 'Doctor not found in clinic records. Please verify the QR code.';
      });
    } catch (e) {
      setState(() {
        _hasDetected = false;
        _errorMessage = 'Could not find doctor with this ID or QR. Please check the code.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveDoctorLocally(Map<String, dynamic> doctor) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final patientId = (currentUser?.data?.id ?? '').toString().trim();
      final linkedStorageKey = patientId.isNotEmpty ? 'patient_linked_doctors_$patientId' : 'patient_linked_doctors';
      final unlinkedStorageKey = patientId.isNotEmpty ? 'patient_unlinked_doctors_$patientId' : 'patient_unlinked_doctors';

      final prefs = await SharedPreferences.getInstance();
      final existingStr = prefs.getString(linkedStorageKey) ?? '[]';
      final List<dynamic> list = jsonDecode(existingStr);
      list.removeWhere((item) => item['doctorId'] == doctor['doctorId'] || item['id'] == doctor['id']);
      list.insert(0, doctor);
      await prefs.setString(linkedStorageKey, jsonEncode(list));

      // Remove from user's unlinked blacklist so re-scanned doctor displays properly
      final unlinkedList = prefs.getStringList(unlinkedStorageKey) ?? [];
      final docId = (doctor['doctorId'] ?? doctor['id'] ?? '').toString().trim();
      final docName = (doctor['name'] ?? '').toString().trim();
      unlinkedList.removeWhere((item) => item == docId || item == docName);
      await prefs.setStringList(unlinkedStorageKey, unlinkedList);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final size = MediaQuery.of(context).size;
    final scanBoxSize = (size.width * 0.72).clamp(230.0, 290.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Live Camera Preview
          if (!_cameraPermissionDenied)
            MobileScanner(
              controller: _scannerController,
              errorBuilder: (context, error) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_cameraPermissionDenied) {
                    setState(() {
                      _cameraPermissionDenied = true;
                      _hasCameraPermission = false;
                    });
                  }
                });
                return _buildPermissionWidget(primaryColor);
              },
              onDetect: (BarcodeCapture capture) {
                if (_hasDetected || _isLoading) return;
                for (final barcode in capture.barcodes) {
                  final rawValue = barcode.rawValue;
                  if (rawValue != null && rawValue.isNotEmpty) {
                    _processDoctorIdentifier(rawValue);
                    break;
                  }
                }
              },
            )
          else
            _buildPermissionWidget(primaryColor),

          // 2. Semi-Transparent Dark Cutout Overlay
          if (_hasCameraPermission)
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.65),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: scanBoxSize,
                      height: scanBoxSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 3. Viewfinder Target Frame & Laser Line
          if (_hasCameraPermission)
            Center(
              child: SizedBox(
                width: scanBoxSize,
                height: scanBoxSize,
                child: Stack(
                  children: [
                    // Corner Frame Bounding Box
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: primaryColor,
                          width: 3.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // Animated Laser Scanning Line
                    AnimatedBuilder(
                      animation: _laserAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: 15 + (_laserAnimation.value * (scanBoxSize - 30)),
                          left: 12,
                          right: 12,
                          child: Container(
                            height: 3.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withValues(alpha: 0.1),
                                  primaryColor,
                                  primaryColor.withValues(alpha: 0.1),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor,
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          // 4. Top Navigation Bar: Close, Title, Flashlight
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Scan Doctor QR',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_hasCameraPermission)
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: _isTorchOn ? primaryColor : Colors.black.withValues(alpha: 0.5),
                      ),
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () async {
                        await _scannerController.toggleTorch();
                        setState(() {
                          _isTorchOn = !_isTorchOn;
                        });
                      },
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // 5. Bottom Instructions & Action Buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.95),
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Text(
                      'Align Doctor\'s QR code within frame to scan automatically',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Quick Action Button: Gallery Scan
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library_rounded, size: 18, color: Colors.white),
                        label: const Text(
                          'Upload QR from Gallery',
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 6. Loading HUD Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 16),
                    const Text(
                      'Connecting with Doctor...',
                      style: TextStyle(fontFamily: appPoppinFont, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionWidget(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 54),
            ),
            const SizedBox(height: 20),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                fontFamily: appPoppinFont,
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'To scan doctor QR codes continuously, please allow camera access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                setState(() {
                  _cameraPermissionDenied = false;
                  _hasCameraPermission = true;
                });
                try {
                  await _scannerController.start();
                } catch (_) {
                  await openAppSettings();
                }
              },
              icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Open Settings / Allow Camera',
                style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library_rounded, size: 18),
              label: const Text(
                'Upload QR from Gallery',
                style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
