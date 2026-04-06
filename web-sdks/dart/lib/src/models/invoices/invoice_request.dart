/// Request for invoices via the v3.2 gateway
class InvoiceRequest {
  final String memberId;
  final String? accountId;
  final String? invoiceNumber;
  final String? purchaseOrderNumber;
  final String? fromInvoiceDate;
  final String? toInvoiceDate;
  final String? locationId;
  final String? partNumber;
  final String? invoiceType;
  final String? transactionId;

  const InvoiceRequest({
    required this.memberId,
    this.accountId,
    this.invoiceNumber,
    this.purchaseOrderNumber,
    this.fromInvoiceDate,
    this.toInvoiceDate,
    this.locationId,
    this.partNumber,
    this.invoiceType,
    this.transactionId,
  });

  Map<String, dynamic> toJson() => {
    'member': memberId,
    if (accountId != null) 'account': accountId,
    if (invoiceNumber != null) 'invoice_number': invoiceNumber,
    if (purchaseOrderNumber != null) 'purchase_order_number': purchaseOrderNumber,
    if (fromInvoiceDate != null) 'from_invoice_date': fromInvoiceDate,
    if (toInvoiceDate != null) 'to_invoice_date': toInvoiceDate,
    if (locationId != null) 'location_id': locationId,
    if (partNumber != null) 'part_number': partNumber,
    if (invoiceType != null) 'invoice_type': invoiceType,
    if (transactionId != null) 'transaction_id': transactionId,
  };
}
