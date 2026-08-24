import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/features/data/models/notifications/app_notification_model.dart';
import 'package:yiraclinics/features/domain/entities/notifications/app_notification_entity.dart';
import 'package:yiraclinics/features/domain/repositories/notifications/notifications_repo.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final ApiClient _apiClient;

  NotificationsRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<NotificationsPayloadEntity?> getNotifications({int page = 1, int limit = 30}) async {
    try {
      final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
      final response = await _apiClient.account(showSuccessSnack: false).get(
        URLs.notificationsListUrl,
        queryParameters: {'page': page, 'limit': limit},
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (response.data != null && response.data is Map<String, dynamic>) {
        final rawData = response.data as Map<String, dynamic>;
        final data = rawData['data'];
        if (data != null && data is Map<String, dynamic>) {
          return NotificationsPayloadModel.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      debugPrint("NotificationsRepositoryImpl getNotifications error: $e");
      return null;
    }
  }

  @override
  Future<bool> markAsRead(String notificationId) async {
    try {
      final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
      final response = await _apiClient.account(showSuccessSnack: false).post(
        "${URLs.markNotificationReadUrl}/$notificationId/read",
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("NotificationsRepositoryImpl markAsRead error: $e");
      return false;
    }
  }

  @override
  Future<bool> markAllAsRead() async {
    try {
      final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
      final response = await _apiClient.account(showSuccessSnack: false).post(
        URLs.markAllNotificationsReadUrl,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("NotificationsRepositoryImpl markAllAsRead error: $e");
      return false;
    }
  }
}
