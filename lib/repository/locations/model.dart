class LocationModel {
  final int id;
  final String name;
  final String value;
  final bool isActive;

  LocationModel({
    required this.id,
    required this.name,
    required this.value,
    required this.isActive,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as int,
      name: json['name'] as String,
      value: json['value'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class LocationsResponse {
  final List<LocationModel> locations;

  LocationsResponse({required this.locations});

  factory LocationsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['locations'] as List<dynamic>? ?? [])
        .map((e) => LocationModel.fromJson(e as Map<String, dynamic>))
        .where((l) => l.isActive)
        .toList();
    return LocationsResponse(locations: list);
  }
}
