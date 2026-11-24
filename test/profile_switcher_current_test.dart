import 'package:flutter_test/flutter_test.dart';
import 'package:yiraclinics/features/presentation/doctor/profile/widgets/profile_switcher_sheet.dart';

const _me = '004A58BD-146F-45FD-B529-B55DF74856C4';
const _patientRole = '4FC67429-28AE-4106-93EF-436228282ED0';
const _providerRole = 'FE80173F-9DB3-4703-84A8-5C23E7CC493C';

bool _current({required bool profile, required bool patientSession, String profileId = _me, String role = _providerRole, String hospital = '20'}) =>
    switcherItemIsCurrent(
      isPatientItem: profile,
      sessionIsPatient: patientSession,
      itemProfileId: profileId,
      sessionUserId: _me.toLowerCase(),
      itemRoleId: profile ? _patientRole : role,
      sessionRoleId: patientSession ? _patientRole : _providerRole,
      itemHospitalId: hospital,
      sessionHospitalId: '20',
    );

void main() {
  test('in a workspace, only that workspace is current, not the own profile', () {
    expect(_current(profile: true, patientSession: false), isFalse);
    expect(_current(profile: false, patientSession: false), isTrue);
    expect(_current(profile: false, patientSession: false, hospital: '19'), isFalse);
  });

  test('as a patient, only the signed-in profile is current, no workspace', () {
    expect(_current(profile: true, patientSession: true), isTrue);
    expect(_current(profile: true, patientSession: true, profileId: 'A5F39C9D-DDD2-448B-B67B-1BD82AFC439D'), isFalse);
    expect(_current(profile: false, patientSession: true), isFalse);
  });
}
