import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/features/data/models/snomed/snomed_concept_model.dart';
import 'package:yiraclinics/features/domain/repositories/snomed/snomed_repository.dart';

class SnomedRepositoryImpl implements SnomedRepository {
  final ApiClient _apiClient;

  SnomedRepositoryImpl(this._apiClient);

  @override
  Future<List<SnomedConceptModel>> searchConcepts({
    required String term,
    String? type,
    int limit = 15,
    CancelToken? cancelToken,
  }) async {
    if (term.trim().isEmpty) return [];

    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String token = currentUser?.data?.accessToken ?? '';

      final queryParams = {
        'term': term.trim(),
        if (type != null && type.isNotEmpty) 'type': type,
        'limit': limit,
      };

      final response = await _apiClient.account(showSuccessSnack: false).get(
        URLs.snomedSearchUrl,
        queryParameters: queryParams,
        cancelToken: cancelToken,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final dataMap = response.data as Map<String, dynamic>;
        final items = dataMap['data']?['items'] ?? dataMap['data'];

        if (items is List) {
          return items
              .map((item) => SnomedConceptModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Request cancelled due to rapid user typing; ignore silently
        return [];
      }
      developer.log("SNOMED search network error: ${e.message}", name: "SnomedRepositoryImpl");
    } catch (e, stackTrace) {
      developer.log("SNOMED search error", error: e, stackTrace: stackTrace, name: "SnomedRepositoryImpl");
    }

    return [];
  }
}
