import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';

/// Look of the patient diet screens. Matches the rest of the patient app
/// (Doctor Suggestions, Vitals): slate background, white app bar with a
/// title and subtitle, white 16 px cards with a hairline border, and small
/// tinted badges and pills in the primary blue.
class DietUi {
  static const Color blue = Color(0xFF2563EB);
  static const Color green = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color slate = Color(0xFF64748B);

  static Color background(bool isDark) => isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  static Color card(bool isDark) => isDark ? const Color(0xFF1E293B) : Colors.white;

  /// Panels set inside a card (stats, inputs).
  static Color sunken(bool isDark) => isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  static Color line(bool isDark) => isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
  static Color strong(bool isDark) => isDark ? Colors.white : const Color(0xFF0F172A);
  static Color body(bool isDark) => isDark ? Colors.white70 : const Color(0xFF475569);
  static Color muted(bool isDark) => isDark ? Colors.white60 : const Color(0xFF64748B);
  static Color hint(bool isDark) => isDark ? Colors.white38 : const Color(0xFF94A3B8);

  static TextStyle text(double size, FontWeight weight, Color color, {double? height, double? spacing}) =>
      TextStyle(fontFamily: appPoppinFont, fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: spacing);

  static BoxDecoration cardDecoration(bool isDark, {double radius = 16, Color? borderColor}) {
    return BoxDecoration(
      color: card(isDark),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? line(isDark)),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// The app's standard screen header: back arrow, bold title, grey subtitle.
  static PreferredSizeWidget appBar(
    BuildContext context,
    bool isDark, {
    required String title,
    String? subtitle,
    Widget? subtitleWidget,
    Widget? titleTrailing,
    double toolbarHeight = 56,
    List<Widget> actions = const [],
  }) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: card(isDark),
      toolbarHeight: toolbarHeight,
      leadingWidth: 48,
      titleSpacing: 6,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: line(isDark),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.maybePop(context),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: strong(isDark),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (titleTrailing == null)
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text(16, FontWeight.w700, strong(isDark), spacing: -0.2, height: 1.25),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 2,
                    softWrap: true,
                    style: text(16, FontWeight.w700, strong(isDark), spacing: -0.2, height: 1.25),
                  ),
                ),
                const SizedBox(width: 8),
                titleTrailing,
              ],
            ),
          if (subtitleWidget != null) ...[
            const SizedBox(height: 2),
            subtitleWidget,
          ] else if (subtitle != null && subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              softWrap: true,
              style: text(11.5, FontWeight.w500, muted(isDark), height: 1.25),
            ),
          ],
        ],
      ),
      actions: actions.isEmpty ? null : [...actions, const SizedBox(width: 8)],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              color: line(isDark),
              height: 1,
            ),
          ],
        ),
      ),
    );
  }

  /// A tinted rounded icon button for app bar actions.
  static Widget actionIcon(
    IconData icon,
    bool isDark,
    VoidCallback onTap, {
    String? tooltip,
    Color? color,
  }) {
    final iconColor = color ?? blue;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Tooltip(
          message: tooltip ?? '',
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: line(isDark),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(19),
                onTap: onTap,
                child: Center(
                  child: Icon(icon, size: 18, color: iconColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A sleek gradient pill button for the app bar, e.g. "New Plan".
  static Widget actionButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    final primary = color ?? blue;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primary,
                Color.lerp(primary, const Color(0xFF1D4ED8), 0.35) ?? primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.32),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(icon, size: 13, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: text(12.5, FontWeight.w700, Colors.white, spacing: 0.2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget pill(String label, Color color, bool isDark, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(label, style: text(11, FontWeight.w600, color)),
        ],
      ),
    );
  }

  static Widget iconBadge(IconData icon, Color color, bool isDark, {double size = 40, double iconSize = 20}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }

  static Widget sectionLabel(String label, bool isDark, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10, top: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text(12, FontWeight.w700, muted(isDark), spacing: 0.6))),
          ?trailing,
        ],
      ),
    );
  }

  /// A rounded notice box (info, warning) like the app's inline banners.
  static Widget notice(String message, Color color, IconData icon, bool isDark, {Widget? action}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: text(12, FontWeight.w500, body(isDark), height: 1.4))),
          ?action,
        ],
      ),
    );
  }

  static String statusLabel(String status, {bool isExpired = false}) {
    if (status == 'active') return isExpired ? 'Ended' : 'Active';
    if (status == 'paused') return isExpired ? 'Ended' : 'Paused';
    if (status == 'cancelled') return 'Stopped by doctor';
    return isExpired ? 'Ended' : 'Inactive';
  }

  static Color statusColor(String status, {bool isExpired = false}) {
    if (isExpired) return slate;
    return switch (status) {
      'active' => green,
      'paused' => amber,
      'cancelled' => red,
      _ => slate,
    };
  }

  /// Icon and colour for a meal slot, so each meal is easy to spot.
  static ({IconData icon, Color color}) slotStyle(String slot) {
    final s = slot.toLowerCase();
    if (s.contains('early')) return (icon: Icons.wb_twilight_rounded, color: amber);
    if (s.contains('breakfast')) return (icon: Icons.free_breakfast_rounded, color: const Color(0xFFF97316));
    if (s.contains('mid')) return (icon: Icons.eco_rounded, color: green);
    if (s.contains('lunch')) return (icon: Icons.lunch_dining_rounded, color: blue);
    if (s.contains('snack') || s.contains('evening') || s.contains('tea')) {
      return (icon: Icons.local_cafe_rounded, color: violet);
    }
    if (s.contains('dinner')) return (icon: Icons.dinner_dining_rounded, color: const Color(0xFF6366F1));
    if (s.contains('bed') || s.contains('night')) return (icon: Icons.bedtime_rounded, color: const Color(0xFF0EA5E9));
    return (icon: Icons.restaurant_rounded, color: blue);
  }
}
