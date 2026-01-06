class LocationDetails {
  final String? description;
  final double? latitude;
  final double? longitude;
  final Map<String, String?>? hours;

  LocationDetails({
    this.description,
    this.latitude,
    this.longitude,
    this.hours,
  });

  factory LocationDetails.fromJson(Map<String, dynamic> json) {
    return LocationDetails(
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      hours: (json['hours'] as Map<String, dynamic>?)?.cast<String, String?>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'hours': hours,
    };
  }
}

