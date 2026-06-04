class OrganizationEntity {
  final String id;
  final String name;
  final List<HospitalEntity> hospitals;
  final bool isExpanded;

  OrganizationEntity({
    required this.id,
    required this.name,
    required this.hospitals,
    this.isExpanded = false,
  });

  OrganizationEntity copyWith({bool? isExpanded}) {
    return OrganizationEntity(
      id: id,
      name: name,
      hospitals: hospitals,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}

class HospitalEntity {
  final String id;
  final String name;

  HospitalEntity({required this.id, required this.name});
}