---
layout: default
title: Authentication
parent: Flutter/Dart SDK
nav_order: 2
description: "Comprehensive authentication guide for the GroupVAN Flutter/Dart SDK including password authentication, session management, and secure token storage."
---

# Authentication
{: .no_toc }

The GroupVAN Flutter/Dart SDK provides secure authentication through JWT tokens with automatic refresh, secure storage, and real-time session monitoring. This guide covers all authentication patterns and best practices.

{: .fs-6 .fw-300 }

---

## Table of contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

The authentication system in the GroupVAN Dart SDK provides:

- **Password Authentication** - Username/password with developer ID
- **Automatic Token Refresh** - Seamless JWT renewal before expiration
- **Secure Token Storage** - Platform-specific encrypted storage
- **Session Management** - Real-time authentication state monitoring
- **Offline Support** - Cached tokens work when network is unavailable

---

## Authentication Methods

### Password Authentication

The primary authentication method uses username, password, and developer ID:

```dart
import 'package:groupvan/groupvan.dart';

Future<void> authenticateUser() async {
  try {
    await GroupVAN.instance.auth.signInWithPassword(
      username: 'your-username',
      password: 'your-password',
      developerId: 'your-developer-id',
    );
    
    print('Authentication successful!');
    print('User ID: ${GroupVAN.instance.auth.currentUser?.userId}');
    
  } catch (error) {
    print('Authentication failed: $error');
  }
}
```

### Authentication with Custom Options

```dart
await GroupVAN.instance.auth.signInWithPassword(
  username: 'your-username',
  password: 'your-password',
  developerId: 'your-developer-id',
  rememberMe: true,        // Keep session longer
  deviceName: 'iPhone 15', // Optional device identifier
);
```

---

## Session Management

### Check Authentication Status

```dart
final auth = GroupVAN.instance.auth;

// Check if user is authenticated
if (auth.isAuthenticated) {
  print('User is signed in');
  print('User ID: ${auth.currentUser?.userId}');
  print('Session expires: ${auth.currentSession?.expiresAt}');
} else {
  print('User is not authenticated');
}
```

### Get Current User Information

```dart
final user = GroupVAN.instance.auth.currentUser;
if (user != null) {
  print('User ID: ${user.userId}');
  print('Username: ${user.username}');
  print('Developer ID: ${user.developerId}');
  print('Created: ${user.createdAt}');
  print('Last Sign In: ${user.lastSignInAt}');
}
```

### Get Current Session

```dart
final session = GroupVAN.instance.auth.currentSession;
if (session != null) {
  print('Access Token: ${session.accessToken}');
  print('Refresh Token: ${session.refreshToken}');
  print('Expires At: ${session.expiresAt}');
  print('Token Type: ${session.tokenType}'); // Usually 'Bearer'
}
```

---

## Authentication State Monitoring

### Listen to Authentication Changes

Monitor authentication state changes throughout your application:

```dart
import 'dart:async';

class AuthenticationManager {
  StreamSubscription<AuthState>? _authSubscription;
  
  void initializeAuthListener() {
    _authSubscription = GroupVAN.instance.auth.onAuthStateChange.listen((state) {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
          _handleSignedIn(state);
          break;
        case AuthChangeEvent.signedOut:
          _handleSignedOut(state);
          break;
        case AuthChangeEvent.tokenRefreshed:
          _handleTokenRefreshed(state);
          break;
        case AuthChangeEvent.passwordRecovery:
          _handlePasswordRecovery(state);
          break;
      }
    });
  }
  
  void _handleSignedIn(AuthState state) {
    print('User signed in: ${state.user?.userId}');
    // Navigate to main app, update UI state, etc.
  }
  
  void _handleSignedOut(AuthState state) {
    print('User signed out');
    // Navigate to login screen, clear user data, etc.
  }
  
  void _handleTokenRefreshed(AuthState state) {
    print('Token refreshed, expires: ${state.session?.expiresAt}');
    // Token was automatically refreshed, no action needed
  }
  
  void _handlePasswordRecovery(AuthState state) {
    print('Password recovery initiated');
    // Show password recovery UI
  }
  
  void dispose() {
    _authSubscription?.cancel();
  }
}
```

### Authentication State in Flutter Widgets

```dart
class AuthStateWidget extends StatefulWidget {
  final Widget Function(bool isAuthenticated) builder;
  
  const AuthStateWidget({Key? key, required this.builder}) : super(key: key);
  
  @override
  _AuthStateWidgetState createState() => _AuthStateWidgetState();
}

class _AuthStateWidgetState extends State<AuthStateWidget> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isAuthenticated = false;
  
  @override
  void initState() {
    super.initState();
    _isAuthenticated = GroupVAN.instance.auth.isAuthenticated;
    
    _authSubscription = GroupVAN.instance.auth.onAuthStateChange.listen((state) {
      setState(() {
        _isAuthenticated = state.event == AuthChangeEvent.signedIn;
      });
    });
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.builder(_isAuthenticated);
  }
}

// Usage
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthStateWidget(
        builder: (isAuthenticated) {
          return isAuthenticated ? HomePage() : LoginPage();
        },
      ),
    );
  }
}
```

---

## Automatic Token Refresh

The SDK automatically handles token refresh before expiration. You can configure this behavior:

```dart
await GroupVAN.initialize(
  autoRefreshTokens: true,     // Enable automatic refresh (default: true)
  tokenRefreshBuffer: Duration(minutes: 5), // Refresh 5 minutes before expiry
);
```

### Manual Token Refresh

Force a token refresh when needed:

```dart
Future<void> refreshToken() async {
  try {
    await GroupVAN.instance.auth.refreshSession();
    print('Token refreshed successfully');
  } catch (error) {
    print('Token refresh failed: $error');
    // May need to re-authenticate
  }
}
```

---

## Sign Out

### Basic Sign Out

```dart
Future<void> signOut() async {
  await GroupVAN.instance.auth.signOut();
  print('User signed out');
}
```

### Sign Out with Options

```dart
await GroupVAN.instance.auth.signOut(
  clearTokens: true,     // Clear stored tokens (default: true)
  revokeTokens: true,    // Revoke tokens on server (default: false)
);
```

### Global Sign Out

Sign out from all devices:

```dart
await GroupVAN.instance.auth.signOut(
  scope: SignOutScope.global, // Sign out from all devices
);
```

---

## Secure Token Storage

### Default Secure Storage

The SDK uses platform-specific secure storage by default:

```dart
// This is the default, no configuration needed
await GroupVAN.initialize(
  tokenStorage: SecureTokenStorage(),
);
```

Platform-specific storage:
- **iOS**: Keychain Services
- **Android**: Android Keystore 
- **Web**: Secure browser storage with encryption
- **Desktop**: Platform-specific secure storage

### Memory Storage (Testing)

For testing or temporary use:

```dart
await GroupVAN.initialize(
  tokenStorage: MemoryTokenStorage(), // Tokens cleared on app restart
);
```

### Custom Storage Implementation

Implement your own token storage:

```dart
class CustomTokenStorage implements TokenStorage {
  @override
  Future<void> setToken(String key, String token) async {
    // Store token securely
  }
  
  @override
  Future<String?> getToken(String key) async {
    // Retrieve token
    return null;
  }
  
  @override
  Future<void> removeToken(String key) async {
    // Remove token
  }
  
  @override
  Future<void> clear() async {
    // Clear all tokens
  }
}

await GroupVAN.initialize(
  tokenStorage: CustomTokenStorage(),
);
```

---

## Error Handling

### Authentication Exceptions

Handle different types of authentication errors:

```dart
Future<void> handleAuthentication() async {
  try {
    await GroupVAN.instance.auth.signInWithPassword(
      username: username,
      password: password,
      developerId: developerId,
    );
  } catch (error) {
    if (error is AuthenticationException) {
      switch (error.type) {
        case AuthErrorType.invalidCredentials:
          print('Invalid username or password');
          break;
        case AuthErrorType.accountDisabled:
          print('Account has been disabled');
          break;
        case AuthErrorType.tooManyAttempts:
          print('Too many failed attempts, try again later');
          break;
        case AuthErrorType.invalidDeveloperId:
          print('Invalid developer ID');
          break;
      }
    } else if (error is NetworkException) {
      print('Network error: ${error.message}');
    } else if (error is ValidationException) {
      print('Validation errors: ${error.errors}');
    }
  }
}
```

### Session Validation

Check if the current session is valid:

```dart
Future<bool> isSessionValid() async {
  try {
    final isValid = await GroupVAN.instance.auth.validateSession();
    if (!isValid) {
      print('Session expired, need to re-authenticate');
    }
    return isValid;
  } catch (error) {
    print('Session validation failed: $error');
    return false;
  }
}
```

---

## Advanced Authentication Patterns

### Persistent Authentication

Keep users signed in across app restarts:

```dart
class PersistentAuthManager {
  static Future<void> initialize() async {
    await GroupVAN.initialize(
      tokenStorage: SecureTokenStorage(),
      autoRefreshTokens: true,
    );
    
    // Check if user has valid stored session
    if (GroupVAN.instance.auth.isAuthenticated) {
      // Validate the stored session
      final isValid = await GroupVAN.instance.auth.validateSession();
      if (!isValid) {
        await GroupVAN.instance.auth.signOut();
      }
    }
  }
}
```

### Conditional Authentication

Authenticate only when needed:

```dart
class ConditionalAuth {
  static Future<bool> ensureAuthenticated() async {
    final auth = GroupVAN.instance.auth;
    
    if (auth.isAuthenticated) {
      // Check if token is close to expiring
      final session = auth.currentSession;
      if (session != null) {
        final expiresIn = session.expiresAt.difference(DateTime.now());
        if (expiresIn.inMinutes < 10) {
          // Refresh token if expiring soon
          await auth.refreshSession();
        }
      }
      return true;
    }
    
    // Need to authenticate
    return false;
  }
}
```

### Background Authentication

Handle authentication in background:

```dart
class BackgroundAuthManager {
  Timer? _refreshTimer;
  
  void startBackgroundRefresh() {
    _refreshTimer = Timer.periodic(Duration(minutes: 30), (timer) async {
      final auth = GroupVAN.instance.auth;
      if (auth.isAuthenticated) {
        try {
          await auth.refreshSession();
          print('Background token refresh successful');
        } catch (error) {
          print('Background refresh failed: $error');
          // May need to prompt user to re-authenticate
        }
      }
    });
  }
  
  void stopBackgroundRefresh() {
    _refreshTimer?.cancel();
  }
}
```

---

## Complete Authentication Flow Example

```dart
import 'package:flutter/material.dart';
import 'package:groupvan/groupvan.dart';

class AuthenticationFlow extends StatefulWidget {
  @override
  _AuthenticationFlowState createState() => _AuthenticationFlowState();
}

class _AuthenticationFlowState extends State<AuthenticationFlow> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _developerIdController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _checkExistingAuth();
  }

  Future<void> _checkExistingAuth() async {
    // Check if user is already authenticated
    if (GroupVAN.instance.auth.isAuthenticated) {
      _navigateToHome();
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await GroupVAN.instance.auth.signInWithPassword(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        developerId: _developerIdController.text.trim(),
        rememberMe: _rememberMe,
      );

      _navigateToHome();
    } catch (error) {
      setState(() {
        if (error is AuthenticationException) {
          switch (error.type) {
            case AuthErrorType.invalidCredentials:
              _errorMessage = 'Invalid username or password';
              break;
            case AuthErrorType.accountDisabled:
              _errorMessage = 'Account has been disabled';
              break;
            case AuthErrorType.tooManyAttempts:
              _errorMessage = 'Too many failed attempts. Please try again later.';
              break;
            case AuthErrorType.invalidDeveloperId:
              _errorMessage = 'Invalid developer ID';
              break;
            default:
              _errorMessage = 'Authentication failed: ${error.message}';
          }
        } else if (error is NetworkException) {
          _errorMessage = 'Network error. Please check your connection.';
        } else {
          _errorMessage = 'An unexpected error occurred';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GroupVAN Login'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo or branding
              Icon(
                Icons.car_rental,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 48),
              
              // Username field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 16),
              
              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 16),
              
              // Developer ID field
              TextFormField(
                controller: _developerIdController,
                decoration: InputDecoration(
                  labelText: 'Developer ID',
                  prefixIcon: Icon(Icons.developer_mode),
                  border: OutlineInputBorder(),
                  helperText: 'Provided by your GroupVAN Integration Specialist',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your developer ID';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: 16),
              
              // Remember me checkbox
              CheckboxListTile(
                title: Text('Remember me'),
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              SizedBox(height: 24),
              
              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],
              
              // Sign in button
              ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Sign In',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _developerIdController.dispose();
    super.dispose();
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = GroupVAN.instance.auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('GroupVAN Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await GroupVAN.instance.auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthenticationFlow()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 8),
                    if (user != null) ...[
                      Text('Username: ${user.username}'),
                      Text('User ID: ${user.userId}'),
                      Text('Developer ID: ${user.developerId}'),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Your authenticated session is now active. You can access all GroupVAN API endpoints.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Best Practices

### Security Best Practices

1. **Never log tokens** - Tokens should never appear in logs
```dart
// ❌ Wrong
print('Token: ${session.accessToken}');

// ✅ Correct  
print('User authenticated: ${auth.isAuthenticated}');
```

2. **Use secure storage** - Always use secure storage in production
```dart
// ✅ Production
await GroupVAN.initialize(
  tokenStorage: SecureTokenStorage(),
);

// ⚠️ Testing only
await GroupVAN.initialize(
  tokenStorage: MemoryTokenStorage(),
);
```

3. **Handle token expiration** - Always handle authentication errors gracefully
```dart
result.fold(
  (error) {
    if (error is AuthenticationException) {
      // Redirect to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  },
  (data) {
    // Handle success
  },
);
```

### Performance Best Practices

1. **Initialize once** - Initialize the SDK once at app startup
2. **Use authentication state streams** - React to auth changes instead of polling
3. **Enable automatic refresh** - Let the SDK handle token refresh automatically
4. **Cache authentication state** - Avoid repeated authentication checks

---

## Next Steps

- **[Getting Started](getting-started)** - Complete setup guide
- **[Vehicles API](vehicles/)** - Vehicle endpoints and examples  
- **[Catalogs API](catalogs/)** - Catalog endpoints and examples
- **[Error Handling](error-handling)** - Comprehensive error handling patterns
- **[Logging](logging)** - Debugging and monitoring