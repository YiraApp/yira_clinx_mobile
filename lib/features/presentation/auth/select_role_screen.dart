import 'dart:ui';
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
import '../../../core/common_widgets/custom_button.dart';
import '../../domain/entities/login/login_entity.dart';

class SelectRoleScreen extends StatefulWidget {
  final List<RoleEntity>? roles;
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
    final canvasBg = isDarkMode
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final primaryTextColor = isDarkMode
        ? Colors.white
        : const Color(0xFF1E293B);
    final secondaryTextColor = isDarkMode
        ? Colors.white60
        : const Color(0xFF64748B);
    final brandIconBg = isDarkMode
        ? theme.cardColor
        : primaryColor.withOpacity(0.08);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body:
      Stack(
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      height:
                          screenSize.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                      child: Column(
                        children: [
                          Padding(
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

                                SizedBox(height: 10),
                                CommonText(
                                  'Select Your Role',
                                  style: TextStyle(
                                    fontSize: displayWidth(context) * (isTab? 0.035:0.065),
                                    fontWeight: FontWeight.w600,
                                    fontFamily: appPoppinFont,
                                  ),
                                ),
                                CommonText(
                                  'Multiple permissions detected for this facility',
                                  style: TextStyle(
                                    fontSize: displayWidth(context) * (isTab? 0.02:0.03),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: appPoppinFont,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: screenHorizontalSpacePadding,
                              ),
                              child: BlocConsumer<RoleBloc, RoleState>(
                                buildWhen: (previous, current) =>
                                    current is! RoleLoading &&
                                    current is! RoleSelectedState,
                                listener: (context, state) {
                                  if (state is RoleSelectedState) {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.workSpaceScreen,
                                    );
                                  }
                                },
                                builder: (context, state) {
                                  if (state is RoleLoading ||
                                      state is RoleInitial) {
                                    return Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              primaryColor,
                                            ),
                                      ),
                                    );
                                  }
                                  if (state is RolesLoaded) {
                                    return FadeTransition(
                                      opacity: _fadeController,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              padding: EdgeInsets.zero,
                                              itemCount: widget.roles?.length ?? 0,
                                              itemBuilder: (context, index) {
                                                final role = state.roles[index];
                                                final isSelected =
                                                    state.selectedRole ==
                                                    role.type;

                                                return GestureDetector(
                                                  onTap: () {

                                                  },
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: fieldSpace,
                                                        ),
                                                    child: DialogRoleCard(
                                                      isTablet: isTab,
                                                      isSelected: isSelected,
                                                      onTap: () {
                                                        context
                                                            .read<RoleBloc>()
                                                            .add(
                                                              ChooseRoleEvent(
                                                                role.type,
                                                              ),
                                                            );
                                                        context
                                                            .read<RoleBloc>()
                                                            .add(RoleSelected());
                                                      }, roleEntity: widget.roles![index],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),

                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                                                      (isTab? 0.018:0.025),
                                                  fontWeight: FontWeight.w500,
                                                  color: isDarkMode
                                                      ? Colors.white30
                                                      : Colors.black38,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),

                                          /* Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16.0,
                                      ),
                                      child: AnimatedScale(
                                        scale: state.selectedRole != null
                                            ? 1.0
                                            : 0.98,
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        curve: Curves.easeOutBack,
                                        child: AnimatedOpacity(
                                          opacity: state.selectedRole != null
                                              ? 1.0
                                              : 0.5,
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: CustomElevatedButton(
                                            noElevation: true,
                                            height: 54,
                                            width: displayWidth(context),
                                            text: "Get Started",
                                            onPressed:
                                                state.selectedRole != null
                                                ? () {
                                                    debugPrint(
                                                      "Initializing workspace route entry: ${state.selectedRole}",
                                                    );
                                                  }
                                                : () {},
                                          ),
                                        ),
                                      ),
                                    ),*/
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
