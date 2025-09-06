# GroupVAN SDK Logging Guide

The GroupVAN Web SDK uses the official Dart [`logging`](https://pub.dev/packages/logging) package to provide comprehensive, configurable logging for debugging and monitoring.

## Quick Start

```dart
import 'package:groupvan/groupvan.dart';
import 'package:logging/logging.dart';

void main() async {
  // Initialize logging (call once at app startup)
  GroupVanLogger.initialize(
    level: Level.INFO,
    enableConsoleOutput: true,
  );
  
  // Your SDK usage...
}
```

## Log Levels

The SDK uses standard logging levels from the `logging` package:

| Level | Description | When to Use |
|-------|-------------|-------------|
| `FINEST` | Very detailed debug info | Development debugging |
| `FINER` | Detailed debug info | Development debugging |
| `FINE` | Debug info, HTTP requests/responses | Development |
| `CONFIG` | Configuration info | Setup debugging |
| `INFO` | General informational messages | Normal operation |
| `WARNING` | Warning conditions | Non-critical issues |
| `SEVERE` | Error conditions | Critical errors |
| `SHOUT` | Critical errors | System failures |

## SDK Logger Categories

The GroupVAN SDK provides specialized loggers for different components:

```dart
// Main SDK logger
GroupVanLogger.sdk.info('SDK initialized');

// API client operations (HTTP requests/responses)
GroupVanLogger.apiClient.fine('GET request: /v3/vehicles/groups');

// Vehicle operations
GroupVanLogger.vehicles.info('Searching vehicles: "Honda Civic"');

// Catalog operations  
GroupVanLogger.catalogs.info('Fetching product listings');

// Authentication operations
GroupVanLogger.auth.warning('Token refresh needed');
```

## Configuration Options

### Basic Configuration

```dart
// Show WARNING and above (default for production)
GroupVanLogger.initialize(level: Level.WARNING);

// Show INFO and above (good for development)
GroupVanLogger.initialize(level: Level.INFO);

// Show all logs (debug mode)
GroupVanLogger.initialize(level: Level.ALL);
```

### Advanced Configuration

```dart
// Disable console output (for custom handlers)
GroupVanLogger.initialize(
  level: Level.INFO,
  enableConsoleOutput: false,
);

// Enable debug logging after initialization
GroupVanLogger.enableDebugLogging();

// Change log level dynamically
GroupVanLogger.setLevel(Level.FINE);

// Disable all logging
GroupVanLogger.disableLogging();
```

## What Gets Logged

### API Client (`GroupVanLogger.apiClient`)
- **FINE**: HTTP request/response details, session IDs
- **WARNING**: Failed API requests (non-200 status codes)
- **SEVERE**: Network errors, connection failures

### Vehicles (`GroupVanLogger.vehicles`)
- **INFO**: Vehicle search queries, important operations
- **FINE**: Request/response details

### Catalogs (`GroupVanLogger.catalogs`)
- **INFO**: Catalog operations, product searches
- **FINE**: Request/response details

### Main SDK (`GroupVanLogger.sdk`)
- **INFO**: SDK lifecycle events, major operations
- **WARNING**: Configuration issues
- **SEVERE**: SDK initialization failures

## Custom Log Handlers

You can add custom log handlers to integrate with your app's logging system:

```dart
import 'dart:developer' as developer;
import 'package:logging/logging.dart';

void setupCustomLogging() {
  // Initialize SDK logging without console output
  GroupVanLogger.initialize(
    level: Level.INFO,
    enableConsoleOutput: false,
  );
  
  // Add custom handler for your logging system
  Logger.root.onRecord.listen((record) {
    // Send to your logging service
    MyLoggingService.log(
      level: record.level.name,
      message: record.message,
      logger: record.loggerName,
      timestamp: record.time,
      error: record.error,
      stackTrace: record.stackTrace,
    );
    
    // Also log to developer console
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
```

## Production Recommendations

### For Production Apps
```dart
// Only log warnings and errors
GroupVanLogger.initialize(level: Level.WARNING);
```

### For Development
```dart
// Show informational logs and API details
GroupVanLogger.initialize(level: Level.INFO);
```

### For Debugging
```dart
// Show all SDK activity
GroupVanLogger.enableDebugLogging();
```

## Integration with Flutter DevTools

The SDK uses `dart:developer.log()` internally, which integrates seamlessly with Flutter DevTools:

1. Open Flutter DevTools in your browser
2. Go to the **Logging** tab
3. Filter by logger name (e.g., "GroupVAN.SDK.ApiClient")
4. View structured logs with timestamps and stack traces

## Example Log Output

```
[INFO] GroupVAN.SDK: SDK initialized at level: INFO
[INFO] GroupVAN.SDK.Vehicles: Searching vehicles: "Honda Civic" (group: 200)
[FINE] GroupVAN.SDK.ApiClient: GET request: https://api.groupvan.com/v3/vehicles/search?query=Honda+Civic&page=1&group_id=200
[FINE] GroupVAN.SDK.ApiClient: GET (with session) response: 200 for v3/vehicles/search
[FINE] GroupVAN.SDK.ApiClient: Session ID received: abc123-def456-ghi789 for v3/vehicles/search
[INFO] GroupVAN.SDK: Search returned 15 results
```

## Troubleshooting

### No Logs Appearing
- Ensure you called `GroupVanLogger.initialize()`
- Check your log level - you may need `Level.ALL` for debug logs
- Verify `enableConsoleOutput: true` (default)

### Too Many Logs  
- Increase the log level: `GroupVanLogger.setLevel(Level.WARNING)`
- Filter by logger name in DevTools

### Performance Impact
- The SDK uses lazy evaluation for log messages
- FINE/FINER/FINEST logs are only formatted if the level is enabled
- Minimal overhead in production with WARNING+ levels

## Best Practices

1. **Initialize Early**: Call `GroupVanLogger.initialize()` before any SDK usage
2. **Use Appropriate Levels**: INFO for important events, FINE for debugging
3. **Production Safety**: Use WARNING+ levels in production
4. **Custom Handlers**: Integrate with your app's logging infrastructure
5. **DevTools Integration**: Leverage Flutter DevTools for development debugging

For more information about the underlying logging package, see the [official documentation](https://pub.dev/packages/logging).