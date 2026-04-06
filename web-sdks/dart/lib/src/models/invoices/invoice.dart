import 'invoice_detail.dart';

/// A single invoice returned in an invoice response
class Invoice {
  final String invoiceNumber;
  final String invoiceDate;
  final String accountId;
  final String locationId;
  final String locationDescription;
  final String poNumber;
  final double itemCount;
  final double totalCost;
  final String? linkUrl;
  final List<InvoiceDetail> invoiceDetail;

  const Invoice({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.accountId,
    required this.locationId,
    required this.locationDescription,
    required this.poNumber,
    required this.itemCount,
    required this.totalCost,
    this.linkUrl,
    required this.invoiceDetail,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    invoiceNumber: json['invoice_number'] as String,
    invoiceDate: json['invoice_date'] as String,
    accountId: json['account_id'] as String,
    locationId: json['location_id'] as String,
    locationDescription: json['location_description'] as String,
    poNumber: json['po_number'] as String,
    itemCount: (json['item_count'] as num).toDouble(),
    totalCost: (json['total_cost'] as num).toDouble(),
    linkUrl: json['link_url'] as String?,
    invoiceDetail: (json['invoice_detail'] as List<dynamic>)
        .map((d) => InvoiceDetail.fromJson(d as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'invoice_number': invoiceNumber,
    'invoice_date': invoiceDate,
    'account_id': accountId,
    'location_id': locationId,
    'location_description': locationDescription,
    'po_number': poNumber,
    'item_count': itemCount,
    'total_cost': totalCost,
    'link_url': linkUrl,
    'invoice_detail': invoiceDetail.map((d) => d.toJson()).toList(),
  };
}
