import 'package:flutter/material.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import '../../common_widgets/common_text.dart';
import '../../local/global_session.dart';
import '../../package/domain/plat_form_info_entity.dart';

class DrawerFooterVersion extends StatelessWidget {
  final double targetWidth;
  final bool isTab;

  const DrawerFooterVersion({
    super.key,
    required this.targetWidth,
    required this.isTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<PlatformInfoEntity?>(
      valueListenable: GlobalSession.instance.platformNotifier,
      builder: (context, platformInfo, _) {
        return Padding(
          padding: EdgeInsets.only(left: targetWidth * 0.1, bottom: 20.0, top: 12.0),
          child: CommonText(
            'App Version- ${platformInfo?.version ?? ''}',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: targetWidth * (isTab ? 0.04 : 0.034),
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}