import 'package:dio/dio.dart';
import 'package:yiraclinics/features/data/models/snomed/snomed_concept_model.dart';

abstract class SnomedRepository {
  Future<List<SnomedConceptModel>> searchConcepts({
    required String term,
    String? type,
    int limit = 15,
    CancelToken? cancelToken,
  });
}
