import 'package:yiraclinics/core/widgets/ios_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yiraclinics/core/app_navigation_drawer/widgets/custom_menu_title.dart';
import '../../../../features/domain/entities/side_menu/side_menu_entity.dart';
import '../navigation_drawer-bloc/navigation_drawer_bloc.dart';

class DrawerNavigationList extends StatelessWidget {
  final NavigationDrawerState state;
  final List<SideMenuItemEntity> dynamicMenuItems;
  final double targetWidth;

  const DrawerNavigationList({
    super.key,
    required this.state,
    required this.dynamicMenuItems,
    required this.targetWidth,
  });

  IconData _getFallbackIconForTaskCode(String taskCode) {
    switch (taskCode) {
      case "1": return IosIcons.grid_view_rounded;
      case "2": return IosIcons.apartment_rounded;
      case "3": return IosIcons.calendar_today_outlined;
      case "4": return IosIcons.people_outline_rounded;
      case "5": return IosIcons.access_time;
      case "6": return IosIcons.info_outline_rounded;
      case "7": return IosIcons.mail_outline_rounded;
      case "8": return IosIcons.gpp_good_outlined;
      case "9": return IosIcons.settings_outlined;
      default: return IosIcons.link_rounded;
    }
  }

  void _dispatchBlocEvent(BuildContext context, String taskCode) {
    final bloc = context.read<NavigationDrawerBloc>();
    switch (taskCode) {
      case "1": bloc.add(const DashBoardNav()); break;
      case "2": bloc.add(OrgSwitchNav()); break;
      case "3": bloc.add(const AppointmentsNav()); break;
      case "4": bloc.add(const PatientsNav()); break;
      case "5": bloc.add(const DoctorSlotsNav()); break;
      case "6": bloc.add(const ReadAboutUsNavEvent()); break;
      case "7": bloc.add(const ContactNavEvent()); break;
      case "8": bloc.add(const PrivacyNavEvent()); break;
      case "9": bloc.add(const SettingsNav()); break;
    }
  }

  int _getSelectedIndexForTaskCode(String taskCode) {
    switch (taskCode) {
      case "1": return 0;
      case "2": return 0;
      case "3": return 1;
      case "4": return 2;
      case "5": return 3;
      case "9": return 7;
      default: return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.2);

    if (dynamicMenuItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No menu modules loaded."),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: targetWidth * 0.025),
      children: [
        ...dynamicMenuItems.map((item) {
          final targetTaskCode = item.taskCode ?? '';
          return CustomMenuTile(
            title: item.title,
            icon: item.imagePath ?? '',
            fallbackIcon: _getFallbackIconForTaskCode(targetTaskCode),
            onTap: () => _dispatchBlocEvent(context, targetTaskCode),
          );
        }),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: targetWidth * 0.08, vertical: 12.0),
          child: Divider(height: 1.0, thickness: 1.2, color: dividerColor),
        ),
        CustomIconMenuTile(
          title: "Logout",
          icon: IosIcons.logout_rounded,
          isSelected: false,
          customColor: Colors.red,
          onTap: () => context.read<NavigationDrawerBloc>().add(const LogoutNavEvent()),
        ),
      ],
    );
  }
}