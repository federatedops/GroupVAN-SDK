/**
 * Input validation system for GroupVAN SDK
 *
 * Provides comprehensive validation for API inputs, following best practices
 * for defensive programming and type safety.
 */

import { ValidationException, ValidationError } from './exceptions.js';

/**
 * Base validator class
 * @template T
 */
export class Validator {
  /**
   * Validates a value and returns validation errors
   * @param {T} value - The value to validate
   * @param {string} fieldName - The name of the field being validated
   * @returns {ValidationError[]} Array of validation errors
   */
  validate(value, fieldName) {
    throw new Error('validate() must be implemented by subclass');
  }

  /**
   * Validates and throws ValidationException if errors exist
   * @param {T} value - The value to validate
   * @param {string} fieldName - The name of the field being validated
   * @throws {ValidationException} If validation fails
   */
  validateAndThrow(value, fieldName) {
    const errors = this.validate(value, fieldName);
    if (errors.length > 0) {
      throw new ValidationException(
        `Validation failed for ${fieldName}`,
        { errors }
      );
    }
  }
}

/**
 * String validation
 */
export class StringValidator extends Validator {
  /**
   * @param {Object} [options]
   * @param {number} [options.minLength] - Minimum string length
   * @param {number} [options.maxLength] - Maximum string length
   * @param {RegExp} [options.pattern] - Regular expression pattern to match
   * @param {boolean} [options.required=true] - Whether the field is required
   * @param {string[]} [options.allowedValues] - List of allowed values
   */
  constructor({ minLength = null, maxLength = null, pattern = null, required = true, allowedValues = null } = {}) {
    super();
    this.minLength = minLength;
    this.maxLength = maxLength;
    this.pattern = pattern;
    this.required = required;
    this.allowedValues = allowedValues;
  }

  validate(value, fieldName) {
    const errors = [];

    // Required check
    if (this.required && (value === null || value === undefined || value === '')) {
      errors.push(new ValidationError({
        field: fieldName,
        message: 'Field is required',
        value,
        rule: 'required',
      }));
      return errors; // Don't continue if required and empty
    }

    if (value === null || value === undefined || value === '') {
      return errors; // Optional field that's empty
    }

    // Length checks
    if (this.minLength !== null && value.length < this.minLength) {
      errors.push(new ValidationError({
        field: fieldName,
        message: `Must be at least ${this.minLength} characters`,
        value,
        rule: 'minLength',
      }));
    }

    if (this.maxLength !== null && value.length > this.maxLength) {
      errors.push(new ValidationError({
        field: fieldName,
        message: `Must be at most ${this.maxLength} characters`,
        value,
        rule: 'maxLength',
      }));
    }

    // Pattern check
    if (this.pattern !== null && !this.pattern.test(value)) {
      errors.push(new ValidationError({
        field: fieldName,
        message: 'Does not match required format',
        value,
        rule: 'pattern',
      }));
    }

    // Allowed values check
    if (this.allowedValues !== null && !this.allowedValues.includes(value)) {
      errors.push(new ValidationError({
        field: fieldName,
        message: `Must be one of: ${this.allowedValues.join(', ')}`,
        value,
        rule: 'allowedValues',
      }));
    }

    return errors;
  }
}

/**
 * Integer validation
 */
export class IntValidator extends Validator {
  /**
   * @param {Object} [options]
   * @param {number} [options.min] - Minimum value
   * @param {number} [options.max] - Maximum value
   * @param {boolean} [options.required=true] - Whether the field is required
   * @param {number[]} [options.allowedValues] - List of allowed values
   */
  constructor({ min = null, max = null, required = true, allowedValues = null } = {}) {
    super();
    this.min = min;
    this.max = max;
    this.required = required;
    this.allowedValues = allowedValues;
  }

  validate(value, fieldName) {
    const errors = [];

    // Required check
    if (this.required && (value === null || value === undefined)) {
      errors.push(new ValidationError({
        field: fieldName,
        message: 'Field is required',
        value,
        rule: 'required',
      }));
      return errors;
    }

    if (value === null || value === undefined) {
      return errors; // Optional field that's null
    }

    // Type check
    if (typeof value !== 'number' || !Number.isInteger(value)) {
      errors.push(new ValidationError({
        field: fieldName,
        message: 'Must be an integer',
        value,
        rule: 'type',
      }));
      return errors;
    }

    // Range checks
    if (this.min !== null && value < this.min) {
      errors.push(new ValidationError({
        field: fieldName,
        message: `Must be at least ${this.min}`,
        value,
        rule: 'min',
      }));
    }

    if (this.max !== null && value > this.max) {
      errors.push(new ValidationError({
        field: fieldName,
        message: `Must be at most ${this.max}`,
        value,
        rule: 'max',
      }));
    }

    // Allowed values check
    if (this.allowedValues !== null && !this.allowedValues.includes(value)) {
      errors.push(new ValidationError({
        field: fieldName,
        message: `Must be one of: ${this.allowedValues.join(', ')}`,
        value,
        rule: 'allowedValues',
      }));
    }

    return errors;
  }
}

/**
 * List validation
 * @template T
 */
export class ListValidator extends Validator {
  /**
   * @param {Object} [options]
   * @param {number} [options.minLength] - Minimum list length
   * @param {number} [options.maxLength] - Maximum list length
   * @param {boolean} [options.required=true] - Whether the field is required
   * @param {Validator} [options.itemValidator] - Validator for individual items
   */
  constructor({ minLength = null, maxLength = null, required = true, itemValidator = null } = {}) {
    super();
    this.minLength = minLength;
    this.maxLength = maxLength;
    this.required = required;
    this.itemValidator = itemValidator;
  }

  validate(value, fieldName) {
    const errors = [];

    // Required check
    if (this.required && (!Array.isArray(value) || value.length === 0)) {
      errors.push(new ValidationError({
        field: fieldName,
        message: 'Field is required',
        value,
        rule: 'required',
      }));
      return errors;
    }

    if (!Array.isArray(value) || value.length === 0) {
      return errors; // Optional field that's empty
    }

    // Length checks
    if (this.minLength !== null && value.length < this.minLength) {
      errors.push(new ValidationError({
        field: fieldName,
        message: `Must contain at least ${this.minLength} items`,
        value,
        rule: 'minLength',
      }));
    }

    if (this.maxLength !== null && value.length > this.maxLength) {
      errors.push(new ValidationError({
        field: fieldName,
        message: `Must contain at most ${this.maxLength} items`,
        value,
        rule: 'maxLength',
      }));
    }

    // Validate individual items
    if (this.itemValidator !== null) {
      for (let i = 0; i < value.length; i++) {
        const itemErrors = this.itemValidator.validate(value[i], `${fieldName}[${i}]`);
        errors.push(...itemErrors);
      }
    }

    return errors;
  }
}

/**
 * Composite validator for validating multiple fields
 */
export class ObjectValidator {
  constructor() {
    this._validators = new Map();
  }

  /**
   * Add a validator for a field
   * @param {string} fieldName - Name of the field
   * @param {Validator} validator - Validator instance
   */
  addField(fieldName, validator) {
    this._validators.set(fieldName, validator);
  }

  /**
   * Validate all fields in an object
   * @param {Object} data - The data object to validate
   * @returns {ValidationError[]} Array of validation errors
   */
  validate(data) {
    const errors = [];

    for (const [fieldName, validator] of this._validators) {
      const value = data[fieldName];
      const fieldErrors = validator.validate(value, fieldName);
      errors.push(...fieldErrors);
    }

    return errors;
  }

  /**
   * Validate and throw if errors exist
   * @param {Object} data - The data object to validate
   * @throws {ValidationException} If validation fails
   */
  validateAndThrow(data) {
    const errors = this.validate(data);
    if (errors.length > 0) {
      throw new ValidationException(
        'Validation failed for object',
        { errors }
      );
    }
  }
}

/**
 * Common validation patterns
 */
export const ValidationPatterns = {
  /** VIN number pattern (17 alphanumeric characters, no I, O, Q) */
  vin: /^[A-HJ-NPR-Z0-9]{17}$/,

  /** US state abbreviation */
  usState: /^[A-Z]{2}$/,

  /** License plate pattern (1-8 alphanumeric characters) */
  licensePlate: /^[A-Z0-9]{1,8}$/i,

  /** Email pattern */
  email: /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/,

  /** SKU pattern */
  sku: /^[A-Z0-9-]{3,20}$/i,

  /** Manufacturer code pattern */
  manufacturerCode: /^[A-Z0-9]{2,10}$/,
};

/**
 * Pre-built validators for common GroupVAN data types
 */
export const GroupVanValidators = {
  /** VIN validator */
  vin: () => new StringValidator({
    minLength: 17,
    maxLength: 17,
    pattern: ValidationPatterns.vin,
  }),

  /** License plate validator */
  licensePlate: () => new StringValidator({
    minLength: 1,
    maxLength: 8,
    pattern: ValidationPatterns.licensePlate,
  }),

  /** US state validator */
  usState: () => new StringValidator({
    minLength: 2,
    maxLength: 2,
    pattern: ValidationPatterns.usState,
  }),

  /** Vehicle year validator */
  vehicleYear: () => new IntValidator({
    min: 1900,
    max: new Date().getFullYear() + 2,
  }),

  /** Pagination offset validator */
  paginationOffset: () => new IntValidator({
    min: 0,
    required: false,
  }),

  /** Pagination limit validator */
  paginationLimit: () => new IntValidator({
    min: 1,
    max: 100,
    required: false,
  }),

  /** Search query validator */
  searchQuery: () => new StringValidator({
    minLength: 1,
    maxLength: 100,
  }),

  /** SKU validator */
  sku: () => new StringValidator({
    minLength: 3,
    maxLength: 20,
    pattern: ValidationPatterns.sku,
  }),

  /** Application IDs validator */
  applicationIds: () => new ListValidator({
    minLength: 1,
    maxLength: 50,
    itemValidator: new IntValidator({ min: 1 }),
  }),

  /** Part types validator for product requests */
  partTypes: () => new ListValidator({
    minLength: 1,
    maxLength: 20,
  }),
};
