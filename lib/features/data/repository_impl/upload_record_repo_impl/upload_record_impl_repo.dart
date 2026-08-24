import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import '../../../domain/entities/uploaded_record/uploaded_record_entity.dart';
import '../../../domain/repositories/uploaded_record/uploaded_record_repo.dart';

class RecordsRepositoryImpl implements RecordsRepository {
  final ApiClient _apiClient;

  RecordsRepositoryImpl(this._apiClient);

  @override
  Future<List<UploadedRecord>> getUploadedRecords({
    String? patientId,
    String? appointmentId,
    String? hospitalId,
    String? orgId,
    int? limit,
  }) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final effectivePatientId = (patientId != null && patientId.trim().isNotEmpty)
          ? patientId.trim()
          : (currentUser?.data?.id ?? '');

      if (effectivePatientId.isNotEmpty) {
        final token = currentUser?.data?.accessToken ?? '';

        final queryParams = <String, dynamic>{};
        if (appointmentId != null && appointmentId.trim().isNotEmpty) {
          queryParams['appointmentId'] = appointmentId.trim();
        }
        if (hospitalId != null && hospitalId.trim().isNotEmpty) {
          queryParams['hospitalId'] = hospitalId.trim();
        }
        if (orgId != null && orgId.trim().isNotEmpty) {
          queryParams['organizationId'] = orgId.trim();
        }
        if (limit != null && limit > 0) {
          queryParams['limit'] = limit;
        }

        final response = await _apiClient.account(showSuccessSnack: false).get(
          '${URLs.medicalDocumentsUrl}/patient/$effectivePatientId',
          queryParameters: queryParams,
          options: Options(
            headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
          ),
        );

        if (response.data != null && response.data is Map<String, dynamic>) {
          final mapData = response.data as Map<String, dynamic>;
          final items = mapData['data'] ?? mapData['result'] ?? mapData['payload'];
          if (items is List) {
            return items.whereType<Map<String, dynamic>>().map((json) {
              DateTime date = DateTime.now();
              final rawDate = json['uploadDate'] ?? json['CreatedAt'] ?? json['createdAt'];
              if (rawDate != null) {
                try {
                  date = DateTime.parse(rawDate.toString());
                } catch (_) {}
              }

              int sizeKb = 150;
              final rawSize = json['fileSizeKB'] ?? json['FileSize'] ?? json['fileSize'];
              if (rawSize != null) {
                sizeKb = (int.tryParse(rawSize.toString()) ?? 150000) ~/ 1024;
              }

              return UploadedRecord(
                id: (json['id'] ?? json['Id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
                fileName: (json['fileName'] ?? json['FileName'] ?? json['OriginalName'] ?? 'Document.pdf').toString(),
                category: (json['category'] ?? json['Category'] ?? json['DocumentType'] ?? 'General').toString(),
                uploadDate: date,
                fileSizeKB: sizeKb,
                fileUrl: (json['blobUrl'] ?? json['BlobUrl'] ?? json['fileUrl'] ?? json['url'] ?? json['Url'] ?? json['filePath'] ?? json['path'] ?? '').toString(),
                filePath: (json['filePath'] ?? json['path'] ?? '').toString(),
              );
            }).toList();
          }
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        "Error fetching medical documents from API",
        error: e,
        stackTrace: stackTrace,
        name: "RecordsRepositoryImpl",
      );
    }

    return [];
  }

  @override
  Future<UploadedRecord?> uploadDocument({
    required String filePath,
    required String fileName,
    required String category,
    String? patientId,
    String? appointmentId,
    String? hospitalId,
    String? orgId,
  }) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';

      final formData = FormData.fromMap({
        'files': await MultipartFile.fromFile(filePath, filename: fileName),
        'category': category,
        'documentCategory': category,
        'patientId': (patientId != null && patientId.trim().isNotEmpty) ? patientId.trim() : '1',
        if (appointmentId != null && appointmentId.trim().isNotEmpty) 'appointmentId': appointmentId.trim(),
        'hospitalId': (hospitalId != null && hospitalId.trim().isNotEmpty) ? hospitalId.trim() : '1',
        'organizationId': (orgId != null && orgId.trim().isNotEmpty) ? orgId.trim() : '1',
      });

      final response = await _apiClient.account(showSuccessSnack: true).post(
        URLs.medicalDocumentsUrl,
        data: formData,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final mapData = response.data as Map<String, dynamic>;
        final rawJson = mapData['data'] ?? mapData['result'] ?? mapData['payload'] ?? mapData;
        Map<String, dynamic>? json;
        if (rawJson is List && rawJson.isNotEmpty && rawJson.first is Map<String, dynamic>) {
          json = rawJson.first as Map<String, dynamic>;
        } else if (rawJson is Map<String, dynamic>) {
          json = rawJson;
        }

        if (json != null) {
          int sizeKb = 150;
          final rawSize = json['fileSizeKB'] ?? json['FileSize'] ?? json['fileSize'];
          if (rawSize != null) {
            sizeKb = (int.tryParse(rawSize.toString()) ?? 150000) ~/ 1024;
          }
          final blobUrl = (json['blobUrl'] ?? json['BlobUrl'] ?? json['fileUrl'] ?? json['url'] ?? json['Url'] ?? '').toString();
          return UploadedRecord(
            id: (json['id'] ?? json['Id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
            fileName: (json['fileName'] ?? json['FileName'] ?? fileName).toString(),
            category: (json['category'] ?? json['Category'] ?? category).toString(),
            uploadDate: DateTime.now(),
            fileSizeKB: sizeKb,
            fileUrl: blobUrl.isNotEmpty ? blobUrl : null,
            filePath: filePath,
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        "Error uploading document to API",
        error: e,
        stackTrace: stackTrace,
        name: "RecordsRepositoryImpl",
      );
    }
    return null;
  }

  @override
  Future<void> deleteUploadedRecord(String id) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';

      await _apiClient.account(showSuccessSnack: true).delete(
        '${URLs.medicalDocumentsUrl}/$id',
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        "Error deleting document from API",
        error: e,
        stackTrace: stackTrace,
        name: "RecordsRepositoryImpl",
      );
    }
  }
}