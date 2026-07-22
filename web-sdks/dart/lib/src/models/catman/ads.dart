/// Catman ads models: [Ad] and [Campaign].
library;

import '../../auth/auth_models.dart' show UserType;

/// Who a campaign is active for, matching the server's campaign scope enum.
enum CampaignScope {
  /// Active only for the member that created it.
  member('member'),

  /// Active for every member of the creator's group.
  group('group');

  final String value;
  const CampaignScope(this.value);

  static CampaignScope fromValue(String value) =>
      CampaignScope.values.firstWhere((s) => s.value == value);
}

/// A single ad within a campaign.
class Ad {
  final int id;
  final String? name;
  final String? headline;
  final String? body;
  final String? url;
  final String? imageUrl;

  const Ad({
    required this.id,
    this.name,
    this.headline,
    this.body,
    this.url,
    this.imageUrl,
  });

  factory Ad.fromJson(Map<String, dynamic> json) => Ad(
    id: json['id'] as int,
    name: json['name'] as String?,
    headline: json['headline'] as String?,
    body: json['body'] as String?,
    url: json['url'] as String?,
    imageUrl: json['image_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'headline': headline,
    'body': body,
    'url': url,
    'image_url': imageUrl,
  };
}

/// An ad campaign with an active window and its ads.
class Campaign {
  final int id;
  final String? name;
  final DateTime? start;
  final DateTime? end;
  final CampaignScope scope;
  final List<Ad> ads;

  const Campaign({
    required this.id,
    this.name,
    this.start,
    this.end,
    required this.scope,
    this.ads = const [],
  });

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
    id: json['id'] as int,
    name: json['name'] as String?,
    start: json['start'] == null
        ? null
        : DateTime.parse(json['start'] as String),
    end: json['end'] == null ? null : DateTime.parse(json['end'] as String),
    scope: CampaignScope.fromValue(json['scope'] as String),
    ads: (json['ads'] as List<dynamic>? ?? const [])
        .map((a) => Ad.fromJson(a as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'start': start?.toUtc().toIso8601String(),
    'end': end?.toUtc().toIso8601String(),
    'scope': scope.value,
    'ads': ads.map((a) => a.toJson()).toList(),
  };
}

/// Fields to create a [Campaign]. [usertypes] must contain at least one value.
///
/// A [CampaignScope.group] campaign is active for the whole group; the server
/// rejects it if the user does not belong to a group.
class CampaignCreate {
  final String name;
  final DateTime start;
  final DateTime end;
  final List<UserType> usertypes;
  final CampaignScope scope;

  const CampaignCreate({
    required this.name,
    required this.start,
    required this.end,
    required this.usertypes,
    required this.scope,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'start': start.toUtc().toIso8601String(),
    'end': end.toUtc().toIso8601String(),
    'usertypes': usertypes.map((t) => t.value).toList(),
    'scope': scope.value,
  };
}

/// Fields to update on a [Campaign]. Omitted fields are left unchanged (PATCH).
class CampaignUpdate {
  final String? name;
  final DateTime? start;
  final DateTime? end;

  const CampaignUpdate({this.name, this.start, this.end});

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (start != null) 'start': start!.toUtc().toIso8601String(),
    if (end != null) 'end': end!.toUtc().toIso8601String(),
  };
}

/// Fields to create or update an [Ad]. On update, omitted fields are left
/// unchanged (PATCH).
///
/// Provide either [imageUrl] or [imageData] (base64), not both. When
/// [imageData] is given, [imageFilename] is required; the image is uploaded
/// and its URL becomes the hero image.
class AdUpdate {
  final String? name;
  final String? headline;
  final String? body;
  final String? url;
  final String? imageUrl;
  final String? imageData;
  final String? imageFilename;

  const AdUpdate({
    this.name,
    this.headline,
    this.body,
    this.url,
    this.imageUrl,
    this.imageData,
    this.imageFilename,
  });

  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (headline != null) 'headline': headline,
    if (body != null) 'body': body,
    if (url != null) 'url': url,
    if (imageUrl != null) 'image_url': imageUrl,
    if (imageData != null) 'image_data': imageData,
    if (imageFilename != null) 'image_filename': imageFilename,
  };
}
