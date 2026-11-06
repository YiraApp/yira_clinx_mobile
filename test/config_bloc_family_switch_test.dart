// Reloading the session after switching profiles must keep the right family list.
import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/features/domain/entities/login/login_entity.dart';
import 'package:yiraclinics/features/presentation/configuration/config_bloc.dart';
import 'package:yiraclinics/features/use_cases/config_use_case.dart';
import 'package:yiraclinics/features/use_cases/get_version_and_token_status_use_case.dart';
import 'package:yiraclinics/features/use_cases/side_menu_use_case.dart';

class _FakeConfig implements ConfigUseCase {
  _FakeConfig(this.result);
  final LoginEntity result;
  @override
  Future<LoginEntity?> call(void _) async => result;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeVersion implements GetVersionAndTokenStatusUseCase {
  @override
  Future<Null> call(void _) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMenu implements SideMenuUseCase {
  @override
  Future<Null> call(SideMenuRequestParams _) async => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _main = 'EE8E1BD0-421C-43B6-AAFE-180D244C5CCD';
const _raju = 'A59C0395-27C4-4A02-B15C-B651F8DB49DB';

final _family = [
  ProfileEntity(id: _main, name: 'ch bhargava', relation: 'Primary', isPrimary: true, accountType: 'Independent'),
  ProfileEntity(id: _raju, name: 'Raju', relation: 'Other', isPrimary: false, accountType: 'Dependent'),
];

/// What the server sends for a family member: only their own profile.
final _rajuOnly = [ProfileEntity(id: _raju, name: 'Raju', relation: 'Self', isPrimary: true, accountType: 'Dependent')];

Future<List<ProfileEntity>> _reload({required String activeId, required List<ProfileEntity> sent}) async {
  final bloc = ConfigBloc(
    configUseCase: _FakeConfig(LoginEntity(status: true, data: DataEntity(id: activeId, profiles: sent))),
    getVersionAndTokenStatusUseCase: _FakeVersion(),
    sideMenuUseCase: _FakeMenu(),
  );
  final done = bloc.stream.firstWhere((s) => s is GetDataSuccessState || s is GetDataFailureState);
  bloc.add(LoadUserConfigurationScreen());
  await done;
  await bloc.close();
  return GlobalSession.instance.userNotifier.value?.data?.profiles ?? const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GlobalSession.instance.rootPrimaryUserId = _main;
    GlobalSession.instance.userNotifier.value = LoginEntity(status: true, data: DataEntity(id: _raju, profiles: _family));
  });

  test('a family member opened from the main account keeps the whole family', () async {
    final profiles = await _reload(activeId: _raju, sent: _rajuOnly);
    expect(profiles.map((p) => p.id), [_main, _raju]);
    expect(profiles.first.isPrimary, isTrue);
    expect(profiles.last.isPrimary, isFalse);
    expect(GlobalSession.instance.rootPrimaryUserId, _main);
  });

  test('switching back to the main account still lists the family', () async {
    GlobalSession.instance.userNotifier.value = LoginEntity(status: true, data: DataEntity(id: _main, profiles: _family));
    final profiles = await _reload(activeId: _main, sent: _rajuOnly);
    expect(profiles.map((p) => p.id), [_main, _raju]);
    expect(GlobalSession.instance.rootPrimaryUserId, _main);
  });

  test("another account's saved profiles are replaced by the server's list", () async {
    const other = 'B0000000-0000-0000-0000-000000000001';
    GlobalSession.instance.rootPrimaryUserId = other;
    GlobalSession.instance.userNotifier.value = LoginEntity(
      status: true,
      data: DataEntity(id: other, profiles: [ProfileEntity(id: other, name: 'Old', relation: 'Self', isPrimary: true)]),
    );
    final profiles = await _reload(activeId: _main, sent: [
      ProfileEntity(id: _main, name: 'ch bhargava', relation: 'Self', isPrimary: true),
      ProfileEntity(id: _raju, name: 'Raju', relation: 'Other', isPrimary: false),
    ]);
    expect(profiles.map((p) => p.id), [_main, _raju]);
    expect(GlobalSession.instance.rootPrimaryUserId, _main);
  });
}
