
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

class CloseAccountButtonSection extends StatelessWidget {
  final bool isSubmitting;
  final bool isButtonEnabled;
  final VoidCallback onConfirmTap;
  final VoidCallback onCancelTap;

  const CloseAccountButtonSection({
    super.key,
    required this.isSubmitting,
    required this.isButtonEnabled,
    required this.onConfirmTap,
    required this.onCancelTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = displayWidth(context);
    final isTab = isTablet(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSubmitting)
            const SizedBox(
              height: 48,
              child: Center(
                child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: isTab ? 56 : 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isButtonEnabled
                      ? Colors.red.shade600
                      : Colors.red.shade200,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                  ),
                ),
                onPressed: isButtonEnabled ? onConfirmTap : null,
                child: Text(
                  'Confirm & Close Account',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? width * 0.02 : width * 0.038,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: isTab ? 56 : 48,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                ),
              ),
              onPressed: isSubmitting ? null : onCancelTap,
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: isTab ? width * 0.02 : width * 0.038,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}