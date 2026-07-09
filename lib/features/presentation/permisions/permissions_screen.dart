import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/permisions/permission_bloc/permission_bloc.dart';
import 'package:yiraclinics/features/presentation/permisions/widgets/permission_card_tile.dart';
import 'package:yiraclinics/features/presentation/permisions/widgets/section_header.dart';

import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/common_widgets/custom_button.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);
    final double screenWidth = displayWidth(context);

    // Calculate dynamic horizontal padding for tablet viewports to naturally center a 550px spine
    final double tabletPadding = isTab ? (screenWidth - 550) / 2 : 0.0;

    return BlocProvider(
      create: (context) => PermissionsBloc()..add(LoadPermissionsEvent()),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          titleSpacing: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          backgroundColor: theme.appBarTheme.backgroundColor,
          leading: Padding(
            padding: EdgeInsets.only(left: isTab ? tabletPadding + 8 : 8.0),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<PermissionsBloc, PermissionsState>(
            builder: (context, state) {
              if (state is PermissionsLoading) {
                return Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                );
              }

              if (state is PermissionsLoaded) {
                final requiredList = state.permissions
                    .where((p) => p.isRequired)
                    .toList();
                final optionalList = state.permissions
                    .where((p) => !p.isRequired)
                    .toList();

                // Establish the internal content scaling threshold limit safely
                final double referenceWidth = isTab ? 550 : screenWidth;

                return Column(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            (screenWidth * 0.05) + tabletPadding,
                            20,
                            (screenWidth * 0.05) + tabletPadding,
                            20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CommonText(
                                'Permissions',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.headlineMedium?.color,
                                  fontFamily: appPoppinFont,
                                  fontSize: referenceWidth * 0.04,
                                ),
                                maxLines: 1,
                              ),
                              const SizedBox(height: 10),
                              CommonText(
                                'To provide clinical-grade monitoring and seamless care, Yira Clinx requires the following access.',
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontFamily: appPoppinFont,
                                  fontSize:isTab?  displayWidth(context)*0.018: referenceWidth * 0.032,
                                  color: theme.textTheme.bodyLarge?.color
                                      ?.withOpacity(0.65),
                                  height: 1.4,
                                ),
                                maxLines: 4,
                                softWrap: true,
                              ),

                              if (requiredList.isNotEmpty) ...[
                                const SectionHeader(
                                  title: 'Required Permissions',
                                ),
                                const SizedBox(height: 8),
                                ...requiredList.map(
                                      (item) => PermissionCardTile(
                                    item: item,
                                    onToggle: (_) => context
                                        .read<PermissionsBloc>()
                                        .add(TogglePermissionEvent(item.id)), isTab: isTab,
                                  ),
                                ),
                              ],

                              if (optionalList.isNotEmpty) ...[
                                const SectionHeader(title: 'Optional'),
                                const SizedBox(height: 8),
                                ...optionalList.map(
                                      (item) => PermissionCardTile(
                                    item: item,
                                    onToggle: (_) => context
                                        .read<PermissionsBloc>()
                                        .add(TogglePermissionEvent(item.id)), isTab: isTab,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Fixed Action panel matching your core layouts
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surface
                            : theme.scaffoldBackgroundColor,
                        border: Border(
                          top: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.05),
                            width: 1,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.25 : 0.03,
                            ),
                            blurRadius: 15,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            (screenWidth * 0.05) + tabletPadding,
                            16,
                            (screenWidth * 0.05) + tabletPadding,
                            12,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomElevatedButton(
                                noElevation: true,
                                height: 50,
                                width: double.infinity,
                                text: "Allow & Continue",
                                onPressed: () {},
                              ),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                  splashFactory: NoSplash.splashFactory,
                                ),
                                child: CommonText(
                                  'Configure Later',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w400,
                                    color: theme.textTheme.headlineMedium?.color,
                                    fontFamily: appPoppinFont,
                                    fontSize:isTab?  displayWidth(context)*0.022: referenceWidth * 0.032,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}