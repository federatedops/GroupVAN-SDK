# GroupVAN SDK for JavaScript

A comprehensive client library for the GroupVAN V3 API, providing type-safe access to vehicle, catalog, cart, and search functionality.

## Installation

```bash
npm install @groupvan/sdk
```

## Quick Start

```javascript
import { GroupVAN } from '@groupvan/sdk';

// Initialize the SDK
await GroupVAN.initialize({
  clientId: 'your-client-id',
  isProduction: false, // Use true for production
});

// Login with email/password
await GroupVAN.client.auth.login({
  email: 'user@example.com',
  password: 'password',
  clientId: 'your-client-id',
});

// Or login with Google (browser only)
GroupVAN.client.auth.loginWithGoogle();

// Use API clients
const result = await GroupVAN.client.vehicles.getVehicleGroups();
if (result.isSuccess) {
  console.log('Vehicle groups:', result.value);
} else {
  console.error('Error:', result.error);
}
```

## Features

- **JWT Authentication** - Automatic token management with refresh
- **Type-Safe API** - Full JSDoc type annotations
- **Result Types** - Functional error handling with `Result<T>`
- **Input Validation** - Comprehensive validation with detailed error messages
- **Retry Logic** - Automatic retries with exponential backoff
- **Logging** - Professional logging system
- **Browser & Node.js** - Works in both environments

## Configuration

### Staging Environment (Default)

```javascript
await GroupVAN.initialize({
  clientId: 'your-client-id',
  isProduction: false,
});
```

### Production Environment

```javascript
await GroupVAN.initialize({
  clientId: 'your-client-id',
  isProduction: true,
});
```

### Custom Configuration

```javascript
import { GroupVAN, GroupVanClientConfig, LocalStorageTokenStorage } from '@groupvan/sdk';

const config = new GroupVanClientConfig({
  baseUrl: 'https://api.custom.groupvan.com',
  clientId: 'your-client-id',
  tokenStorage: new LocalStorageTokenStorage(),
  enableLogging: true,
  enableCaching: true,
});

const client = new GroupVanClient(config);
await client.initialize();
```

## API Reference

### Authentication

```javascript
// Login with email/password
await GroupVAN.client.auth.login({
  email: 'user@example.com',
  password: 'password',
  clientId: 'your-client-id',
});

// Check authentication status
const status = GroupVAN.client.authStatus;
console.log('Authenticated:', status.isAuthenticated);

// Subscribe to auth state changes
const unsubscribe = GroupVAN.client.auth.onAuthStateChange((status) => {
  console.log('Auth state changed:', status.state);
});

// Logout
await GroupVAN.client.auth.logout();
```

### Vehicles API

```javascript
// Get vehicle groups
const groups = await GroupVAN.client.vehicles.getVehicleGroups();

// Search vehicles
const search = await GroupVAN.client.vehicles.searchVehicles({
  query: '2020 Toyota',
  page: 1,
});

// Search by VIN
const vehicle = await GroupVAN.client.vehicles.searchByVin('1HGBH41JXMN109186');

// Search by license plate
const vehicles = await GroupVAN.client.vehicles.searchByPlate({
  plate: 'ABC123',
  state: 'CA',
});

// Get user vehicles with pagination
const userVehicles = await GroupVAN.client.vehicles.getUserVehicles({
  offset: 0,
  limit: 20,
});

// Filter vehicles
const filtered = await GroupVAN.client.vehicles.filterVehicles(
  new VehicleFilterRequest({ groupId: 1, yearId: 2020 })
);

// Get fleets
const fleets = await GroupVAN.client.vehicles.getFleets();
```

### Catalogs API

```javascript
// Get catalogs
const catalogs = await GroupVAN.client.catalogs.getCatalogs();

// Get vehicle categories
const categories = await GroupVAN.client.catalogs.getVehicleCategories({
  catalogId: 1,
  engineIndex: 12345,
});

// Get supply categories
const supplyCategories = await GroupVAN.client.catalogs.getSupplyCategories(1);

// Get application assets
const assets = await GroupVAN.client.catalogs.getApplicationAssets({
  applicationIds: [1, 2, 3],
});

// Get interchanges
const interchange = await GroupVAN.client.catalogs.getInterchanges({
  partNumber: 'ABC123',
});

// Get product info
const productInfo = await GroupVAN.client.catalogs.getProductInfo(12345);
```

### Cart API

```javascript
import { AddToCartRequest, CartItem, CartItemType } from '@groupvan/sdk';

// Add items to cart
const cartItem = new CartItem({
  mfrCode: 'ABC',
  partNumber: '12345',
  listPrice: 29.99,
  cost: 19.99,
  core: 0,
  quantity: 2,
  memberNumber: 'MEM001',
  locationId: 'LOC001',
  type: CartItemType.CATALOG,
});

const result = await GroupVAN.client.cart.addToCart(
  new AddToCartRequest({ items: [cartItem] })
);

// Remove items from cart
import { RemoveFromCartRequest, RemovalItem } from '@groupvan/sdk';

const removeResult = await GroupVAN.client.cart.removeFromCart(
  new RemoveFromCartRequest({
    cartId: 'cart-123',
    items: [new RemovalItem({ id: 1, quantity: 1 })],
  })
);
```

### Search API

```javascript
// Get VIN data
const vinData = await GroupVAN.client.search.vinData('1HGBH41JXMN109186');
```

### User API

```javascript
// Get location details
const location = await GroupVAN.client.user.getLocationDetails('LOC001');
```

## Error Handling

The SDK uses a `Result<T>` type for error handling:

```javascript
const result = await GroupVAN.client.vehicles.getVehicleGroups();

if (result.isSuccess) {
  // Access the value
  const groups = result.value;
  console.log(groups);
} else {
  // Handle the error
  const error = result.error;
  console.error(error.message);
}

// Or use fold for functional style
const message = result.fold(
  (error) => `Error: ${error.message}`,
  (value) => `Found ${value.length} groups`
);
```

### Exception Types

- `GroupVanException` - Base exception class
- `NetworkException` - Network/connection errors
- `HttpException` - HTTP response errors (4xx, 5xx)
- `AuthenticationException` - Authentication failures
- `ValidationException` - Input validation errors
- `ConfigurationException` - Configuration errors
- `RateLimitException` - Rate limiting (429)
- `DataException` - Data parsing errors

## Token Storage

The SDK provides multiple token storage options:

```javascript
import {
  MemoryTokenStorage,
  LocalStorageTokenStorage,
  SessionStorageTokenStorage,
  SecureTokenStorage,
} from '@groupvan/sdk';

// In-memory (not persisted)
new MemoryTokenStorage();

// LocalStorage (persisted across sessions, NOT encrypted)
new LocalStorageTokenStorage();

// SessionStorage (cleared on tab close, NOT encrypted)
new SessionStorageTokenStorage();

// Secure storage with AES-GCM encryption (RECOMMENDED)
new SecureTokenStorage();

// Custom storage
class CustomTokenStorage extends TokenStorage {
  async storeTokens({ accessToken, refreshToken }) { /* ... */ }
  async getTokens() { /* ... */ }
  async clearTokens() { /* ... */ }
}
```

### Secure Token Storage

The `SecureTokenStorage` class provides encrypted token storage using the Web Crypto API, similar to how `flutter_secure_storage` works in the Dart SDK. This is the recommended storage option for production applications.

**Features:**
- AES-256-GCM encryption for tokens at rest
- Automatically generates and manages encryption keys
- Keys are stored in localStorage but tokens remain encrypted
- Requires HTTPS (secure context) for Web Crypto API

**Usage:**

```javascript
import { GroupVAN, GroupVanClientConfig, SecureTokenStorage } from '@groupvan/sdk';

// Check if secure storage is supported
if (SecureTokenStorage.isSupported()) {
  const config = new GroupVanClientConfig({
    clientId: 'your-client-id',
    isProduction: true,
    tokenStorage: new SecureTokenStorage(),
  });

  const client = new GroupVanClient(config);
  await client.initialize();
}
```

**Note:** `SecureTokenStorage` requires a secure context (HTTPS) to access the Web Crypto API. In development on localhost, most browsers treat this as a secure context.

## Logging

```javascript
import { GroupVanLogger, LogLevel } from '@groupvan/sdk';

// Enable debug logging
GroupVanLogger.enableDebugLogging();

// Set custom log level
GroupVanLogger.setLevel(LogLevel.INFO);

// Disable logging
GroupVanLogger.disableLogging();
```

## Input Validation

```javascript
import { GroupVanValidators } from '@groupvan/sdk';

// Validate VIN
try {
  GroupVanValidators.vin().validateAndThrow('1HGBH41JXMN109186', 'vin');
} catch (e) {
  console.error(e.errorMessages);
}

// Available validators
GroupVanValidators.vin();
GroupVanValidators.licensePlate();
GroupVanValidators.usState();
GroupVanValidators.vehicleYear();
GroupVanValidators.paginationOffset();
GroupVanValidators.paginationLimit();
GroupVanValidators.searchQuery();
GroupVanValidators.sku();
GroupVanValidators.applicationIds();
```

## Browser Support

The SDK works in all modern browsers (Chrome, Firefox, Safari, Edge) and Node.js 18+.

For older browsers, you may need to polyfill:
- `fetch`
- `AbortController`
- `FormData`

## License

MIT

## Support

For issues and feature requests, please visit:
https://github.com/groupvan/sdk-javascript/issues
