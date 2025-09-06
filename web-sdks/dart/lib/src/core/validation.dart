/// Input validation system for GroupVAN SDK
/// 
/// Provides comprehensive validation for API inputs, following Dart best practices
/// for defensive programming and type safety.
library validation;

import 'exceptions.dart';

/// Base validator class
abstract class Validator<T> {
  /// Validates a value and returns validation errors
  List<ValidationError> validate(T? value, String fieldName);

  /// Validates and throws ValidationException if errors exist
  void validateAndThrow(T? value, String fieldName) {
    final errors = validate(value, fieldName);
    if (errors.isNotEmpty) {
      throw ValidationException(
        'Validation failed for $fieldName',
        errors: errors,
      );
    }
  }
}

/// String validation
class StringValidator extends Validator<String> {
  final int? minLength;
  final int? maxLength;
  final RegExp? pattern;
  final bool required;
  final List<String>? allowedValues;

  StringValidator({
    this.minLength,
    this.maxLength,
    this.pattern,
    this.required = true,
    this.allowedValues,
  });

  @override
  List<ValidationError> validate(String? value, String fieldName) {
    final errors = <ValidationError>[];

    // Required check
    if (required && (value == null || value.isEmpty)) {
      errors.add(ValidationError(
        field: fieldName,
        message: 'Field is required',
        value: value,
        rule: 'required',
      ));
      return errors; // Don't continue if required and empty
    }

    if (value == null || value.isEmpty) {
      return errors; // Optional field that's empty
    }

    // Length checks
    if (minLength != null && value.length < minLength!) {
      errors.add(ValidationError(
        field: fieldName,
        message: 'Must be at least $minLength characters',
        value: value,
        rule: 'minLength',
      ));
    }

    if (maxLength != null && value.length > maxLength!) {
      errors.add(ValidationError(
        field: fieldName,
        message: 'Must be at most $maxLength characters',
        value: value,
        rule: 'maxLength',
      ));
    }

    // Pattern check
    if (pattern != null && !pattern!.hasMatch(value)) {
      errors.add(ValidationError(
        field: fieldName,
        message: 'Does not match required format',
        value: value,
        rule: 'pattern',
      ));
    }

    // Allowed values check
    if (allowedValues != null && !allowedValues!.contains(value)) {
      errors.add(ValidationError(
        field: fieldName,
        message: 'Must be one of: ${allowedValues!.join(', ')}',
        value: value,
        rule: 'allowedValues',
      ));
    }

    return errors;
  }
}

/// Integer validation
class IntValidator extends Validator<int> {
  final int? min;
  final int? max;
  final bool required;
  final List<int>? allowedValues;

  IntValidator({
    this.min,
    this.max,
    this.required = true,
    this.allowedValues,
  });

  @override
  List<ValidationError> validate(int? value, String fieldName) {
    final errors = <ValidationError>[];

    // Required check
    if (required && value == null) {
      errors.add(ValidationError(
        field: fieldName,
        message: 'Field is required',
        value: value,
        rule: 'required',
      ));
      return errors;
    }

    if (value == null) {
      return errors; // Optional field that's null
    }

    // Range checks
    if (min != null && value < min!) {
      errors.add(ValidationError(
        field: fieldName,
        message: 'Must be at least $min',
        value: value,
        rule: 'min',
      ));
    }

    if (max != null && value > max!) {
      errors.add(ValidationError(
        field: fieldName,
        message: 'Must be at most $max',
        value: value,
        rule: 'max',
      ));
    }

    // Allowed values check
    if (allowedValues != null && !allowedValues!.contains(value)) {
      errors.add(ValidationError(
        field: fieldName,
        message: 'Must be one of: ${allowedValues!.join(', ')}',
        value: value,
        rule: 'allowedValues',
      ));
    }

    return errors;
  }
}

/// List validation
class ListValidator<T> extends Validator<List<T>> {
  final int? minLength;
  final int? maxLength;
  final bool required;
  final Validator<T>? itemValidator;

  ListValidator({
    this.minLength,
    this.maxLength,
    this.required = true,
    this.itemValidator,
  });

  @override
  List<ValidationError> validate(List<T>? value, String fieldName) {
    final errors = <ValidationError>[];

    // Required check
    if (required && (value == null || value.isEmpty)) {
      errors.add(ValidationError(
        field: fieldName,
        message: 'Field is required',
        value: value,
        rule: 'required',
      ));
      return errors;
    }

    if (value == null || value.isEmpty) {
      return errors; // Optional field that's empty
    }

    // Length checks
    if (minLength != null && value.length < minLength!) {
      errors.add(ValidationError(
        field: fieldName,
        message: 'Must contain at least $minLength items',
        value: value,
        rule: 'minLength',
      ));
    }

    if (maxLength != null && value.length > maxLength!) {
      errors.add(ValidationError(
        field: fieldName,
        message: 'Must contain at most $maxLength items',
        value: value,
        rule: 'maxLength',
      ));
    }

    // Validate individual items
    if (itemValidator != null) {
      for (int i = 0; i < value.length; i++) {
        final itemErrors = itemValidator!.validate(value[i], '$fieldName[$i]');
        errors.addAll(itemErrors);
      }
    }

    return errors;
  }
}

/// Composite validator for validating multiple fields
class ObjectValidator {
  final Map<String, Validator> _validators = {};

  /// Add a validator for a field
  void addField<T>(String fieldName, Validator<T> validator) {
    _validators[fieldName] = validator;
  }

  /// Validate all fields in a map
  List<ValidationError> validate(Map<String, dynamic> data) {
    final errors = <ValidationError>[];

    for (final entry in _validators.entries) {
      final fieldName = entry.key;
      final validator = entry.value;
      final value = data[fieldName];

      final fieldErrors = validator.validate(value, fieldName);
      errors.addAll(fieldErrors);
    }

    return errors;
  }

  /// Validate and throw if errors exist
  void validateAndThrow(Map<String, dynamic> data) {
    final errors = validate(data);
    if (errors.isNotEmpty) {
      throw ValidationException(
        'Validation failed for object',
        errors: errors,
      );
    }
  }
}

/// Common validation patterns
class ValidationPatterns {
  /// VIN number pattern (17 alphanumeric characters, no I, O, Q)
  static final RegExp vin = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');

  /// US state abbreviation
  static final RegExp usState = RegExp(r'^[A-Z]{2}$');

  /// License plate pattern (1-8 alphanumeric characters)
  static final RegExp licensePlate = RegExp(r'^[A-Z0-9]{1,8}$');

  /// Email pattern
  static final RegExp email = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  /// SKU pattern
  static final RegExp sku = RegExp(r'^[A-Z0-9-]{3,20}$');

  /// Manufacturer code pattern
  static final RegExp manufacturerCode = RegExp(r'^[A-Z0-9]{2,10}$');
}

/// Pre-built validators for common GroupVAN data types
class GroupVanValidators {
  /// VIN validator
  static StringValidator vin() => StringValidator(
        minLength: 17,
        maxLength: 17,
        pattern: ValidationPatterns.vin,
      );

  /// License plate validator
  static StringValidator licensePlate() => StringValidator(
        minLength: 1,
        maxLength: 8,
        pattern: ValidationPatterns.licensePlate,
      );

  /// US state validator
  static StringValidator usState() => StringValidator(
        minLength: 2,
        maxLength: 2,
        pattern: ValidationPatterns.usState,
      );

  /// Vehicle year validator
  static IntValidator vehicleYear() => IntValidator(
        min: 1900,
        max: DateTime.now().year + 2,
      );

  /// Pagination offset validator
  static IntValidator paginationOffset() => IntValidator(
        min: 0,
        required: false,
      );

  /// Pagination limit validator
  static IntValidator paginationLimit() => IntValidator(
        min: 1,
        max: 100,
        required: false,
      );

  /// Search query validator
  static StringValidator searchQuery() => StringValidator(
        minLength: 1,
        maxLength: 100,
      );

  /// SKU validator
  static StringValidator sku() => StringValidator(
        minLength: 3,
        maxLength: 20,
        pattern: ValidationPatterns.sku,
      );

  /// Session ID validator
  static StringValidator sessionId() => StringValidator(
        minLength: 10,
        maxLength: 50,
      );

  /// Application IDs validator
  static ListValidator<int> applicationIds() => ListValidator<int>(
        minLength: 1,
        maxLength: 50,
        itemValidator: IntValidator(min: 1),
      );

  /// Part types validator for product requests
  static ListValidator<Map<String, dynamic>> partTypes() => ListValidator<Map<String, dynamic>>(
        minLength: 1,
        maxLength: 20,
      );
}