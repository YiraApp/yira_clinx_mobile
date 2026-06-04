
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class UnSyncedDataDialog extends StatelessWidget {
  final VoidCallback onSyncAndClose;
  final VoidCallback onForceClose;

  const UnSyncedDataDialog({
    super.key,
    required this.onSyncAndClose,
    required this.onForceClose,
  });

  @override
  Widget build(BuildContext context) {
    final width = displayWidth(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            Image.asset(
              'assets/icons/export_img.png',
              width: width * 0.16,
              errorBuilder: (_, __, ___) => const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.orange),
            ),
            const SizedBox(height: 16),
            Text(
              'Unsynced Local Data Detected',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: width * 0.042,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Some local records, consultations, or modifications are not yet synced to the cloud. Do you want to process them before shutting down?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: width * 0.034,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onSyncAndClose();
                },
                child: Text(
                  'Sync & Close Account',
                  style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onForceClose();
                },
                child: Text(
                  'Discard & Close Anyway',
                  style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}