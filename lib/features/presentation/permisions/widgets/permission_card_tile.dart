// presentation/widgets/permission_card_tile.dart
import 'package:flutter/material.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';
import '../../../domain/entities/permissions/permision_entity.dart';

class PermissionCardTile extends StatelessWidget {
  final PermissionItemEntity item;
  final ValueChanged<bool> onToggle;
  final bool isTab;

  const PermissionCardTile({
    super.key,
    required this.item,
    required this.onToggle, required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: theme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText(
                  item.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: appPoppinFont,
                      fontSize:isTab?  displayWidth(context)*0.024: displayWidth(context)*0.035),
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                CommonText(
                  item.description,
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontFamily: appPoppinFont,
                      fontSize: isTab?  displayWidth(context)*0.018:displayWidth(context)*0.032
                  ),
                  maxLines: 2,
                  softWrap: true,
                ),
              ],
            ),
          ),
          // Adaptive Switch
          Switch.adaptive(
            value: item.isGranted,
            activeColor: theme.primaryColor,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}