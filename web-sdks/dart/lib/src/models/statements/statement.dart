import 'statement_detail.dart';

/// A single statement returned in a statement response
class Statement {
  final String statementDate;
  final String accountId;
  final String accountDescription;
  final String locationId;
  final double totalCost;
  final String? linkUrl;
  final List<StatementDetail> statementDetail;

  const Statement({
    required this.statementDate,
    required this.accountId,
    required this.accountDescription,
    required this.locationId,
    required this.totalCost,
    this.linkUrl,
    required this.statementDetail,
  });

  factory Statement.fromJson(Map<String, dynamic> json) => Statement(
    statementDate: json['statement_date'] as String,
    accountId: json['account_id'] as String,
    accountDescription: (json['account_description'] ?? '') as String,
    locationId: (json['location_id'] ?? '') as String,
    totalCost: (json['total_cost'] as num).toDouble(),
    linkUrl: json['link_url'] as String?,
    statementDetail: (json['statement_detail'] as List<dynamic>)
        .map((d) => StatementDetail.fromJson(d as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'statement_date': statementDate,
    'account_id': accountId,
    'account_description': accountDescription,
    'location_id': locationId,
    'total_cost': totalCost,
    'link_url': linkUrl,
    'statement_detail': statementDetail.map((d) => d.toJson()).toList(),
  };
}
