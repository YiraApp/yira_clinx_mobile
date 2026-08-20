import 'package:equatable/equatable.dart';

class ProviderProfileEntity extends Equatable {
  final int? id;
  final String? userId;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? gender;
  final String? dob;
  final String? bloodGroup;
  final String? imagePath;
  final String? profileImageUrl;
  final String? specialty;
  final String? subSpecialty;
  final String? department;
  final String? registrationNumber;
  final String? qualification;
  final String? experience;
  final double? consultationFee;
  final String? bio;
  final int? hospitalId;
  final String? hospitalName;
  final String? clinicAddress;
  final int? orgId;
  final String? orgName;
  final bool? isEmailVerified;
  final bool? isMobileVerified;

  const ProviderProfileEntity({
    this.id,
    this.userId,
    this.name,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.gender,
    this.dob,
    this.bloodGroup,
    this.imagePath,
    this.profileImageUrl,
    this.specialty,
    this.subSpecialty,
    this.department,
    this.registrationNumber,
    this.qualification,
    this.experience,
    this.consultationFee,
    this.bio,
    this.hospitalId,
    this.hospitalName,
    this.clinicAddress,
    this.orgId,
    this.orgName,
    this.isEmailVerified,
    this.isMobileVerified,
  });

  ProviderProfileEntity copyWith({
    int? id,
    String? userId,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? gender,
    String? dob,
    String? bloodGroup,
    String? imagePath,
    String? profileImageUrl,
    String? specialty,
    String? subSpecialty,
    String? department,
    String? registrationNumber,
    String? qualification,
    String? experience,
    double? consultationFee,
    String? bio,
    int? hospitalId,
    String? hospitalName,
    String? clinicAddress,
    int? orgId,
    String? orgName,
    bool? isEmailVerified,
    bool? isMobileVerified,
  }) {
    return ProviderProfileEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      imagePath: imagePath ?? this.imagePath,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      specialty: specialty ?? this.specialty,
      subSpecialty: subSpecialty ?? this.subSpecialty,
      department: department ?? this.department,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      qualification: qualification ?? this.qualification,
      experience: experience ?? this.experience,
      consultationFee: consultationFee ?? this.consultationFee,
      bio: bio ?? this.bio,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      orgId: orgId ?? this.orgId,
      orgName: orgName ?? this.orgName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isMobileVerified: isMobileVerified ?? this.isMobileVerified,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        firstName,
        lastName,
        email,
        phoneNumber,
        gender,
        dob,
        bloodGroup,
        imagePath,
        profileImageUrl,
        specialty,
        subSpecialty,
        department,
        registrationNumber,
        qualification,
        experience,
        consultationFee,
        bio,
        hospitalId,
        hospitalName,
        clinicAddress,
        orgId,
        orgName,
        isEmailVerified,
        isMobileVerified,
      ];
}
