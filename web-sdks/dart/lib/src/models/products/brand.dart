class Brand {
  final String code;
  final String name;

  const Brand({required this.code, required this.name});

  factory Brand.fromJson(Map<String, dynamic> json) =>
      Brand(code: json['code'], name: json['name']);
}
