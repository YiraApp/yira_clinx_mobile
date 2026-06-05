import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/common_appbar/common_app_bar.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/constants/constants.dart';
import '../theme/theme_bloc/theme_bloc.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double fontScale = isTablet(context) ? 1.2 : 1.0;
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CommonAppBar(

      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(displayWidth(context) * 0.05),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(fieldBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined,
                            color: theme.primaryColor,
                            size: 28 * fontScale),
                        const SizedBox(width: 12),
                        CommonText(
                          "Appearance",
                          style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: displayWidth(context) * 0.038,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    CommonText(
                      "Customize how the application looks",
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: displayWidth(context) * 0.032,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CommonText(
                      "Theme",
                      style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: displayWidth(context) * 0.038,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),

                    const _ThemeSelectorRow(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSelectorRow extends StatelessWidget {
  const _ThemeSelectorRow();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ThemeOptionCard(
              label: "Light",
              icon: Icons.wb_sunny_outlined,
              isSelected: state.themeMode == ThemeMode.light,
              onTap: () => context.read<ThemeBloc>().add(SetThemeEvent(ThemeMode.light)),
              iconColor: Colors.orange.shade400,
            ),
            _ThemeOptionCard(
              label: "Dark",
              icon: Icons.dark_mode_outlined,
              isSelected: state.themeMode == ThemeMode.dark,
              onTap: () => context.read<ThemeBloc>().add(SetThemeEvent(ThemeMode.dark)),
              iconColor: isDark ? Colors.white : const Color(0xFF2D3142),
            ),
            _ThemeOptionCard(
              label: "System",
              icon: Icons.important_devices_outlined,
              isSelected: state.themeMode == ThemeMode.system,
              onTap: () => context.read<ThemeBloc>().add(SetThemeEvent(ThemeMode.system)),
              iconColor: Colors.blue.shade600,
            ),
          ],
        );
      },
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color iconColor;

  const _ThemeOptionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final bool isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: displayWidth(context) * 0.24,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(fieldBorderRadius),
          border: Border.all(
            color: isSelected ? primary : (isDark ? Colors.white24 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? (isDark ? Colors.white.withOpacity(0.05) : primary.withOpacity(0.04))
              : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? primary : iconColor,
              size: 20,
            ),
            const SizedBox(height: 12),
            CommonText(
              label,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: displayWidth(context) * 0.032,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white60 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}