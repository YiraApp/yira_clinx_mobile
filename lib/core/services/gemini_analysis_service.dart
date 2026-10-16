import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/prescription_analysis_result.dart';

/// Service that sends prescription images/PDFs to Google's Gemini AI
/// and returns a structured [PrescriptionAnalysisResult].
class GeminiAnalysisService {
  GeminiAnalysisService._();

  static const String _apiKey = 'AIzaSyCiaq6HIzpKZEN0Qg4Wm3HxcQ0lWz2nxzM';
  static const String _model = 'gemini-2.5-flash';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// The structured prompt that instructs Gemini to extract prescription data.
  static const String _systemPrompt = '''
You are an expert medical prescription analysis assistant. Analyze this prescription image or PDF document (supporting up to 2 pages) and extract the information as JSON. Return ONLY the JSON object, no extra text.

{
  "doctorName": "string - doctor's full name as written on the prescription",
  "hospitalName": "string - clinic/hospital/healthcare center name if visible, empty string if not",
  "specialty": "string - medical specialty if mentioned (e.g., General Medicine, Cardiology, Dermatology, Pediatrics, Orthopedics, ENT, Gynecology, Dental). Default to General Medicine if unclear",
  "consultationDate": "string - date in YYYY-MM-DD format if visible, empty string if not",
  "diagnosis": "string - condition/diagnosis/symptoms/reason for visit. Combine multiple if present",
  "doctorNotes": "string - general advice, follow-up instructions, dietary instructions, or precautions",
  "medications": [
    {
      "name": "string - full medicine name with strength and formulation if visible (e.g., Tab Paracetamol 650mg, Cap Amoxicillin 500mg, Syp Corex 100ml)",
      "frequency": "string - one of: 1-0-1, 1-0-0, 0-0-1, 1-1-1, SOS. Map BD to 1-0-1, OD to 1-0-0, TDS/TID to 1-1-1, HS/ON to 0-0-1, SOS/PRN to SOS",
      "mealTiming": "string - one of: After Food, Before Food. Default to After Food if not specified",
      "durationDays": "number - duration in days. Convert weeks to days (e.g. 1 week = 7). Use 0 if continuous or unclear",
      "isContinuous": "boolean - true if medicine is marked as ongoing/continuous/lifelong",
      "notes": "string - any specific instructions for this medicine (e.g., Take with warm water)"
    }
  ],
  "confidence": "number 0-100 - your confidence in the extraction accuracy based on image clarity and handwriting legibility"
}

IMPORTANT RULES:
- FOR PDF DOCUMENTS (UP TO 2 PAGES): Carefully examine and extract details from BOTH Page 1 and Page 2 (if present). Combine all medications, dosages, and notes found across both pages into a single unified JSON response. Do not omit medications from either page. If more than 2 pages exist, analyze only the first 2 pages.
- Extract EVERY SINGLE medication visible in the prescription.
- If you see Rx or ℞ symbols, all items listed below are medications.
- If a field is not visible or unclear, use empty string for strings, 5 for durationDays, false for booleans.
- Map common abbreviations: Tab=Tablet, Cap=Capsule, Syp=Syrup, Inj=Injection, OD=1-0-0, BD=1-0-1, TDS/TID=1-1-1, HS=0-0-1, SOS=SOS, AC=Before Food, PC=After Food.
- Translate any non-English text to English.
- Return ONLY valid JSON, no markdown backticks, no explanation text.
''';

  /// Analyzes a prescription [file] (image or PDF) and returns structured data.
  ///
  /// Throws [GeminiAnalysisException] on any failure.
  static Future<PrescriptionAnalysisResult> analyze(File file) async {
    try {
      final String mimeType = _getMimeType(file.path);
      final Uint8List bytes;

      if (mimeType.startsWith('image/')) {
        bytes = await _compressImage(file);
      } else {
        // PDF — send as-is (Gemini supports inline PDF data)
        bytes = await file.readAsBytes();
      }

      final String base64Data = base64Encode(bytes);
      debugPrint('[GeminiAnalysis] Sending ${(bytes.length / 1024).toStringAsFixed(0)} KB to $mimeType analysis...');

      final response = await _dio.post(
        '$_baseUrl/$_model:generateContent?key=$_apiKey',
        data: {
          'contents': [
            {
              'parts': [
                {'text': _systemPrompt},
                {
                  'inlineData': {
                    'mimeType': mimeType,
                    'data': base64Data,
                  }
                },
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 4096,
            'responseMimeType': 'application/json',
          },
        },
      );

      if (response.statusCode != 200) {
        throw GeminiAnalysisException(
          'Gemini API returned status ${response.statusCode}',
          code: GeminiErrorCode.apiError,
        );
      }

      return _parseResponse(response.data);
    } on DioException catch (e) {
      debugPrint('[GeminiAnalysis] Dio error: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const GeminiAnalysisException(
          'Analysis is taking too long. Please try with a clearer image.',
          code: GeminiErrorCode.timeout,
        );
      }
      if (e.response?.statusCode == 429) {
        throw const GeminiAnalysisException(
          'Service is busy right now. Please try again in a moment.',
          code: GeminiErrorCode.rateLimited,
        );
      }
      if (e.response?.statusCode == 400) {
        throw const GeminiAnalysisException(
          'Could not process this image. Please try a clearer photo.',
          code: GeminiErrorCode.badRequest,
        );
      }
      throw GeminiAnalysisException(
        'Connection failed. Please check your internet.',
        code: GeminiErrorCode.networkError,
      );
    } catch (e) {
      if (e is GeminiAnalysisException) rethrow;
      debugPrint('[GeminiAnalysis] Unexpected error: $e');
      throw GeminiAnalysisException(
        'Something went wrong while analyzing. Please try again.',
        code: GeminiErrorCode.unknown,
      );
    }
  }

  /// Compresses an image to reduce payload size for the API.
  static Future<Uint8List> _compressImage(File file) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: 1280,
        minHeight: 1280,
        quality: 75,
        format: CompressFormat.jpeg,
      );
      if (result != null && result.isNotEmpty) {
        debugPrint('[GeminiAnalysis] Compressed: ${(file.lengthSync() / 1024).toStringAsFixed(0)} KB → ${(result.length / 1024).toStringAsFixed(0)} KB');
        return result;
      }
    } catch (e) {
      debugPrint('[GeminiAnalysis] Compression failed, using original: $e');
    }
    return file.readAsBytesSync();
  }

  /// Parses the Gemini API response and extracts the JSON content.
  static PrescriptionAnalysisResult _parseResponse(dynamic data) {
    try {
      if (data == null) {
        throw const GeminiAnalysisException(
          'Empty response from analysis service.',
          code: GeminiErrorCode.emptyResponse,
        );
      }

      final Map<String, dynamic> responseMap =
          data is Map<String, dynamic> ? data : jsonDecode(data.toString());

      // Navigate: candidates[0].content.parts[0].text
      final candidates = responseMap['candidates'];
      if (candidates == null || candidates is! List || candidates.isEmpty) {
        // Check for prompt-level block
        final blockReason = responseMap['promptFeedback']?['blockReason'];
        if (blockReason != null) {
          throw GeminiAnalysisException(
            'Image was blocked by safety filters. Please try a different image.',
            code: GeminiErrorCode.blocked,
          );
        }
        throw const GeminiAnalysisException(
          'No analysis results returned. Please try again.',
          code: GeminiErrorCode.emptyResponse,
        );
      }

      final content = candidates[0]['content'];
      if (content == null) {
        throw const GeminiAnalysisException(
          'No content in analysis response.',
          code: GeminiErrorCode.emptyResponse,
        );
      }

      final parts = content['parts'];
      if (parts == null || parts is! List || parts.isEmpty) {
        throw const GeminiAnalysisException(
          'No data extracted from the prescription.',
          code: GeminiErrorCode.emptyResponse,
        );
      }

      final text = (parts[0]['text'] ?? '').toString().trim();
      if (text.isEmpty) {
        throw const GeminiAnalysisException(
          'Empty extraction result.',
          code: GeminiErrorCode.emptyResponse,
        );
      }

      // Clean any potential markdown fences
      String cleanedJson = text;
      if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.replaceFirst(RegExp(r'^```\w*\n?'), '');
        cleanedJson = cleanedJson.replaceFirst(RegExp(r'\n?```$'), '');
      }

      final Map<String, dynamic> parsed = jsonDecode(cleanedJson.trim());
      final result = PrescriptionAnalysisResult.fromJson(parsed);

      debugPrint('[GeminiAnalysis] ✅ Extracted: ${result.medications.length} medications, confidence: ${result.confidence}%');
      return result;
    } on FormatException catch (e) {
      debugPrint('[GeminiAnalysis] JSON parse error: $e');
      throw const GeminiAnalysisException(
        'Could not understand the prescription. Please try a clearer image.',
        code: GeminiErrorCode.parseError,
      );
    }
  }

  /// Returns the MIME type based on file extension.
  static String _getMimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'image/jpeg';
    }
  }
}

/// Error codes for prescription analysis failures.
enum GeminiErrorCode {
  networkError,
  timeout,
  rateLimited,
  badRequest,
  apiError,
  blocked,
  emptyResponse,
  parseError,
  unknown,
}

/// Exception thrown when prescription analysis fails.
class GeminiAnalysisException implements Exception {
  final String message;
  final GeminiErrorCode code;

  const GeminiAnalysisException(this.message, {this.code = GeminiErrorCode.unknown});

  @override
  String toString() => 'GeminiAnalysisException($code): $message';
}
