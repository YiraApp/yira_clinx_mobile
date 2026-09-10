import 'package:flutter/material.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/services/notification_services/notification_badge_service.dart';

class NotificationBadgeIcon extends StatelessWidget {
  final Color? iconColor;
  final Color? badgeColor;
  final double size;
  final bool showCapsule;
  final VoidCallback? onTap;

  const NotificationBadgeIcon({
    super.key,
    this.iconColor,
    this.badgeColor,
    this.size = 22,
    this.showCapsule = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final effectiveIconColor = iconColor ?? (isDark ? Colors.white : const Color(0xFF0F172A));
    final effectiveBadgeColor = badgeColor ?? const Color(0xFFEF4444);
    final borderBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return ValueListenableBuilder<int>(
      valueListenable: NotificationBadgeService.instance.unreadCountNotifier,
      builder: (context, count, _) {
        final badgeText = count > 99 ? '99+' : '$count';

        Widget iconWidget = Icon(
          count > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
          size: size,
          color: count > 0 && !showCapsule ? effectiveIconColor : effectiveIconColor,
        );

        if (showCapsule) {
          iconWidget = Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              count > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
              size: size,
              color: primaryColor,
            ),
          );
        }

        return Semantics(
          label: count > 0 ? "Notifications ($count unread)" : "Notifications",
          button: true,
          child: IconButton(
            tooltip: 'Notifications',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            onPressed: () async {
              if (onTap != null) {
                onTap!();
              } else {
                await Navigator.pushNamed(context, AppRoutes.recentNotifications);
                NotificationBadgeService.instance.syncUnreadCount();
              }
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                iconWidget,
                if (count > 0)
                  Positioned(
                    top: showCapsule ? -2 : -4,
                    right: showCapsule ? -2 : -4,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      child: Container(
                        key: ValueKey<int>(count),
                        padding: EdgeInsets.symmetric(
                          horizontal: count > 9 ? 5.0 : 4.0,
                          vertical: 1.5,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: effectiveBadgeColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: borderBg,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: effectiveBadgeColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
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
