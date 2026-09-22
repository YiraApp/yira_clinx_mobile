import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'package:yiraclinics/features/data/repository_impl/notifications/notifications_repo_impl.dart';
import 'package:yiraclinics/features/domain/entities/notifications/app_notification_entity.dart';
import 'package:yiraclinics/features/presentation/notifications/bloc/notifications_bloc.dart';
import 'package:yiraclinics/features/presentation/notifications/bloc/notifications_event.dart';
import 'package:yiraclinics/features/presentation/notifications/bloc/notifications_state.dart';
import 'package:yiraclinics/features/use_cases/notifications/clear_all_notifications_use_case.dart';
import 'package:yiraclinics/features/use_cases/notifications/delete_notification_use_case.dart';
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
  final Set<String> _expandedNotificationIds = {};

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
        clearAllNotificationsUseCase: ClearAllNotificationsUseCase(repository: repo),
        deleteNotificationUseCase: DeleteNotificationUseCase(repository: repo),
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

    if (diff.inSeconds < 45) {
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
        return Icons.event_available_rounded;
      case 'APPOINTMENT_STATUS':
        return Icons.calendar_month_rounded;
      case 'APPOINTMENT_REMINDER_10MIN':
        return Icons.alarm_rounded;
      case 'PRESCRIPTION_ADDED':
        return Icons.medication_rounded;
      case 'MEDICAL_RECORD_ADDED':
        return Icons.description_outlined;
      case 'DOCTOR_SUGGESTION':
        return Icons.lightbulb_outline_rounded;
      case 'TELECONSULT_START':
        return Icons.video_camera_front_rounded;
      case 'PROMOTIONS':
      case 'OFFER_PROMOTION':
        return Icons.local_offer_outlined;
      case 'HEALTH_TIPS':
        return Icons.favorite_outline_rounded;
      case 'CONSENT_REQUEST':
      case 'CONSENT_REQUIRED':
      case 'CONSENT_RESPONSE':
        return Icons.verified_user_rounded;
      case 'CONSENT_APPROVED':
        return Icons.check_circle_outline_rounded;
      case 'CONSENT_REVOKED':
        return Icons.remove_circle_outline_rounded;
      case 'CONSENT_REJECTED':
        return Icons.cancel_outlined;
      case 'CONSENT_SENT':
        return Icons.send_rounded;
      case 'SYSTEM_ALERT':
      case 'BROADCAST':
        return Icons.notifications_active_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toUpperCase()) {
      case 'APPOINTMENT_BOOKED':
      case 'APPOINTMENT_STATUS':
        return const Color(0xFF2563EB); // Royal Blue
      case 'APPOINTMENT_REMINDER_10MIN':
        return const Color(0xFFD97706); // Amber
      case 'PRESCRIPTION_ADDED':
        return const Color(0xFF059669); // Emerald Green
      case 'MEDICAL_RECORD_ADDED':
        return const Color(0xFF0D9488); // Teal
      case 'DOCTOR_SUGGESTION':
        return const Color(0xFF6366F1); // Indigo
      case 'TELECONSULT_START':
        return const Color(0xFF7C3AED); // Violet
      case 'PROMOTIONS':
      case 'OFFER_PROMOTION':
        return const Color(0xFFE11D48); // Rose
      case 'HEALTH_TIPS':
        return const Color(0xFF0284C7); // Cyan
      case 'CONSENT_REQUEST':
      case 'CONSENT_REQUIRED':
        return const Color(0xFF0284C7); // Sky Blue
      case 'CONSENT_RESPONSE':
      case 'CONSENT_APPROVED':
        return const Color(0xFF10B981); // Emerald Green
      case 'CONSENT_REVOKED':
        return const Color(0xFFEF4444); // Red
      case 'CONSENT_REJECTED':
        return const Color(0xFFEA580C); // Orange
      case 'CONSENT_SENT':
        return const Color(0xFF6366F1); // Indigo
      case 'SYSTEM_ALERT':
      case 'BROADCAST':
        return const Color(0xFFEA580C); // Orange
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'APPOINTMENT_BOOKED':
        return 'Appointment';
      case 'APPOINTMENT_STATUS':
        return 'Status Update';
      case 'APPOINTMENT_REMINDER_10MIN':
        return 'Reminder';
      case 'PRESCRIPTION_ADDED':
        return 'Prescription';
      case 'MEDICAL_RECORD_ADDED':
        return 'Health Record';
      case 'DOCTOR_SUGGESTION':
        return 'Doctor Tip';
      case 'TELECONSULT_START':
        return 'Teleconsult';
      case 'PROMOTIONS':
      case 'OFFER_PROMOTION':
        return 'Offer';
      case 'HEALTH_TIPS':
        return 'Wellness';
      case 'CONSENT_REQUEST':
      case 'CONSENT_REQUIRED':
        return 'Consent Request';
      case 'CONSENT_APPROVED':
        return 'Access Granted';
      case 'CONSENT_REVOKED':
        return 'Access Revoked';
      case 'CONSENT_REJECTED':
        return 'Access Declined';
      case 'CONSENT_SENT':
        return 'Request Sent';
      case 'CONSENT_RESPONSE':
        return 'Consent Update';
      default:
        return 'Notification';
    }
  }

  void _handleNotificationTap(AppNotificationEntity notification) {
    if (!notification.isRead) {
      _bloc.add(MarkNotificationAsReadEvent(notification.id));
    }

    setState(() {
      if (_expandedNotificationIds.contains(notification.id)) {
        _expandedNotificationIds.remove(notification.id);
      } else {
        _expandedNotificationIds.add(notification.id);
      }
    });
  }

  void _showNotificationDetailSheet(AppNotificationEntity notification) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final typeColor = _getColorForType(notification.type);
    final typeIcon = _getIconForType(notification.type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getTypeLabel(notification.type).toUpperCase(),
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: typeColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatRelativeTime(notification.createdAt),
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                notification.title,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                notification.body,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _bloc.add(DeleteNotificationEvent(notification.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Notification removed"),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      label: const Text(
                        "Delete",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },
                      child: const Text(
                        "Done",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearAllConfirmationDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Clear Notifications",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Text(
            "Are you sure you want to clear all notifications? This will permanently remove them from your notification center.",
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 13.5,
              height: 1.4,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "Cancel",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                _bloc.add(ClearAllNotificationsEvent());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All notifications cleared"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                "Clear All",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, List<AppNotificationEntity>> _groupNotifications(List<AppNotificationEntity> list) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final Map<String, List<AppNotificationEntity>> groups = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    // Guarantee that items are sorted strictly newest-first so new notifications are at the top
    final sortedList = List<AppNotificationEntity>.from(list)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final item in sortedList) {
      final localDate = item.createdAt.toLocal();
      if (!localDate.isBefore(todayStart)) {
        groups['Today']!.add(item);
      } else if (!localDate.isBefore(yesterdayStart)) {
        groups['Yesterday']!.add(item);
      } else {
        groups['Earlier']!.add(item);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
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
        backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
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

              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                ),
              );
            },
          ),
          actions: [
            BlocBuilder<NotificationsBloc, NotificationsState>(
              builder: (context, state) {
                if (state is! NotificationsLoadedState || state.notifications.isEmpty) {
                  return const SizedBox.shrink();
                }

                final hasUnread = state.unreadCount > 0;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasUnread)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          _bloc.add(MarkAllNotificationsAsReadEvent());
                        },
                        child: Text(
                          "Mark all read",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 13 : 12,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: "Clear All Notifications",
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.delete_sweep_outlined,
                        size: 22,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      onPressed: () => _showClearAllConfirmationDialog(context),
                    ),
                    const SizedBox(width: 4),
                  ],
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoadingState) {
              return _buildShimmerSkeleton(isDark);
            }

            if (state is NotificationsErrorState) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _bloc.add(const FetchNotificationsEvent()),
                        child: const Text("Retry", style: TextStyle(fontFamily: appPoppinFont, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is NotificationsLoadedState) {
              final allNotifications = state.notifications;
              final displayList = _filterOnlyUnread
                  ? allNotifications.where((n) => !n.isRead).toList()
                  : allNotifications;

              return RefreshIndicator(
                color: primaryColor,
                onRefresh: () async {
                  _bloc.add(const FetchNotificationsEvent(isRefresh: true));
                },
                child: Column(
                  children: [
                    // Segment Filter Header
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
                            label: "All",
                            count: allNotifications.length,
                            isSelected: !_filterOnlyUnread,
                            primaryColor: primaryColor,
                            isDark: isDark,
                            onTap: () => setState(() => _filterOnlyUnread = false),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: "Unread",
                            count: state.unreadCount,
                            isSelected: _filterOnlyUnread,
                            primaryColor: primaryColor,
                            isDark: isDark,
                            onTap: () => setState(() => _filterOnlyUnread = true),
                          ),
                          const Spacer(),
                          if (allNotifications.isNotEmpty)
                            Text(
                              "Swipe left to delete",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // List of Grouped Notifications
                    Expanded(
                      child: displayList.isEmpty
                          ? _buildEmptyState(isDark, isFiltered: _filterOnlyUnread)
                          : _buildGroupedListView(
                              groupedMap: _groupNotifications(displayList),
                              isDark: isDark,
                              isTab: isTab,
                              primaryColor: primaryColor,
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
    required int count,
    required bool isSelected,
    required Color primaryColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$count",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedListView({
    required Map<String, List<AppNotificationEntity>> groupedMap,
    required bool isDark,
    required bool isTab,
    required Color primaryColor,
  }) {
    final groupKeys = groupedMap.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: groupKeys.length,
      itemBuilder: (context, groupIndex) {
        final groupTitle = groupKeys[groupIndex];
        final items = groupedMap[groupTitle]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
              child: Row(
                children: [
                  Text(
                    groupTitle.toUpperCase(),
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ],
              ),
            ),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildDismissibleNotificationTile(
                  context: context,
                  notification: item,
                  isDark: isDark,
                  isTab: isTab,
                  primaryColor: primaryColor,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildDismissibleNotificationTile({
    required BuildContext context,
    required AppNotificationEntity notification,
    required bool isDark,
    required bool isTab,
    required Color primaryColor,
  }) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              "Delete",
              style: TextStyle(
                fontFamily: appPoppinFont,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        _bloc.add(DeleteNotificationEvent(notification.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Notification deleted"),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: "OK",
              onPressed: () {},
            ),
          ),
        );
      },
      child: _buildNotificationTile(
        context: context,
        notification: notification,
        isDark: isDark,
        isTab: isTab,
        primaryColor: primaryColor,
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
        onLongPress: () => _showNotificationDetailSheet(notification),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? (notification.isRead ? const Color(0xFF1E293B) : const Color(0xFF1E2C44))
                : (notification.isRead ? Colors.white : const Color(0xFFF0F7FF)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? (notification.isRead ? const Color(0xFF334155) : primaryColor.withValues(alpha: 0.35))
                  : (notification.isRead ? const Color(0xFFE2E8F0) : primaryColor.withValues(alpha: 0.25)),
              width: notification.isRead ? 1 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.025),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Capsule
              Container(
                width: isTab ? 44 : 40,
                height: isTab ? 44 : 40,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  typeIcon,
                  size: isTab ? 22 : 20,
                  color: typeColor,
                ),
              ),
              const SizedBox(width: 12),

              // Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Time Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 14.5 : 13.5,
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          relativeTime,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Body with Read more at last of text if longer
                    Builder(
                      builder: (context) {
                        final bool isExpanded = _expandedNotificationIds.contains(notification.id);
                        final String bodyText = notification.body.trim();
                        final bool isLong = bodyText.length > 65;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bodyText,
                              maxLines: isExpanded ? null : 2,
                              overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: isTab ? 13 : 12.5,
                                fontWeight: FontWeight.w400,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                height: 1.35,
                              ),
                            ),
                            if (isLong) ...[
                              const SizedBox(height: 3),
                              GestureDetector(
                                onTap: () => _handleNotificationTap(notification),
                                child: Text(
                                  isExpanded ? "Read less" : "Read more",
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Unread Indicator Dot
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, {bool isFiltered = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered ? Icons.mark_email_read_outlined : Icons.notifications_none_rounded,
                size: 50,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isFiltered ? "No Unread Notifications" : "All Caught Up!",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? "You have read all your notifications."
                  : "You're all caught up! Updates regarding appointments, prescriptions, and health records will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            if (isFiltered) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => setState(() => _filterOnlyUnread = false),
                child: const Text("View All", style: TextStyle(fontFamily: appPoppinFont)),
              ),
            ],
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
                  width: 40,
                  height: 40,
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
