
import 'package:flutter/material.dart';

import '../common_widgets/common_text.dart';
import '../constants/constants.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? titleText;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const CommonAppBar({
    super.key,
    this.titleText,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasTitle = titleText != null && titleText!.trim().isNotEmpty;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      backgroundColor:isDarkMode? Colors.transparent:Colors.white,
      elevation: 0,
      titleSpacing: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 20),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      ),
      title: hasTitle
          ? CommonText(
        titleText!,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: MediaQuery.of(context).size.width * 0.045,
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