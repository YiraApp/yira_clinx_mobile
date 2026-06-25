import 'package:flutter/material.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/common_widgets/common_text.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import '../../../core/common_widgets/custom_button.dart';
import '../../../core/constants/clinx_storage_keys.dart';
import '../../../core/local/global_session.dart';
import '../../../core/local/shared_preferences.dart';
import '../../../di/dependency_injection.dart';
import '../../domain/entities/login/login_entity.dart';

class UnsupportedRoleScreen extends StatefulWidget {
  final LoginEntity loginEntity;

  const UnsupportedRoleScreen({super.key, required this.loginEntity});

  @override
  State<UnsupportedRoleScreen> createState() => _UnsupportedRoleScreenState();
}

class _UnsupportedRoleScreenState extends State<UnsupportedRoleScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String userId = widget.loginEntity.data?.id ?? '';

      await Future.wait([
        GlobalSession.instance.clear(),
        sl<SharedPrefsService>().setValue<bool>(
          ClinxStorageKeys.isUserLoggedIn,
          false,
        ),
      ]);

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.signIn,
        (route) => false,
      );
    } catch (error) {
      debugPrint(
        "CRITICAL (UnsupportedRoleScreen): Native logout sequence crashed: $error",
      );
      await GlobalSession.instance.clear();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.signIn,
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTab = isTablet(context);
    final double width = displayWidth(context);
    final ThemeData theme = Theme.of(context);

    final double horizontalPadding = isTab ? width * 0.15 : 24.0;
    final double iconSize = isTab ? 100.0 : 80.0;
    final String assignedRole =
        widget.loginEntity.data?.latestUserRole ?? 'Unknown Role';

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              Container(
                height: iconSize,
                width: iconSize,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_person_outlined,
                  size: iconSize * 0.5,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              CommonText(
                'Access Restricted',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: appPoppinFont,
                  fontSize: isTab
                      ? displayWidth(context) * 0.022
                      : displayWidth(context) * 0.055,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              CommonText(
                'Your account is currently configured under the role: "${assignedRole.toUpperCase()}". This clinical workspace only permits access configurations for designated Doctor or Patient terminals.',
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.w400,
                  fontSize: isTab
                      ? displayWidth(context) * 0.022
                      : displayWidth(context) * 0.031,
                ),
                maxLines: null,
                softWrap: true,
                textAlign: TextAlign.center,
              ),

              const Spacer(),
              _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : CustomElevatedButton(
                      text: 'Sign Out of Account',
                      onPressed: _isLoading ? null : _handleLogout,
                      borderRadius: 25.0,
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
