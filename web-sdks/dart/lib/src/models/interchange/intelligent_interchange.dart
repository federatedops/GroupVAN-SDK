/// Match tier for an intelligent interchange candidate.
///
/// Shown as Match / Questionable / Non-match.
enum IntelligentMatchTier {
  high,
  medium,
  low;

  static IntelligentMatchTier fromJson(String? value) => switch (value) {
    'high' => IntelligentMatchTier.high,
    'medium' => IntelligentMatchTier.medium,
    _ => IntelligentMatchTier.low,
  };
}

/// How a spec difference affects an intelligent interchange match.
///
/// [mismatch] is a deal-breaker, [sourceDataError] means other brands outvote
/// the searched part's own spec, [kit] and [verify] flag kit contents and
/// materials, and [info] does not affect the tier.
enum IntelligentConflictSeverity {
  mismatch,
  sourceDataError,
  kit,
  verify,
  info;

  static IntelligentConflictSeverity fromJson(String? value) => switch (value) {
    'mismatch' => IntelligentConflictSeverity.mismatch,
    'source_data_error' => IntelligentConflictSeverity.sourceDataError,
    'kit' => IntelligentConflictSeverity.kit,
    'verify' => IntelligentConflictSeverity.verify,
    _ => IntelligentConflictSeverity.info,
  };
}

/// Request for `POST /v3/catalogs/interchange/intelligent`.
///
/// [partNumber] is 1-50 characters; punctuation and spacing are ignored.
/// [mfrCode] and [partTypeId] narrow a part number several brands or part
/// types share. [targetMfrCodes] grades only those manufacturers. [limit] is
/// matches per source part, 1-100.
class IntelligentInterchangeRequest {
  final String partNumber;
  final String? mfrCode;
  final int? partTypeId;
  final List<String>? targetMfrCodes;
  final IntelligentMatchTier? minTier;
  final int? limit;
  final bool? includeSameBrand;

  const IntelligentInterchangeRequest({
    required this.partNumber,
    this.mfrCode,
    this.partTypeId,
    this.targetMfrCodes,
    this.minTier,
    this.limit,
    this.includeSameBrand,
  });

  Map<String, dynamic> toJson() => {
    'part_number': partNumber,
    if (mfrCode != null) 'mfr_code': mfrCode,
    if (partTypeId != null) 'part_type_id': partTypeId,
    if (targetMfrCodes != null) 'target_mfr_codes': targetMfrCodes,
    if (minTier != null) 'min_tier': minTier!.name,
    if (limit != null) 'limit': limit,
    if (includeSameBrand != null) 'include_same_brand': includeSameBrand,
  };
}

/// Response for `POST /v3/catalogs/interchange/intelligent`.
///
/// [results] has one entry per catalog part matching the part number, up to
/// five; [sourcesTruncated] is true when more matched.
class IntelligentInterchangeResponse {
  final String partNumber;
  final bool sourcesTruncated;
  final List<IntelligentInterchangeResult> results;

  const IntelligentInterchangeResponse({
    required this.partNumber,
    required this.sourcesTruncated,
    required this.results,
  });

  factory IntelligentInterchangeResponse.fromJson(Map<String, dynamic> json) =>
      IntelligentInterchangeResponse(
        partNumber: json['part_number'] as String? ?? '',
        sourcesTruncated: json['sources_truncated'] as bool? ?? false,
        results: [
          for (final result in json['results'] as List? ?? const [])
            IntelligentInterchangeResult.fromJson(
              result as Map<String, dynamic>,
            ),
        ],
      );
}

/// A searched part and its graded matches, ordered by tier then score.
class IntelligentInterchangeResult {
  final IntelligentInterchangePart source;
  final List<IntelligentInterchangeMatch> matches;

  const IntelligentInterchangeResult({
    required this.source,
    required this.matches,
  });

  factory IntelligentInterchangeResult.fromJson(Map<String, dynamic> json) =>
      IntelligentInterchangeResult(
        source: IntelligentInterchangePart.fromJson(
          json['source'] as Map<String, dynamic>,
        ),
        matches: [
          for (final match in json['matches'] as List? ?? const [])
            IntelligentInterchangeMatch.fromJson(match as Map<String, dynamic>),
        ],
      );
}

/// A catalog part as the intelligent interchange identifies it.
///
/// [positions] are every position the part fits. [vehicles] is the count of
/// base vehicles it applies to.
class IntelligentInterchangePart {
  final int partId;
  final String mfrCode;
  final String partNumber;
  final String? sku;
  final String? brandName;
  final String? aaiaBrandId;
  final int? partTypeId;
  final String? partTypeName;
  final List<String> positions;
  final int vehicles;

  const IntelligentInterchangePart({
    required this.partId,
    required this.mfrCode,
    required this.partNumber,
    this.sku,
    this.brandName,
    this.aaiaBrandId,
    this.partTypeId,
    this.partTypeName,
    this.positions = const [],
    this.vehicles = 0,
  });

  factory IntelligentInterchangePart.fromJson(Map<String, dynamic> json) =>
      IntelligentInterchangePart(
        partId: json['part_id'] as int,
        mfrCode: json['mfr_code'] as String,
        partNumber: json['part_number'] as String,
        sku: json['sku'] as String?,
        brandName: json['brand_name'] as String?,
        aaiaBrandId: json['aaia_brand_id'] as String?,
        partTypeId: json['part_type_id'] as int?,
        partTypeName: json['part_type_name'] as String?,
        positions: List<String>.from(json['positions'] as List? ?? const []),
        vehicles: json['vehicles'] as int? ?? 0,
      );
}

/// A graded candidate for the searched part.
///
/// [score] is 0-100 and orders matches within a [tier]. [result] is the
/// display label for the tier. [grade] is the fitment grade after the spec
/// check and [fitmentGrade] the grade before it. [coverage] is the share of
/// the searched part's vehicles the candidate fits, on [coverageBasis]
/// (`vio` or `vehicles`). [sideCheck] is one of `MATCH`, `AMBIGUOUS`,
/// `AXLE_ONLY`, `AXLE_SOURCE`, `UNKNOWN`, `MISMATCH` or `NONE`. [reasons] are
/// plain-English explanations for anything below the high tier.
class IntelligentInterchangeMatch {
  final IntelligentInterchangePart part;
  final IntelligentMatchTier tier;
  final String? result;
  final double score;
  final String? grade;
  final String? fitmentGrade;
  final double coverage;
  final String? coverageBasis;
  final double? vehicleCoverage;
  final int sourceVehicles;
  final int targetVehicles;
  final int sharedVehicles;
  final int missingVehicles;
  final int extraVehicles;
  final String? sideCheck;
  final List<String> sourcePositions;
  final List<String> targetPositions;
  final List<String> corroboration;
  final int specsCompared;
  final int specsMatched;
  final List<IntelligentInterchangeConflict> conflicts;
  final List<String> reasons;
  final List<IntelligentInterchangeVehicle> missingVehicleExamples;
  final List<IntelligentInterchangeVehicle> extraVehicleExamples;

  const IntelligentInterchangeMatch({
    required this.part,
    required this.tier,
    this.result,
    required this.score,
    this.grade,
    this.fitmentGrade,
    required this.coverage,
    this.coverageBasis,
    this.vehicleCoverage,
    this.sourceVehicles = 0,
    this.targetVehicles = 0,
    this.sharedVehicles = 0,
    this.missingVehicles = 0,
    this.extraVehicles = 0,
    this.sideCheck,
    this.sourcePositions = const [],
    this.targetPositions = const [],
    this.corroboration = const [],
    this.specsCompared = 0,
    this.specsMatched = 0,
    this.conflicts = const [],
    this.reasons = const [],
    this.missingVehicleExamples = const [],
    this.extraVehicleExamples = const [],
  });

  factory IntelligentInterchangeMatch.fromJson(
    Map<String, dynamic> json,
  ) => IntelligentInterchangeMatch(
    part: IntelligentInterchangePart.fromJson(json),
    tier: IntelligentMatchTier.fromJson(json['tier'] as String?),
    result: json['result'] as String?,
    score: (json['score'] as num? ?? 0).toDouble(),
    grade: json['grade'] as String?,
    fitmentGrade: json['fitment_grade'] as String?,
    coverage: (json['coverage'] as num? ?? 0).toDouble(),
    coverageBasis: json['coverage_basis'] as String?,
    vehicleCoverage: (json['vehicle_coverage'] as num?)?.toDouble(),
    sourceVehicles: json['source_vehicles'] as int? ?? 0,
    targetVehicles: json['target_vehicles'] as int? ?? 0,
    sharedVehicles: json['shared_vehicles'] as int? ?? 0,
    missingVehicles: json['missing_vehicles'] as int? ?? 0,
    extraVehicles: json['extra_vehicles'] as int? ?? 0,
    sideCheck: json['side_check'] as String?,
    sourcePositions: List<String>.from(
      json['source_positions'] as List? ?? const [],
    ),
    targetPositions: List<String>.from(
      json['target_positions'] as List? ?? const [],
    ),
    corroboration: List<String>.from(
      json['corroboration'] as List? ?? const [],
    ),
    specsCompared: json['specs_compared'] as int? ?? 0,
    specsMatched: json['specs_matched'] as int? ?? 0,
    conflicts: [
      for (final conflict in json['conflicts'] as List? ?? const [])
        IntelligentInterchangeConflict.fromJson(
          conflict as Map<String, dynamic>,
        ),
    ],
    reasons: List<String>.from(json['reasons'] as List? ?? const []),
    missingVehicleExamples: [
      for (final vehicle
          in json['missing_vehicle_examples'] as List? ?? const [])
        IntelligentInterchangeVehicle.fromJson(vehicle as Map<String, dynamic>),
    ],
    extraVehicleExamples: [
      for (final vehicle in json['extra_vehicle_examples'] as List? ?? const [])
        IntelligentInterchangeVehicle.fromJson(vehicle as Map<String, dynamic>),
    ],
  );
}

/// A PIES spec that differs between the searched part and a candidate.
///
/// [specClass] is the backend's grouping (`gating`, `kit`, ...). [market]
/// maps each value other brands list to how many list it, when the backend
/// arbitrated a likely source data error.
class IntelligentInterchangeConflict {
  final String attribute;
  final String? specClass;
  final String? sourceValue;
  final String? targetValue;
  final IntelligentConflictSeverity severity;
  final Map<String, int> market;

  const IntelligentInterchangeConflict({
    required this.attribute,
    this.specClass,
    this.sourceValue,
    this.targetValue,
    required this.severity,
    this.market = const {},
  });

  factory IntelligentInterchangeConflict.fromJson(Map<String, dynamic> json) =>
      IntelligentInterchangeConflict(
        attribute: json['attribute'] as String? ?? '',
        specClass: json['class'] as String?,
        sourceValue: json['source_value']?.toString(),
        targetValue: json['target_value']?.toString(),
        severity: IntelligentConflictSeverity.fromJson(
          json['severity'] as String?,
        ),
        market: {
          for (final entry
              in (json['market'] as Map<String, dynamic>? ?? const {}).entries)
            entry.key: (entry.value as num).toInt(),
        },
      );
}

/// A vehicle a candidate misses or adds, with its vehicles in operation.
class IntelligentInterchangeVehicle {
  final int baseVehicleId;
  final String vehicle;
  final int? vio;

  const IntelligentInterchangeVehicle({
    required this.baseVehicleId,
    required this.vehicle,
    this.vio,
  });

  factory IntelligentInterchangeVehicle.fromJson(Map<String, dynamic> json) =>
      IntelligentInterchangeVehicle(
        baseVehicleId: json['base_vehicle_id'] as int? ?? 0,
        vehicle: json['vehicle'] as String? ?? '',
        vio: json['vio'] as int?,
      );
}
