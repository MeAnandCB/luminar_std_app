class Qualification {
  final int id;
  final String name;
  final String value;
  final bool isActive;

  Qualification({
    required this.id,
    required this.name,
    required this.value,
    required this.isActive,
  });

  factory Qualification.fromJson(Map<String, dynamic> json) {
    return Qualification(
      id: json['id'],
      name: json['name'],
      value: json['value'],
      isActive: json['is_active'],
    );
  }
}

class QualificationResponse {
  final String status;
  final List<Qualification> qualifications;

  QualificationResponse({
    required this.status,
    required this.qualifications,
  });

  factory QualificationResponse.fromJson(Map<String, dynamic> json) {
    return QualificationResponse(
      status: json['status'],
      qualifications: (json['qualifications'] as List)
          .map((i) => Qualification.fromJson(i))
          .toList(),
    );
  }
}

class Specialization {
  final String name;
  final String value;

  Specialization({
    required this.name,
    required this.value,
  });

  factory Specialization.fromJson(Map<String, dynamic> json) {
    return Specialization(
      name: json['name'],
      value: json['value'],
    );
  }
}

class SpecializationResponse {
  final String status;
  final List<Specialization> specializations;
  final int totalCount;

  SpecializationResponse({
    required this.status,
    required this.specializations,
    required this.totalCount,
  });

  factory SpecializationResponse.fromJson(Map<String, dynamic> json) {
    return SpecializationResponse(
      status: json['status'],
      specializations: (json['specializations'] as List)
          .map((i) => Specialization.fromJson(i))
          .toList(),
      totalCount: json['total_count'],
    );
  }
}
