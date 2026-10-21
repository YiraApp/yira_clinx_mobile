import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/medical_report/medical_report_analysis.dart';

class ReportAiException implements Exception {
  final String message;
  final String code;

  const ReportAiException(this.message, {this.code = 'UNKNOWN'});

  @override
  String toString() => message;
}

/// The result of uploading a report: the saved document and, when it worked,
/// what the AI found. The upload can succeed even if the analysis fails.
/// When [analysisPending], the server is still reading it and will send a push.
class ReportUploadResult {
  final String documentId;
  final String fileName;
  final String category;
  final String? fileUrl;
  final int pageCount;
  final MedicalReportAnalysis? analysis;
  final ReportAiException? analysisError;
  final bool analysisPending;
  final String? pendingMessage;

  const ReportUploadResult({
    required this.documentId,
    required this.fileName,
    required this.category,
    this.fileUrl,
    required this.pageCount,
    this.analysis,
    this.analysisError,
    this.analysisPending = false,
    this.pendingMessage,
  });
}

/// Uploads medical reports and asks the server to read them with AI. The AI
/// itself runs on the server, so no API key lives in the app.
class MedicalReportAiService {
  MedicalReportAiService._();

  static const int maxPages = 10;
  static const int maxFileBytes = 10 * 1024 * 1024;

  // Reading a 10-page report can take a while; don't give up after 30s.
  static const Duration _aiTimeout = Duration(seconds: 150);

  static Dio get _dio => sl<ApiClient>().account(showSuccessSnack: false);

  static Options _options({bool long = false}) {
    final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
    return Options(
      headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
      extra: const {'suppressErrorSnack': true},
      receiveTimeout: long ? _aiTimeout : null,
      sendTimeout: long ? const Duration(seconds: 90) : null,
    );
  }

  /// Number of pages in a PDF, or null if it can't be read on the device
  /// (the server checks again either way).
  static Future<int?> pdfPageCount(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      final count = doc.pages.count;
      doc.dispose();
      return count;
    } catch (e) {
      debugPrint('[MedicalReportAI] Could not count PDF pages: $e');
      return null;
    }
  }

  /// Shrinks a page photo to a sharp but small JPEG (also turns HEIC into JPEG).
  static Future<File> preparePhoto(String path) async {
    try {
      final dir = await getTemporaryDirectory();
      final target = '${dir.path}/report_page_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final out = await FlutterImageCompress.compressAndGetFile(
        path,
        target,
        minWidth: 1600,
        minHeight: 1600,
        quality: 82,
        format: CompressFormat.jpeg,
      );
      if (out != null) return File(out.path);
    } catch (e) {
      debugPrint('[MedicalReportAI] Photo compression failed, using original: $e');
    }
    return File(path);
  }

  /// Uploads one report: a single PDF (up to 10 pages) or 1-10 page photos,
  /// which the server joins into one PDF. Reads it with AI when [analyze].
  static Future<ReportUploadResult> uploadReport({
    required List<File> files,
    required String title,
    required String category,
    String? notes,
    bool analyze = true,
  }) async {
    final user = GlobalSession.instance.userNotifier.value?.data;
    final userId = user?.id ?? '';

    final parts = <MultipartFile>[];
    for (var i = 0; i < files.length; i++) {
      final path = files[i].path;
      final isPdf = path.toLowerCase().endsWith('.pdf');
      final isPng = path.toLowerCase().endsWith('.png');
      parts.add(await MultipartFile.fromFile(
        path,
        filename: isPdf ? 'report.pdf' : 'page_${i + 1}.${isPng ? 'png' : 'jpg'}',
        contentType: isPdf ? DioMediaType('application', 'pdf') : DioMediaType('image', isPng ? 'png' : 'jpeg'),
      ));
    }

    final form = FormData.fromMap({
      'files': parts,
      'title': title,
      'category': category,
      'documentCategory': category,
      if (notes != null && notes.trim().isNotEmpty) 'description': notes.trim(),
      'patientId': userId,
      'hospitalId': user?.latestHospitalId?.toString() ?? '1',
      'organizationId': user?.latestOrgId?.toString() ?? '1',
      if (userId.isNotEmpty) 'uploadedByUserId': userId,
      'isPatientUploaded': 'true',
      'isDoctorUploaded': 'false',
      'analyze': analyze ? 'true' : 'false',
    });

    final data = await _call(() => _dio.post('${URLs.medicalDocumentsUrl}/report', data: form, options: _options(long: true)));
    final doc = data['document'] is Map ? Map<String, dynamic>.from(data['document']) : <String, dynamic>{};
    final rawAnalysis = data['analysis'];
    final rawError = data['analysisError'];

    return ReportUploadResult(
      documentId: (doc['Id'] ?? doc['id'] ?? '').toString(),
      fileName: (doc['FileName'] ?? doc['fileName'] ?? title).toString(),
      category: category,
      fileUrl: (doc['BlobUrl'] ?? doc['blobUrl'])?.toString(),
      pageCount: (data['pageCount'] as num?)?.toInt() ?? files.length,
      analysis: rawAnalysis is Map ? MedicalReportAnalysis.fromJson(Map<String, dynamic>.from(rawAnalysis)) : null,
      analysisError: rawError is Map
          ? ReportAiException((rawError['message'] ?? 'AI analysis failed.').toString(), code: (rawError['code'] ?? 'AI_ERROR').toString())
          : null,
      analysisPending: data['analysisPending'] == true,
      pendingMessage: data['pendingMessage']?.toString(),
    );
  }

  /// Reads an uploaded document with AI. The server keeps the result, so
  /// asking again is instant unless [force] re-reads the file.
  static Future<MedicalReportAnalysis> analyzeDocument(String documentId, {bool force = false}) async {
    final data = await _call(() => _dio.post(
          '${URLs.medicalDocumentsUrl}/$documentId/analyze',
          data: {'force': force},
          options: _options(long: true),
        ));
    return MedicalReportAnalysis.fromJson(data);
  }

  /// The saved analysis of a document, or null if it was never analysed.
  static Future<MedicalReportAnalysis?> getAnalysis(String documentId) async {
    final response = await _dio.get('${URLs.medicalDocumentsUrl}/$documentId/analysis', options: _options());
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    return data is Map ? MedicalReportAnalysis.fromJson(Map<String, dynamic>.from(data)) : null;
  }

  static Future<Map<String, dynamic>> _call(Future<Response> Function() request) async {
    try {
      final response = await request();
      final body = response.data;
      final data = body is Map ? body['data'] : null;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const ReportAiException('The server sent an unexpected reply. Please try again.', code: 'BAD_RESPONSE');
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['message'] != null) {
        final code = body['data'] is Map ? (body['data']['code'] ?? 'ERROR').toString() : 'ERROR';
        throw ReportAiException(body['message'].toString(), code: code);
      }
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw const ReportAiException('This is taking longer than usual. Please try again.', code: 'TIMEOUT');
        case DioExceptionType.connectionError:
          throw const ReportAiException('No internet connection. Check your network and try again.', code: 'NETWORK');
        default:
          throw const ReportAiException('Something went wrong. Please try again.');
      }
    }
  }
}
