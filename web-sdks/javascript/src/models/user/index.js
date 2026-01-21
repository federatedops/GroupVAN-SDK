/**
 * User models for the GroupVAN API
 */

/**
 * Location details
 */
export class LocationDetails {
  constructor({
    id,
    name,
    address,
    city,
    state,
    zip,
    phone,
    email,
    fax,
    hoursOfOperation,
  }) {
    this.id = id;
    this.name = name;
    this.address = address;
    this.city = city;
    this.state = state;
    this.zip = zip;
    this.phone = phone;
    this.email = email;
    this.fax = fax;
    this.hoursOfOperation = hoursOfOperation;
  }

  static fromJson(json) {
    return new LocationDetails({
      id: json.id,
      name: json.name,
      address: json.address,
      city: json.city,
      state: json.state,
      zip: json.zip,
      phone: json.phone,
      email: json.email,
      fax: json.fax,
      hoursOfOperation: json.hours_of_operation,
    });
  }

  toJson() {
    return {
      id: this.id,
      name: this.name,
      address: this.address,
      city: this.city,
      state: this.state,
      zip: this.zip,
      phone: this.phone,
      email: this.email,
      fax: this.fax,
      hours_of_operation: this.hoursOfOperation,
    };
  }
}
