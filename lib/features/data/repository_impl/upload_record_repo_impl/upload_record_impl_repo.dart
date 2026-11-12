import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/core/utils/record_display_name.dart';
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

              final rawName = (json['originalFileName'] ?? json['OriginalFileName'] ?? json['fileName'] ?? json['FileName'] ?? json['OriginalName'] ?? 'Document.pdf').toString();
              final storedName = (json['fileName'] ?? json['FileName'] ?? rawName).toString();
              // The file's own extension decides its type; DocumentType holds the record kind ("Prescription")
              final ext = recordFileExtension(rawName).isNotEmpty ? recordFileExtension(rawName) : recordFileExtension(storedName);
              String fileType = ext.toUpperCase();
              if (fileType.isEmpty) fileType = (json['fileType'] ?? '').toString().replaceAll('.', '').toUpperCase();
              if (fileType.isEmpty) fileType = 'PDF';
              // "Prescription_<id>.pdf" reads as "Prescription · 12 Nov 2026"
              final fileName = recordDisplayName(rawName,
                  category: (json['category'] ?? json['Category'] ?? json['documentCategory'] ?? json['DocumentCategory'] ?? '').toString(),
                  date: date);

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
              // The API sends Hospital / Appointment.Hospital / Organization with a "Name", and
              // Doctor / UploadedByUser with FirstName + LastName, as the web Health Records reads them.
              if (!isPatientUploaded) {
                hospitalName = _text(json['hospitalName'] ?? json['HospitalName']) ??
                    _nameOf(json['Hospital'] ?? json['hospital']) ??
                    _nameOf(json['Appointment'] is Map ? json['Appointment']['Hospital'] : null) ??
                    _nameOf(json['Organization']) ??
                    '';

                final isDoctorUploaded = json['IsDoctorUploaded'] == true || json['isDoctorUploaded'] == true;
                doctorName = _text(json['doctorName'] ?? json['DoctorName']) ??
                    _personName(json['Doctor'] ?? json['doctor']) ??
                    (isDoctorUploaded ? _personName(json['UploadedByUser']) : null) ??
                    '';
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
                aiStatus: _text(json['AiStatus'] ?? json['aiStatus']),
                aiAnalysisJson: _text(json['AiAnalysis'] ?? json['aiAnalysis']),
                aiJobStatus: _text(json['AiJobStatus'] ?? json['aiJobStatus']),
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

  static String? _text(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text == 'null' ? null : text;
  }

  /// A hospital or organization's name from its JSON object.
  static String? _nameOf(dynamic value) =>
      value is Map ? _text(value['Name'] ?? value['name'] ?? value['HospitalName'] ?? value['hospitalName']) : null;

  /// A person's "FirstName LastName" from a user JSON object.
  static String? _personName(dynamic value) =>
      value is Map ? _text('${value['FirstName'] ?? ''} ${value['LastName'] ?? ''}') : null;

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