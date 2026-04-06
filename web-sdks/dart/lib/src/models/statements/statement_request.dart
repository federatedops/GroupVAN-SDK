/// Request for statements via the v3.2 gateway
class StatementRequest {
  final String memberId;
  final String accountId;
  final String fromStatementDate;
  final String toStatementDate;
  final String? locationId;
  final String? statementType;
  final String? transactionId;

  const StatementRequest({
    required this.memberId,
    required this.accountId,
    required this.fromStatementDate,
    required this.toStatementDate,
    this.locationId,
    this.statementType,
    this.transactionId,
  });

  Map<String, dynamic> toJson() => {
    'member': memberId,
    'account': accountId,
    'from_statement_date': fromStatementDate,
    'to_statement_date': toStatementDate,
    if (locationId != null) 'location_id': locationId,
    if (statementType != null) 'statement_type': statementType,
    if (transactionId != null) 'transaction_id': transactionId,
  };
}
