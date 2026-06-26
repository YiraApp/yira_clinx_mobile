import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:yiraclinics/config/yira_colors/yira_colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/auth/work_space/widgets/organization_card.dart';
import 'package:yiraclinics/features/presentation/auth/work_space/work_space_bloc/work_space_bloc.dart';
import 'package:yiraclinics/features/use_cases/get_work_space_details_use_case.dart';
import '../../../../core/colors/colors.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/common_widgets/common_text.dart';
import '../../../../core/local/global_session.dart';
import '../../../../di/dependency_injection.dart';
import '../../../domain/entities/login/login_entity.dart';

class WorkspaceScreen extends StatefulWidget {
  final bool? isInApp;
  final RoleEntity? roleEntity;
  const WorkspaceScreen({super.key, this.isInApp = false, this.roleEntity});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  late final WorkspaceBloc _workspaceBloc;
  final currentUser = GlobalSession.instance.userNotifier.value;

  @override
  void initState() {
    super.initState();

    _workspaceBloc = WorkspaceBloc(
      getWorkSpaceDetailsUseCase: sl<GetWorkSpaceDetailsUseCase>(),
    );

    final params = WorkSpaceParameters(
      currentUser?.data?.id ?? '',
      widget.roleEntity?.roleId ?? '',
    );

    _workspaceBloc.add(LoadWorkspacesEvent(params));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bool isTab = isTablet(context);

    final mainHeadingColor = isDarkMode
        ? Colors.white
        : const Color(0xFF0F172A);
    final paragraphColor = isDarkMode
        ? Colors.white60
        : const Color(0xFF64748B);
    final panelBg = isDarkMode ? theme.cardColor : Colors.white;
    final bool currentIsInApp = widget.isInApp ?? false;

    // 4. Use BlocProvider.value to inject the pre-initialized BLoC instance
    return BlocProvider.value(
      value: _workspaceBloc,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: currentIsInApp
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: mainHeadingColor,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              )
            : AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
                      currentIsInApp
                          ? Icon(
                              Icons.admin_panel_settings_rounded,
                              color: primaryColor,
                              size: isTab ? 65 : 55,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: SvgPicture.asset(
                                'assets/images/svgs/ic_apps_logo.svg',
                                width: isTab ? 65 : 60,
                                height: isTab ? 65 : 60,
                              ),
                            ),
                      const SizedBox(height: 14),
                      currentIsInApp
                          ? CommonText(
                              'Identity & Access Management',
                              style: TextStyle(
                                fontSize:
                                    displayWidth(context) *
                                    (isTab ? 0.024 : 0.048),
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
                                  fontSize:
                                      displayWidth(context) *
                                      (isTab ? 0.045 : 0.07),
                                  letterSpacing: -0.8,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Current Session: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : scoreSubTextColor,
                                      fontSize:
                                          displayWidth(context) *
                                          (isTab ? 0.025 : 0.065),
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '${currentUser?.data?.firstName ?? ''} ${currentUser?.data?.lastName ?? ''}'
                                            .trim()
                                            .isNotEmpty
                                        ? '${currentUser?.data?.firstName} ${currentUser?.data?.lastName}'
                                        : 'Rajesh Nagalingam',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontFamily: appPoppinFont,
                                      color: isDarkMode
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      fontSize:
                                          displayWidth(context) *
                                          (isTab ? 0.025 : 0.065),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: CommonText(
                          currentIsInApp
                              ? 'Switch your active tenant profile to load localized operational records, patient databases, and facility permissions.'
                              : 'Select an organization to view hospitals',
                          softWrap: true,
                          maxLines: null,
                          style: TextStyle(
                            fontSize:
                                displayWidth(context) * (isTab ? 0.016 : 0.028),
                            fontWeight: isTab
                                ? FontWeight.w400
                                : FontWeight.w500,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: screenHorizontalSpacePadding,
                      ),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      currentIsInApp
                                          ? 'Authorized Directories'
                                          : 'Workspaces',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize:
                                            displayWidth(context) *
                                            (isTab ? 0.028 : 0.046),
                                        fontWeight: isTab
                                            ? FontWeight.w600
                                            : FontWeight.bold,
                                        color: mainHeadingColor,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          fieldBorderRadius,
                                        ),
                                      ),
                                      child: Icon(
                                        currentIsInApp
                                            ? Icons.lan_rounded
                                            : Icons.domain_rounded,
                                        color: theme.primaryColor,
                                        size: isTab ? 26 : 22,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currentIsInApp
                                      ? 'Select an enterprise domain linked to your credentials'
                                      : 'Available organizations and hospitals',
                                  softWrap: true,
                                  maxLines: null,
                                  style: TextStyle(
                                    fontSize:
                                        displayWidth(context) *
                                        (isTab ? 0.016 : 0.028),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              theme.primaryColor,
                                            ),
                                      ),
                                    );
                                  }

                                  if (state is WorkspaceError) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error_outline_rounded,
                                              color: theme.colorScheme.error,
                                              size: 40,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              state.errorMessage,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: appPoppinFont,
                                                color: paragraphColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  if (state is WorkspacesLoaded) {
                                    if (state.organizations.isEmpty) {
                                      return Center(
                                        child: Text(
                                          'No workspaces assigned to this account.',
                                          style: TextStyle(
                                            fontFamily: appPoppinFont,
                                            color: paragraphColor,
                                          ),
                                        ),
                                      );
                                    }
                                    return ListView.builder(
                                      itemCount: state.organizations.length,
                                      physics: const BouncingScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      itemBuilder: (context, index) {
                                        return OrganizationCard(
                                          isTablet: isTab,
                                          org: state.organizations[index],
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
                  currentIsInApp
                      ? const SizedBox(height: 24)
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Cancel Login'),
                            style: TextButton.styleFrom(
                              foregroundColor: paragraphColor,
                              textStyle: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontFamily: appPoppinFont,
                                fontSize:
                                    displayWidth(context) *
                                    (isTab ? 0.018 : 0.034),
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
