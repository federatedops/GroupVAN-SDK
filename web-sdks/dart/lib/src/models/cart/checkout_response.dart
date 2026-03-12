class CheckoutResponse {
  final String message;
  final String? warning;
  final List<String>? failedLocations;

  const CheckoutResponse({
    required this.message,
    this.warning,
    this.failedLocations,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json, int statusCode) {
    if (statusCode == 207) {
      return CheckoutResponse(
        message: json['message'] ?? 'Cart checkout partially successful',
        warning: json['warning'],
        failedLocations: (json['failed_locations'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
      );
    }
    return CheckoutResponse(
      message: json['message'] ?? 'Cart checkout successful',
    );
  }

  bool get isPartialSuccess => warning != null;

  Map<String, dynamic> toJson() => {
    'message': message,
    if (warning != null) 'warning': warning,
    if (failedLocations != null) 'failed_locations': failedLocations,
  };
}
