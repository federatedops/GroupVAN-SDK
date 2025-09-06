---
layout: default
title: Getting Started
parent: Flutter/Dart SDK
nav_order: 1
description: "Complete guide to setting up and using the GroupVAN Flutter/Dart SDK in your application."
---

# Getting Started with GroupVAN Flutter/Dart SDK
{: .no_toc }

This guide will walk you through setting up the GroupVAN Flutter/Dart SDK in your Flutter or Dart application, from installation to making your first API calls.

{: .fs-6 .fw-300 }

---

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Prerequisites

Before you begin, ensure you have:

- **Flutter SDK** installed (version 3.8.0 or higher)
- **Dart SDK** (version 3.8.0 or higher) 
- **GroupVAN Developer Account** with valid credentials
- **Developer ID** provided by your GroupVAN Integration Specialist

---

## Installation

### Add Dependency

Add the GroupVAN SDK to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  groupvan: ^0.0.1
  # Other dependencies...

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

### Install Packages

Run the following command to install the SDK:

```bash
flutter pub get
```

### Platform Configuration

The SDK works out-of-the-box on all Flutter platforms, but for optimal security, ensure the following platform-specific configurations:

#### Android
No additional configuration required. The SDK uses Android Keystore for secure token storage.

#### iOS  
No additional configuration required. The SDK uses iOS Keychain for secure token storage.

#### Web
For web applications, the SDK uses secure browser storage APIs. Ensure your app is served over HTTPS in production.

#### Desktop (macOS, Windows, Linux)
No additional configuration required. The SDK uses platform-specific secure storage.

---

## Basic Setup

### 1. Import the SDK

```dart
import 'package:groupvan/groupvan.dart';
```

### 2. Initialize the SDK

Initialize the SDK early in your application lifecycle, typically in your `main()` function:

```dart
import 'package:flutter/material.dart';
import 'package:groupvan/groupvan.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize GroupVAN SDK
  await GroupVAN.initialize(
    isProduction: false,          // Use staging for development
    enableLogging: true,          // Enable logging for debugging
    enableCaching: true,          // Enable response caching
    autoRefreshTokens: true,      // Automatic token refresh
  );
  
  runApp(MyApp());
}
```

### 3. Handle SDK Lifecycle

Properly dispose of the SDK when your application shuts down:

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GroupVAN.dispose(); // Clean up SDK resources
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      GroupVAN.dispose(); // Clean up when app is closing
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GroupVAN SDK Demo',
      home: MyHomePage(),
    );
  }
}
```

---

## Authentication

### Sign In with Password

The most common authentication method is username/password with developer ID:

```dart
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _developerIdController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await GroupVAN.instance.auth.signInWithPassword(
        username: _usernameController.text,
        password: _passwordController.text,
        developerId: _developerIdController.text,
      );

      // Navigate to main app
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GroupVAN Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _developerIdController,
              decoration: InputDecoration(labelText: 'Developer ID'),
            ),
            SizedBox(height: 24),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              child: _isLoading 
                ? CircularProgressIndicator()
                : Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Monitor Authentication State

Listen to authentication state changes throughout your app:

```dart
class AuthStateListener extends StatefulWidget {
  final Widget child;

  const AuthStateListener({Key? key, required this.child}) : super(key: key);

  @override
  _AuthStateListenerState createState() => _AuthStateListenerState();
}

class _AuthStateListenerState extends State<AuthStateListener> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = GroupVAN.instance.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
          print('User signed in: ${state.user?.userId}');
          // Handle sign in
          break;
        case AuthChangeEvent.signedOut:
          print('User signed out');
          // Navigate to login
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
            (route) => false,
          );
          break;
        case AuthChangeEvent.tokenRefreshed:
          print('Token refreshed');
          // Token was automatically refreshed
          break;
        case AuthChangeEvent.passwordRecovery:
          print('Password recovery initiated');
          break;
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
```

---

## Making API Calls

### Using Result Types

The SDK uses `Result<T>` types for safe error handling without exceptions:

```dart
class VehiclesPage extends StatefulWidget {
  @override
  _VehiclesPageState createState() => _VehiclesPageState();
}

class _VehiclesPageState extends State<VehiclesPage> {
  List<Vehicle> _vehicles = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await GroupVAN.instance.client.vehicles.getUserVehicles(limit: 10);
    
    result.fold(
      (error) {
        setState(() {
          _errorMessage = 'Failed to load vehicles: $error';
        });
      },
      (vehicles) {
        setState(() {
          _vehicles = vehicles;
        });
      },
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Vehicles'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadVehicles,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVehicles,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_vehicles.isEmpty) {
      return Center(child: Text('No vehicles found'));
    }

    return ListView.builder(
      itemCount: _vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        return ListTile(
          title: Text('${vehicle.year} ${vehicle.make} ${vehicle.model}'),
          subtitle: vehicle.engine != null ? Text(vehicle.engine!) : null,
          leading: Icon(Icons.directions_car),
        );
      },
    );
  }
}
```

### Multiple API Calls

Chain multiple API calls or run them in parallel:

```dart
Future<void> _loadDashboardData() async {
  setState(() => _isLoading = true);

  // Run multiple API calls in parallel
  final results = await Future.wait([
    GroupVAN.instance.client.vehicles.getUserVehicles(limit: 5),
    GroupVAN.instance.client.vehicles.getGroups(),
    GroupVAN.instance.client.catalogs.getCatalogs(),
  ]);

  // Handle each result
  results[0].fold(
    (error) => print('Failed to load vehicles: $error'),
    (vehicles) => setState(() => _vehicles = vehicles),
  );

  results[1].fold(
    (error) => print('Failed to load groups: $error'),
    (groups) => setState(() => _vehicleGroups = groups),
  );

  results[2].fold(
    (error) => print('Failed to load catalogs: $error'),
    (catalogs) => setState(() => _catalogs = catalogs),
  );

  setState(() => _isLoading = false);
}
```

---

## Configuration Options

### Environment Configuration

```dart
// Production configuration
await GroupVAN.initialize(
  isProduction: true,
  enableLogging: false,  // Disable logging in production
  enableCaching: true,   // Enable caching for performance
);

// Staging configuration
await GroupVAN.initialize(
  isProduction: false,
  baseUrl: 'https://api.staging.groupvan.com',
  enableLogging: true,   // Enable for debugging
);

// Custom review branch
await GroupVAN.initialize(
  isProduction: false,
  baseUrl: 'https://feature-branch.dev.groupvan.com',
  enableLogging: true,
);
```

### Storage Configuration

```dart
// Secure storage (default)
await GroupVAN.initialize(
  tokenStorage: SecureTokenStorage(), // Uses platform secure storage
);

// Memory storage (for testing)
await GroupVAN.initialize(
  tokenStorage: MemoryTokenStorage(), // Tokens cleared on app restart
);

// Custom storage implementation
class CustomTokenStorage implements TokenStorage {
  // Implement your custom storage logic
}

await GroupVAN.initialize(
  tokenStorage: CustomTokenStorage(),
);
```

### HTTP Configuration

```dart
await GroupVAN.initialize(
  httpClientConfig: HttpClientConfig(
    baseUrl: 'https://api.staging.groupvan.com',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 30),
    enableRetry: true,
    maxRetries: 3,
    enableLogging: true,
    enableCaching: true,
  ),
);
```

---

## Next Steps

Now that you have the SDK set up and running, explore these areas:

- **[Authentication](authentication)** - Advanced authentication patterns and session management
- **[Vehicles API](vehicles/)** - Complete vehicle operations and examples
- **[Catalogs API](catalogs/)** - Catalog browsing and product management
- **[Error Handling](error-handling)** - Comprehensive error handling patterns
- **[Logging](logging)** - Debugging and monitoring with structured logging

---

## Troubleshooting

### Common Issues

**SDK not initializing**
```dart
// Ensure you call this before using the SDK
await GroupVAN.initialize(isProduction: false);
```

**Authentication failures**  
```dart
// Check your credentials and network connection
try {
  await GroupVAN.instance.auth.signInWithPassword(
    username: username,
    password: password,
    developerId: developerId,
  );
} catch (error) {
  if (error is AuthenticationException) {
    print('Auth error: ${error.message}');
  } else if (error is NetworkException) {
    print('Network error: ${error.message}');
  }
}
```

**Token storage issues**
```dart
// For testing, use memory storage
await GroupVAN.initialize(
  tokenStorage: MemoryTokenStorage(),
);
```

### Enable Debug Logging

```dart
await GroupVAN.initialize(
  enableLogging: true, // This will log all requests and responses
);
```

### Check Authentication Status

```dart
final auth = GroupVAN.instance.auth;
print('Is authenticated: ${auth.isAuthenticated}');
print('Current user: ${auth.currentUser?.userId}');
print('Session expires: ${auth.currentSession?.expiresAt}');
```