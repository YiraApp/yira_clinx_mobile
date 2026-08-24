import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/domain/entities/notifications/app_notification_entity.dart';
import 'package:yiraclinics/features/presentation/notifications/bloc/notifications_bloc.dart';
import 'package:yiraclinics/features/presentation/notifications/bloc/notifications_event.dart';
import 'package:yiraclinics/features/presentation/notifications/bloc/notifications_state.dart';

import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/features/data/repository_impl/notifications/notifications_repo_impl.dart';
import 'package:yiraclinics/features/use_cases/notifications/get_notifications_use_case.dart';
import 'package:yiraclinics/features/use_cases/notifications/mark_notification_read_use_case.dart';

class RecentNotificationsScreen extends StatefulWidget {
  const RecentNotificationsScreen({super.key});

  @override
  State<RecentNotificationsScreen> createState() => _RecentNotificationsScreenState();
}

class _RecentNotificationsScreenState extends State<RecentNotificationsScreen> {
  late final NotificationsBloc _bloc;
  bool _filterOnlyUnread = false;

  @override
  void initState() {
    super.initState();
    try {
      _bloc = sl<NotificationsBloc>()..add(const FetchNotificationsEvent());
    } catch (_) {
      final repo = NotificationsRepositoryImpl(apiClient: sl<ApiClient>());
      _bloc = NotificationsBloc(
        getNotificationsUseCase: GetNotificationsUseCase(repository: repo),
        markNotificationReadUseCase: MarkNotificationReadUseCase(repository: repo),
      )..add(const FetchNotificationsEvent());
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return "Just now";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else if (diff.inDays == 1) {
      return "Yesterday";
    } else if (diff.inDays < 7) {
      return "${diff.inDays}d ago";
    } else {
      return DateFormat('d MMM, yyyy').format(dateTime);
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'APPOINTMENT_BOOKED':
      case 'APPOINTMENT_STATUS':
        return Icons.calendar_month_rounded;
      case 'MEDICAL_RECORD_ADDED':
        return Icons.description_outlined;
      case 'PRESCRIPTION_ADDED':
        return Icons.medication_rounded;
      case 'TELECONSULT_START':
        return Icons.video_camera_front_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'APPOINTMENT_BOOKED':
      case 'APPOINTMENT_STATUS':
        return const Color(0xFF3B82F6); // Blue
      case 'MEDICAL_RECORD_ADDED':
        return const Color(0xFF0D9488); // Teal
      case 'PRESCRIPTION_ADDED':
        return const Color(0xFF10B981); // Emerald
      case 'TELECONSULT_START':
        return const Color(0xFF8B5CF6); // Violet
      default:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  void _handleNotificationTap(AppNotificationEntity notification) {
    if (!notification.isRead) {
      _bloc.add(MarkNotificationAsReadEvent(notification.id));
    }

    if (notification.route != null && notification.route!.isNotEmpty) {
      try {
        Navigator.pushNamed(
          context,
          notification.route!,
          arguments: notification.referenceId,
        );
      } catch (e) {
        debugPrint("Navigation from notification failed: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);
    final primaryColor = theme.primaryColor;

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              int unreadCount = 0;
              if (state is NotificationsLoadedState) {
                unreadCount = state.unreadCount;
              }

              return Row(
                children: [
                  Text(
                    "Notifications",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 20 : 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$unreadCount new",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: isTab ? 12 : 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          actions: [
            BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                final bool hasUnread = state is NotificationsLoadedState && state.unreadCount > 0;
                if (!hasUnread) return const SizedBox.shrink();

                return TextButton(
                  onPressed: () {
                    _bloc.add(MarkAllNotificationsAsReadEvent());
                  },
                  child: Text(
                    "Mark all read",
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: isTab ? 13.5 : 12.5,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoadingState) {
              return _buildShimmerSkeleton(isDark);
            }

            if (state is NotificationsErrorState) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 54, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _bloc.add(const FetchNotificationsEvent()),
                      child: const Text("Retry", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            }

            if (state is NotificationsLoadedState) {
              final allNotifications = state.notifications;
              final displayList = _filterOnlyUnread
                  ? allNotifications.where((n) => !n.isRead).toList()
                  : allNotifications;

              return RefreshIndicator(
                onRefresh: () async {
                  _bloc.add(const FetchNotificationsEvent(isRefresh: true));
                },
                child: Column(
                  children: [
                    // Filter Chips Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: "All (${allNotifications.length})",
                            isSelected: !_filterOnlyUnread,
                            primaryColor: primaryColor,
                            isDark: isDark,
                            onTap: () => setState(() => _filterOnlyUnread = false),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: "Unread (${state.unreadCount})",
                            isSelected: _filterOnlyUnread,
                            primaryColor: primaryColor,
                            isDark: isDark,
                            onTap: () => setState(() => _filterOnlyUnread = true),
                          ),
                        ],
                      ),
                    ),

                    // List of Notifications
                    Expanded(
                      child: displayList.isEmpty
                          ? _buildEmptyState(isDark)
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              itemCount: displayList.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = displayList[index];
                                return _buildNotificationTile(
                                  context: context,
                                  notification: item,
                                  isDark: isDark,
                                  isTab: isTab,
                                  primaryColor: primaryColor,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Color primaryColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: appPoppinFont,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required BuildContext context,
    required AppNotificationEntity notification,
    required bool isDark,
    required bool isTab,
    required Color primaryColor,
  }) {
    final typeColor = _getColorForType(notification.type);
    final typeIcon = _getIconForType(notification.type);
    final relativeTime = _formatRelativeTime(notification.createdAt);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? (notification.isRead ? const Color(0xFF1E293B) : const Color(0xFF24344D))
                : (notification.isRead ? Colors.white : const Color(0xFFF0F7FF)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? (notification.isRead ? const Color(0xFF334155) : primaryColor.withValues(alpha: 0.3))
                  : (notification.isRead ? const Color(0xFFE2E8F0) : primaryColor.withValues(alpha: 0.2)),
              width: notification.isRead ? 1 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored Icon Capsule
              Container(
                width: isTab ? 44 : 38,
                height: isTab ? 44 : 38,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  typeIcon,
                  size: isTab ? 22 : 19,
                  color: typeColor,
                ),
              ),
              const SizedBox(width: 12),

              // Title, Body & Timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 15 : 13.5,
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          relativeTime,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 12 : 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: isTab ? 13.5 : 12.5,
                        fontWeight: FontWeight.w400,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 48,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "No Notifications",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "You're all caught up! Updates regarding appointments, prescriptions, and records will show up here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerSkeleton(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return BaseShimmer(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 160,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
