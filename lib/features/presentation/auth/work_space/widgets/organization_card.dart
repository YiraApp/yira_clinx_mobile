import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';

import '../../../../domain/entities/work_space/get_work_space_entity.dart';
import '../work_space_bloc/work_space_bloc.dart';

class OrganizationCard extends StatelessWidget {
  final DataEntity org;
  final bool? isTablet;
  final Function(int hospitalId)? onPressed;


  const OrganizationCard({super.key, required this.org, this.isTablet = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bool isTab = isTablet ?? false;

    final cardBg = isDarkMode
        ? theme.scaffoldBackgroundColor
        : const Color(0xFFF8FAFC);
    final expandedSubTileBg = isDarkMode
        ? Colors.white.withOpacity(0.02)
        : const Color(0xFFFAFAFA);
    final mainText = isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final subText = isDarkMode ? Colors.white60 : const Color(0xFF94A3B8);

    final double widthFactor = displayWidth(context);

    return BlocBuilder<WorkspaceBloc, WorkspaceState>(
      buildWhen: (previous, current) {
        if (previous is WorkspacesLoaded && current is WorkspacesLoaded) {
          final prevExpanded = previous.expandedOrganizationIds.contains(
            org.organizationId,
          );
          final currExpanded = current.expandedOrganizationIds.contains(
            org.organizationId,
          );
          return prevExpanded != currExpanded;
        }
        return true;
      },
      builder: (context, state) {
        bool isExpanded = false;
        if (state is WorkspacesLoaded) {
          isExpanded = state.expandedOrganizationIds.contains(
            org.organizationId,
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  // Trigger the BLoC event using the real unique ID
                  if (org.organizationId != null) {
                    context.read<WorkspaceBloc>().add(
                      ToggleOrganizationEvent(org.organizationId!),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(fieldBorderRadius),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isTab ? 20 : 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(fieldBorderRadius),
                    border: Border.all(
                      color: isExpanded
                          ? theme.primaryColor.withOpacity(0.3)
                          : (isDarkMode
                                ? Colors.white10
                                : const Color(0xFFE2E8F0)),
                      width: isExpanded ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? theme.cardColor : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.business_rounded,
                          color: theme.primaryColor,
                          size: isTab ? 28 : 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              org.organizationName ?? '',
                              style: TextStyle(
                                color: mainText,
                                fontSize: widthFactor * (isTab ? 0.022 : 0.036),
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${org.hospitals?.length ?? 0} ${(org.hospitals?.length ?? 0) == 1 ? 'HOSPITAL' : 'HOSPITALS'}',
                              style: TextStyle(
                                color: subText,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                fontSize: widthFactor * (isTab ? 0.016 : 0.029),
                                fontFamily: appPoppinFont,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: subText,
                        size: isTab ? 28 : 24,
                      ),
                    ],
                  ),
                ),
              ),

              if (isExpanded)
                Padding(
                  padding: EdgeInsets.only(top: 8.0, left: isTab ? 20.0 : 12.0),
                  child: Column(
                    children:
                        org.hospitals?.map((hospital) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: expandedSubTileBg,
                              borderRadius: BorderRadius.circular(
                                fieldBorderRadius,
                              ),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white10
                                    : const Color(0xFFEDF2F7),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isTab ? 20 : 16,
                                vertical: isTab ? 8 : 4,
                              ),
                              leading: Icon(
                                Icons.wb_sunny_outlined,
                                color: theme.primaryColor,
                                size: isTab ? 18 : 16,
                              ),
                              title: Text(
                                hospital.hospitalName ?? '',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700,
                                  fontFamily: appPoppinFont,
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      widthFactor * (isTab ? 0.018 : 0.032),
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right_rounded,
                                color: subText,
                                size: isTab ? 24 : 20,
                              ),
                              onTap:() {
                                if (onPressed != null && hospital.hospitalId != null) {
                                  onPressed!(hospital.hospitalId ?? 1) ;
                                }
                              }
                                /*() {
                                var data = UpdateLatestOrgDetailsModelParams(
                                  latestRoleId: '',
                                  latestOrgId: org.organizationId ?? 1,
                                  latestHospitalId: hospital.hospitalId ?? 1,
                                );
                                context.read<WorkspaceBloc>().add(
                                  OnSaveLatestOrgDetailsEvent(data),
                                );
                              },*/
                            ),
                          );
                        }).toList() ??
                        [],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
