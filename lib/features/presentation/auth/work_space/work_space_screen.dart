import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/auth/work_space/widgets/organization_card.dart';
import 'package:yiraclinics/features/presentation/auth/work_space/work_space_bloc/work_space_bloc.dart';
import '../../../../core/colors/colors.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';

class WorkspaceScreen extends StatefulWidget {
  final bool? isInApp;

  const WorkspaceScreen({
    super.key,
    this.isInApp = false,
  });

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    final mainHeadingColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final paragraphColor = isDarkMode ? Colors.white60 : const Color(0xFF64748B);
    final panelBg = isDarkMode ? theme.cardColor : Colors.white;
    final bool currentIsInApp = widget.isInApp ?? false;

    return BlocProvider(
      create: (context) => WorkspaceBloc()..add(LoadWorkspacesEvent()),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: currentIsInApp
            ? AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: mainHeadingColor, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        )
            : null,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTab ? 650 : double.infinity,
              ),
              child: Column(
                children: [
                  SizedBox(height: currentIsInApp ? 0 : 24),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentIsInApp ? Icons.admin_panel_settings_rounded : Icons.health_and_safety, // Conveys secure access management
                        color: primaryColor,
                        size: isTab ? 65 : 55,
                      ),
                      const SizedBox(height: 14),
                      currentIsInApp
                          ? CommonText(
                        'Identity & Access Management',
                        style: TextStyle(
                          fontSize: displayWidth(context) * (isTab ? 0.024 : 0.048),
                          fontWeight: FontWeight.w600,
                          fontFamily: appPoppinFont,
                          color: mainHeadingColor,
                          letterSpacing: -0.5,
                        ),
                      )
                          : RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: displayWidth(context) * (isTab ? 0.045 : 0.07),
                            letterSpacing: -0.8,
                          ),
                          children: [
                            TextSpan(
                              text: 'Current Session: ',
                              style: TextStyle(
                                fontWeight: FontWeight.w400,
                                color: isDarkMode ? Colors.white70 : scoreSubTextColor,
                                fontSize: displayWidth(context) * (isTab ? 0.025 : 0.065),
                              ),
                            ),
                            TextSpan(
                              text: 'Bhargava',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontFamily: appPoppinFont,
                                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                fontSize: displayWidth(context) * (isTab ? 0.025 : 0.065),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.0),
                        child: CommonText(
                          currentIsInApp
                              ? 'Switch your active tenant profile to load localized operational records, patient databases, and facility permissions.'
                              : 'Select an organization to view hospitals',
                          softWrap: true,
                          maxLines: null,
                          style: TextStyle(
                            fontSize: displayWidth(context) * (isTab ? 0.016 : 0.028),
                            fontWeight: isTab ? FontWeight.w400 : FontWeight.w500,
                            fontFamily: appPoppinFont,
                            color: currentIsInApp ? paragraphColor : null,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: currentIsInApp ? 20 : 36),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: screenHorizontalSpacePadding),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isTab ? 28 : 24),
                        decoration: BoxDecoration(
                          color: panelBg,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey.shade200.withOpacity(0.8),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: .start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      currentIsInApp ? 'Authorized Directories' : 'Workspaces',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize: displayWidth(context) * (isTab ? 0.028 : 0.046),
                                        fontWeight: isTab ? FontWeight.w600 : FontWeight.bold,
                                        color: mainHeadingColor,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8), // Enhanced professional layout alignment
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        currentIsInApp ? Icons.lan_rounded : Icons.domain_rounded, // Local Area Network/Enterprise topology visual
                                        color: theme.primaryColor,
                                        size: isTab ? 26 : 22,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 0,),
                                Text(

                                      currentIsInApp
                                          ? 'Select an enterprise domain linked to your credentials'
                                          : 'Available organizations and hospitals',
                                      softWrap: true,
                                      maxLines: null,
                                      style: TextStyle(
                                        fontSize: displayWidth(context) * (isTab ? 0.016 : 0.028),
                                        fontFamily: appPoppinFont,
                                        color: paragraphColor,
                                      ),
                                    ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Expanded(
                              child: BlocBuilder<WorkspaceBloc, WorkspaceState>(
                                builder: (context, state) {
                                  if (state is WorkspaceLoading) {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          theme.primaryColor,
                                        ),
                                      ),
                                    );
                                  }
                                  if (state is WorkspacesLoaded) {
                                    return ListView.builder(
                                      itemCount: state.organizations.length,
                                      physics: const BouncingScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      itemBuilder: (context, index) {
                                        return OrganizationCard(
                                          isTablet: isTab,
                                          org: state.organizations[index]!,
                                        );
                                      },
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Spacer / Interactive Safe Element
                  currentIsInApp
                      ? const SizedBox(height: 24)
                      : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Cancel Login'),
                      style: TextButton.styleFrom(
                        foregroundColor: paragraphColor,
                        textStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontFamily: appPoppinFont,
                          fontSize: displayWidth(context) * (isTab ? 0.018 : 0.034),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}