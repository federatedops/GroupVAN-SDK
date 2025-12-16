import 'dart:convert';

class LocationHours {
  final String? sundayOpen;
  final String? sundayClose;
  final String? mondayOpen;
  final String? mondayClose;
  final String? tuesdayOpen;
  final String? tuesdayClose;
  final String? wednesdayOpen;
  final String? wednesdayClose;
  final String? thursdayOpen;
  final String? thursdayClose;
  final String? fridayOpen;
  final String? fridayClose;
  final String? saturdayOpen;
  final String? saturdayClose;

  LocationHours({
    this.sundayOpen,
    this.sundayClose,
    this.mondayOpen,
    this.mondayClose,
    this.tuesdayOpen,
    this.tuesdayClose,
    this.wednesdayOpen,
    this.wednesdayClose,
    this.thursdayOpen,
    this.thursdayClose,
    this.fridayOpen,
    this.fridayClose,
    this.saturdayOpen,
    this.saturdayClose,
  });

  factory LocationHours.fromJson(Map<String, dynamic> json) {
    return LocationHours(
      sundayOpen: json['sunday_open'] as String?,
      sundayClose: json['sunday_close'] as String?,
      mondayOpen: json['monday_open'] as String?,
      mondayClose: json['monday_close'] as String?,
      tuesdayOpen: json['tuesday_open'] as String?,
      tuesdayClose: json['tuesday_close'] as String?,
      wednesdayOpen: json['wednesday_open'] as String?,
      wednesdayClose: json['wednesday_close'] as String?,
      thursdayOpen: json['thursday_open'] as String?,
      thursdayClose: json['thursday_close'] as String?,
      fridayOpen: json['friday_open'] as String?,
      fridayClose: json['friday_close'] as String?,
      saturdayOpen: json['saturday_open'] as String?,
      saturdayClose: json['saturday_close'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sunday_open': sundayOpen,
      'sunday_close': sundayClose,
      'monday_open': mondayOpen,
      'monday_close': mondayClose,
      'tuesday_open': tuesdayOpen,
      'tuesday_close': tuesdayClose,
      'wednesday_open': wednesdayOpen,
      'wednesday_close': wednesdayClose,
      'thursday_open': thursdayOpen,
      'thursday_close': thursdayClose,
      'friday_open': fridayOpen,
      'friday_close': fridayClose,
      'saturday_open': saturdayOpen,
      'saturday_close': saturdayClose,
    };
  }
}

class LocationDetails {
  final String? description;
  final double? latitude;
  final double? longitude;
  final LocationHours? hours;

  LocationDetails({
    this.description,
    this.latitude,
    this.longitude,
    this.hours,
  });

  factory LocationDetails.fromJson(Map<String, dynamic> json) {
    var hoursData = json['hours'];
    LocationHours? hours;

    if (hoursData != null) {
      if (hoursData is String) {
        try {
          hoursData = jsonDecode(hoursData);
        } catch (_) {
          // If decoding fails, hours remains null or we could log it
        }
      }

      if (hoursData is Map<String, dynamic>) {
        hours = LocationHours.fromJson(hoursData);
      }
    }

    return LocationDetails(
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      hours: hours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'hours': hours?.toJson(),
    };
  }
}

