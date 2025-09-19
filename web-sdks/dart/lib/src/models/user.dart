class UserDetails {
  final String name;
  final String countryDivisionCode;
  final String companyName;

  const UserDetails({
    required this.name,
    required this.countryDivisionCode,
    required this.companyName,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) => UserDetails(
    name: json['name'],
    countryDivisionCode: json['country_division_code'],
    companyName: json['company_name'],
  );
}
