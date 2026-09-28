/// One Places autocomplete suggestion for a partial address.
class AddressSuggestion {
  final String placeId;

  /// Full suggestion text, e.g. "123 Main St, Staunton, VA, USA".
  final String text;

  /// Street part of [text], for the first line of a suggestion row.
  final String mainText;

  /// Locality part of [text], for the second line of a suggestion row.
  final String secondaryText;

  const AddressSuggestion({
    required this.placeId,
    required this.text,
    required this.mainText,
    required this.secondaryText,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) =>
      AddressSuggestion(
        placeId: json['place_id'] as String,
        text: json['text'] as String,
        mainText: json['main_text'] as String,
        secondaryText: json['secondary_text'] as String,
      );
}

/// An address as standardised and geocoded by Google Address Validation.
///
/// [state] and [country] are short codes ("VA", "US") sized for
/// [LocationCompany]. A second address line is folded into [address].
class ValidatedAddress {
  final String address;
  final String city;
  final String state;
  final String zip;
  final String country;
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final bool addressComplete;
  final bool hasUnconfirmedComponents;
  final bool hasReplacedComponents;

  const ValidatedAddress({
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.addressComplete,
    required this.hasUnconfirmedComponents,
    required this.hasReplacedComponents,
  });

  /// Whether Google matched the address without guessing or fixing parts.
  bool get isConfirmed =>
      addressComplete && !hasUnconfirmedComponents && !hasReplacedComponents;

  factory ValidatedAddress.fromJson(Map<String, dynamic> json) =>
      ValidatedAddress(
        address: json['address'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        zip: json['zip'] as String,
        country: json['country'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        formattedAddress: json['formatted_address'] as String,
        addressComplete: json['address_complete'] as bool,
        hasUnconfirmedComponents: json['has_unconfirmed_components'] as bool,
        hasReplacedComponents: json['has_replaced_components'] as bool,
      );
}
