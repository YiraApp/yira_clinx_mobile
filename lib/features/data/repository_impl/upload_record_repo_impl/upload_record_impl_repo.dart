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
    int? page,
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
        if (page != null && page > 0) {
          queryParams['page'] = page;
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

              int sizeKb = 0;
              final rawSize = json['fileSizeKB'] ?? json['FileSize'] ?? json['fileSize'];
              if (rawSize != null) {
                final parsed = int.tryParse(rawSize.toString());
                if (parsed != null && parsed > 0) {
                  sizeKb = parsed > 1024 ? (parsed ~/ 1024) : parsed;
                }
              }

              final fileName = (json['fileName'] ?? json['FileName'] ?? json['OriginalName'] ?? 'Document.pdf').toString();
              String fileType = (json['documentType'] ?? json['DocumentType'] ?? json['fileType'] ?? '').toString();
              if (fileType.isEmpty && fileName.contains('.')) {
                fileType = fileName.substring(fileName.lastIndexOf('.') + 1).toUpperCase();
              }
              if (fileType.isEmpty) fileType = 'PDF';

              final description = (json['description'] ?? json['Description'] ?? json['notes'] ?? json['Notes'] ?? '').toString().trim();
              final appointmentDate = (json['appointmentDate'] ?? json['AppointmentDate'] ?? '').toString().trim();
              final apptId = (json['appointmentId'] ?? json['AppointmentId'] ?? '').toString().trim();

              final isPatientUploaded = json['isPatientUploaded'] == true ||
                  json['IsPatientUploaded'] == true ||
                  json['isPatientUploaded'] == 'true' ||
                  json['IsPatientUploaded'] == 'true';

              String hospitalName = '';
              String doctorName = '';

              // If record was added by hospital/provider, resolve hospital and doctor name
              if (!isPatientUploaded) {
                hospitalName = (json['hospitalName'] ??
                        json['HospitalName'] ??
                        (json['hospital'] is Map ? json['hospital']['hospitalName'] ?? json['hospital']['HospitalName'] : '') ??
                        (json['Hospital'] is Map ? json['Hospital']['HospitalName'] ?? json['Hospital']['hospitalName'] : '') ??
                        (json['appointment'] is Map && json['appointment']['hospital'] is Map ? json['appointment']['hospital']['hospitalName'] : '') ??
                        (json['Appointment'] is Map && json['Appointment']['Hospital'] is Map ? json['Appointment']['Hospital']['HospitalName'] : '') ??
                        '')
                    .toString()
                    .trim();

                doctorName = (json['doctorName'] ??
                        json['DoctorName'] ??
                        (json['doctor'] is Map ? json['doctor']['name'] ?? json['doctor']['DoctorName'] : '') ??
                        (json['Doctor'] is Map ? json['Doctor']['DoctorName'] ?? json['Doctor']['name'] : '') ??
                        '')
                    .toString()
                    .trim();
              }

              return UploadedRecord(
                id: (json['id'] ?? json['Id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
                fileName: fileName,
                category: (json['category'] ?? json['Category'] ?? json['documentCategory'] ?? json['DocumentCategory'] ?? 'General').toString(),
                uploadDate: date,
                fileSizeKB: sizeKb,
                fileUrl: (json['blobUrl'] ?? json['BlobUrl'] ?? json['fileUrl'] ?? json['url'] ?? json['Url'] ?? json['filePath'] ?? json['path'] ?? '').toString(),
                filePath: (json['filePath'] ?? json['path'] ?? '').toString(),
                description: description.isNotEmpty ? description : null,
                doctorName: doctorName.isNotEmpty ? doctorName : null,
                hospitalName: hospitalName.isNotEmpty ? hospitalName : null,
                appointmentDate: appointmentDate.isNotEmpty ? appointmentDate : null,
                appointmentId: apptId.isNotEmpty ? apptId : null,
                fileType: fileType,
                isAppointmentDoc: apptId.isNotEmpty,
                isPatientUploaded: isPatientUploaded,
                isDeletable: true,
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
    String? description,
    String? patientId,
    String? appointmentId,
    String? hospitalId,
    String? orgId,
  }) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';
      final currentUserId = currentUser?.data?.id ?? '';

      final formData = FormData.fromMap({
        'files': await MultipartFile.fromFile(filePath, filename: fileName),
        'category': category,
        'documentCategory': category,
        if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
        'patientId': (patientId != null && patientId.trim().isNotEmpty) ? patientId.trim() : (currentUserId.isNotEmpty ? currentUserId : '1'),
        if (appointmentId != null && appointmentId.trim().isNotEmpty) 'appointmentId': appointmentId.trim(),
        'hospitalId': (hospitalId != null && hospitalId.trim().isNotEmpty) ? hospitalId.trim() : (currentUser?.data?.latestHospitalId?.toString() ?? '1'),
        'organizationId': (orgId != null && orgId.trim().isNotEmpty) ? orgId.trim() : (currentUser?.data?.latestOrgId?.toString() ?? '1'),
        if (currentUserId.isNotEmpty) 'uploadedByUserId': currentUserId,
        'isPatientUploaded': currentUser?.data?.navigationId == "1" ? "true" : "false",
        'isDoctorUploaded': currentUser?.data?.navigationId != "1" ? "true" : "false",
      });

      final response = await _apiClient.account(showSuccessSnack: true).post(
        URLs.medicalDocumentsUrl,
        data: formData,
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
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
          int sizeKb = 0;
          final rawSize = json['fileSizeKB'] ?? json['FileSize'] ?? json['fileSize'];
          if (rawSize != null) {
            final parsed = int.tryParse(rawSize.toString());
            if (parsed != null && parsed > 0) {
              sizeKb = parsed > 1024 ? (parsed ~/ 1024) : parsed;
            }
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
            description: description,
            isPatientUploaded: true,
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