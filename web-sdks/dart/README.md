# GroupVAN Dart SDK

**Elite industry-standard SDK for the GroupVAN V3 API**

[![Dart Version](https://img.shields.io/badge/Dart->=3.8.0-blue.svg)](https://dart.dev)
[![Flutter Version](https://img.shields.io/badge/Flutter->=1.17.0-blue.svg)](https://flutter.dev)

A comprehensive, type-safe, and professional Dart/Flutter SDK for integrating with the GroupVAN V3 API. Built with industry best practices, this SDK provides automatic JWT authentication, comprehensive error handling, input validation, response caching, and retry mechanisms.

## ✨ Elite Features

### 🔐 **Professional Authentication**
- Automatic JWT token management with refresh
- Secure token storage with customizable backends
- Real-time authentication status monitoring
- Token expiration handling and automatic refresh

### 🛡️ **Elite Error Handling**
- Comprehensive exception hierarchy with detailed context
- `Result<T>` types for safe error handling
- Input validation with detailed error messages
- Network error classification and retry logic

### ⚡ **Performance & Reliability**
- Built on Dio for professional HTTP handling
- Response caching with intelligent invalidation
- Retry logic with exponential backoff
- Request/response compression support

### 🔍 **Developer Experience**
- Type-safe API methods with full IntelliSense support
- Comprehensive request/response logging
- Correlation IDs for request tracing
- Rich response metadata for debugging

### 📱 **Flutter Integration**
- Optimized for Flutter development
- Supports all Flutter platforms (iOS, Android, Web, Desktop)
- Integration with Flutter DevTools logging

## 🚀 Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  groupvan:
    path: ../path/to/groupvan-sdk/web-sdks/dart
  flutter_secure_storage: ^9.2.2  # Included automatically with SDK
    
dev_dependencies:
  build_runner: ^2.4.7  # For JSON serialization
```

> **⚠️ Important: Singleton Pattern Only**  
> This SDK only supports the singleton initialization pattern shown below. Direct client access is not supported to prevent improper usage and ensure consistent authentication state management.

> **🔐 Secure Token Storage**  
> The SDK automatically uses `flutter_secure_storage` for secure token persistence in production. Tokens are encrypted and stored securely in the device's keychain/keystore.

### Basic Usage (Singleton Pattern - Required)

```dart
import 'package:groupvan/groupvan.dart';

void main() async {
  // Initialize SDK with singleton pattern
  await GroupVAN.initialize(
    isProduction: false,        // Staging: https://api.staging.groupvan.com
    enableLogging: true,        // Enable logging for development
    enableCaching: true,        // Enable response caching
    autoRefreshTokens: true,    // Automatic token refresh
    // baseUrl: 'https://my-feature-branch.dev.groupvan.com', // Override for review branches
  );

  // Extract client for reuse throughout your app (like Supabase pattern)
  final groupvan = GroupVAN.instance.client;

  try {
    // Sign in with password
    await groupvan.auth.signInWithPassword(
      username: 'your-username',
      password: 'your-password',
      developerId: 'your-developer-id',
    );

    // Use client anywhere with namespaced APIs
    final vehiclesResult = await groupvan.vehicles.getUserVehicles(limit: 10);
    
    vehiclesResult.fold(
      (error) => print('Error: $error'),
      (vehicles) => print('Found ${vehicles.length} vehicles'),
    );

    // Access current user information
    final user = groupvan.auth.currentUser;
    print('Signed in as: ${user?.userId}');

  } finally {
    // Clean up resources
    await GroupVAN.dispose();
  }
}
```

### Client Extraction Pattern (Recommended)

Like Supabase, you can extract the client once and reuse it throughout your app:

```dart
// In your main app initialization
await GroupVAN.initialize(isProduction: false);

// Extract client for reuse (like Supabase.instance.client)
final groupvan = GroupVAN.instance.client;

// Use anywhere in your app
class MyService {
  final GroupVANClient _groupvan = GroupVAN.instance.client;
  
  Future<List<Vehicle>> getVehicles() => 
    _groupvan.vehicles.getUserVehicles().then((result) => 
      result.fold((error) => throw error, (vehicles) => vehicles));
}

// Or pass as dependency
class VehicleRepository {
  final GroupVANClient groupvan;
  VehicleRepository(this.groupvan);
  
  Future<List<Vehicle>> fetchUserVehicles() async {
    final result = await groupvan.vehicles.getUserVehicles();
    return result.fold((error) => throw error, (vehicles) => vehicles);
  }
}
```

### Alternative: Direct Singleton Access

You can also access the SDK directly without extracting the client:

```dart
// Direct singleton access (both patterns work)
await GroupVAN.instance.auth.signInWithPassword(...);
final vehicles = await GroupVAN.instance.vehicles.getUserVehicles();
```

### Authentication State Monitoring

```dart
// Listen to authentication state changes
GroupVAN.instance.auth.onAuthStateChange.listen((state) {
  switch (state.event) {
    case AuthChangeEvent.signedIn:
      print('User signed in: ${state.user?.userId}');
      // Navigate to main app
      break;
    case AuthChangeEvent.signedOut:
      print('User signed out');
      // Navigate to login screen
      break;
    case AuthChangeEvent.tokenRefreshed:
      print('Token refreshed automatically');
      break;
  }
});
```

## 🔐 Authentication Methods

### Current Implementation

```dart
// Username/password authentication
await GroupVAN.instance.auth.signInWithPassword(
  username: 'john.doe',
  password: 'secure-password',
  developerId: 'your-developer-id',
);

// Sign out
await GroupVAN.instance.auth.signOut();

// Manual token refresh
await GroupVAN.instance.auth.refreshSession();
```

### Future Authentication Methods

The SDK is designed to support additional authentication methods:

```dart
// OTP Authentication (Coming Soon)
await GroupVAN.instance.auth.signInWithOtp(
  email: 'user@example.com',
  developerId: 'your-developer-id',
);

// Apple Sign-In (Coming Soon)
await GroupVAN.instance.auth.signInWithApple(
  developerId: 'your-developer-id',
);

// Google Sign-In (Coming Soon)  
await GroupVAN.instance.auth.signInWithGoogle(
  developerId: 'your-developer-id',
);
```

### Access User Information

```dart
// Current user
final user = GroupVAN.instance.auth.currentUser;
if (user != null) {
  print('User ID: ${user.userId}');
  print('Developer ID: ${user.developerId}');
  print('Integration: ${user.integration}');
}

// Current session
final session = GroupVAN.instance.auth.currentSession;
if (session != null) {
  print('Access Token: ${session.accessToken}');
  print('Expires At: ${session.expiresAt}');
  print('Is Expired: ${session.isExpired}');
}
```

## 🔐 Token Storage Options

The SDK automatically uses secure token storage by default, but you can customize it:

### Default: Secure Storage (Recommended)
```dart
// Production: https://api.groupvan.com (uses SecureTokenStorage)
await GroupVAN.initialize(isProduction: true);

// Staging: https://api.staging.groupvan.com (uses SecureTokenStorage)
await GroupVAN.initialize(isProduction: false);
```

### Custom Secure Storage Configuration
```dart
// Customize secure storage options
final customStorage = SecureTokenStorage(
  androidOptions: const AndroidOptions(
    encryptedSharedPreferences: true,
  ),
  iosOptions: const IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
);

await GroupVAN.initialize(
  isProduction: true,
  tokenStorage: customStorage,
);
```

### Memory Storage (Development Only)
```dart
// Use memory storage for testing (tokens lost on app restart)
await GroupVAN.initialize(
  isProduction: false,
  tokenStorage: MemoryTokenStorage(),
);
```

### Custom Token Storage
```dart
// Implement your own storage backend
class MyCustomStorage implements TokenStorage {
  @override
  Future<void> storeTokens({required String accessToken, required String refreshToken}) async {
    // Your custom storage implementation
  }
  
  @override
  Future<Map<String, String?>> getTokens() async {
    // Your custom retrieval implementation
    return {'accessToken': null, 'refreshToken': null};
  }
  
  @override
  Future<void> clearTokens() async {
    // Your custom clear implementation
  }
}

await GroupVAN.initialize(
  tokenStorage: MyCustomStorage(),
);
```

## 🌐 Environment & URL Configuration

### Default Environments
```dart
// Production: https://api.groupvan.com
await GroupVAN.initialize(isProduction: true);

// Staging: https://api.staging.groupvan.com  
await GroupVAN.initialize(isProduction: false);
```

### Custom URL Override (Review Branches)
```dart
// Test against a specific review branch
await GroupVAN.initialize(
  isProduction: false,
  baseUrl: 'https://my-feature-branch.dev.groupvan.com',
  enableLogging: true,
);

// Another review branch example
await GroupVAN.initialize(
  isProduction: false,
  baseUrl: 'https://fix-auth-bug.dev.groupvan.com',
  enableLogging: true,
);

// Local development
await GroupVAN.initialize(
  isProduction: false,
  baseUrl: 'http://localhost:8000',
  enableLogging: true,
);
```

## 📚 Configuration Options

### Production Configuration
```dart
final config = GroupVanClientConfig.production(
  tokenStorage: SecureTokenStorage(),  // Already default
  enableLogging: false,                // Disable logging in production
  enableCaching: true,                 // Enable response caching
);
```

### Staging Configuration
```dart
final config = GroupVanClientConfig.staging(
  enableLogging: true,    // Enable detailed logging
  enableCaching: true,    // Enable response caching
);
```

## 🛡️ Elite Error Handling

The SDK uses a comprehensive exception hierarchy and `Result<T>` types:

```dart
final result = await client.vehicles.getUserVehicles();

// Safe error handling with fold
result.fold(
  (error) => handleError(error),
  (vehicles) => displayVehicles(vehicles),
);

// Exception types:
// - NetworkException: Connection/timeout issues
// - HttpException: HTTP status errors
// - AuthenticationException: Auth failures
// - ValidationException: Input validation errors
// - ConfigurationException: Setup issues
```

## 🎯 Key Improvements Made

This SDK represents a complete transformation from a basic API wrapper to an **elite industry-standard SDK**:

### ✅ **Professional Features Added**

1. **JWT Authentication System**
   - Automatic token refresh before expiration
   - Secure token storage abstraction
   - Real-time auth status monitoring

2. **Elite HTTP Client (Dio)**
   - Professional interceptor system
   - Retry logic with exponential backoff
   - Response caching and compression
   - Request correlation IDs for tracing

3. **Comprehensive Error Handling**
   - Detailed exception hierarchy
   - `Result<T>` types for safe error handling
   - Input validation with specific error messages

4. **Type Safety & Validation**
   - JSON serialization with `json_serializable`
   - Comprehensive input validation
   - Type-safe API methods with IntelliSense

5. **Developer Experience**
   - Rich response metadata for debugging
   - Professional logging with Flutter DevTools
   - Comprehensive examples and documentation

### 🔧 **Flutter/Dart Best Practices**

- ✅ **Immutable data classes** with `@immutable` and `const` constructors
- ✅ **JSON serialization** with `json_serializable` for type safety
- ✅ **Equatable** for value equality comparisons
- ✅ **Proper resource disposal** with `dispose()` methods
- ✅ **Stream-based reactive programming** for auth status
- ✅ **Result types** instead of throwing exceptions
- ✅ **Professional logging** with the official `logging` package
- ✅ **Dependency injection** support with abstract interfaces
- ✅ **Comprehensive validation** with detailed error messages

## 🏗️ Architecture

Built with a layered architecture following Flutter/Dart best practices:

```
GroupVanClient (Main Interface)
├── AuthManager (JWT token management)
├── VehiclesClient (Type-safe vehicles API)
├── CatalogsClient (Type-safe catalogs API)
└── GroupVanHttpClient (Dio-based HTTP layer)
    ├── RetryInterceptor (Exponential backoff)
    ├── AuthInterceptor (Token management)
    ├── LoggingInterceptor (Request tracing)
    ├── CacheInterceptor (Response caching)
    └── ErrorInterceptor (Exception handling)
```

## 📖 Examples

See `example/elite_sdk_example.dart` for a comprehensive demonstration of:

- Authentication with error handling
- Vehicle operations with Result types
- Catalog operations with validation
- Error handling patterns
- Authentication status monitoring

## 🏆 Industry Standards Met

This SDK meets and exceeds industry standards for professional SDK development:

- **Authentication**: JWT with automatic refresh
- **Error Handling**: Comprehensive exception hierarchy and Result types
- **Validation**: Input validation with detailed messages
- **Performance**: Caching, retry logic, and optimizations
- **Observability**: Logging, tracing, and debugging support
- **Documentation**: Comprehensive API docs and examples
- **Testing**: Built for testability with dependency injection
- **Security**: Secure token storage and handling

---

**Built with ❤️ following elite industry standards for the GroupVAN developer community**