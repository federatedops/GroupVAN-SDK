enum CountryCode { us, ca, mx }

enum CountryDivisionCode {
  alabama(countryCode: CountryCode.us, abbreviation: 'AL', name: 'Alabama'),
  alaska(countryCode: CountryCode.us, abbreviation: 'AK', name: 'Alaska'),
  arizona(countryCode: CountryCode.us, abbreviation: 'AZ', name: 'Arizona'),
  arkansas(countryCode: CountryCode.us, abbreviation: 'AR', name: 'Arkansas'),
  california(
      countryCode: CountryCode.us, abbreviation: 'CA', name: 'California'),
  colorado(countryCode: CountryCode.us, abbreviation: 'CO', name: 'Colorado'),
  connecticut(
      countryCode: CountryCode.us, abbreviation: 'CT', name: 'Connecticut'),
  delaware(countryCode: CountryCode.us, abbreviation: 'DE', name: 'Delaware'),
  districtOfColumbia(
      countryCode: CountryCode.us,
      abbreviation: 'DC',
      name: 'District of Columbia'),
  florida(countryCode: CountryCode.us, abbreviation: 'FL', name: 'Florida'),
  georgia(countryCode: CountryCode.us, abbreviation: 'GA', name: 'Georgia'),
  guam(countryCode: CountryCode.us, abbreviation: 'GU', name: 'Guam'),
  hawaii(countryCode: CountryCode.us, abbreviation: 'HI', name: 'Hawaii'),
  idaho(countryCode: CountryCode.us, abbreviation: 'ID', name: 'Idaho'),
  illinois(countryCode: CountryCode.us, abbreviation: 'IL', name: 'Illinois'),
  indiana(countryCode: CountryCode.us, abbreviation: 'IN', name: 'Indiana'),
  iowa(countryCode: CountryCode.us, abbreviation: 'IA', name: 'Iowa'),
  kansas(countryCode: CountryCode.us, abbreviation: 'KS', name: 'Kansas'),
  kentucky(countryCode: CountryCode.us, abbreviation: 'KY', name: 'Kentucky'),
  louisiana(countryCode: CountryCode.us, abbreviation: 'LA', name: 'Louisiana'),
  maine(countryCode: CountryCode.us, abbreviation: 'ME', name: 'Maine'),
  maryland(countryCode: CountryCode.us, abbreviation: 'MD', name: 'Maryland'),
  massachusetts(
      countryCode: CountryCode.us, abbreviation: 'MA', name: 'Massachusetts'),
  michigan(countryCode: CountryCode.us, abbreviation: 'MI', name: 'Michigan'),
  minnesota(countryCode: CountryCode.us, abbreviation: 'MN', name: 'Minnesota'),
  mississippi(
      countryCode: CountryCode.us, abbreviation: 'MS', name: 'Mississippi'),
  missouri(countryCode: CountryCode.us, abbreviation: 'MO', name: 'Missouri'),
  montana(countryCode: CountryCode.us, abbreviation: 'MT', name: 'Montana'),
  nebraska(countryCode: CountryCode.us, abbreviation: 'NE', name: 'Nebraska'),
  nevada(countryCode: CountryCode.us, abbreviation: 'NV', name: 'Nevada'),
  newHampshire(
      countryCode: CountryCode.us, abbreviation: 'NH', name: 'New Hampshire'),
  newJersey(
      countryCode: CountryCode.us, abbreviation: 'NJ', name: 'New Jersey'),
  newMexico(
      countryCode: CountryCode.us, abbreviation: 'NM', name: 'New Mexico'),
  newYork(countryCode: CountryCode.us, abbreviation: 'NY', name: 'New York'),
  northCarolina(
      countryCode: CountryCode.us, abbreviation: 'NC', name: 'North Carolina'),
  northDakota(
      countryCode: CountryCode.us, abbreviation: 'ND', name: 'North Dakota'),
  ohio(countryCode: CountryCode.us, abbreviation: 'OH', name: 'Ohio'),
  oklahoma(countryCode: CountryCode.us, abbreviation: 'OK', name: 'Oklahoma'),
  oregon(countryCode: CountryCode.us, abbreviation: 'OR', name: 'Oregon'),
  pennsylvania(
      countryCode: CountryCode.us, abbreviation: 'PA', name: 'Pennsylvania'),
  puertoRico(
      countryCode: CountryCode.us, abbreviation: 'PR', name: 'Puerto Rico'),
  rhodeIsland(
      countryCode: CountryCode.us, abbreviation: 'RI', name: 'Rhode Island'),
  southCarolina(
      countryCode: CountryCode.us, abbreviation: 'SC', name: 'South Carolina'),
  southDakota(
      countryCode: CountryCode.us, abbreviation: 'SD', name: 'South Dakota'),
  tennessee(countryCode: CountryCode.us, abbreviation: 'TN', name: 'Tennessee'),
  texas(countryCode: CountryCode.us, abbreviation: 'TX', name: 'Texas'),
  utah(countryCode: CountryCode.us, abbreviation: 'UT', name: 'Utah'),
  vermont(countryCode: CountryCode.us, abbreviation: 'VT', name: 'Vermont'),
  virginia(countryCode: CountryCode.us, abbreviation: 'VA', name: 'Virginia'),
  washington(
      countryCode: CountryCode.us, abbreviation: 'WA', name: 'Washington'),
  westVirginia(
      countryCode: CountryCode.us, abbreviation: 'WV', name: 'West Virginia'),
  wisconsin(countryCode: CountryCode.us, abbreviation: 'WI', name: 'Wisconsin'),
  wyoming(countryCode: CountryCode.us, abbreviation: 'WY', name: 'Wyoming'),
  unknown(countryCode: CountryCode.us, abbreviation: 'XX', name: 'Unknown');

  const CountryDivisionCode(
      {required this.countryCode,
      required this.abbreviation,
      required this.name});

  final CountryCode countryCode;
  final String abbreviation;
  final String name;

  factory CountryDivisionCode.fromAbbreviation(String abbreviation) {
    return CountryDivisionCode.values.firstWhere(
      (el) => el.abbreviation == abbreviation,
      orElse: () => CountryDivisionCode.unknown,
    );
  }

  factory CountryDivisionCode.fromName(String name) {
    return CountryDivisionCode.values.firstWhere(
      (el) => el.name.toLowerCase() == name.toLowerCase(),
      orElse: () => CountryDivisionCode.unknown,
    );
  }
}
