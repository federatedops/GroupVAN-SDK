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
  print('Client ID: ${user.clientId}');
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

## 🔐 Admin Features (Impersonation & 2FA)

The SDK provides admin functionality for users with the `catalog_developer` role, enabling secure user impersonation for debugging and support purposes.

### Security Features (SOC2 Compliant)

- **Mandatory 2FA** for every impersonation session
- **Three 2FA methods** (in priority order):
  1. **Passkey/WebAuthn** - Most secure, phishing-resistant (Touch ID, Face ID, Windows Hello, YubiKey)
  2. **TOTP** - Authenticator app (Google Authenticator, Authy, 1Password)
  3. **Email OTP** - Fallback option, always available
- **1-hour session limit** with automatic expiration
- **Complete audit trail** for compliance
- **Rate limiting** (5 attempts per hour)

### Quick Start: User Impersonation

```dart
import 'package:groupvan/groupvan.dart';

// Access admin features (requires catalog_developer role)
final admin = GroupVAN.instance.admin;

// Check available 2FA methods
final status = await admin.getTwoFactorStatus();
print('Passkey enabled: ${status.passkeyEnabled}');
print('TOTP enabled: ${status.totpEnabled}');
print('Recommended method: ${status.recommendedMethod}');

// Start impersonation with TOTP or email OTP
final session = await admin.startImpersonation(
  targetUserId: 'user-uuid-to-impersonate',
  twoFactorCode: '123456',  // From authenticator app or email
);

print('Impersonating: ${session.targetEmail}');
print('Session expires: ${session.expiresAt}');

// All API calls now act as the impersonated user
final vehicles = await GroupVAN.instance.vehicles.getUserVehicles();

// End impersonation (restores admin identity)
await admin.endImpersonation();
```

### Passkey Authentication (Recommended)

Passkeys provide the highest level of security - they're phishing-resistant and use biometric verification (Touch ID, Face ID, Windows Hello) or hardware security keys.

#### Setup: Register a Passkey (One-time)

```dart
import 'package:groupvan/groupvan.dart';
import 'dart:html' as html;  // For web
import 'dart:convert';

final admin = GroupVAN.instance.admin;

// Step 1: Begin registration ceremony
final beginResponse = await admin.beginPasskeyRegistration();

// Step 2: Call WebAuthn API (browser/platform)
final credential = await _createPasskeyCredential(beginResponse.options);

// Step 3: Complete registration
final result = await admin.completePasskeyRegistration(
  challengeId: beginResponse.challengeId,
  credential: credential,
  deviceName: 'MacBook Pro Touch ID',  // Optional friendly name
);

print('Passkey registered: ${result.passkeyId}');
```

#### Usage: Impersonate with Passkey

```dart
final admin = GroupVAN.instance.admin;

// Step 1: Begin authentication ceremony
final authResponse = await admin.beginPasskeyAuthentication();

// Step 2: Call WebAuthn API (user touches Touch ID / Face ID / security key)
final credential = await _getPasskeyCredential(authResponse.options);

// Step 3: Start impersonation with passkey
final session = await admin.startImpersonationWithPasskey(
  targetUserId: 'user-uuid-to-impersonate',
  passkeyChallengeId: authResponse.challengeId,
  passkeyCredential: credential,
);

print('Impersonating with passkey: ${session.targetEmail}');
```

### Flutter Web: WebAuthn Integration

For Flutter Web, use the browser's WebAuthn API via `dart:html`:

```dart
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';

/// Create a new passkey credential (registration)
Future<Map<String, dynamic>> createPasskeyCredential(
  Map<String, dynamic> options,
) async {
  // Convert base64url challenge to Uint8Array
  final challenge = _base64UrlDecode(options['challenge']);
  final userId = _base64UrlDecode(options['user']['id']);

  final publicKeyCredentialCreationOptions = {
    'challenge': challenge,
    'rp': options['rp'],
    'user': {
      'id': userId,
      'name': options['user']['name'],
      'displayName': options['user']['displayName'],
    },
    'pubKeyCredParams': options['pubKeyCredParams'],
    'timeout': options['timeout'],
    'attestation': options['attestation'] ?? 'none',
    'authenticatorSelection': options['authenticatorSelection'],
  };

  final credential = await html.window.navigator.credentials!.create(
    {'publicKey': publicKeyCredentialCreationOptions},
  ) as html.PublicKeyCredential;

  // Convert response to JSON for API
  final response = credential.response as html.AuthenticatorAttestationResponse;
  return {
    'id': credential.id,
    'rawId': _base64UrlEncode(Uint8List.view(credential.rawId!)),
    'type': credential.type,
    'response': {
      'clientDataJSON': _base64UrlEncode(
        Uint8List.view(response.clientDataJson!),
      ),
      'attestationObject': _base64UrlEncode(
        Uint8List.view(response.attestationObject!),
      ),
    },
  };
}

/// Get existing passkey credential (authentication)
Future<Map<String, dynamic>> getPasskeyCredential(
  Map<String, dynamic> options,
) async {
  final challenge = _base64UrlDecode(options['challenge']);

  final allowCredentials = (options['allowCredentials'] as List?)?.map((cred) {
    return {
      'id': _base64UrlDecode(cred['id']),
      'type': cred['type'],
      'transports': cred['transports'],
    };
  }).toList();

  final publicKeyCredentialRequestOptions = {
    'challenge': challenge,
    'timeout': options['timeout'],
    'rpId': options['rpId'],
    'allowCredentials': allowCredentials,
    'userVerification': options['userVerification'] ?? 'preferred',
  };

  final credential = await html.window.navigator.credentials!.get(
    {'publicKey': publicKeyCredentialRequestOptions},
  ) as html.PublicKeyCredential;

  final response = credential.response as html.AuthenticatorAssertionResponse;
  return {
    'id': credential.id,
    'rawId': _base64UrlEncode(Uint8List.view(credential.rawId!)),
    'type': credential.type,
    'response': {
      'clientDataJSON': _base64UrlEncode(
        Uint8List.view(response.clientDataJson!),
      ),
      'authenticatorData': _base64UrlEncode(
        Uint8List.view(response.authenticatorData!),
      ),
      'signature': _base64UrlEncode(
        Uint8List.view(response.signature!),
      ),
      'userHandle': response.userHandle != null
          ? _base64UrlEncode(Uint8List.view(response.userHandle!))
          : null,
    },
  };
}

// Base64URL encoding/decoding helpers
Uint8List _base64UrlDecode(String input) {
  String normalized = input.replaceAll('-', '+').replaceAll('_', '/');
  while (normalized.length % 4 != 0) {
    normalized += '=';
  }
  return base64Decode(normalized);
}

String _base64UrlEncode(Uint8List data) {
  return base64Encode(data).replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
}
```

### Flutter Mobile: Platform-Specific Passkey Integration

For iOS and Android, use platform channels or a package like `passkeys` or `webauthn`:

```dart
// Example using a passkey package (conceptual)
import 'package:passkeys/passkeys.dart';

class PasskeyService {
  final _passkeys = Passkeys();

  Future<Map<String, dynamic>> createCredential(Map<String, dynamic> options) async {
    final credential = await _passkeys.register(
      challenge: options['challenge'],
      rpId: options['rp']['id'],
      rpName: options['rp']['name'],
      userId: options['user']['id'],
      userName: options['user']['name'],
    );
    return credential.toJson();
  }

  Future<Map<String, dynamic>> getCredential(Map<String, dynamic> options) async {
    final credential = await _passkeys.authenticate(
      challenge: options['challenge'],
      rpId: options['rpId'],
      allowCredentials: options['allowCredentials'],
    );
    return credential.toJson();
  }
}
```

### Managing Passkeys

```dart
final admin = GroupVAN.instance.admin;

// List all registered passkeys
final passkeys = await admin.getPasskeys();
for (final passkey in passkeys) {
  print('${passkey.deviceName}: ${passkey.authenticatorType}');
  print('  Created: ${passkey.createdAt}');
  print('  Last used: ${passkey.lastUsedAt}');
}

// Revoke a passkey
await admin.revokePasskey(passkeyId: 'passkey-uuid');
```

### TOTP Setup (Authenticator App)

```dart
final admin = GroupVAN.instance.admin;

// Step 1: Get setup info
final setup = await admin.setupTotp();
print('Secret: ${setup.secret}');
print('QR Code URI: ${setup.qrCodeUri}');

// Step 2: Display QR code to user (use qr_flutter package)
// QrImageView(data: setup.qrCodeUri)

// Step 3: User scans QR, enters code to verify
final verified = await admin.verifyTotp(code: '123456');
if (verified) {
  print('TOTP enabled successfully!');
}
```

### Email OTP (Fallback)

```dart
final admin = GroupVAN.instance.admin;

// Request email OTP
final response = await admin.requestEmailOtp();
print('OTP sent to: ${response.emailMasked}');  // j***@example.com
print('Expires at: ${response.expiresAt}');

// Use the code for impersonation
await admin.startImpersonation(
  targetUserId: 'user-uuid',
  twoFactorCode: '123456',  // From email
);
```

### Checking Impersonation Status

```dart
final admin = GroupVAN.instance.admin;

// Check if currently impersonating
if (admin.isImpersonating) {
  final session = admin.currentImpersonation!;
  print('Impersonating: ${session.targetEmail}');
  print('Time remaining: ${session.expiresAt.difference(DateTime.now())}');
}
```

### Viewing Impersonation History (Audit)

```dart
final admin = GroupVAN.instance.admin;

// Get recent impersonation sessions
final sessions = await admin.getImpersonationSessions(limit: 10);
for (final session in sessions) {
  print('${session.createdAt}: Impersonated ${session.targetEmail}');
  print('  Method: ${session.twoFactorMethod}');
  print('  Duration: ${session.endedAt?.difference(session.createdAt)}');
}
```

### Complete Example: Admin Panel Widget

```dart
import 'package:flutter/material.dart';
import 'package:groupvan/groupvan.dart';

class ImpersonationWidget extends StatefulWidget {
  @override
  State<ImpersonationWidget> createState() => _ImpersonationWidgetState();
}

class _ImpersonationWidgetState extends State<ImpersonationWidget> {
  final _admin = GroupVAN.instance.admin;
  final _userIdController = TextEditingController();
  final _codeController = TextEditingController();
  TwoFactorStatus? _status;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await _admin.getTwoFactorStatus();
    setState(() => _status = status);
  }

  Future<void> _startImpersonation() async {
    setState(() => _loading = true);
    try {
      if (_status?.passkeyEnabled == true) {
        // Use passkey (most secure)
        final authResponse = await _admin.beginPasskeyAuthentication();
        final credential = await getPasskeyCredential(authResponse.options);
        await _admin.startImpersonationWithPasskey(
          targetUserId: _userIdController.text,
          passkeyChallengeId: authResponse.challengeId,
          passkeyCredential: credential,
        );
      } else {
        // Fall back to TOTP/email
        await _admin.startImpersonation(
          targetUserId: _userIdController.text,
          twoFactorCode: _codeController.text,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Now impersonating user')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _endImpersonation() async {
    await _admin.endImpersonation();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Impersonation ended')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_admin.isImpersonating) {
      final session = _admin.currentImpersonation!;
      return Card(
        color: Colors.orange.shade100,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 48),
              Text('Impersonating: ${session.targetEmail}'),
              Text('Expires: ${session.expiresAt}'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _endImpersonation,
                child: Text('End Impersonation'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Impersonation', style: Theme.of(context).textTheme.titleLarge),
            if (_status != null) ...[
              SizedBox(height: 8),
              Text('2FA Methods: ${_status!.recommendedMethod} (recommended)'),
              if (_status!.passkeyEnabled)
                Chip(label: Text('Passkey Ready'), avatar: Icon(Icons.fingerprint)),
            ],
            SizedBox(height: 16),
            TextField(
              controller: _userIdController,
              decoration: InputDecoration(labelText: 'Target User ID'),
            ),
            if (_status?.passkeyEnabled != true) ...[
              SizedBox(height: 8),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(labelText: '2FA Code'),
                keyboardType: TextInputType.number,
              ),
            ],
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _startImpersonation,
              child: _loading
                  ? CircularProgressIndicator()
                  : Text(_status?.passkeyEnabled == true
                      ? 'Impersonate with Passkey'
                      : 'Impersonate'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Error Handling

```dart
try {
  await admin.startImpersonation(
    targetUserId: userId,
    twoFactorCode: code,
  );
} on AuthorizationException catch (e) {
  // User doesn't have catalog_developer role
  print('Not authorized: ${e.message}');
} on ValidationException catch (e) {
  // Invalid 2FA code
  print('Invalid code: ${e.message}');
} on RateLimitException catch (e) {
  // Too many attempts (5/hour limit)
  print('Rate limited: ${e.message}');
} on NetworkException catch (e) {
  // Network issues
  print('Network error: ${e.message}');
}
```

---

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