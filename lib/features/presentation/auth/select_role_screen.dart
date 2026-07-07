import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/features/presentation/auth/role_bloc/role_bloc.dart';
import 'package:yiraclinics/features/presentation/auth/widgets/role_card.dart';

import '../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../core/common_widgets/common_text.dart';
import '../../../core/local/global_session.dart';
import '../../../core/models/select_role_model.dart';
import '../../../core/models/work_space_model.dart';

class SelectRoleScreen extends StatefulWidget {
  final SelectRoleModel? roles;
  const SelectRoleScreen({super.key, this.roles});

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    final bloc = context.read<RoleBloc>();
    if (bloc.state is RoleInitial) {
      bloc.add(LoadRolesEvent());
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    bool isTab = isTablet(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mainHeadingColor = isDarkMode
        ? Colors.white
        : const Color(0xFF0F172A);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: widget.roles?.inApp ?? false
          ? AppBar(
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: mainHeadingColor,
                  size: 20,
                ),
                onPressed: () {
                  final currentUser = GlobalSession.instance.userNotifier.value;
                  final payload = currentUser?.data;
                  final navigationId = payload?.navigationId;
                  final navigationRoutes = const {
                    '1': AppRoutes.dashboardPatientDetails,
                    '2': AppRoutes.doctorDashboard,
                  };

                  final coreRoute = navigationRoutes[navigationId];
                  if (coreRoute != null) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      coreRoute,
                      (route) => false,
                    );
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.unsupportedRole,
                      (route) => false,
                      arguments: currentUser?.data,
                    );
                  }
                },
              ),
              automaticallyImplyLeading: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : AppBar(
              automaticallyImplyLeading: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenSize.height * 0.45,
            child: Opacity(
              opacity: isDarkMode ? 0.03 : 0.06,
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.black.withOpacity(0.0)],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/images/ic_role_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SafeArea(
            child: BlocBuilder<RoleBloc, RoleState>(
              builder: (context, state) {
                if (state is RoleLoading || state is RoleInitial) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  );
                }

                if (state is RolesLoaded || widget.roles?.roles != null) {
                  return FadeTransition(
                    opacity: _fadeController,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24.0,
                              vertical: 36.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: SvgPicture.asset(
                                    'assets/images/svgs/ic_apps_logo.svg',
                                    width: isTab ? 65 : 60,
                                    height: isTab ? 65 : 60,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                CommonText(
                                  'Select Your Role',
                                  style: TextStyle(
                                    fontSize:
                                        displayWidth(context) *
                                        (isTab ? 0.035 : 0.065),
                                    fontWeight: FontWeight.w600,
                                    fontFamily: appPoppinFont,
                                  ),
                                ),
                                CommonText(
                                  'Multiple permissions detected for this facility',
                                  style: TextStyle(
                                    fontSize:
                                        displayWidth(context) *
                                        (isTab ? 0.02 : 0.03),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: appPoppinFont,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: screenHorizontalSpacePadding,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final role = widget.roles?.roles[index];
                              final isSelected =
                                  state is RoleSelectedState &&
                                  state.roleEntity.roleId == role?.roleId;

                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: fieldSpace,
                                ),
                                child: DialogRoleCard(
                                  isTablet: isTab,
                                  isSelected: isSelected,
                                  roleEntity: role!,
                                  onTap: () async {
                                    final selectedRole =
                                        widget.roles?.roles[index];
                                    if (selectedRole == null) return;

                                    context.read<RoleBloc>().add(
                                      RoleSelected(selectedRole),
                                    );
                                    WorkSpaceModel data = WorkSpaceModel(
                                      widget.roles?.inApp ?? false,
                                      selectedRole,
                                    );
                                    await Navigator.pushNamed(
                                      context,
                                      AppRoutes.workSpaceScreen,
                                      arguments: data,
                                    );
                                    if (context.mounted) {
                                      context.read<RoleBloc>().add(
                                        ClearRoleSelectionEvent(),
                                      );
                                    }
                                  },
                                ),
                              );
                            }, childCount: widget.roles?.roles.length ?? 0),
                          ),
                        ),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 24.0,
                              top: 16.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.verified_user_outlined,
                                      size: 14,
                                      color: isDarkMode
                                          ? Colors.white24
                                          : Colors.black26,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Secure configuration environment rules apply.',
                                      style: TextStyle(
                                        fontFamily: appPoppinFont,
                                        fontSize:
                                            displayWidth(context) *
                                            (isTab ? 0.018 : 0.025),
                                        fontWeight: FontWeight.w500,
                                        color: isDarkMode
                                            ? Colors.white30
                                            : Colors.black38,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
