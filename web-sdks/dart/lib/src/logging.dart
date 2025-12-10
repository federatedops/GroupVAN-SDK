import 'dart:developer' as developer;
import 'package:logging/logging.dart';

/// Centralized logging configuration for the GroupVAN SDK
class GroupVanLogger {
  static bool _initialized = false;

  /// The main SDK logger instance
  static final Logger sdk = Logger('GroupVAN.SDK');

  /// Logger for API client operations
  static final Logger apiClient = Logger('GroupVAN.SDK.ApiClient');

  /// Logger for vehicle operations
  static final Logger vehicles = Logger('GroupVAN.SDK.Vehicles');

  /// Logger for catalog operations
  static final Logger catalogs = Logger('GroupVAN.SDK.Catalogs');

  /// Logger for cart operations
  static final Logger cart = Logger('GroupVAN.SDK.Cart');

  /// Logger for authentication operations
  static final Logger auth = Logger('GroupVAN.SDK.Auth');

  /// Logger for reports operations
  static final Logger reports = Logger('GroupVAN.SDK.Reports');

  /// Logger for admin operations (impersonation, 2FA)
  static final Logger admin = Logger('GroupVAN.SDK.Admin');

  /// Initialize the logging system
  ///
  /// Call this once during SDK initialization to configure logging.
  /// By default, logs WARNING level and above to the console.
  ///
  /// Parameters:
  /// - [level]: The minimum log level to output (defaults to WARNING)
  /// - [enableConsoleOutput]: Whether to log to console (defaults to true)
  static void initialize({
    Level level = Level.WARNING,
    bool enableConsoleOutput = true,
  }) {
    if (_initialized) return;

    // Set the root logger level
    Logger.root.level = level;

    if (enableConsoleOutput) {
      Logger.root.onRecord.listen((record) {
        // Use dart:developer log for better integration with DevTools
        developer.log(
          record.message,
          time: record.time,
          level: _mapLogLevel(record.level),
          name: record.loggerName,
          error: record.error,
          stackTrace: record.stackTrace,
        );
      });
    }

    _initialized = true;
    sdk.info('GroupVAN SDK logging initialized at level: ${level.name}');
  }

  /// Map logging package levels to dart:developer levels
  static int _mapLogLevel(Level level) {
    if (level >= Level.SEVERE) return 1000;
    if (level >= Level.WARNING) return 900;
    if (level >= Level.INFO) return 800;
    if (level >= Level.CONFIG) return 700;
    if (level >= Level.FINE) return 500;
    if (level >= Level.FINER) return 400;
    if (level >= Level.FINEST) return 300;
    return 0;
  }

  /// Enable debug logging (shows all log levels)
  static void enableDebugLogging() {
    Logger.root.level = Level.ALL;
    sdk.info('Debug logging enabled - showing all log levels');
  }

  /// Disable all logging
  static void disableLogging() {
    Logger.root.level = Level.OFF;
  }

  /// Set custom log level
  static void setLevel(Level level) {
    Logger.root.level = level;
    sdk.info('Log level set to: ${level.name}');
  }
}
