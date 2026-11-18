
import 'package:yiraclinics/core/widgets/ios_icons.dart';
import 'package:flutter/material.dart';

class NavItemModel {
  final int id;
  final String title;
  final IconData icon;

  const NavItemModel({required this.title, required this.icon, required this.id});
}

 List<NavItemModel> primaryNavItems = [
  NavItemModel(title: "Doctor Dashboard", icon: IosIcons.grid_view_rounded, id: 1),
  NavItemModel(title: "Org Switch", icon: IosIcons.apartment_rounded, id: 1),
  NavItemModel(title: "Appointments", icon: IosIcons.calendar_today_outlined, id: 3),
  NavItemModel(title: "Patients", icon: IosIcons.people_outline_rounded, id: 4),
  NavItemModel(title: "Doctor Slots", icon: IosIcons.access_time, id: 5),
  NavItemModel(title: "Read About Us", icon: IosIcons.info_outline_rounded, id: 6),
  NavItemModel(title: "Contact Us", icon: IosIcons.mail_outline_rounded, id: 7),
  NavItemModel(title: "Privacy Policy", icon: IosIcons.gpp_good_outlined, id: 8),
];