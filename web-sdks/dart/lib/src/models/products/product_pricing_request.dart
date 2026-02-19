class ProductPricingRequest {
  const ProductPricingRequest({
    required this.mfrCode,
    required this.partNumber,
  });
  final String mfrCode;
  final String partNumber;

  Map<String, dynamic> toJson() => {
    'mfr_code': mfrCode,
    'part_number': partNumber,
  };
}
