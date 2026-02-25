class Product {
  const Product({
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

class ProductPricingRequest {
  const ProductPricingRequest({
    required this.products,
  });
  final List<Product> products;

  Map<String, dynamic> toJson() => {
    'products': products.map((product) => product.toJson()).toList(),
  };
}
