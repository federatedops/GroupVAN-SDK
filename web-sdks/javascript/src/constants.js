/**
 * Constants for the GroupVAN SDK
 */

/**
 * Country codes
 * @enum {string}
 */
export const CountryCode = {
  US: 'us',
  CA: 'ca',
  MX: 'mx',
};

/**
 * US State and territory codes
 */
export const CountryDivisionCode = {
  ALABAMA: { countryCode: CountryCode.US, abbreviation: 'AL', name: 'Alabama' },
  ALASKA: { countryCode: CountryCode.US, abbreviation: 'AK', name: 'Alaska' },
  ARIZONA: { countryCode: CountryCode.US, abbreviation: 'AZ', name: 'Arizona' },
  ARKANSAS: { countryCode: CountryCode.US, abbreviation: 'AR', name: 'Arkansas' },
  CALIFORNIA: { countryCode: CountryCode.US, abbreviation: 'CA', name: 'California' },
  COLORADO: { countryCode: CountryCode.US, abbreviation: 'CO', name: 'Colorado' },
  CONNECTICUT: { countryCode: CountryCode.US, abbreviation: 'CT', name: 'Connecticut' },
  DELAWARE: { countryCode: CountryCode.US, abbreviation: 'DE', name: 'Delaware' },
  DISTRICT_OF_COLUMBIA: { countryCode: CountryCode.US, abbreviation: 'DC', name: 'District of Columbia' },
  FLORIDA: { countryCode: CountryCode.US, abbreviation: 'FL', name: 'Florida' },
  GEORGIA: { countryCode: CountryCode.US, abbreviation: 'GA', name: 'Georgia' },
  GUAM: { countryCode: CountryCode.US, abbreviation: 'GU', name: 'Guam' },
  HAWAII: { countryCode: CountryCode.US, abbreviation: 'HI', name: 'Hawaii' },
  IDAHO: { countryCode: CountryCode.US, abbreviation: 'ID', name: 'Idaho' },
  ILLINOIS: { countryCode: CountryCode.US, abbreviation: 'IL', name: 'Illinois' },
  INDIANA: { countryCode: CountryCode.US, abbreviation: 'IN', name: 'Indiana' },
  IOWA: { countryCode: CountryCode.US, abbreviation: 'IA', name: 'Iowa' },
  KANSAS: { countryCode: CountryCode.US, abbreviation: 'KS', name: 'Kansas' },
  KENTUCKY: { countryCode: CountryCode.US, abbreviation: 'KY', name: 'Kentucky' },
  LOUISIANA: { countryCode: CountryCode.US, abbreviation: 'LA', name: 'Louisiana' },
  MAINE: { countryCode: CountryCode.US, abbreviation: 'ME', name: 'Maine' },
  MARYLAND: { countryCode: CountryCode.US, abbreviation: 'MD', name: 'Maryland' },
  MASSACHUSETTS: { countryCode: CountryCode.US, abbreviation: 'MA', name: 'Massachusetts' },
  MICHIGAN: { countryCode: CountryCode.US, abbreviation: 'MI', name: 'Michigan' },
  MINNESOTA: { countryCode: CountryCode.US, abbreviation: 'MN', name: 'Minnesota' },
  MISSISSIPPI: { countryCode: CountryCode.US, abbreviation: 'MS', name: 'Mississippi' },
  MISSOURI: { countryCode: CountryCode.US, abbreviation: 'MO', name: 'Missouri' },
  MONTANA: { countryCode: CountryCode.US, abbreviation: 'MT', name: 'Montana' },
  NEBRASKA: { countryCode: CountryCode.US, abbreviation: 'NE', name: 'Nebraska' },
  NEVADA: { countryCode: CountryCode.US, abbreviation: 'NV', name: 'Nevada' },
  NEW_HAMPSHIRE: { countryCode: CountryCode.US, abbreviation: 'NH', name: 'New Hampshire' },
  NEW_JERSEY: { countryCode: CountryCode.US, abbreviation: 'NJ', name: 'New Jersey' },
  NEW_MEXICO: { countryCode: CountryCode.US, abbreviation: 'NM', name: 'New Mexico' },
  NEW_YORK: { countryCode: CountryCode.US, abbreviation: 'NY', name: 'New York' },
  NORTH_CAROLINA: { countryCode: CountryCode.US, abbreviation: 'NC', name: 'North Carolina' },
  NORTH_DAKOTA: { countryCode: CountryCode.US, abbreviation: 'ND', name: 'North Dakota' },
  OHIO: { countryCode: CountryCode.US, abbreviation: 'OH', name: 'Ohio' },
  OKLAHOMA: { countryCode: CountryCode.US, abbreviation: 'OK', name: 'Oklahoma' },
  OREGON: { countryCode: CountryCode.US, abbreviation: 'OR', name: 'Oregon' },
  PENNSYLVANIA: { countryCode: CountryCode.US, abbreviation: 'PA', name: 'Pennsylvania' },
  PUERTO_RICO: { countryCode: CountryCode.US, abbreviation: 'PR', name: 'Puerto Rico' },
  RHODE_ISLAND: { countryCode: CountryCode.US, abbreviation: 'RI', name: 'Rhode Island' },
  SOUTH_CAROLINA: { countryCode: CountryCode.US, abbreviation: 'SC', name: 'South Carolina' },
  SOUTH_DAKOTA: { countryCode: CountryCode.US, abbreviation: 'SD', name: 'South Dakota' },
  TENNESSEE: { countryCode: CountryCode.US, abbreviation: 'TN', name: 'Tennessee' },
  TEXAS: { countryCode: CountryCode.US, abbreviation: 'TX', name: 'Texas' },
  UTAH: { countryCode: CountryCode.US, abbreviation: 'UT', name: 'Utah' },
  VERMONT: { countryCode: CountryCode.US, abbreviation: 'VT', name: 'Vermont' },
  VIRGINIA: { countryCode: CountryCode.US, abbreviation: 'VA', name: 'Virginia' },
  WASHINGTON: { countryCode: CountryCode.US, abbreviation: 'WA', name: 'Washington' },
  WEST_VIRGINIA: { countryCode: CountryCode.US, abbreviation: 'WV', name: 'West Virginia' },
  WISCONSIN: { countryCode: CountryCode.US, abbreviation: 'WI', name: 'Wisconsin' },
  WYOMING: { countryCode: CountryCode.US, abbreviation: 'WY', name: 'Wyoming' },
  UNKNOWN: { countryCode: CountryCode.US, abbreviation: 'XX', name: 'Unknown' },
};

/**
 * Get all country division codes as an array
 * @returns {Array}
 */
export function getAllDivisions() {
  return Object.values(CountryDivisionCode);
}

/**
 * Get a country division by abbreviation
 * @param {string} abbreviation
 * @returns {Object|null}
 */
export function getDivisionByAbbreviation(abbreviation) {
  const upperAbbr = abbreviation.toUpperCase();
  for (const division of Object.values(CountryDivisionCode)) {
    if (division.abbreviation === upperAbbr) {
      return division;
    }
  }
  return CountryDivisionCode.UNKNOWN;
}

/**
 * Get a country division by name
 * @param {string} name
 * @returns {Object|null}
 */
export function getDivisionByName(name) {
  const lowerName = name.toLowerCase();
  for (const division of Object.values(CountryDivisionCode)) {
    if (division.name.toLowerCase() === lowerName) {
      return division;
    }
  }
  return CountryDivisionCode.UNKNOWN;
}

/**
 * Get divisions by country code
 * @param {string} countryCode
 * @returns {Array}
 */
export function getDivisionsByCountry(countryCode) {
  return Object.values(CountryDivisionCode).filter(
    division => division.countryCode === countryCode
  );
}
