import 'statement.dart';

/// Response from the v3.2 statement endpoint
class StatementResponse {
  final String status;
  final String errorDescription;
  final List<Statement> statements;

  const StatementResponse({
    required this.status,
    required this.errorDescription,
    required this.statements,
  });

  factory StatementResponse.fromJson(Map<String, dynamic> json) =>
      StatementResponse(
        status: (json['status'] ?? '') as String,
        errorDescription: (json['error_description'] ?? '') as String,
        statements: (json['statements'] as List<dynamic>)
            .map((s) => Statement.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'status': status,
    'error_description': errorDescription,
    'statements': statements.map((s) => s.toJson()).toList(),
  };
}
