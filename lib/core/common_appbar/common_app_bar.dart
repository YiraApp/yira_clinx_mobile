
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';

import '../common_widgets/common_text.dart';
import '../constants/constants.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? titleText;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? leading;

  const CommonAppBar({
    super.key,
    this.titleText,
    this.onBackPressed,
    this.actions,
    this.showBackButton = true,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasTitle = titleText != null && titleText!.trim().isNotEmpty;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bool isTab = isTablet(context);
    return AppBar(
      backgroundColor: isDarkMode ? Colors.transparent : Colors.white,
      elevation: 0,
      titleSpacing: showBackButton ? 0 : 16,
      automaticallyImplyLeading: showBackButton,
      centerTitle: false,
      leading: showBackButton
          ? (leading ??
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: onBackPressed ?? () => Navigator.pop(context),
              ))
          : leading,
      title: hasTitle
          ? CommonText(
              titleText!,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab
                    ? displayWidth(context) * 0.022
                    : MediaQuery.of(context).size.width * 0.045,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      actions: actions ?? [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}