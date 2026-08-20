import 'package:flutter/material.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import '../../common_widgets/common_text.dart';

class DrawerHeaderProfile extends StatelessWidget {
  final double currentDrawerWidth;
  final bool isTab;
  final String? profileImageUrl;

  const DrawerHeaderProfile({
    super.key,
    required this.currentDrawerWidth,
    required this.isTab,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = GlobalSession.instance.userNotifier.value?.data;

    final fullName = "${currentUser?.firstName ?? ''} ${currentUser?.lastName ?? ''}".trim();
    final prefix = (fullName.isNotEmpty && !fullName.toLowerCase().startsWith('dr.') && !fullName.toLowerCase().startsWith('dr '))
        ? 'Dr. '
        : '';
    final doctorName = fullName.isNotEmpty ? '$prefix$fullName' : 'Dr. Healthcare Provider';
    final roleName = currentUser?.latestUserRole ?? 'Healthcare Provider';

    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // close drawer
        Navigator.pushNamed(context, AppRoutes.profile);
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: currentDrawerWidth * 0.09,
          top: currentDrawerWidth * 0.09,
          right: currentDrawerWidth * 0.07,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.4)],
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: currentDrawerWidth * 0.115,
                  backgroundColor: isDark ? const Color(0xFF232733) : const Color(0xFFE9ECEF),
                  backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                  child: profileImageUrl == null
                      ? Icon(Icons.person_rounded, size: currentDrawerWidth * 0.115, color: theme.primaryColor.withOpacity(0.7))
                      : null,
                ),
              ),
            ),
            SizedBox(height: currentDrawerWidth * 0.06),
            Row(
              children: [
                Expanded(
                  child: CommonText(
                    doctorName,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: currentDrawerWidth * (isTab ? 0.052 : 0.05),
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0A2540),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            CommonText(
              roleName,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: currentDrawerWidth * (isTab ? 0.042 : 0.038),
                color: isDark ? Colors.white60 : Colors.grey.withOpacity(0.8),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}