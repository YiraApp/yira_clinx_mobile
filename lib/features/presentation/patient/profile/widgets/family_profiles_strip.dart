import 'package:flutter/material.dart';

import '../../../../../config/app_route/app_routes.dart';
import '../../../../../core/constants/constants.dart';
import '../../../../../core/local/global_session.dart';
import '../../../../../core/widgets/phosphor_icons.dart';
import '../../../../../core/widgets/profile_visuals.dart';
import '../../../../domain/entities/login/login_entity.dart';
import '../../../doctor/profile/widgets/profile_switcher_sheet.dart';

/// Every profile on the account as a round picture; tap one to switch to it.
/// The open profile has a ring and a tick. Hidden for family members who
/// signed in themselves, since they only have their own profile.
class FamilyProfilesStrip extends StatefulWidget {
  const FamilyProfilesStrip({super.key, required this.isDark});

  final bool isDark;

  @override
  State<FamilyProfilesStrip> createState() => _FamilyProfilesStripState();
}

class _FamilyProfilesStripState extends State<FamilyProfilesStrip> {
  String? _switchingId;

  static bool _isSelf(ProfileEntity p) {
    final r = (p.relation ?? '').trim().toLowerCase();
    return p.isPrimary == true && (r.isEmpty || r == 'self' || r == 'primary' || r == 'admin');
  }

  static String _name(ProfileEntity p) {
    final full = (p.name ?? '').trim().isNotEmpty ? p.name!.trim() : '${p.firstName ?? ''} ${p.lastName ?? ''}'.trim();
    return full.isEmpty ? 'Profile' : full;
  }

  Future<void> _switch(ProfileEntity p) async {
    if (_switchingId != null || (p.id ?? '').isEmpty) return;
    setState(() => _switchingId = p.id);
    await ProfileSwitcherSheet.switchToFamilyProfile(context, p.id!);
    if (mounted) setState(() => _switchingId = null);
  }

  @override
  Widget build(BuildContext context) {
    if (GlobalSession.instance.isSignedInAsFamilyMember) return const SizedBox.shrink();
    final user = GlobalSession.instance.userNotifier.value;
    // One entry per person: saved lists can hold the same id in different letter case.
    final seenIds = <String>{};
    final profiles = [
      for (final p in user?.data?.profiles ?? const <ProfileEntity>[])
        if (seenIds.add((p.id ?? '').trim().toLowerCase())) p,
    ]..sort((a, b) => (_isSelf(b) ? 1 : 0).compareTo(_isSelf(a) ? 1 : 0));
    if (profiles.isEmpty) return const SizedBox.shrink();
    final currentId = (user?.data?.id ?? '').toLowerCase();
    final isDark = widget.isDark;
    final primary = Theme.of(context).primaryColor;
    final ink = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);
    // Staff roles on this account, such as provider. The sheet lists each facility.
    final workspaceCount = (user?.data?.roles ?? const <RoleEntity>[]).where((r) {
      final name = (r.roleName ?? '').toLowerCase();
      return name.isNotEmpty && !name.contains('patient') && !name.contains('user');
    }).length;

    Widget person(ProfileEntity p) {
      final self = _isSelf(p);
      final active = (p.id ?? '').toLowerCase() == currentId;
      final relation = self ? 'You' : ((p.relation ?? '').trim().isEmpty ? 'Family' : p.relation!.trim());
      final color = profileRelationColor(relation, isPrimary: self);
      final switching = _switchingId == p.id;
      return SizedBox(
        width: 68,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: active ? null : () => _switch(p),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: active ? primary : Colors.transparent, width: 2.2),
                      ),
                      child: Opacity(
                        opacity: switching ? 0.4 : 1,
                        child: ProfileAvatar(name: _name(p), imagePath: p.imagePath, color: color, size: 48),
                      ),
                    ),
                    if (switching)
                      const Positioned.fill(child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)))),
                    if (active)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF232323) : Colors.white, width: 2),
                          ),
                          child: const PhosphorIcon(PhosphorIconsBold.check, size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(_name(p).split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: ink)),
                Text(relation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 10, color: active ? primary : muted)),
              ],
            ),
          ),
        ),
      );
    }

    final add = SizedBox(
      width: 68,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, AppRoutes.patientMyFamily),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 57,
                height: 57,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: isDark ? 0.15 : 0.06),
                  border: Border.all(color: primary.withValues(alpha: 0.35), width: 1.5),
                ),
                child: PhosphorIcon(PhosphorIconsBold.plus, size: 22, color: primary),
              ),
              const SizedBox(height: 6),
              Text('Add', style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w500, color: ink)),
              Text('Family', style: TextStyle(fontFamily: appPoppinFont, fontSize: 10, color: muted)),
            ],
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 6),
            child: Text('SWITCH PROFILE',
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: muted)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [for (final p in profiles) person(p), add]),
          ),
          if (workspaceCount > 0)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ProfileSwitcherSheet(),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                child: Row(
                  children: [
                    PhosphorIcon(PhosphorIconsBold.briefcase, size: 18, color: primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        workspaceCount == 1 ? 'Switch to your workspace' : 'Switch workspace ($workspaceCount)',
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: ink),
                      ),
                    ),
                    PhosphorIcon(PhosphorIconsBold.caretRight, size: 14, color: muted),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
