import '../shared.dart';

/// Catalog discrepancy report (wrong fitment, missing part, bad data).
///
/// [vehicleId] is a hashed v3 vehicle id from any `/v3/vehicles` service and
/// must be a catalog vehicle. [comments] is capped at 300 characters.
class DiscrepancyCreateRequest {
  final String locationId;
  final int reasonId;
  final String comments;
  final String? vehicleId;
  final int? partTypeId;
  final String? mfrCode;
  final String? partNumber;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;

  const DiscrepancyCreateRequest({
    required this.locationId,
    required this.reasonId,
    required this.comments,
    this.vehicleId,
    this.partTypeId,
    this.mfrCode,
    this.partNumber,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
  });

  Map<String, dynamic> toJson() => {
    'location_id': locationId,
    'reason_id': reasonId,
    'comments': comments,
    if (vehicleId != null) 'vehicle_id': vehicleId,
    if (partTypeId != null) 'part_type_id': partTypeId,
    if (mfrCode != null) 'mfr_code': mfrCode,
    if (partNumber != null) 'part_number': partNumber,
    if (contactName != null) 'contact_name': contactName,
    if (contactEmail != null) 'contact_email': contactEmail,
    if (contactPhone != null) 'contact_phone': contactPhone,
  };
}

/// A discrepancy reported by the signed-in user.
///
/// [resolution] and [notes] are set once the discrepancy has been worked, and
/// [screenshotUrl] once a screenshot has been attached.
class Discrepancy {
  final int id;
  final String status;
  final String reason;
  final String? comments;
  final String? resolution;
  final String? notes;
  final String? locationId;
  final int? partTypeId;
  final String? mfrCode;
  final String? partNumber;
  final String? contactInfo;
  final String? screenshotUrl;
  final Vehicle? vehicle;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Discrepancy({
    required this.id,
    required this.status,
    required this.reason,
    this.comments,
    this.resolution,
    this.notes,
    this.locationId,
    this.partTypeId,
    this.mfrCode,
    this.partNumber,
    this.contactInfo,
    this.screenshotUrl,
    this.vehicle,
    this.createdAt,
    this.updatedAt,
  });

  factory Discrepancy.fromJson(Map<String, dynamic> json) => Discrepancy(
    id: json['id'],
    status: json['status'],
    reason: json['reason'],
    comments: json['comments'],
    resolution: json['resolution'],
    notes: json['notes'],
    locationId: json['location_id'],
    partTypeId: json['part_type_id'],
    mfrCode: json['mfr_code'],
    partNumber: json['part_number'],
    contactInfo: json['contact_info'],
    screenshotUrl: json['screenshot_url'],
    vehicle: json['vehicle'] == null
        ? null
        : Vehicle.fromJson(json['vehicle'] as Map<String, dynamic>),
    createdAt: json['created_at'] == null
        ? null
        : DateTime.parse(json['created_at'] as String),
    updatedAt: json['updated_at'] == null
        ? null
        : DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'reason': reason,
    if (comments != null) 'comments': comments,
    if (resolution != null) 'resolution': resolution,
    if (notes != null) 'notes': notes,
    if (locationId != null) 'location_id': locationId,
    if (partTypeId != null) 'part_type_id': partTypeId,
    if (mfrCode != null) 'mfr_code': mfrCode,
    if (partNumber != null) 'part_number': partNumber,
    if (contactInfo != null) 'contact_info': contactInfo,
    if (screenshotUrl != null) 'screenshot_url': screenshotUrl,
    if (vehicle != null) 'vehicle': vehicle!.toJson(),
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };
}

/// Result of attaching a screenshot to a discrepancy
class DiscrepancyScreenshotResponse {
  final int id;
  final String screenshotUrl;

  const DiscrepancyScreenshotResponse({
    required this.id,
    required this.screenshotUrl,
  });

  factory DiscrepancyScreenshotResponse.fromJson(Map<String, dynamic> json) =>
      DiscrepancyScreenshotResponse(
        id: json['id'],
        screenshotUrl: json['screenshot_url'],
      );

  Map<String, dynamic> toJson() => {'id': id, 'screenshot_url': screenshotUrl};
}
