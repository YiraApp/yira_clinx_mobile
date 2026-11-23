import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';

import 'family_link_api.dart';

String _key(String? id) => (id ?? '').trim().toLowerCase();

bool _blank(String? s) => s == null || s.trim().isEmpty;

/// [d] with the given fields replaced.
DataEntity copyFamilyData(
  DataEntity d, {
  String? accessToken,
  String? refreshToken,
  String? accessTokenExpiry,
  String? refreshTokenExpiry,
  List<ProfileEntity>? profiles,
}) {
  return DataEntity(
    accessToken: accessToken ?? d.accessToken,
    refreshToken: refreshToken ?? d.refreshToken,
    accessTokenExpiry: accessTokenExpiry ?? d.accessTokenExpiry,
    refreshTokenExpiry: refreshTokenExpiry ?? d.refreshTokenExpiry,
    id: d.id,
    isMobileVerified: d.isMobileVerified,
    isEmailVerified: d.isEmailVerified,
    roleCount: d.roleCount,
    hospitalCount: d.hospitalCount,
    organizationCount: d.organizationCount,
    roles: d.roles,
    profiles: profiles ?? d.profiles,
    firstName: d.firstName,
    lastName: d.lastName,
    email: d.email,
    phoneNumber: d.phoneNumber,
    countryCode: d.countryCode,
    gender: d.gender,
    dob: d.dob,
    height: d.height,
    weight: d.weight,
    heightUnit: d.heightUnit,
    weightUnit: d.weightUnit,
    latestUserRole: d.latestUserRole,
    latestOrgId: d.latestOrgId,
    latestHospitalId: d.latestHospitalId,
    latestRoleId: d.latestRoleId,
    navigationId: d.navigationId,
    imagePath: d.imagePath,
  );
}

/// The session to keep after reloading the open profile from the server:
/// - the current tokens stay when the reply has none (a profile opened through
///   a family link is not given tokens of its own);
/// - the current profile list stays when the reply leaves out the main account
///   (a family member's profile is open), so the user can still switch back.
LoginEntity mergeFreshFamilySession(LoginEntity? current, LoginEntity fresh, {String? rootId}) {
  final old = current?.data;
  final data = fresh.data;
  if (old == null || data == null) return fresh;

  bool lists(List<ProfileEntity>? profiles, String? id) =>
      _key(id).isNotEmpty && (profiles ?? const []).any((p) => _key(p.id) == _key(id));
  final keepList = lists(old.profiles, rootId) && !lists(data.profiles, rootId);

  final merged = copyFamilyData(
    data,
    accessToken: _blank(data.accessToken) ? old.accessToken : null,
    refreshToken: _blank(data.refreshToken) ? old.refreshToken : null,
    accessTokenExpiry: _blank(data.accessToken) ? old.accessTokenExpiry : null,
    refreshTokenExpiry: _blank(data.refreshToken) ? old.refreshTokenExpiry : null,
    profiles: keepList || (data.profiles ?? const []).isEmpty ? old.profiles : null,
  );
  return LoginEntity(status: fresh.status, message: fresh.message, data: merged);
}

/// [profiles] with every linked member on it once, and without [removedIds].
List<ProfileEntity> withLinkedFamily(
  List<ProfileEntity> profiles,
  List<FamilyLinkedMember> linked, {
  Set<String> removedIds = const {},
}) {
  final removed = {for (final id in removedIds) _key(id)};
  final result = [for (final p in profiles) if (!removed.contains(_key(p.id))) p];
  final seen = {for (final p in result) _key(p.id)};
  for (final m in linked) {
    final key = _key(m.userId);
    if (key.isEmpty || removed.contains(key) || !seen.add(key)) continue;
    final name = m.name.trim().isNotEmpty ? m.name.trim() : '${m.firstName} ${m.lastName}'.trim();
    result.add(ProfileEntity(
      id: m.userId,
      name: name.isNotEmpty ? name : 'Family member',
      firstName: m.firstName,
      lastName: m.lastName,
      phoneNumber: m.phoneNumber,
      relation: m.relation.isNotEmpty ? m.relation : 'Family',
      isPrimary: false,
      gender: m.gender,
      dob: m.dob,
      accountType: 'Dependent',
      imagePath: m.imagePath,
    ));
  }
  return result;
}
