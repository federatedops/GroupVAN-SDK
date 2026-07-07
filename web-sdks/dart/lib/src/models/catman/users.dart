/// Catman users models: account search results and user detail.
library;

/// A single account returned by the account search.
class UserAccount {
  final int userId;
  final String? uuid;
  final String username;
  final String? company;
  final String? lastActivity;
  final bool isApproved;
  final String fullName;
  final String? account;

  /// Display name of the user type (e.g. "Installer").
  final String userType;
  final String? memberNumber;
  final String employeeNo;

  const UserAccount({
    required this.userId,
    this.uuid,
    required this.username,
    this.company,
    this.lastActivity,
    required this.isApproved,
    required this.fullName,
    this.account,
    required this.userType,
    this.memberNumber,
    required this.employeeNo,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
    userId: json['user_id'] as int,
    uuid: json['uuid'] as String?,
    username: json['username'] as String,
    company: json['company'] as String?,
    lastActivity: json['last_activity'] as String?,
    isApproved: (json['is_approved'] as int? ?? 0) != 0,
    fullName: json['full_name'] as String? ?? '',
    account: json['account'] as String?,
    userType: json['user_type'] as String? ?? '',
    memberNumber: json['member_number'] as String?,
    employeeNo: json['EmployeeNo'] as String? ?? '',
  );
}

/// Location assignment sent when adding a location to a user.
///
/// The primary location (sort order 1) must have [canOrder] set to true.
class UserLocationInput {
  final String id;
  final bool canOrder;
  final int sortOrder;

  const UserLocationInput({
    required this.id,
    required this.canOrder,
    required this.sortOrder,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'can_order': canOrder,
    'sort_order': sortOrder,
  };
}

/// Full detail for a single user.
class UserDetail {
  final int userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? companyName;
  final String? address;
  final String? city;
  final String? state;
  final String? zip;
  final String? accountId;
  final String? memberNumber;
  final String? terminalPin;
  final int? userTypeId;
  final bool identifixAccess;
  final bool identifixBlocked;
  final String? identifixMask;
  final String? dropoffInstructions;

  /// Display name of the user type (e.g. "Installer").
  final String userType;
  final bool isApproved;
  final bool isLockedOut;
  final String? lastSignedIn;
  final String? lastActivity;
  final String? passwordChanged;
  final String employeeId;
  final String catalogRegion;
  final String laborRate;
  final String memberName;
  final bool canExportBuyersGuide;
  final bool showCartButtonWhenNoPrice;
  final bool hideMexicanVehicle;
  final bool hideCanadianVehicle;
  final bool requireDeliveryExpectation;

  const UserDetail({
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.companyName,
    this.address,
    this.city,
    this.state,
    this.zip,
    this.accountId,
    this.memberNumber,
    this.terminalPin,
    this.userTypeId,
    required this.identifixAccess,
    required this.identifixBlocked,
    this.identifixMask,
    this.dropoffInstructions,
    required this.userType,
    required this.isApproved,
    required this.isLockedOut,
    this.lastSignedIn,
    this.lastActivity,
    this.passwordChanged,
    required this.employeeId,
    required this.catalogRegion,
    required this.laborRate,
    required this.memberName,
    required this.canExportBuyersGuide,
    required this.showCartButtonWhenNoPrice,
    required this.hideMexicanVehicle,
    required this.hideCanadianVehicle,
    required this.requireDeliveryExpectation,
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) => UserDetail(
    userId: json['user_id'] as int,
    username: json['username'] as String,
    firstName: json['first_name'] as String?,
    lastName: json['last_name'] as String?,
    email: json['email'] as String?,
    phoneNumber: json['phone_number'] as String?,
    companyName: json['company_name'] as String?,
    address: json['address'] as String?,
    city: json['city'] as String?,
    state: json['state'] as String?,
    zip: json['zip'] as String?,
    accountId: json['account_id'] as String?,
    memberNumber: json['member_number'] as String?,
    terminalPin: json['terminal_pin'] as String?,
    userTypeId: json['user_type_id'] as int?,
    identifixAccess: _asBool(json['identifix_access']),
    identifixBlocked: _asBool(json['identifix_blocked']),
    identifixMask: json['identifix_mask'] as String?,
    dropoffInstructions: json['dropoff_instructions'] as String?,
    userType: json['user_type'] as String? ?? '',
    isApproved: _asBool(json['is_approved']),
    isLockedOut: _asBool(json['is_locked_out']),
    lastSignedIn: json['last_signed_in'] as String?,
    lastActivity: json['last_activity'] as String?,
    passwordChanged: json['password_changed'] as String?,
    employeeId: json['employee_id'] as String? ?? '',
    catalogRegion: json['catalog_region'] as String? ?? '',
    laborRate: json['labor_rate'] as String? ?? '0',
    memberName: json['member_name'] as String? ?? '',
    canExportBuyersGuide: _asBool(json['can_export_buyers_guide']),
    showCartButtonWhenNoPrice: _asBool(json['show_cart_button_when_no_price']),
    hideMexicanVehicle: _asBool(json['hide_mexican_vehicle']),
    hideCanadianVehicle: _asBool(json['hide_canadian_vehicle']),
    requireDeliveryExpectation: _asBool(json['require_delivery_expectation']),
  );
}

/// The API returns booleans as ints (0/1) or numeric strings ('0'/'1')
/// depending on the column; normalize both.
bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value.isNotEmpty && value != '0';
  return false;
}
