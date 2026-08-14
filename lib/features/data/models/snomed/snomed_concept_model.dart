class SnomedConceptModel {
  final String conceptId;
  final String term;
  final String fsn;
  final String? semanticTag;

  SnomedConceptModel({
    required this.conceptId,
    required this.term,
    required this.fsn,
    this.semanticTag,
  });

  factory SnomedConceptModel.fromJson(Map<String, dynamic> json) {
    final conceptId = (json['conceptId'] ?? json['id'] ?? '').toString();
    
    String term = '';
    if (json['pt'] != null && json['pt']['term'] != null) {
      term = json['pt']['term'].toString();
    } else if (json['term'] != null) {
      term = json['term'].toString();
    } else if (json['fsn'] != null && json['fsn']['term'] != null) {
      term = json['fsn']['term'].toString();
    }

    String fsn = term;
    if (json['fsn'] != null && json['fsn']['term'] != null) {
      fsn = json['fsn']['term'].toString();
    }

    String? tag;
    if (fsn.contains('(') && fsn.contains(')')) {
      tag = fsn.substring(fsn.lastIndexOf('(') + 1, fsn.lastIndexOf(')'));
    }

    return SnomedConceptModel(
      conceptId: conceptId,
      term: term.isNotEmpty ? term : fsn,
      fsn: fsn,
      semanticTag: tag,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conceptId': conceptId,
      'term': term,
      'fsn': fsn,
      'semanticTag': semanticTag,
    };
  }
}
