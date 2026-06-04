
import 'package:flutter/material.dart';

class NavItemModel {
  final int id;
  final String title;
  final IconData icon;

  const NavItemModel({required this.title, required this.icon, required this.id});
}

const List<NavItemModel> primaryNavItems = [
  NavItemModel(title: "Doctor Dashboard", icon: Icons.grid_view_rounded, id: 1),
  NavItemModel(title: "Appointments", icon: Icons.calendar_today_outlined, id: 2),
  NavItemModel(title: "Patients", icon: Icons.people_outline_rounded, id: 3),
  NavItemModel(title: "Doctor Slots", icon: Icons.access_time, id: 4),
  NavItemModel(title: "Read About Us", icon: Icons.info_outline_rounded, id: 5),
  NavItemModel(title: "Contact Us", icon: Icons.mail_outline_rounded, id: 6),
  NavItemModel(title: "Privacy Policy", icon: Icons.gpp_good_outlined, id: 7),
];