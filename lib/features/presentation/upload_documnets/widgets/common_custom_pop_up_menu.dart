import 'package:flutter/material.dart';
import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../model/app_pop_up_model.dart';

class CommonCustomPopupMenu extends StatelessWidget {
  final List<AppPopupItemModel> items;
  final Widget child;
  final double? arrowSize;
  final double? menuRadius;

  const CommonCustomPopupMenu({
    super.key,
    required this.items,
    required this.child,
    this.arrowSize = 10,
    this.menuRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isTab = isTablet(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
 final Color menuBackground = isDark
        ? theme.colorScheme.surface
        : Colors.white;

    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.grey.withOpacity(0.2);

    final CustomPopupMenuController menuController = CustomPopupMenuController();

    return CustomPopupMenu(
      enablePassEvent: true,
      showArrow: true,
      controller: menuController,
      arrowSize: arrowSize!,
      arrowColor: menuBackground, // Matches the solid color background token perfectly
      barrierColor: Colors.transparent,
      pressType: PressType.singleClick,
      verticalMargin: 4,
      menuBuilder: () => Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: menuBackground,
          borderRadius: BorderRadius.circular(menuRadius!),
          border: Border.all(width: 1, color: borderColor),
          boxShadow: isDark
              ? null
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: _buildMenuItems(
              context,
              isDark,
              theme,
              menuController,isTab
            ),
          ),
        ),
      ),
      child: child,
    );
  }

  List<Widget> _buildMenuItems(
      BuildContext context,
      bool isDark,
      ThemeData theme,
      CustomPopupMenuController controller,
      bool isTab
      ) {
    final List<Widget> menuWidgets = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      if (item.isDestructive && i > 0) {
        menuWidgets.add(
          Divider(
            height: 8,
            thickness: 0.5,
            color: isDark ? Colors.white10 : const Color(0xFFE9EBF0),
          ),
        );
      }

      menuWidgets.add(
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            controller.hideMenu();
            item.onTap();
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 16,
                  color: item.iconColor ??
                      (item.isDestructive
                          ? Colors.redAccent
                          : theme.primaryColor),
                ),
                const SizedBox(width: 10),
                CommonText(
                  item.title,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize:isTab? displayWidth(context) * 0.018: displayWidth(context) * 0.032,
                    fontWeight: FontWeight.w500,
                    color: item.textColor ??
                        (item.isDestructive
                            ? Colors.redAccent
                            : (isDark
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black87)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return menuWidgets;
  }
}