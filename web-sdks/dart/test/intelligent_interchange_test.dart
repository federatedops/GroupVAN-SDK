import 'package:groupvan/groupvan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IntelligentInterchangeRequest', () {
    test('serializes only the fields that were set', () {
      const request = IntelligentInterchangeRequest(
        partNumber: '12-9451',
        mfrCode: 'FLC',
        minTier: IntelligentMatchTier.medium,
        limit: 25,
      );

      expect(request.toJson(), {
        'part_number': '12-9451',
        'mfr_code': 'FLC',
        'min_tier': 'medium',
        'limit': 25,
      });
    });
  });

  group('IntelligentInterchangeResponse', () {
    final json = {
      'part_number': '12-9451',
      'sources_truncated': false,
      'results': [
        {
          'source': {
            'part_id': 51033,
            'mfr_code': 'FLC',
            'part_number': '12-9451',
            'sku': '01dd8fd688c5d32ee1d23266a92b513c',
            'brand_name': 'Silent Stop Caliper',
            'aaia_brand_id': 'GNQW',
            'part_type_id': 1704,
            'part_type_name': 'Disc Brake Caliper',
            'positions': ['Rear Right'],
            'vehicles': 8,
          },
          'matches': [
            {
              'part_id': 24269,
              'mfr_code': 'BBB',
              'part_number': '99-01736A',
              'sku': '3767000f6532506b2a944ddb08da6991',
              'brand_name': 'BBB Industries',
              'aaia_brand_id': 'BGRT',
              'part_type_id': 1704,
              'part_type_name': 'Disc Brake Caliper',
              'positions': ['Rear Right'],
              'vehicles': 8,
              'tier': 'medium',
              'result': 'Questionable',
              'score': 100.0,
              'grade': 'A',
              'fitment_grade': 'A',
              'coverage': 1.0,
              'coverage_basis': 'vio',
              'vehicle_coverage': 1.0,
              'source_vehicles': 8,
              'target_vehicles': 8,
              'shared_vehicles': 8,
              'missing_vehicles': 0,
              'extra_vehicles': 0,
              'side_check': 'MATCH',
              'source_positions': ['Rear Right'],
              'target_positions': ['Rear Right'],
              'corroboration': ['oe_interchange', 'identical_vehicles'],
              'specs_compared': 5,
              'specs_matched': 3,
              'conflicts': [
                {
                  'attribute': 'Piston Quantity',
                  'class': 'gating',
                  'source_value': '4',
                  'target_value': '1',
                  'market': {'1': 2},
                  'severity': 'source_data_error',
                },
                {
                  'attribute': 'Caliper Slides Included',
                  'class': 'kit',
                  'source_value': 'NO',
                  'target_value': 'YES',
                  'severity': 'kit',
                },
              ],
              'reasons': [
                'Silent Stop Caliper specs likely wrong: piston quantity listed 4, other brands say 1',
                'Caliper Slides Included: Silent Stop Caliper NO, BBB Industries YES',
              ],
              'missing_vehicle_examples': [
                {
                  'base_vehicle_id': 12345,
                  'vehicle': '2015 Jeep Wrangler',
                  'vio': 152340,
                },
              ],
              'extra_vehicle_examples': [],
            },
          ],
        },
      ],
    };

    test('parses the documented example', () {
      final response = IntelligentInterchangeResponse.fromJson(json);

      expect(response.partNumber, '12-9451');
      expect(response.sourcesTruncated, isFalse);
      expect(response.results, hasLength(1));

      final result = response.results.single;
      expect(result.source.partId, 51033);
      expect(result.source.brandName, 'Silent Stop Caliper');
      expect(result.source.positions, ['Rear Right']);

      final match = result.matches.single;
      expect(match.part.mfrCode, 'BBB');
      expect(match.part.partNumber, '99-01736A');
      expect(match.tier, IntelligentMatchTier.medium);
      expect(match.result, 'Questionable');
      expect(match.score, 100.0);
      expect(match.grade, 'A');
      expect(match.coverage, 1.0);
      expect(match.coverageBasis, 'vio');
      expect(match.sideCheck, 'MATCH');
      expect(match.corroboration, ['oe_interchange', 'identical_vehicles']);
      expect(match.specsCompared, 5);
      expect(match.reasons, hasLength(2));
      expect(match.missingVehicleExamples.single.vio, 152340);
    });

    test('parses conflicts with their severity and market votes', () {
      final match = IntelligentInterchangeResponse.fromJson(
        json,
      ).results.single.matches.single;

      final gating = match.conflicts.first;
      expect(gating.attribute, 'Piston Quantity');
      expect(gating.specClass, 'gating');
      expect(gating.severity, IntelligentConflictSeverity.sourceDataError);
      expect(gating.market, {'1': 2});

      final kit = match.conflicts.last;
      expect(kit.severity, IntelligentConflictSeverity.kit);
      expect(kit.market, isEmpty);
    });

    test('tolerates a match with only the required fields', () {
      final match = IntelligentInterchangeMatch.fromJson({
        'part_id': 1,
        'mfr_code': 'BBB',
        'part_number': 'X',
      });

      expect(match.tier, IntelligentMatchTier.low);
      expect(match.score, 0);
      expect(match.conflicts, isEmpty);
      expect(match.reasons, isEmpty);
    });
  });

  group('IntelligentInterchangeUnavailableException', () {
    test('carries the server detail', () {
      final exception = IntelligentInterchangeUnavailableException(
        'Intelligent interchange is not available',
        detail: 'Interchange data is not loaded yet',
      );

      expect(exception.toString(), contains('not loaded yet'));
      expect(exception, isA<GroupVanException>());
    });
  });
}
