import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/local/global_session.dart';
import '../../../../../core/urls/urls.dart';
import '../../../../../di/dependency_injection.dart';
import '../models/offer_banner_model.dart';

class OfferBannerService {
  final ApiClient _apiClient = sl<ApiClient>();

  Future<List<OfferBannerModel>> fetchActiveOffers({
    String? organizationId,
    String placement = 'carousel',
  }) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';
      final orgId = organizationId ?? currentUser?.data?.latestOrgId?.toString();

      final queryParams = <String, dynamic>{
        'placement': placement,
      };
      if (orgId != null && orgId.trim().isNotEmpty && orgId.trim() != '0') {
        queryParams['organizationId'] = orgId.trim();
      }

      final options = token.isNotEmpty
          ? Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'})
          : null;

      debugPrint('[OFFERS] Fetching active offers from backend (orgId: $orgId, placement: $placement)...');
      final response = await _apiClient.account(showSuccessSnack: false).get(
            URLs.offerBannersUrl,
            queryParameters: queryParams,
            options: options,
          );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final rawList = response.data['data'];
        if (rawList is List) {
          final items = rawList
              .map((e) => OfferBannerModel.fromJson(Map<String, dynamic>.from(e)))
              .where((b) => b.isActive)
              .toList();

          debugPrint('[OFFERS] Successfully loaded ${items.length} offers from backend.');
          return items;
        }
      }
    } catch (e) {
      debugPrint('[OFFERS] Fetch error from backend: $e');
    }

    // No dummy or fallback data — only real backend data
    return [];
  }

  Future<OfferBannerModel?> fetchActivePopupAd({String? organizationId}) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final token = currentUser?.data?.accessToken ?? '';
      final orgId = organizationId ?? currentUser?.data?.latestOrgId?.toString();

      final queryParams = <String, dynamic>{};
      if (orgId != null && orgId.trim().isNotEmpty && orgId.trim() != '0') {
        queryParams['organizationId'] = orgId.trim();
      }

      final options = token.isNotEmpty
          ? Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'})
          : null;

      debugPrint('[POPUP_AD] Checking active popup ad from backend (orgId: $orgId)...');
      final response = await _apiClient.account(showSuccessSnack: false).get(
            URLs.popupAdUrl,
            queryParameters: queryParams,
            options: options,
          );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final rawData = response.data['data'];
        if (rawData != null && rawData is Map<String, dynamic>) {
          final popup = OfferBannerModel.fromJson(Map<String, dynamic>.from(rawData));
          if (popup.isActive && popup.imageUrl.trim().isNotEmpty) {
            debugPrint('[POPUP_AD] Successfully retrieved popup ad: #${popup.id}');
            return popup;
          }
        }
      }
    } catch (e) {
      debugPrint('[POPUP_AD] Fetch error from backend: $e');
    }

    return null;
  }
}
