import '../catalogs.dart';
import 'member_category.dart';

/// Search suggestions response.
///
/// Returned by `GET /v3/search/suggestions` — the most popular part terms
/// plus the member's most-looked-up categories, used to seed an empty search
/// box with suggestions.
class SuggestionsResponse {
  final List<PartType> partTermSuggestions;
  final List<MemberCategory> memberCategoriesSuggestions;

  const SuggestionsResponse({
    required this.partTermSuggestions,
    required this.memberCategoriesSuggestions,
  });

  factory SuggestionsResponse.fromJson(Map<String, dynamic> json) =>
      SuggestionsResponse(
        partTermSuggestions: ((json['part_term_suggestions'] as List<dynamic>?) ?? [])
            .map((item) => PartType.fromJson(item as Map<String, dynamic>))
            .toList(),
        memberCategoriesSuggestions:
            ((json['member_categories_suggestions'] as List<dynamic>?) ?? [])
                .map((item) => MemberCategory.fromJson(item as Map<String, dynamic>))
                .toList(),
      );

  Map<String, dynamic> toJson() => {
    'part_term_suggestions': partTermSuggestions.map((pt) => pt.toJson()).toList(),
    'member_categories_suggestions': memberCategoriesSuggestions
        .map((mc) => mc.toJson())
        .toList(),
  };
}
