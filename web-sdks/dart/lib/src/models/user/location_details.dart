class LocationDetails {
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? zip;
  final Map<String, String?>? hours;


  LocationDetails({
    this.description,
    this.latitude,
    this.longitude,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.zip,
    this.hours,
  });

  factory LocationDetails.fromJson(Map<String, dynamic> json) {
    return LocationDetails(
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zip: json['zip'] as String?,
      hours: (json['hours'] as Map<String, dynamic>?)?.cast<String, String?>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'hours': hours,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
    };
  }
}

