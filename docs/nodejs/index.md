---
layout: default
title: Node.js
nav_order: 5
has_children: true
---

# Node.js Client Library
{: .no_toc }

Complete documentation for the GroupVAN Node.js client library.
{: .fs-6 .fw-300 }

---

## Installation

### Requirements
- Node.js 16.0 or higher
- npm or yarn package manager

### Install from npm

```bash
# Using npm
npm install @groupvan/client

# Using yarn
yarn add @groupvan/client
```

## Quick Example

```javascript
const { GroupVANClient } = require('@groupvan/client');

// Initialize client
const client = new GroupVANClient({
    developerId: 'DEV123',
    keyId: 'KEY001',
    privateKeyPath: '/path/to/private_key.pem'
});

// Generate JWT token
const token = client.generateToken();

// Make API call
const response = await client.apiCall({
    method: 'GET',
    endpoint: '/api/v3/users',
    token: token
});

console.log(response.data);
```

## Configuration

### Using Environment Variables

```javascript
// Automatically reads from environment
const client = GroupVANClient.fromEnv();
// Looks for:
// - GROUPVAN_DEVELOPER_ID
// - GROUPVAN_KEY_ID
// - GROUPVAN_PRIVATE_KEY_PATH
```

### Using Configuration Object

```javascript
const client = new GroupVANClient({
    developerId: 'DEV123',
    keyId: 'KEY001',
    privateKeyPath: '/path/to/private_key.pem',
    baseUrl: 'https://api.groupvan.com', // optional
    timeout: 30000 // optional, in milliseconds
});
```

## API Reference

### Constructor Options

| Option | Type | Required | Description |
|:-------|:-----|:---------|:------------|
| `developerId` | string | Yes | Your GroupVAN developer ID |
| `keyId` | string | Yes | Your key identifier |
| `privateKeyPath` | string | No* | Path to private key file |
| `privateKey` | string | No* | Private key content |
| `baseUrl` | string | No | API base URL |
| `timeout` | number | No | Request timeout in ms |

### Methods

#### generateToken(options)
Generate a JWT token for API authentication.

```javascript
const token = client.generateToken({
    expirationMinutes: 5, // optional, default: 5
    additionalClaims: {} // optional
});
```

#### apiCall(options)
Make an authenticated API call.

```javascript
const response = await client.apiCall({
    method: 'GET',
    endpoint: '/api/v3/users',
    token: token, // optional, auto-generated if not provided
    data: {}, // request body for POST/PUT
    params: {}, // query parameters
    headers: {} // additional headers
});
```

## Error Handling

```javascript
try {
    const token = client.generateToken();
    const response = await client.apiCall({
        method: 'GET',
        endpoint: '/api/v3/users',
        token
    });
} catch (error) {
    if (error.name === 'AuthenticationError') {
        console.error('Authentication failed:', error.message);
    } else if (error.name === 'APIError') {
        console.error('API call failed:', error.message);
        console.error('Status:', error.statusCode);
    }
}
```

## TypeScript Support

The library includes TypeScript definitions:

```typescript
import { GroupVANClient, ClientOptions, TokenOptions } from '@groupvan/client';

const options: ClientOptions = {
    developerId: 'DEV123',
    keyId: 'KEY001',
    privateKeyPath: '/path/to/private_key.pem'
};

const client = new GroupVANClient(options);

const tokenOptions: TokenOptions = {
    expirationMinutes: 5
};

const token: string = client.generateToken(tokenOptions);
```

## Resources

- [Source Code](https://github.com/federatedops/GroupVAN-SDK/tree/main/clients/nodejs)
- [npm Package](https://www.npmjs.com/package/@groupvan/client)
- [Examples](https://github.com/federatedops/GroupVAN-SDK/tree/main/examples/nodejs)