class OfferBannerModel {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String placement; // 'carousel' or 'popup'
  final String redirectionType; // 'browser' or 'in_app'
  final String? redirectionUrl;
  final String? inAppRoute;
  final dynamic inAppParams;
  final bool isAllOrganizations;
  final List<int> targetOrganizationIds;
  final bool isActive;
  final bool showTitle;
  final bool showDescription;
  final bool showOfferTag;
  final String offerTag;
  final int displayOrder;
  final int maxDisplayCount; // 0 = continuous, 1 = 1 time, 2 = 2 times, 5 = 5 times, 6 = 6 times
  final DateTime? startDate;
  final DateTime? endDate;

  const OfferBannerModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.placement = 'carousel',
    required this.redirectionType,
    this.redirectionUrl,
    this.inAppRoute,
    this.inAppParams,
    this.isAllOrganizations = true,
    this.targetOrganizationIds = const [],
    this.isActive = true,
    this.showTitle = true,
    this.showDescription = true,
    this.showOfferTag = true,
    this.offerTag = 'SPECIAL OFFER',
    this.displayOrder = 0,
    this.maxDisplayCount = 0,
    this.startDate,
    this.endDate,
  });

  factory OfferBannerModel.fromJson(Map<String, dynamic> json) {
    List<int> orgIds = [];
    if (json['targetOrganizationIds'] is List) {
      orgIds = (json['targetOrganizationIds'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList();
    }

    return OfferBannerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      placement: (json['placement']?.toString().toLowerCase() == 'popup') ? 'popup' : 'carousel',
      redirectionType: (json['redirectionType']?.toString().toLowerCase() == 'in_app') ? 'in_app' : 'browser',
      redirectionUrl: json['redirectionUrl']?.toString(),
      inAppRoute: json['inAppRoute']?.toString(),
      inAppParams: json['inAppParams'],
      isAllOrganizations: json['isAllOrganizations'] is bool
          ? json['isAllOrganizations']
          : (json['isAllOrganizations']?.toString() == '1' || json['isAllOrganizations']?.toString().toLowerCase() == 'true'),
      targetOrganizationIds: orgIds,
      isActive: json['isActive'] is bool
          ? json['isActive']
          : (json['isActive']?.toString() == '1' || json['isActive']?.toString().toLowerCase() == 'true'),
      showTitle: json['showTitle'] is bool
          ? json['showTitle']
          : (json['showTitle']?.toString() != '0' && json['showTitle']?.toString().toLowerCase() != 'false'),
      showDescription: json['showDescription'] is bool
          ? json['showDescription']
          : (json['showDescription']?.toString() != '0' && json['showDescription']?.toString().toLowerCase() != 'false'),
      showOfferTag: json['showOfferTag'] is bool
          ? json['showOfferTag']
          : (json['showOfferTag']?.toString() != '0' && json['showOfferTag']?.toString().toLowerCase() != 'false'),
      offerTag: (json['offerTag'] != null && json['offerTag'].toString().trim().isNotEmpty)
          ? json['offerTag'].toString().trim()
          : 'SPECIAL OFFER',
      displayOrder: json['displayOrder'] is int
          ? json['displayOrder']
          : int.tryParse(json['displayOrder']?.toString() ?? '0') ?? 0,
      maxDisplayCount: json['maxDisplayCount'] is int
          ? json['maxDisplayCount']
          : int.tryParse(json['maxDisplayCount']?.toString() ?? '0') ?? 0,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'placement': placement,
      'redirectionType': redirectionType,
      'redirectionUrl': redirectionUrl,
      'inAppRoute': inAppRoute,
      'inAppParams': inAppParams,
      'isAllOrganizations': isAllOrganizations,
      'targetOrganizationIds': targetOrganizationIds,
      'isActive': isActive,
      'showTitle': showTitle,
      'showDescription': showDescription,
      'showOfferTag': showOfferTag,
      'offerTag': offerTag,
      'displayOrder': displayOrder,
      'maxDisplayCount': maxDisplayCount,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }
}
