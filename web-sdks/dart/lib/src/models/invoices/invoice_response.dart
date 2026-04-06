import 'invoice.dart';

/// Response from the v3.2 invoice endpoint
class InvoiceResponse {
  final String status;
  final String errorDescription;
  final List<Invoice> invoices;

  const InvoiceResponse({
    required this.status,
    required this.errorDescription,
    required this.invoices,
  });

  factory InvoiceResponse.fromJson(Map<String, dynamic> json) =>
      InvoiceResponse(
        status: (json['status'] ?? '') as String,
        errorDescription: (json['error_description'] ?? '') as String,
        invoices: (json['invoices'] as List<dynamic>)
            .map((i) => Invoice.fromJson(i as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'status': status,
    'error_description': errorDescription,
    'invoices': invoices.map((i) => i.toJson()).toList(),
  };
}
