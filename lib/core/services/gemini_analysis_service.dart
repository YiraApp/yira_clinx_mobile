import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/prescriptions/prescription_analysis_result.dart';

/// Reads a prescription photo or PDF for "Scan prescription" and returns a structured
/// [PrescriptionAnalysisResult]. The server reads it with Gemini using its own key, so no AI key
/// ships inside the app.
class GeminiAnalysisService {
  GeminiAnalysisService._();

  static Dio get _dio => sl<ApiClient>().account(showSuccessSnack: false);

  /// Analyzes a prescription [file] (image or PDF) and returns structured data.
  ///
  /// Throws [GeminiAnalysisException] on any failure.
  static Future<PrescriptionAnalysisResult> analyze(File file) async {
    try {
      final String mimeType = _getMimeType(file.path);
      // Photos are shrunk first so they upload quickly; PDFs go as they are.
      final Uint8List bytes = mimeType.startsWith('image/') ? await _compressImage(file) : await file.readAsBytes();
      final String fileName = mimeType.startsWith('image/') ? 'prescription.jpg' : 'prescription.pdf';
      final String sendType = mimeType.startsWith('image/') ? 'image/jpeg' : mimeType;
      debugPrint('[PrescriptionScan] Sending ${(bytes.length / 1024).toStringAsFixed(0)} KB ($sendType)');

      final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
      final response = await _dio.post(
        '${URLs.prescriptionsUrl}/scan',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: fileName, contentType: DioMediaType.parse(sendType)),
        }),
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
          extra: const {'suppressErrorSnack': true},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 100),
        ),
      );

      final body = response.data;
      final data = body is Map ? body['data'] : null;
      if (data is! Map) {
        throw const GeminiAnalysisException('No analysis results returned. Please try again.', code: GeminiErrorCode.emptyResponse);
      }
      final result = PrescriptionAnalysisResult.fromJson(Map<String, dynamic>.from(data));
      debugPrint('[PrescriptionScan] Extracted ${result.medications.length} medications, confidence ${result.confidence}%');
      return result;
    } on DioException catch (e) {
      debugPrint('[PrescriptionScan] Dio error: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const GeminiAnalysisException(
          'Analysis is taking too long. Please try with a clearer image.',
          code: GeminiErrorCode.timeout,
        );
      }
      final body = e.response?.data;
      final message = body is Map && body['message'] != null ? body['message'].toString() : null;
      final status = e.response?.statusCode;
      if (status == 429) {
        throw GeminiAnalysisException(message ?? 'Service is busy right now. Please try again in a moment.',
            code: GeminiErrorCode.rateLimited);
      }
      if (status == 400 || status == 422) {
        throw GeminiAnalysisException(message ?? 'Could not process this image. Please try a clearer photo.',
            code: GeminiErrorCode.badRequest);
      }
      if (status != null) {
        throw GeminiAnalysisException(message ?? 'Something went wrong while analyzing. Please try again.',
            code: GeminiErrorCode.apiError);
      }
      throw const GeminiAnalysisException(
        'Connection failed. Please check your internet.',
        code: GeminiErrorCode.networkError,
      );
    } catch (e) {
      if (e is GeminiAnalysisException) rethrow;
      debugPrint('[PrescriptionScan] Unexpected error: $e');
      throw const GeminiAnalysisException(
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
        debugPrint('[PrescriptionScan] Compressed: ${(file.lengthSync() / 1024).toStringAsFixed(0)} KB → ${(result.length / 1024).toStringAsFixed(0)} KB');
        return result;
      }
    } catch (e) {
      debugPrint('[PrescriptionScan] Compression failed, using original: $e');
    }
    return file.readAsBytesSync();
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
