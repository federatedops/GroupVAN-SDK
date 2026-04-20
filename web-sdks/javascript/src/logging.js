/**
 * Centralized logging configuration for the GroupVAN SDK
 */

/**
 * Log levels
 * @enum {number}
 */
export const LogLevel = {
  OFF: 0,
  SEVERE: 100,
  WARNING: 200,
  INFO: 300,
  CONFIG: 400,
  FINE: 500,
  FINER: 600,
  FINEST: 700,
  ALL: 1000,
};

/**
 * Simple logger implementation
 */
class Logger {
  /**
   * @param {string} name - Logger name
   * @param {function} [outputFn] - Output function (defaults to console)
   */
  constructor(name, outputFn = null) {
    this.name = name;
    this._outputFn = outputFn;
    this._level = LogLevel.WARNING;
  }

  /**
   * Set the log level
   * @param {number} level
   */
  setLevel(level) {
    this._level = level;
  }

  /**
   * Get the current log level
   * @returns {number}
   */
  get level() {
    return this._level;
  }

  /**
   * Log a message at the given level
   * @param {number} level
   * @param {string} message
   * @param {...*} args
   */
  _log(level, message, ...args) {
    if (level > this._level) return;

    const timestamp = new Date().toISOString();
    const levelName = Object.entries(LogLevel).find(([_, v]) => v === level)?.[0] || 'UNKNOWN';
    const formattedMessage = `[${timestamp}] [${levelName}] [${this.name}] ${message}`;

    if (this._outputFn) {
      this._outputFn(formattedMessage, ...args);
    } else {
      // Use appropriate console method based on level
      if (level <= LogLevel.SEVERE) {
        console.error(formattedMessage, ...args);
      } else if (level <= LogLevel.WARNING) {
        console.warn(formattedMessage, ...args);
      } else if (level <= LogLevel.INFO) {
        console.info(formattedMessage, ...args);
      } else {
        console.log(formattedMessage, ...args);
      }
    }
  }

  severe(message, ...args) {
    this._log(LogLevel.SEVERE, message, ...args);
  }

  warning(message, ...args) {
    this._log(LogLevel.WARNING, message, ...args);
  }

  info(message, ...args) {
    this._log(LogLevel.INFO, message, ...args);
  }

  config(message, ...args) {
    this._log(LogLevel.CONFIG, message, ...args);
  }

  fine(message, ...args) {
    this._log(LogLevel.FINE, message, ...args);
  }

  finer(message, ...args) {
    this._log(LogLevel.FINER, message, ...args);
  }

  finest(message, ...args) {
    this._log(LogLevel.FINEST, message, ...args);
  }
}

/**
 * Centralized logging configuration for the GroupVAN SDK
 */
class GroupVanLoggerClass {
  constructor() {
    this._initialized = false;
    this._level = LogLevel.WARNING;
    this._enableConsoleOutput = true;

    // Create logger instances
    this.sdk = new Logger('GroupVAN.SDK');
    this.apiClient = new Logger('GroupVAN.SDK.ApiClient');
    this.vehicles = new Logger('GroupVAN.SDK.Vehicles');
    this.catalogs = new Logger('GroupVAN.SDK.Catalogs');
    this.cart = new Logger('GroupVAN.SDK.Cart');
    this.auth = new Logger('GroupVAN.SDK.Auth');
    this.reports = new Logger('GroupVAN.SDK.Reports');
    this.search = new Logger('GroupVAN.SDK.Search');
    this.user = new Logger('GroupVAN.SDK.User');

    this._loggers = [
      this.sdk,
      this.apiClient,
      this.vehicles,
      this.catalogs,
      this.cart,
      this.auth,
      this.reports,
      this.search,
      this.user,
    ];
  }

  /**
   * Initialize the logging system
   * @param {Object} [options]
   * @param {number} [options.level=LogLevel.WARNING] - The minimum log level to output
   * @param {boolean} [options.enableConsoleOutput=true] - Whether to log to console
   */
  initialize({ level = LogLevel.WARNING, enableConsoleOutput = true } = {}) {
    if (this._initialized) return;

    this._level = level;
    this._enableConsoleOutput = enableConsoleOutput;

    for (const logger of this._loggers) {
      logger.setLevel(level);
    }

    this._initialized = true;
    this.sdk.info(`GroupVAN SDK logging initialized at level: ${this._getLevelName(level)}`);
  }

  /**
   * Get the name of a log level
   * @param {number} level
   * @returns {string}
   */
  _getLevelName(level) {
    return Object.entries(LogLevel).find(([_, v]) => v === level)?.[0] || 'UNKNOWN';
  }

  /**
   * Enable debug logging (shows all log levels)
   */
  enableDebugLogging() {
    this.setLevel(LogLevel.ALL);
    this.sdk.info('Debug logging enabled - showing all log levels');
  }

  /**
   * Disable all logging
   */
  disableLogging() {
    this.setLevel(LogLevel.OFF);
  }

  /**
   * Set custom log level
   * @param {number} level
   */
  setLevel(level) {
    this._level = level;
    for (const logger of this._loggers) {
      logger.setLevel(level);
    }
    this.sdk.info(`Log level set to: ${this._getLevelName(level)}`);
  }
}

// Export singleton instance
export const GroupVanLogger = new GroupVanLoggerClass();
