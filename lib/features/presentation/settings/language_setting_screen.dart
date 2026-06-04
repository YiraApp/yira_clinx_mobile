
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/features/presentation/settings/setting_bloc/setting_bloc.dart';

import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_button.dart';
import '../../../core/constants/constants.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double fontScale = isTablet(context) ? 1.2 : 1.0;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.language, color: theme.primaryColor, size: 28 * fontScale),
            const SizedBox(width: 12),
            CommonText(
              "Language Settings",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: displayWidth(context) * 0.045,
                fontWeight: FontWeight.w600,
                color: theme.textTheme.titleLarge?.color,
              ),
            )
          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: theme.appBarTheme.iconTheme?.color,
            size: displayWidth(context) * 0.06,
          ),
          onPressed: () => Navigator.pop(context),
        ),

      ),
      body: BlocConsumer<SettingsBloc,SettingsState>(
        builder: (context, state) {
          String getLanguageDisplayName(String code) {
            switch (code) {
              case 'hi': return 'Hindi (हिन्दी)';
              case 'te': return 'Telugu (తెలుగు)';
              case 'mr': return 'Marathi (मराठी)';
              case 'ta': return 'Tamil (தமிழ்)';
              default: return 'English (English)';
            }
          }

          final currentFullDisplayName = getLanguageDisplayName(state.selectedLanguageCode);
          final languageOnly = currentFullDisplayName.split(' ')[0];

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: screenHorizontalSpacePadding,
                vertical: 20.0
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonText(
                  'Select Language',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.035,
                    letterSpacing: 1.1,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                CommonText(
                  maxLines: null,
                  softWrap: true,
                  'Choose your preferred language for the application interface and communications.',
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: displayWidth(context) * 0.032,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),
                _LanguageCard(
                  label: 'English',
                  nativeLabel: 'English',
                  isSelected: state.selectedLanguageCode == 'en',
                  fontScale: fontScale,
                  onTap: () => context.read<SettingsBloc>().add(LanguageChanged('en')),
                ),
                _LanguageCard(
                  label: 'Hindi',
                  nativeLabel: 'हिन्दी',
                  isSelected: state.selectedLanguageCode == 'hi',
                  fontScale: fontScale,
                  onTap: () => context.read<SettingsBloc>().add(LanguageChanged('hi')),
                ),
                _LanguageCard(
                  label: 'Telugu',
                  nativeLabel: 'తెలుగు',
                  isSelected: state.selectedLanguageCode == 'te',
                  fontScale: fontScale,
                  onTap: () => context.read<SettingsBloc>().add(LanguageChanged('te')),
                ),
                _LanguageCard(
                  label: 'Marathi',
                  nativeLabel: 'मराठी',
                  isSelected: state.selectedLanguageCode == 'mr',
                  fontScale: fontScale,
                  onTap: () => context.read<SettingsBloc>().add(LanguageChanged('mr')),
                ),
                _LanguageCard(
                  label: 'Tamil',
                  nativeLabel: 'தமிழ்',
                  isSelected: state.selectedLanguageCode == 'ta',
                  fontScale: fontScale,
                  onTap: () => context.read<SettingsBloc>().add(LanguageChanged('ta')),
                ),

                const SizedBox(height: 24),

                // Feedback box for current selection
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonText(
                        'Current selection: $currentFullDisplayName',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: displayWidth(context) * 0.035,
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CommonText(
                        'The interface will be displayed in $languageOnly after saving. Some system notifications may still appear in the default system language.',
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: displayWidth(context) * 0.032,
                          height: 1.4,
                        ),
                        maxLines: 5,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                CustomElevatedButton(
                  text: state.isSaving ? 'SAVING...' : 'Save Changes',
                  onPressed: state.isSaving
                      ? null
                      : () => context.read<SettingsBloc>().add(SaveSettingsPressed()),
                  backgroundColor: theme.primaryColor,
                  textColor: Colors.white,
                  borderRadius: 25.0, // Matches your AppTheme rounded style
                  height: 54.0,
                  icon: state.isSaving
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                      : null,
                ),
              ],
            ),
          );
        }
      , listener: (_,_){})
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String label;
  final String nativeLabel;
  final bool isSelected;
  final double fontScale;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.label,
    required this.nativeLabel,
    required this.isSelected,
    required this.fontScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: isTablet(context) ? 22 : 12
          ),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected ? theme.primaryColor : Colors.grey.shade300,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText(
                    label,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: displayWidth(context) * 0.032,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  CommonText(
                    nativeLabel,
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: displayWidth(context) * 0.038,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18 * fontScale,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}