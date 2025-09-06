---
layout: default
title: Flutter/Dart SDK
nav_order: 6
has_children: true
permalink: /dart/
description: "Elite GroupVAN Flutter/Dart SDK for mobile and web applications with comprehensive API coverage, automatic authentication, and professional error handling."
---

# GroupVAN Flutter/Dart SDK
{: .no_toc }

The GroupVAN Flutter/Dart SDK provides a comprehensive, type-safe interface to the GroupVAN V3 API. Built with modern Dart practices, it offers automatic JWT authentication, input validation, and professional error handling out of the box.

{: .fs-6 .fw-300 }

[![Dart CI](https://github.com/federatedops/GroupVAN-SDK/actions/workflows/dart.yml/badge.svg)](https://github.com/federatedops/GroupVAN-SDK/actions/workflows/dart.yml)
[![Pub Version](https://img.shields.io/pub/v/groupvan?logo=dart&logoColor=blue)](https://pub.dev/packages/groupvan)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Quick Start

### Installation

Add the SDK to your `pubspec.yaml`:

```yaml
dependencies:
  groupvan: ^0.0.1
```

### Initialize and Authenticate

```dart
import 'package:groupvan/groupvan.dart';

void main() async {
  // Initialize SDK with singleton pattern
  await GroupVAN.initialize(
    isProduction: false,          // Use staging environment
    enableLogging: true,          // Enable for debugging
    enableCaching: true,          // Enable response caching
    autoRefreshTokens: true,      // Automatic token refresh
  );

  // Authenticate
  await GroupVAN.instance.auth.signInWithPassword(
    username: 'your-username',
    password: 'your-password', 
    developerId: 'your-developer-id',
  );

  // Use the API
  final vehicles = await GroupVAN.instance.client.vehicles.getUserVehicles();
  vehicles.fold(
    (error) => print('Error: $error'),
    (vehicleList) => print('Found ${vehicleList.length} vehicles'),
  );

  // Clean up
  await GroupVAN.dispose();
}
```

---

## Key Features

### 🚀 Elite Industry Standard
Professional SDK following Flutter/Dart best practices with comprehensive type safety and error handling.

### 🔐 Automatic Authentication  
JWT token management with automatic refresh, secure storage, and seamless reauthentication.

### 🛡️ Input Validation
Comprehensive validation with detailed error messages and type checking before API calls.

### 🎯 Result Types
Safe error handling using `Result<T>` types instead of exceptions, making error states explicit and manageable.

### 📱 Secure Storage 
Encrypted token storage using `flutter_secure_storage` with platform-specific security features.

### 🔄 Retry Logic
Automatic retry with exponential backoff for transient network errors and rate limiting.

### 📊 Professional Logging
Structured logging with configurable levels for debugging, monitoring, and production diagnostics.

### 🌍 Platform Support
Full support for all Flutter platforms: iOS, Android, Web, macOS, Windows, Linux.

---

## API Coverage

The SDK provides **complete 100% parity** with the GroupVAN V3 API:

### Vehicles API
- **Vehicle Groups** - Get available vehicle groups
- **User Vehicles** - Get user's vehicles with pagination  
- **Vehicle Search** - Search vehicles by query with filtering
- **VIN Lookup** - Search vehicles by VIN number
- **License Plate Search** - Search by license plate and state
- **Vehicle Filtering** - Filter by group, year, make, model
- **Engine Data** - Get engine information for vehicle configurations
- **Fleet Management** - Get fleets and fleet vehicles
- **Account Vehicles** - Get account-level vehicles

### Catalogs API
- **Catalog Listing** - Get available catalogs
- **Vehicle Categories** - Get vehicle categories for catalogs
- **Supply Categories** - Get supply categories
- **Application Assets** - Get application-specific assets
- **Cart Management** - Get cart contents
- **Product Listings** - Get product listings with filtering

### Authentication API
- **Password Authentication** - Username/password with developer ID
- **Automatic Token Refresh** - Seamless token renewal
- **Secure Token Storage** - Encrypted storage across platforms
- **Session Management** - Real-time authentication state monitoring
- **Future Support** - OTP, Apple Sign-In, Google Sign-In (planned)

---

## Configuration Options

### Production Configuration
```dart
await GroupVAN.initialize(
  isProduction: true,
  enableLogging: false, 
  enableCaching: true,
  tokenStorage: SecureTokenStorage(), // Default
);
```

### Development Configuration  
```dart
await GroupVAN.initialize(
  isProduction: false,
  baseUrl: 'https://feature-branch.dev.groupvan.com', // Custom URL
  enableLogging: true,
  tokenStorage: MemoryTokenStorage(), // For testing
);
```

### Custom HTTP Configuration
```dart
await GroupVAN.initialize(
  isProduction: false,
  httpClientConfig: HttpClientConfig(
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
    enableRetry: true,
    maxRetries: 3,
  ),
);
```

---

## Architecture

### Singleton Pattern
Following the Supabase pattern, the SDK uses a singleton for global access:

```dart
// Initialize once
await GroupVAN.initialize(isProduction: false);

// Access anywhere in your app
final client = GroupVAN.instance.client;
final auth = GroupVAN.instance.auth;

// Or extract for reuse
final groupvan = GroupVAN.instance.client;
```

### Result Types
Safe error handling without exceptions:

```dart
final result = await client.vehicles.getUserVehicles();
result.fold(
  (error) {
    // Handle error - network, validation, or API errors
    if (error is NetworkException) {
      print('Network error: ${error.message}');
    } else if (error is ValidationException) {
      print('Validation error: ${error.errors}');
    }
  },
  (vehicles) {
    // Handle success - use the vehicles data
    print('Got ${vehicles.length} vehicles');
  },
);
```

### Authentication State Management
Real-time authentication monitoring:

```dart
GroupVAN.instance.auth.onAuthStateChange.listen((state) {
  switch (state.event) {
    case AuthChangeEvent.signedIn:
      print('User signed in: ${state.user?.userId}');
      break;
    case AuthChangeEvent.signedOut:
      print('User signed out');
      break;
    case AuthChangeEvent.tokenRefreshed:
      print('Token refreshed: ${state.session?.expiresAt}');
      break;
  }
});
```

---

## Next Steps

- **[Getting Started](getting-started)** - Complete setup and first API call
- **[Authentication](authentication)** - Authentication patterns and token management  
- **[Vehicles API](vehicles/)** - Vehicle endpoints and examples
- **[Catalogs API](catalogs/)** - Catalog endpoints and examples
- **[Error Handling](error-handling)** - Comprehensive error handling patterns
- **[Logging](logging)** - Debugging and monitoring with structured logging

---

## Support

- 📖 **[API Documentation](https://api.groupvan.com/docs)** - Full API reference
- 🐛 **[Issue Tracker](https://github.com/federatedops/GroupVAN-SDK/issues)** - Report bugs or request features  
- 📱 **[Example App](https://github.com/federatedops/GroupVAN-SDK/tree/main/web-sdks/dart/example)** - Complete example implementation
- 👥 **Integration Specialist** - Contact your GroupVAN Integration Specialist

---

## Comparison with Server SDKs

| Feature | Server SDKs | Flutter/Dart SDK |
|:--------|:------------|:------------------|
| **Purpose** | JWT Authentication | Complete API Client |
| **API Coverage** | Token Generation | Full V3 API Coverage |
| **Authentication** | RSA256 Signing | Username/Password + JWT |
| **Platform** | Server-side only | Cross-platform client |
| **Storage** | File-based keys | Secure encrypted storage |
| **UI Integration** | N/A | Native Flutter widgets |
| **Error Handling** | Exceptions | Result types |
| **Caching** | N/A | Response caching |
| **Retry Logic** | N/A | Automatic retry |