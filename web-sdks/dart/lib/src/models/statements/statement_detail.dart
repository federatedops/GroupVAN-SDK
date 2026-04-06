/// A single line item inside a statement
class StatementDetail {
  final String invoiceDate;
  final String invoiceNumber;
  final String referenceNumber;
  final double originalAmount;
  final double paidAmount;
  final String? referenceType;

  const StatementDetail({
    required this.invoiceDate,
    required this.invoiceNumber,
    required this.referenceNumber,
    required this.originalAmount,
    required this.paidAmount,
    this.referenceType,
  });

  factory StatementDetail.fromJson(Map<String, dynamic> json) =>
      StatementDetail(
        invoiceDate: json['invoice_date'] as String,
        invoiceNumber: (json['invoice_number'] ?? '') as String,
        referenceNumber: (json['reference_number'] ?? '') as String,
        originalAmount: (json['original_amount'] as num?)?.toDouble() ?? 0,
        paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
        referenceType: json['reference_type'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'invoice_date': invoiceDate,
    'invoice_number': invoiceNumber,
    'reference_number': referenceNumber,
    'original_amount': originalAmount,
    'paid_amount': paidAmount,
    if (referenceType != null) 'reference_type': referenceType,
  };
}
