import 'package:flutter/material.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';

/// What a dialog is about. Sets its accent colour and default icon.
enum AppDialogTone { info, success, warning, danger }

/// The app's standard popup: an icon badge, a title, a short message and one
/// or two actions.
///
/// Use [AppDialog.confirm] for a yes/no question and [AppDialog.alert] for a
/// message with a single button. Build an [AppDialog] directly (inside
/// [showDialog]) when the buttons need their own behaviour, such as a loading
/// state or an action that should not close the dialog.
class AppDialog extends StatelessWidget {
  final String title;
  final String? message;

  /// Extra content under the message, e.g. a summary card.
  final Widget? content;

  final AppDialogTone tone;

  /// Overrides the tone's default icon.
  final IconData? icon;

  /// Replaces the icon inside the badge, e.g. an asset image.
  final Widget? badge;

  /// Overrides the tone's colour for the badge and the primary button.
  final Color? accentColor;

  final String primaryLabel;

  /// Defaults to closing the dialog with `true`.
  final VoidCallback? onPrimary;

  final String? secondaryLabel;

  /// Defaults to closing the dialog with `false`.
  final VoidCallback? onSecondary;

  /// Shows a spinner in the primary button and disables both actions.
  final bool isPrimaryLoading;

  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.tone = AppDialogTone.info,
    this.icon,
    this.badge,
    this.accentColor,
    required this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.isPrimaryLoading = false,
  });

  /// Asks a yes/no question. Resolves to true only if the user confirms.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    AppDialogTone tone = AppDialogTone.info,
    IconData? icon,
    Color? accentColor,
    bool barrierDismissible = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => AppDialog(
        title: title,
        message: message,
        content: content,
        tone: tone,
        icon: icon,
        accentColor: accentColor,
        primaryLabel: confirmLabel,
        secondaryLabel: cancelLabel,
      ),
    );
    return result == true;
  }

  /// Shows a message with a single button.
  static Future<void> alert(
    BuildContext context, {
    required String title,
    String? message,
    Widget? content,
    String buttonLabel = 'OK',
    AppDialogTone tone = AppDialogTone.info,
    IconData? icon,
    Color? accentColor,
    bool barrierDismissible = true,
  }) async {
    // The button closes the dialog with `true`, so the route is typed as bool.
    await showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => AppDialog(
        title: title,
        message: message,
        content: content,
        tone: tone,
        icon: icon,
        accentColor: accentColor,
        primaryLabel: buttonLabel,
      ),
    );
  }

  static Color toneColor(AppDialogTone tone) {
    switch (tone) {
      case AppDialogTone.info:
        return primaryColor;
      case AppDialogTone.success:
        return const Color(0xFF10B981);
      case AppDialogTone.warning:
        return const Color(0xFFF59E0B);
      case AppDialogTone.danger:
        return const Color(0xFFEF4444);
    }
  }

  IconData get _defaultIcon {
    switch (tone) {
      case AppDialogTone.info:
        return Icons.info_outline_rounded;
      case AppDialogTone.success:
        return Icons.check_circle_outline_rounded;
      case AppDialogTone.warning:
        return Icons.warning_amber_rounded;
      case AppDialogTone.danger:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? toneColor(tone);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final bodyColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    // Two long labels do not fit side by side on a phone, so stack them.
    final stackActions =
        secondaryLabel != null && primaryLabel.length + secondaryLabel!.length > 26;

    return Dialog(
      backgroundColor: isDark ? darkModeCardColor : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.transparent),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: badge ?? Icon(icon ?? _defaultIcon, color: accent, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: titleColor,
                ),
              ),
              if (message != null && message!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: bodyColor,
                  ),
                ),
              ],
              if (content != null) ...[
                const SizedBox(height: 16),
                content!,
              ],
              const SizedBox(height: 24),
              if (stackActions) ...[
                SizedBox(width: double.infinity, child: _buildPrimary(context, accent)),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: _buildSecondary(context, isDark)),
              ] else
                Row(
                  children: [
                    if (secondaryLabel != null) ...[
                      Expanded(child: _buildSecondary(context, isDark)),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: _buildPrimary(context, accent)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimary(BuildContext context, Color accent) {
    return FilledButton(
      onPressed: isPrimaryLoading ? null : (onPrimary ?? () => Navigator.of(context).pop(true)),
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: accent.withValues(alpha: 0.6),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: isPrimaryLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
            )
          : _label(primaryLabel, FontWeight.w700),
    );
  }

  Widget _buildSecondary(BuildContext context, bool isDark) {
    return OutlinedButton(
      onPressed: isPrimaryLoading ? null : (onSecondary ?? () => Navigator.of(context).pop(false)),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _label(secondaryLabel!, FontWeight.w600),
    );
  }

  Widget _label(String text, FontWeight weight) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: weight),
      ),
    );
  }
}
