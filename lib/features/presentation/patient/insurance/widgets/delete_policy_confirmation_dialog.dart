import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class DeletePolicyConfirmationDialog extends StatefulWidget {
  final Future<void> Function()? onConfirmAsync;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const DeletePolicyConfirmationDialog({
    super.key,
    this.onConfirmAsync,
    this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    Future<void> Function()? onConfirmAsync,
    VoidCallback? onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DeletePolicyConfirmationDialog(
        onConfirmAsync: onConfirmAsync,
        onConfirm: onConfirm ?? (onConfirmAsync == null ? () => Navigator.of(ctx).pop(true) : null),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  State<DeletePolicyConfirmationDialog> createState() => _DeletePolicyConfirmationDialogState();
}

class _DeletePolicyConfirmationDialogState extends State<DeletePolicyConfirmationDialog> {
  bool _isLoading = false;

  Future<void> _handleConfirm() async {
    if (_isLoading) return;

    if (widget.onConfirmAsync != null) {
      setState(() => _isLoading = true);
      try {
        await widget.onConfirmAsync!();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else if (widget.onConfirm != null) {
      widget.onConfirm!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_isLoading,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Capsule Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Delete Confirmation',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                'Are you sure?',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),

              // Description
              Text(
                'Do you really want to delete this policy record? This process cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              // Primary Confirm Button with Loading Spinner
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.65),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Deleting...',
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Yes! Confirm Delete',
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Cancel Button
              TextButton(
                onPressed: _isLoading ? null : (widget.onCancel ?? () => Navigator.of(context).pop(false)),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                  minimumSize: const Size(double.infinity, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
