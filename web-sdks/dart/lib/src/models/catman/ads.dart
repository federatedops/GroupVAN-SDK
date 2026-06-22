/// Catman ads models: [Ad] and [Campaign].
library;

/// A single ad within a campaign.
class Ad {
  final String? name;
  final String? headline;
  final String? body;
  final String? url;
  final String? imageUrl;

  const Ad({
    this.name,
    this.headline,
    this.body,
    this.url,
    this.imageUrl,
  });

  factory Ad.fromJson(Map<String, dynamic> json) => Ad(
    name: json['name'] as String?,
    headline: json['headline'] as String?,
    body: json['body'] as String?,
    url: json['url'] as String?,
    imageUrl: json['image_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
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
  final List<Ad> ads;

  const Campaign({
    required this.id,
    this.name,
    this.start,
    this.end,
    this.ads = const [],
  });

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
    id: json['id'] as int,
    name: json['name'] as String?,
    start: json['start'] == null
        ? null
        : DateTime.parse(json['start'] as String),
    end: json['end'] == null ? null : DateTime.parse(json['end'] as String),
    ads: (json['ads'] as List<dynamic>? ?? const [])
        .map((a) => Ad.fromJson(a as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'start': start?.toUtc().toIso8601String(),
    'end': end?.toUtc().toIso8601String(),
    'ads': ads.map((a) => a.toJson()).toList(),
  };
}
